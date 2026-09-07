# Nestarium multiplayer shard and roster migration

Status: protected routing, private per-player migration RPC and isolated empty
two-shard canary implemented; public activation blocked.
Updated: 2026-09-07.

## Compatibility boundary

The live protected Worker uses Durable Object name `protected-v1`. Its SQLite
database owns test Online Rosters, ratings, settlements, trades, reports and
blocks. That name is a data address, not cosmetic branding. Renaming it or
changing its shard count would make existing records appear absent.

The Worker therefore keeps the exact route while configured as:

```text
MATCHMAKING_POOL=protected-v1
MATCHMAKING_SHARD_COUNT=1
MATCHMAKING_ROUTING_MODE=single_compatibility
```

Routing code returns `protected-v1` byte-for-byte in this mode. Multi-shard
routing requires both a new immutable generation name and the explicit
`sharded_migration_ready` mode. The code refuses to shard `protected-v1`.
Invalid counts, names and modes fail closed before opening a WebSocket.

## Public topology

A public generation uses deterministic UID routing:

```text
<generation>-shard-<zero-padded index>
```

The FNV-1a mapping is versioned as part of the generation. A Firebase UID always
returns to the same pool, so its roster, pending receipts, blocks and reconnect
state stay co-located. Each pool retains the explicit 32-session guardrail.
Adding shards increases aggregate protected capacity, but also divides the
matchmaking population. The initial public shard count must be chosen from a
measured canary; it must not be changed in place.

This topology supports random battle/trade matchmaking. Cross-shard invitations
and global discovery remain disabled and are not implied by this design.

## Migration manifest

Before an existing generation can move, produce one private manifest containing:

- source generation and destination generation;
- immutable destination shard count and routing algorithm version;
- cutover time and source write-freeze time;
- per-UID destination shard, arena revision and inventory revision;
- counts and checksums for inventory rows, daily grants, unacknowledged battle
  settlements, unacknowledged trade receipts and block rows;
- active-session/trade/battle drain totals;
- report retention/export receipt;
- operator, verification result and rollback boundary.

The manifest must not contain Firebase tokens, email addresses, display names,
free text, credentials or private keys. UIDs belong only in the private
operations record, never public deployment logs or screenshots.

The Durable Object now exposes private RPC for migration mode/status, paginated
authority UID listing, per-player export and transactional import. Export/import
is accepted only after the generation reaches drained `read_only` mode. Each
bundle carries a SHA-256 checksum; a `(manifest ID, UID)` receipt makes the same
import idempotent and rejects a conflicting rerun. The operator bridge is not
attached to any public Worker route.

The local operator uses an internal remote service binding rather than a public
admin hostname. It writes only AES-256-GCM encrypted artifacts, refuses to
overwrite an existing artifact, takes its passphrase only from the process
environment and requires exact generation-name confirmation for every mutating
command. A live read-only status call is part of operator acceptance; no real
export/import is run merely to test the tool.

## Cutover sequence

1. **Create, do not repurpose, a generation.** Select a new non-public name such
   as `public-v1` and an immutable shard count. Keep the protected route on
   `protected-v1`.
2. **Canary empty data first.** The new configuration is deployed only on the
   separate Access-protected `nestarium-mp-canary.daygullstudios.com` hostname.
   Empty-shard status and the Access denial boundary pass. Still verify
   authenticated routing, capability denial, matching, trade atomicity,
   reconnect, rate limits, 32-session per-shard saturation and cost/latency.
   Do not attach `playnestarium.com`.
3. **Freeze new source activity.** Stop new battle/trade queues, allow active
   battles and trades to finish or expire, and confirm zero active rows. A route
   flip is not a substitute for a drain.
4. **Export owner state.** Through private Worker-to-Durable-Object RPC, export
   arena account, inventory account/rows, daily grants, unacknowledged settlement
   and trade receipts, and both directions of block rows. Export reports to the
   approved moderation/retention system instead of scattering the review queue
   across gameplay shards. Do not migrate active sessions, battles or trades.
5. **Import idempotently.** Route each UID with the checked-in algorithm. Import
   into an empty destination generation using transactions and immutable source
   revision/checksum markers. Re-running the same manifest must not duplicate an
   animal, reward, receipt or block.
6. **Verify before writes.** Compare every manifest count/checksum and sample
   disposable accounts through a separate protected canary. Any mismatch leaves
   source authority unchanged and the destination closed.
7. **One-way cutover.** Mark the manifest verified, set
   `MATCHMAKING_ROUTING_MODE=sharded_migration_ready`, then enable destination
   writes. Preserve the source generation read-only for the recorded recovery
   period. The public hostname still waits for its separate Access/Firebase/
   policy/origin gates.
8. **Rollback honestly.** Before destination writes, rollback is a configuration
   return to the frozen source. After destination writes, never point clients
   back blindly; reconcile forward using receipts/revisions or keep the
   destination authoritative while repairing routing.

## Required implementation before activation

The deterministic router, activation interlock, queue drain/read-only control,
paginated export, idempotent checked import, encrypted private operator and
Access-protected empty two-shard canary are complete. Canary Worker version
`f593529b-6aba-4d28-a87f-c29053b8add3` owns a dedicated custom domain and a
separate Durable Object namespace. Both `canary-v1-shard-00` and
`canary-v1-shard-01` report active, empty and drained; anonymous health requests
receive Access 302. No source data was exported or imported and no migration
mode changed. The following remain prerequisites:

- central moderation-report destination and retention procedure;
- authenticated multi-client canary behavior, saturation and measured latency/cost;
- representative human/device/network acceptance;
- reviewed family claim issuance/revocation and public hostname authorization.

No current player save, Firebase UID, local storage, package/bundle identity,
protected roster record, domain route or production credential changes in this
foundation.
