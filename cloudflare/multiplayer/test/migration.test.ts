import { env, exports } from "cloudflare:workers";
import { describe, expect, it } from "vitest";

import {
  playerAuthorityChecksum,
  type PlayerAuthorityExport,
} from "../src/migration";

const capabilities = JSON.stringify({
  onlineBattle: true,
  profileDiscovery: false,
  presetMessages: true,
  trading: true,
});

describe("multiplayer generation migration", () => {
  it("keeps migration operations off the public HTTP surface", async () => {
    const hidden = await exports.default.fetch(
      new Request("https://example.com/__migration", {
        method: "POST",
        body: JSON.stringify({ generation: "bridge-test", action: "status" }),
      }),
    );
    expect(hidden.status).toBe(404);
    const stillHidden = await exports.default.fetch(
      new Request("https://example.com/__migration", {
        method: "POST",
        headers: {
          "X-Nestarium-Migration-Binding": "private-binding-v1",
        },
        body: JSON.stringify({ generation: "bridge-test", action: "status" }),
      }),
    );
    expect(stillHidden.status).toBe(404);
    await expect(
      exports.MultiplayerOperator.migrationCall(
        "bridge-test",
        "status",
        {},
      ),
    ).resolves.toMatchObject({ mode: "active", drained: true });
  });

  it("drains through explicit modes and refuses new sessions", async () => {
    const pool = env.MATCHMAKING.getByName("migration-control-v1");
    const hidden = await pool.fetch(
      new Request("https://private-binding.invalid/__migration", {
        method: "POST",
        body: JSON.stringify({ action: "status" }),
      }),
    );
    expect(hidden.status).toBe(404);
    const visible = await pool.fetch(
      new Request("https://private-binding.invalid/__migration", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Nestarium-Migration-Binding": "private-binding-v1",
        },
        body: JSON.stringify({ action: "status" }),
      }),
    );
    expect(await visible.json()).toMatchObject({ mode: "active", drained: true });
    expect(await pool.setGenerationMigrationMode("draining")).toMatchObject({
      mode: "draining",
      drained: true,
    });

    const response = await pool.fetch(
      new Request("https://example.com/ws", {
        headers: {
          Upgrade: "websocket",
          "X-Nestarium-Uid": "migration-session",
          "X-Nestarium-Capabilities": capabilities,
        },
      }),
    );
    expect(response.status).toBe(503);
    expect(response.headers.get("Retry-After")).toBe("10");
    expect(await pool.setGenerationMigrationMode("read_only")).toMatchObject({
      mode: "read_only",
      drained: true,
    });
  });

  it("exports and idempotently imports checked player authority", async () => {
    const uid = "migration-player";
    const seeded = await authorityFixture(uid);
    const source = env.MATCHMAKING.getByName("migration-source-v1");
    await source.setGenerationMigrationMode("draining");
    await source.setGenerationMigrationMode("read_only");
    expect(await source.importPlayerAuthority("seed-manifest", seeded)).toEqual({
      uid,
      checksum: seeded.checksum,
      alreadyImported: false,
    });
    await source.setGenerationMigrationMode("active");
    await source.setGenerationMigrationMode("draining");
    await source.setGenerationMigrationMode("read_only");

    const exported = await source.exportPlayerAuthority(
      uid,
      "migration-source-v1",
    );
    expect(exported.payload).toEqual(seeded.payload);
    expect(exported.checksum).toMatch(/^[a-f0-9]{64}$/);
    expect(await source.listPlayerAuthorityUids("", 1)).toEqual({
      uids: ["blocked-player"],
      nextCursor: "blocked-player",
    });
    expect(await source.listPlayerAuthorityUids("blocked-player", 10)).toEqual({
      uids: [uid],
      nextCursor: null,
    });

    const destination = env.MATCHMAKING.getByName("migration-destination-v1");
    await destination.setGenerationMigrationMode("draining");
    await destination.setGenerationMigrationMode("read_only");
    expect(
      await destination.importPlayerAuthority("migration-manifest-v1", exported),
    ).toMatchObject({ uid, checksum: exported.checksum, alreadyImported: false });
    expect(
      await destination.importPlayerAuthority("migration-manifest-v1", exported),
    ).toMatchObject({ uid, checksum: exported.checksum, alreadyImported: true });

    const destinationExport = await destination.exportPlayerAuthority(
      uid,
      "migration-destination-v1",
    );
    expect(destinationExport.payload).toEqual(exported.payload);

    const tampered = structuredClone(exported);
    tampered.payload.inventory[0].quantity += 1;
    const { checksum: ignored, ...tamperedUnsigned } = tampered;
    expect(await playerAuthorityChecksum(tamperedUnsigned)).not.toBe(
      exported.checksum,
    );
  });
});

async function authorityFixture(uid: string): Promise<PlayerAuthorityExport> {
  const unsigned = {
    schemaVersion: 1 as const,
    sourceGeneration: "fixture-v0",
    uid,
    payload: {
      arenaAccount: {
        uid,
        rating: 1120,
        win_streak: 2,
        wins: 5,
        losses: 3,
        coins_earned: 750,
        tokens_earned: 3,
        updated_at: 100,
      },
      inventoryAccount: {
        uid,
        revision: 4,
        created_at: 10,
        updated_at: 110,
      },
      inventory: [
        {
          uid,
          item_key: "chicken:none:1",
          animal_id: "chicken",
          mutation_id: "none",
          level: 1,
          quantity: 2,
          updated_at: 110,
        },
      ],
      grants: [
        {
          grant_id: "grant-1",
          uid,
          match_id: "match-1",
          grant_key: "daily:2026-09-07",
          item_json: '{"animalId":"chicken"}',
          created_at: 105,
        },
      ],
      pendingSettlements: [
        {
          receipt_id: "match-1:migration-player",
          match_id: "match-1",
          uid,
          won: 1,
          rating_change: 18,
          coins: 250,
          battle_tokens: 1,
          server_rating: 1120,
          roster_reward_json: '{"animalId":"chicken"}',
          acknowledged: 0,
          created_at: 106,
        },
      ],
      pendingTradeReceipts: [
        {
          receipt_id: "trade-1:migration-player",
          trade_id: "trade-1",
          uid,
          sent_json: '{"animalId":"mouse"}',
          received_json: '{"animalId":"rabbit"}',
          acknowledged: 0,
          created_at: 107,
        },
      ],
      blocks: [
        {
          blocker_uid: uid,
          blocked_uid: "blocked-player",
          context_type: "battle",
          context_id: "match-0",
          created_at: 108,
        },
      ],
    },
  };
  return { ...unsigned, checksum: await playerAuthorityChecksum(unsigned) };
}
