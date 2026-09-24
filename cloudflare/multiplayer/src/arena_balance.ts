export type HostedArenaReward = {
  ratingChange: number;
  coins: number;
  battleTokens: number;
};

export function hostedArenaReward(
  won: boolean,
  playerRating: number,
  opponentRating: number,
  currentStreak: number,
): HostedArenaReward {
  const difference = opponentRating - playerRating;
  if (!won) {
    return {
      ratingChange: -clamp(12 - Math.trunc(difference / 25), 6, 18),
      coins: 0,
      battleTokens: 0,
    };
  }
  const ratingChange = clamp(18 + Math.trunc(difference / 25), 12, 28);
  const nextStreak = currentStreak + 1;
  return {
    ratingChange,
    // Rewards never depend on client-supplied fighter power.
    coins: 250,
    battleTokens:
      1 + (opponentRating >= 1250 ? 1 : 0) + (nextStreak % 5 === 0 ? 1 : 0),
  };
}

const earlyOnlineRosterRewards = [
  "chicken",
  "mouse",
  "rabbit",
  "fox",
  "deer",
  "bear",
  "cow",
  "pig",
  "sheep",
  "horse",
] as const;

const establishedOnlineRosterRewards = [
  ...earlyOnlineRosterRewards,
  "tiger",
  "dragon",
  "unicorn",
  "monkey",
  "parrot",
  "snake",
  "gorilla",
] as const;

const advancedOnlineRosterRewards = [
  ...establishedOnlineRosterRewards,
  "fish",
  "turtle",
  "dolphin",
  "shark",
  "penguin",
  "seal",
  "polar_bear",
  "snow_owl",
  "raptor",
  "triceratops",
  "t_rex",
  "fossil_dragon",
  "moon_cat",
  "star_fox",
  "alien_slime",
  "galaxy_dragon",
] as const;

export function onlineRosterRewardPool(rating: number): readonly string[] {
  if (rating >= 1600) return advancedOnlineRosterRewards;
  if (rating >= 1250) return establishedOnlineRosterRewards;
  return earlyOnlineRosterRewards;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, Math.trunc(value)));
}
