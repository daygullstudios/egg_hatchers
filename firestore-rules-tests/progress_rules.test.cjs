const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { serverTimestamp } = require('firebase/firestore');

const projectId = 'egg-hatchers-dev';
let environment;

function progress(uid, revision = 1, overrides = {}) {
  return {
    format: 'egg_hatchers_cloud_progress',
    schemaVersion: 1,
    ownerUid: uid,
    cloudRevision: revision,
    localRevision: revision,
    savedAt: serverTimestamp(),
    contentFingerprint: 'a'.repeat(64),
    playerState: { coins: 250 },
    ...overrides,
  };
}

function document(context, uid) {
  return context.firestore().doc(`users/${uid}/products/egg_hatchers`);
}

test.before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

test.after(async () => {
  await environment.cleanup();
});

test.beforeEach(async () => {
  await environment.clearFirestore();
});

test('anonymous owner may create, read, and increment a progress revision', async () => {
  const owner = environment.authenticatedContext('guest-uid', {
    firebase: { sign_in_provider: 'anonymous' },
  });
  const ref = document(owner, 'guest-uid');
  await assertSucceeds(ref.set(progress('guest-uid')));
  await assertSucceeds(ref.get());
  await assertSucceeds(ref.set(progress('guest-uid', 2)));
});

test('signed-out and different users cannot read or write progress', async () => {
  const owner = environment.authenticatedContext('guest-uid');
  await assertSucceeds(document(owner, 'guest-uid').set(progress('guest-uid')));

  const signedOut = environment.unauthenticatedContext();
  const attacker = environment.authenticatedContext('other-uid');
  await assertFails(document(signedOut, 'guest-uid').get());
  await assertFails(document(attacker, 'guest-uid').get());
  await assertFails(
    document(attacker, 'guest-uid').set(progress('guest-uid', 2)),
  );
});

test('revision skips, owner changes, extra fields, and deletes are rejected', async () => {
  const owner = environment.authenticatedContext('guest-uid');
  const ref = document(owner, 'guest-uid');
  await assertSucceeds(ref.set(progress('guest-uid')));
  await assertFails(ref.set(progress('guest-uid', 1)));
  await assertFails(ref.set(progress('guest-uid', 3)));
  await assertFails(ref.set(progress('other-uid', 2)));
  await assertFails(ref.set(progress('guest-uid', 2, { surprise: true })));
  await assertFails(ref.delete());
});
