import { describe, expect, it } from "vitest";

import {
  matchmakingShardCount,
  maximumMatchmakingShardCount,
  routeMatchmakingPool,
} from "../src/pool_routing";

describe("matchmaking pool routing", () => {
  it("preserves the exact compatibility pool when configured for one shard", () => {
    expect(
      routeMatchmakingPool(
        "existing-player",
        "protected-v1",
        "1",
        "single_compatibility",
      ),
    ).toEqual({
      poolName: "protected-v1",
      shardCount: 1,
      shardIndex: 0,
    });
  });

  it("routes each UID deterministically across a versioned sharded generation", () => {
    const first = routeMatchmakingPool(
      "stable-player",
      "public-v1",
      "16",
      "sharded_migration_ready",
    );
    expect(
      routeMatchmakingPool(
        "stable-player",
        "public-v1",
        "16",
        "sharded_migration_ready",
      ),
    ).toEqual(first);
    expect(first.poolName).toBe(
      `public-v1-shard-${first.shardIndex.toString().padStart(2, "0")}`,
    );

    const observed = new Set(
      Array.from({ length: 2_000 }, (_, index) =>
        routeMatchmakingPool(
          `player-${index}`,
          "public-v1",
          "16",
          "sharded_migration_ready",
        ).shardIndex,
      ),
    );
    expect(observed.size).toBe(16);
  });

  it("fails closed for invalid counts or an unapproved migration mode", () => {
    for (const value of ["", "0", "01", "1.5", "257", "many"]) {
      expect(() => matchmakingShardCount(value)).toThrow(
        "invalid matchmaking shard count",
      );
    }
    expect(maximumMatchmakingShardCount).toBe(256);
    expect(() =>
      routeMatchmakingPool(
        "player",
        "public-v1",
        "4",
        "single_compatibility",
      ),
    ).toThrow("sharded routing migration is not ready");
    expect(() =>
      routeMatchmakingPool(
        "player",
        "protected-v1",
        "4",
        "sharded_migration_ready",
      ),
    ).toThrow("protected compatibility generation cannot be sharded");
  });
});
