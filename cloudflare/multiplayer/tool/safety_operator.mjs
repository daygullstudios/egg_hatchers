import { readFile, writeFile } from "node:fs/promises";
import process from "node:process";
import { fileURLToPath } from "node:url";

import { encryptArtifact } from "./migration_operator.mjs";

const uidVariable = "NESTARIUM_SAFETY_UID";
const passphraseVariable = "NESTARIUM_SAFETY_EXPORT_PASSPHRASE";

async function main() {
  const [command, config, third = "", fourth = ""] = process.argv.slice(2);
  if (!command || !config) throw new Error(usage());
  const { getPlatformProxy } = await import("wrangler");
  const platform = await getPlatformProxy({
    configPath: config,
    remoteBindings: true,
    persist: false,
  });
  try {
    const service = platform.env.MULTIPLAYER;
    switch (command) {
      case "summary":
        requireLength(2);
        printJson(await service.safetySummary());
        return;
      case "backfill-reports":
        requireLength(3);
        await backfillReports(service, third);
        return;
      case "export-reports":
        requireLength(3);
        await exportReports(service, third);
        return;
      case "capability-get":
        requireLength(2);
        printJson(await service.getCapability(requireUid()));
        return;
      case "capability-issue":
        requireLength(4);
        await issueCapability(service, third, fourth);
        return;
      case "capability-revoke":
        requireLength(4);
        if (third !== fourth) throw new Error("review reference confirmation mismatch");
        printJson(await service.revokeCapability(requireUid(), third));
        return;
      default:
        throw new Error(usage());
    }
  } finally {
    await platform.dispose();
  }
}

async function backfillReports(service, generation) {
  let createdAt = 0;
  let reportId = "";
  let scanned = 0;
  let inserted = 0;
  for (;;) {
    const page = await service.centralizeReports(
      generation,
      createdAt,
      reportId,
      100,
    );
    scanned += page.scanned;
    inserted += page.inserted;
    if (!page.nextCursor) break;
    createdAt = page.nextCursor.createdAt;
    reportId = page.nextCursor.reportId;
  }
  printJson({ generation, scanned, inserted });
}

async function exportReports(service, file) {
  const reports = [];
  let createdAt = 0;
  let reportId = "";
  for (;;) {
    const page = await service.listReports(createdAt, reportId, 100);
    reports.push(...page.reports);
    if (!page.nextCursor) break;
    createdAt = page.nextCursor.createdAt;
    reportId = page.nextCursor.reportId;
  }
  const artifact = encryptArtifact(
    {
      schemaVersion: 1,
      createdAt: new Date().toISOString(),
      reports,
    },
    process.env[passphraseVariable],
  );
  await writeFile(file, `${JSON.stringify(artifact, null, 2)}\n`, {
    encoding: "utf8",
    flag: "wx",
    mode: 0o600,
  });
  printJson({ written: file, reports: reports.length });
}

async function issueCapability(service, file, confirmation) {
  const input = JSON.parse(await readFile(file, "utf8"));
  if (input.decisionId !== confirmation) {
    throw new Error("decision id confirmation mismatch");
  }
  printJson(await service.issueCapability(requireUid(), input));
}

function requireUid() {
  const uid = process.env[uidVariable];
  if (!uid) throw new Error(`${uidVariable} is required`);
  return uid;
}

function requireLength(expected) {
  if (process.argv.slice(2).length !== expected) throw new Error(usage());
}

function printJson(value) {
  process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
}

function usage() {
  return [
    "usage:",
    "  safety_operator.mjs summary <config>",
    "  safety_operator.mjs backfill-reports <config> <generation>",
    "  safety_operator.mjs export-reports <config> <artifact>",
    "  safety_operator.mjs capability-get <config>",
    "  safety_operator.mjs capability-issue <config> <decision-json> <exact-decision-id>",
    "  safety_operator.mjs capability-revoke <config> <review-reference> <exact-review-reference>",
  ].join("\n");
}

if (process.argv[1] && fileURLToPath(import.meta.url) === process.argv[1]) {
  main().catch((error) => {
    process.stderr.write(`${error instanceof Error ? error.message : error}\n`);
    process.exitCode = 1;
  });
}
