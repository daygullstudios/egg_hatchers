export type RatedQueueEntry = {
  rating: number;
  queuedAt: number;
};

export const initialRatingWindow = 100;
export const maximumRatingWindow = 400;
export const ratingWindowStep = 50;
export const ratingWindowStepMs = 15_000;

export function matchmakingRatingWindow(queuedAt: number, now: number): number {
  const waitMs = Math.max(0, now - queuedAt);
  return Math.min(
    maximumRatingWindow,
    initialRatingWindow +
      Math.floor(waitMs / ratingWindowStepMs) * ratingWindowStep,
  );
}

export function isFairMatch(
  first: RatedQueueEntry,
  second: RatedQueueEntry,
  now: number,
): boolean {
  const allowedDifference = Math.max(
    matchmakingRatingWindow(first.queuedAt, now),
    matchmakingRatingWindow(second.queuedAt, now),
  );
  return Math.abs(first.rating - second.rating) <= allowedDifference;
}

export function compareFairCandidates(
  seeker: RatedQueueEntry,
  first: RatedQueueEntry,
  second: RatedQueueEntry,
): number {
  const firstDifference = Math.abs(seeker.rating - first.rating);
  const secondDifference = Math.abs(seeker.rating - second.rating);
  return firstDifference - secondDifference || first.queuedAt - second.queuedAt;
}
