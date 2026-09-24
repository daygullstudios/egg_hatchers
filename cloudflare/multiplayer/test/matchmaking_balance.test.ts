import { describe, expect, it } from "vitest";

import {
  hostedArenaReward,
  onlineRosterRewardPool,
} from "../src/arena_balance";
import {
  compareFairCandidates,
  initialRatingWindow,
  isFairMatch,
  matchmakingRatingWindow,
  maximumRatingWindow,
} from "../src/matchmaking";

describe("representative matchmaking fairness", () => {
  it("starts narrow, expands predictably, and stays capped", () => {
    expect(matchmakingRatingWindow(100_000, 100_000)).toBe(
      initialRatingWindow,
    );
    expect(matchmakingRatingWindow(100_000, 115_000)).toBe(150);
    expect(matchmakingRatingWindow(100_000, 190_000)).toBe(
      maximumRatingWindow,
    );
    expect(matchmakingRatingWindow(100_000, 500_000)).toBe(
      maximumRatingWindow,
    );
  });

  it("keeps fresh queues close and lets established waits broaden", () => {
    const now = 100_000;
    expect(
      isFairMatch(
        { rating: 1000, queuedAt: now },
        { rating: 1099, queuedAt: now },
        now,
      ),
    ).toBe(true);
    expect(
      isFairMatch(
        { rating: 1000, queuedAt: now },
        { rating: 1101, queuedAt: now },
        now,
      ),
    ).toBe(false);
    expect(
      isFairMatch(
        { rating: 1000, queuedAt: now },
        { rating: 1300, queuedAt: now - 60_000 },
        now,
      ),
    ).toBe(true);
    expect(
      isFairMatch(
        { rating: 1000, queuedAt: now - 600_000 },
        { rating: 1401, queuedAt: now - 600_000 },
        now,
      ),
    ).toBe(false);
  });

  it("prefers the closest rating before using queue age", () => {
    const seeker = { rating: 1000, queuedAt: 100_000 };
    const olderFarther = { rating: 1090, queuedAt: 10_000 };
    const newerCloser = { rating: 1020, queuedAt: 90_000 };
    expect(compareFairCandidates(seeker, olderFarther, newerCloser)).toBeGreaterThan(0);
    expect(
      compareFairCandidates(
        seeker,
        { rating: 1020, queuedAt: 50_000 },
        newerCloser,
      ),
    ).toBeLessThan(0);
  });
});

describe("representative hosted reward balance", () => {
  it("keeps equal-rating results within the launch reward budget", () => {
    expect(hostedArenaReward(true, 1000, 1000, 0)).toEqual({
      ratingChange: 18,
      coins: 250,
      battleTokens: 1,
    });
    expect(hostedArenaReward(false, 1000, 1000, 0)).toEqual({
      ratingChange: -12,
      coins: 0,
      battleTokens: 0,
    });
  });

  it("bounds favorite and underdog rating movement", () => {
    expect(hostedArenaReward(true, 900, 1400, 0).ratingChange).toBe(28);
    expect(hostedArenaReward(true, 1400, 900, 0).ratingChange).toBe(12);
    expect(hostedArenaReward(false, 900, 1400, 0).ratingChange).toBe(-6);
    expect(hostedArenaReward(false, 1400, 900, 0).ratingChange).toBe(-18);
  });

  it("adds only the documented opponent and fifth-win token bonuses", () => {
    expect(hostedArenaReward(true, 1200, 1250, 0).battleTokens).toBe(2);
    expect(hostedArenaReward(true, 1000, 1000, 4).battleTokens).toBe(2);
    expect(hostedArenaReward(true, 1200, 1250, 4).battleTokens).toBe(3);
  });

  it("expands roster rewards by rating without exposing secret animals", () => {
    const early = onlineRosterRewardPool(1249);
    const established = onlineRosterRewardPool(1250);
    const advanced = onlineRosterRewardPool(1600);
    expect(early).toHaveLength(10);
    expect(established.length).toBeGreaterThan(early.length);
    expect(advanced.length).toBeGreaterThan(established.length);
    for (const pool of [early, established, advanced]) {
      expect(pool).not.toContain("the_hatched_egg");
      expect(pool).not.toContain("boba_bazooka");
      expect(pool).not.toContain("crossword_beast");
    }
  });
});
