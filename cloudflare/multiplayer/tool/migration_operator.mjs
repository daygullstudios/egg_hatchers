import {
  createCipheriv,
  createDecipheriv,
  createHash,
  pbkdf2Sync,
  randomBytes,
} from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";
import process from "node:process";
import { fileURLToPath } from "node:url";

const artifactVersion = 1;
const kdfIterations = 310_000;
const passphraseVariable = "NESTARIUM_MIGRATION_PASSPHRASE";

export function manifestChecksum(manifest) {
  return createHash("sha256")
    .update(
      JSON.stringify({
        schemaVersion: manifest.schemaVersion,
        sourceGeneration: manifest.sourceGeneration,
        entries: manifest.entries.map(({ uid, checksum }) => ({ uid, checksum })),
      }),
    )
    .digest("hex");
}

export function encryptArtifact(value, passphrase) {
  requirePassphrase(passphrase);
  const salt = randomBytes(16);
  const iv = randomBytes(12);
  const key = pbkdf2Sync(passphrase, salt, kdfIterations, 32, "sha256");
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  const plaintext = Buffer.from(JSON.stringify(value), "utf8");
  const ciphertext = Buffer.concat([cipher.update(plaintext), cipher.final()]);
  return {
    artifactVersion,
    cipher: "aes-256-gcm",
    kdf: "pbkdf2-sha256",
    iterations: kdfIterations,
    salt: salt.toString("base64"),
    iv: iv.toString("base64"),
    tag: cipher.getAuthTag().toString("base64"),
    ciphertext: ciphertext.toString("base64"),
  };
}

export function decryptArtifact(artifact, passphrase) {
  requirePassphrase(passphrase);
  if (
    artifact?.artifactVersion !== artifactVersion ||
    artifact?.cipher !== "aes-256-gcm" ||
    artifact?.kdf !== "pbkdf2-sha256" ||
    artifact?.iterations !== kdfIterations
  ) {
    throw new Error("unsupported migration artifact");
  }
  const salt = Buffer.from(artifact.salt, "base64");
  const iv = Buffer.from(artifact.iv, "base64");
  const tag = Buffer.from(artifact.tag, "base64");
  const key = pbkdf2Sync(passphrase, salt, kdfIterations, 32, "sha256");
  const decipher = createDecipheriv("aes-256-gcm", key, iv);
  decipher.setAuthTag(tag);
  const plaintext = Buffer.concat([
    decipher.update(Buffer.from(artifact.ciphertext, "base64")),
    decipher.final(),
  ]);
  return JSON.parse(plaintext.toString("utf8"));
}

async function main() {
  const options = parseArguments(process.argv.slice(2));
  const { getPlatformProxy } = await import("wrangler");
  const platform = await getPlatformProxy({
    configPath: options.config,
    remoteBindings: true,
    persist: false,
  });
  try {
    const service = platform.env.MULTIPLAYER;
    switch (options.command) {
      case "status":
        printJson(await migrationCall(service, options.generation, "status"));
        return;
      case "begin-drain":
        requireConfirmation(options);
        printJson(await migrationCall(service, options.generation, "setMode", { mode: "draining" }));
        return;
      case "freeze":
        requireConfirmation(options);
        printJson(await migrationCall(service, options.generation, "setMode", { mode: "read_only" }));
        return;
      case "activate":
        requireConfirmation(options);
        printJson(await migrationCall(service, options.generation, "setMode", { mode: "active" }));
        return;
      case "export":
        await exportManifest(service, options);
        return;
      case "import":
        requireConfirmation(options);
        await importManifest(service, options);
        return;
      default:
        throw new Error(`unsupported command: ${options.command}`);
    }
  } finally {
    await platform.dispose();
  }
}

async function exportManifest(service, options) {
  if (!options.file) throw new Error("export requires --file");
  const status = await migrationCall(service, options.generation, "status");
  if (status.mode !== "read_only" || !status.drained) {
    throw new Error("export requires a drained read-only generation");
  }
  const entries = [];
  let cursor = "";
  do {
    const page = await migrationCall(service, options.generation, "listUids", {
      afterUid: cursor,
      limit: 100,
    });
    for (const uid of page.uids) {
      entries.push(
        await migrationCall(service, options.generation, "exportPlayer", {
          uid,
          sourceGeneration: options.generation,
        }),
      );
    }
    cursor = page.nextCursor ?? "";
  } while (cursor);
  const manifest = {
    schemaVersion: 1,
    sourceGeneration: options.generation,
    createdAt: new Date().toISOString(),
    entries,
  };
  const wrapped = { ...manifest, manifestId: manifestChecksum(manifest) };
  const encrypted = encryptArtifact(
    wrapped,
    process.env[passphraseVariable],
  );
  await writeFile(options.file, `${JSON.stringify(encrypted, null, 2)}\n`, {
    encoding: "utf8",
    flag: "wx",
    mode: 0o600,
  });
  printJson({
    written: options.file,
    sourceGeneration: options.generation,
    players: entries.length,
    manifestId: wrapped.manifestId,
  });
}

async function importManifest(service, options) {
  if (!options.file) throw new Error("import requires --file");
  const encrypted = JSON.parse(await readFile(options.file, "utf8"));
  const manifest = decryptArtifact(
    encrypted,
    process.env[passphraseVariable],
  );
  const actual = manifestChecksum(manifest);
  if (manifest.manifestId !== actual) {
    throw new Error("migration manifest checksum mismatch");
  }
  const status = await migrationCall(service, options.generation, "status");
  if (status.mode !== "read_only" || !status.drained) {
    throw new Error("import requires a drained read-only generation");
  }
  let imported = 0;
  let alreadyImported = 0;
  for (const entry of manifest.entries) {
    const result = await migrationCall(service, options.generation, "importPlayer", {
      manifestId: manifest.manifestId,
      bundle: entry,
    });
    if (result.alreadyImported) alreadyImported += 1;
    else imported += 1;
  }
  printJson({
    destinationGeneration: options.generation,
    sourceGeneration: manifest.sourceGeneration,
    players: manifest.entries.length,
    imported,
    alreadyImported,
    manifestId: manifest.manifestId,
  });
}

async function migrationCall(service, generation, action, payload = {}) {
  const response = await service.fetch(
    "https://private-binding.invalid/__migration",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Nestarium-Migration-Binding": "private-binding-v1",
      },
      body: JSON.stringify({ generation, action, ...payload }),
    },
  );
  const responseText = await response.text();
  let result;
  try {
    result = JSON.parse(responseText);
  } catch {
    throw new Error(
      `migration binding returned ${response.status}: ${responseText.slice(0, 160)}`,
    );
  }
  if (!response.ok) {
    throw new Error(result?.error ?? `migration operation failed (${response.status})`);
  }
  return result;
}

function parseArguments(values) {
  const [command, config = "", generation = "", fourth = "", fifth = ""] =
    values;
  const needsFile = command === "export" || command === "import";
  const options = {
    command,
    config,
    generation,
    file: needsFile ? fourth : "",
    confirm: command === "import" ? fifth : needsFile ? "" : fourth,
  };
  if (!command || !options.config || !options.generation) {
    throw new Error(
      "usage: migration_operator.mjs <command> <config> <generation> [artifact] [exact-generation-confirmation]",
    );
  }
  const expectedLength = command === "import" ? 5 : needsFile || command !== "status" ? 4 : 3;
  if (values.length !== expectedLength) throw new Error("invalid argument count");
  return options;
}

function requireConfirmation(options) {
  if (options.confirm !== options.generation) {
    throw new Error(
      `mutation requires exact generation confirmation: ${options.generation}`,
    );
  }
}

function requirePassphrase(passphrase) {
  if (typeof passphrase !== "string" || passphrase.length < 16) {
    throw new Error(`${passphraseVariable} must contain at least 16 characters`);
  }
}

function printJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exitCode = 1;
  });
}
