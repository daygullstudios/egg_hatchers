import { describe, expect, it } from "vitest";

import {
  authoritativeFighter,
  collectEnergy,
  createBattle,
  expireReconnect,
  markReady,
  pauseBattle,
  processBattleClock,
  resumeBattle,
  stateFor,
  useAbility,
} from "../src/battle";

describe("server-run battle", () => {
  it("derives power from the owned animal contract", () => {
    expect(authoritativeFighter("chicken", "none", 1)?.power).toBe(1);
    expect(authoritativeFighter("chicken", "shadow", 3)?.power).toBe(30);
    expect(authoritativeFighter("unknown", "none", 1)).toBeUndefined();
    expect(authoritativeFighter("chicken", "forged", 1)).toBeUndefined();
  });

  it("runs readiness, energy, attacks, and recipient-relative outcomes", () => {
    const strong = authoritativeFighter("dragon", "shadow", 50)!;
    const weak = authoritativeFighter("chicken", "none", 1)!;
    const battle = createBattle(
      "match-1",
      "first-uid",
      "Player FIRST",
      [strong, strong, strong],
      "second-uid",
      "Player SECOND",
      [weak, weak, weak],
    );
    expect(markReady(battle, "first-uid", 1_000).message).toBeUndefined();
    expect(markReady(battle, "second-uid", 1_000).message).toContain(
      "Collect energy",
    );

    const clock = processBattleClock(battle, 1_550, () => 0.5);
    expect(clock.notices).toHaveLength(2);
    expect(battle.players[0].activeSpawnId).toBe(1);
    expect(collectEnergy(battle, "first-uid", 1, 1_600, () => 0).changed).toBe(
      true,
    );
    expect(battle.players[0].energy).toBe(1);

    while (!battle.finished) {
      battle.players[0].energy = 10;
      expect(useAbility(battle, "first-uid", 2, () => 0.5).changed).toBe(true);
    }
    battle.revision += 1;
    const winner = stateFor(
      battle,
      "first-uid",
      "Player FIRST wins",
      "first-uid",
    );
    const loser = stateFor(
      battle,
      "second-uid",
      "Player FIRST wins",
      "first-uid",
    );
    expect(winner).toMatchObject({
      revision: 1,
      lastActor: "self",
      winner: "self",
    });
    expect(loser).toMatchObject({
      revision: 1,
      lastActor: "opponent",
      winner: "opponent",
    });
  });

  it("pauses battle clocks for reconnect and expires without a winner", () => {
    const fighter = authoritativeFighter("chicken", "none", 1)!;
    const battle = createBattle(
      "match-reconnect",
      "first-uid",
      "Player FIRST",
      [fighter, fighter, fighter],
      "second-uid",
      "Player SECOND",
      [fighter, fighter, fighter],
    );
    markReady(battle, "first-uid", 1_000);
    markReady(battle, "second-uid", 1_000);
    expect(battle.players[0].nextSpawnAt).toBe(1_550);

    expect(pauseBattle(battle, "first-uid", 1_200, 31_200).changed).toBe(true);
    expect(processBattleClock(battle, 20_000).changed).toBe(false);
    expect(resumeBattle(battle, "first-uid", 11_200).message).toContain(
      "resumed",
    );
    expect(battle.players[0].nextSpawnAt).toBe(11_550);

    pauseBattle(battle, "first-uid", 12_000, 42_000);
    expect(expireReconnect(battle, 41_999).changed).toBe(false);
    expect(expireReconnect(battle, 42_000).changed).toBe(true);
    expect(battle.finished).toBe(true);
    expect(battle.winnerUid).toBeUndefined();
  });
});
