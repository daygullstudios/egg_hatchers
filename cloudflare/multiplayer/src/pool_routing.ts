export type MatchmakingPoolRoute = {
  poolName: string;
  shardCount: number;
  shardIndex: number;
};

export const maximumMatchmakingShardCount = 256;

export function matchmakingShardCount(rawValue: string): number {
  if (!/^[1-9][0-9]{0,2}$/.test(rawValue)) {
    throw new Error("invalid matchmaking shard count");
  }
  const value = Number(rawValue);
  if (!Number.isSafeInteger(value) || value > maximumMatchmakingShardCount) {
    throw new Error("invalid matchmaking shard count");
  }
  return value;
}

export function routeMatchmakingPool(
  uid: string,
  generation: string,
  rawShardCount: string,
  routingMode: string,
): MatchmakingPoolRoute {
  if (!/^[a-z0-9][a-z0-9._-]{0,79}$/i.test(generation)) {
    throw new Error("invalid matchmaking generation");
  }
  const shardCount = matchmakingShardCount(rawShardCount);
  if (shardCount === 1) {
    if (routingMode !== "single_compatibility") {
      throw new Error("single-pool routing is not explicitly enabled");
    }
    return { poolName: generation, shardCount, shardIndex: 0 };
  }
  if (routingMode !== "sharded_migration_ready") {
    throw new Error("sharded routing migration is not ready");
  }
  if (generation === "protected-v1") {
    throw new Error("the protected compatibility generation cannot be sharded");
  }
  const shardIndex = stableStringIndex(uid, shardCount);
  const width = Math.max(2, (shardCount - 1).toString().length);
  return {
    poolName: `${generation}-shard-${shardIndex.toString().padStart(width, "0")}`,
    shardCount,
    shardIndex,
  };
}

function stableStringIndex(value: string, length: number): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193);
  }
  return (hash >>> 0) % length;
}
