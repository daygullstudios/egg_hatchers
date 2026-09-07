import assert from "node:assert/strict";
import test from "node:test";

import {
  decryptArtifact,
  encryptArtifact,
  manifestChecksum,
} from "./migration_operator.mjs";

const passphrase = "disposable-test-passphrase";

test("encrypted migration artifacts round-trip and reject the wrong key", () => {
  const value = { manifestId: "test", entries: [{ uid: "opaque-uid" }] };
  const encrypted = encryptArtifact(value, passphrase);
  assert.deepEqual(decryptArtifact(encrypted, passphrase), value);
  assert.throws(() => decryptArtifact(encrypted, "another-test-passphrase"));
  assert.equal(JSON.stringify(encrypted).includes("opaque-uid"), false);
});

test("manifest checksum covers ordered player checksums but not wall-clock time", () => {
  const first = {
    schemaVersion: 1,
    sourceGeneration: "source-v1",
    createdAt: "first",
    entries: [{ uid: "uid-a", checksum: "checksum-a", payload: {} }],
  };
  const second = { ...first, createdAt: "second" };
  assert.equal(manifestChecksum(first), manifestChecksum(second));
  second.entries = [{ ...first.entries[0], checksum: "changed" }];
  assert.notEqual(manifestChecksum(first), manifestChecksum(second));
});
