import { animalCatalog, mutationMultipliers } from "./game_catalog.generated";

export type BattleFighter = {
  animalId: string;
  mutationId: string;
  level: number;
  power: number;
};

export type BattleCombatant = {
  uid: string;
  name: string;
  fighters: BattleFighter[];
  health: number[];
  activeIndex: number;
  energy: number;
  shield: number;
  energyHits: number;
  energyMisses: number;
  combo: number;
  bestCombo: number;
  ready: boolean;
  nextSpawnId: number;
  nextSpawnAt?: number;
  activeSpawnId?: number;
  activeSpawnGolden?: boolean;
  spawnExpiresAt?: number;
};

export type BattleSession = {
  matchId: string;
  revision: number;
  started: boolean;
  finished: boolean;
  winnerUid?: string;
  players: [BattleCombatant, BattleCombatant];
};

export type BattleNotice = {
  targetUid?: string;
  payload: Record<string, unknown>;
};

export type BattleMutation = {
  changed: boolean;
  message?: string;
  actorUid?: string;
  notices?: BattleNotice[];
};

type RandomSource = () => number;

const maxEnergy = 10;
const switchEnergyCost = 1;

export function authoritativeFighter(
  animalId: string,
  mutationId: string,
  level: number,
): BattleFighter | undefined {
  const animal = animalCatalog[animalId as keyof typeof animalCatalog];
  const multiplier =
    mutationMultipliers[mutationId as keyof typeof mutationMultipliers];
  if (!animal || multiplier === undefined || level < 1 || level > 1_000_000) {
    return undefined;
  }
  const power = Math.max(
    1,
    Math.min(Number.MAX_SAFE_INTEGER, animal.coinsPerSecond * level * multiplier),
  );
  return { animalId, mutationId, level, power };
}

export function createBattle(
  matchId: string,
  firstUid: string,
  firstName: string,
  firstTeam: BattleFighter[],
  secondUid: string,
  secondName: string,
  secondTeam: BattleFighter[],
): BattleSession {
  return {
    matchId,
    revision: 0,
    started: false,
    finished: false,
    players: [
      combatant(firstUid, firstName, firstTeam),
      combatant(secondUid, secondName, secondTeam),
    ],
  };
}

export function markReady(
  battle: BattleSession,
  uid: string,
  now: number,
): BattleMutation {
  const actor = playerFor(battle, uid);
  if (!actor || battle.finished) return { changed: false };
  actor.ready = true;
  if (!battle.started && battle.players.every((player) => player.ready)) {
    battle.started = true;
    for (const player of battle.players) player.nextSpawnAt = now + 550;
    return {
      changed: true,
      message: "Collect energy and use your abilities!",
    };
  }
  return { changed: true };
}

export function processBattleClock(
  battle: BattleSession,
  now: number,
  random: RandomSource = Math.random,
): BattleMutation {
  if (!battle.started || battle.finished) return { changed: false };
  let changed = false;
  let message: string | undefined;
  const notices: BattleNotice[] = [];
  for (const player of battle.players) {
    if (player.activeSpawnId !== undefined && player.spawnExpiresAt! <= now) {
      notices.push({
        targetUid: player.uid,
        payload: { type: "energyGone", id: player.activeSpawnId },
      });
      player.activeSpawnId = undefined;
      player.activeSpawnGolden = undefined;
      player.spawnExpiresAt = undefined;
      player.energyMisses += 1;
      player.combo = 0;
      player.nextSpawnAt = now + spawnDelay(random);
      changed = true;
      message = "Energy missed";
    }
    if (
      player.activeSpawnId === undefined &&
      player.nextSpawnAt !== undefined &&
      player.nextSpawnAt <= now
    ) {
      const spawnId = ++player.nextSpawnId;
      const golden = random() < 0.1;
      player.activeSpawnId = spawnId;
      player.activeSpawnGolden = golden;
      player.spawnExpiresAt = now + 1150;
      player.nextSpawnAt = undefined;
      notices.push({
        targetUid: player.uid,
        payload: {
          type: "energy",
          id: spawnId,
          x: 0.12 + random() * 0.76,
          y: 0.15 + random() * 0.7,
          golden,
        },
      });
      changed = true;
    }
  }
  return { changed, message, notices };
}

export function collectEnergy(
  battle: BattleSession,
  uid: string,
  spawnId: number,
  now: number,
  random: RandomSource = Math.random,
): BattleMutation {
  const actor = playerFor(battle, uid);
  if (
    !actor ||
    !battle.started ||
    battle.finished ||
    actor.activeSpawnId !== spawnId
  ) {
    return { changed: false };
  }
  const golden = actor.activeSpawnGolden === true;
  actor.activeSpawnId = undefined;
  actor.activeSpawnGolden = undefined;
  actor.spawnExpiresAt = undefined;
  actor.nextSpawnAt = now + spawnDelay(random);
  actor.energy = Math.min(maxEnergy, actor.energy + (golden ? 2 : 1));
  actor.energyHits += 1;
  actor.combo += 1;
  actor.bestCombo = Math.max(actor.bestCombo, actor.combo);
  return {
    changed: true,
    actorUid: uid,
    message: golden ? "+2 golden energy!" : "+1 energy",
    notices: [
      { targetUid: uid, payload: { type: "energyGone", id: spawnId } },
    ],
  };
}

export function useAbility(
  battle: BattleSession,
  uid: string,
  abilityIndex: number,
  random: RandomSource = Math.random,
): BattleMutation {
  const actor = playerFor(battle, uid);
  const defender = opponentFor(battle, uid);
  if (!actor || !defender || !battle.started || battle.finished) {
    return { changed: false };
  }
  const fighter = actor.fighters[actor.activeIndex];
  const defenderFighter = defender.fighters[defender.activeIndex];
  const animal = animalCatalog[fighter.animalId as keyof typeof animalCatalog];
  const ability = animal?.abilities[abilityIndex];
  if (!ability || actor.energy < ability.energyCost) {
    return { changed: false };
  }
  actor.energy -= ability.energyCost;
  const variance = 0.92 + random() * 0.16;
  const matchup = clamp(fighter.power / Math.max(1, defenderFighter.power), 0.7, 1.4);
  const rawDamage = Math.max(
    1,
    Math.round(
      attackFor(fighter) * ability.damageScale * Math.sqrt(matchup) * variance,
    ),
  );
  const absorbed = Math.min(defender.shield, rawDamage);
  defender.shield -= absorbed;
  const damage = rawDamage - absorbed;
  defender.health[defender.activeIndex] = Math.max(
    0,
    defender.health[defender.activeIndex] - damage,
  );
  applyEffect(actor, defender, fighter, ability);

  let message = `${actor.name}: ${ability.name}  -${damage}`;
  if (defender.health[defender.activeIndex] === 0) {
    const next = defender.health.findIndex((health) => health > 0);
    if (next < 0) {
      battle.finished = true;
      battle.winnerUid = uid;
      clearClock(battle);
      return {
        changed: true,
        actorUid: uid,
        message: `${actor.name} wins the online battle!`,
      };
    }
    defender.activeIndex = next;
    defender.shield = 0;
    message = `${message}  |  ${defender.name} sends in the next animal!`;
  }
  return { changed: true, actorUid: uid, message };
}

export function switchFighter(
  battle: BattleSession,
  uid: string,
  fighterIndex: number,
): BattleMutation {
  const actor = playerFor(battle, uid);
  if (
    !actor ||
    !battle.started ||
    battle.finished ||
    fighterIndex < 0 ||
    fighterIndex >= actor.fighters.length ||
    fighterIndex === actor.activeIndex ||
    actor.health[fighterIndex] <= 0 ||
    actor.energy < switchEnergyCost
  ) {
    return { changed: false };
  }
  actor.energy -= switchEnergyCost;
  actor.activeIndex = fighterIndex;
  actor.shield = 0;
  return {
    changed: true,
    actorUid: uid,
    message: `${actor.name} switched fighters  |  -1 energy`,
  };
}

export function forfeitBattle(
  battle: BattleSession,
  uid: string,
): BattleMutation {
  const actor = playerFor(battle, uid);
  const winner = opponentFor(battle, uid);
  if (!actor || !winner || battle.finished) return { changed: false };
  battle.finished = true;
  battle.winnerUid = winner.uid;
  clearClock(battle);
  return {
    changed: true,
    actorUid: winner.uid,
    message: `${actor.name} left. ${winner.name} wins the test battle.`,
  };
}

export function nextBattleEventAt(battle: BattleSession): number | undefined {
  if (!battle.started || battle.finished) return undefined;
  const values = battle.players.flatMap((player) =>
    [player.nextSpawnAt, player.spawnExpiresAt].filter(
      (value): value is number => value !== undefined,
    ),
  );
  return values.length === 0 ? undefined : Math.min(...values);
}

export function stateFor(
  battle: BattleSession,
  recipientUid: string,
  message: string,
  actorUid?: string,
): Record<string, unknown> {
  const self = playerFor(battle, recipientUid)!;
  const opponent = opponentFor(battle, recipientUid)!;
  return {
    type: "battleState",
    matchId: battle.matchId,
    revision: battle.revision,
    message,
    lastActor:
      actorUid === undefined
        ? undefined
        : actorUid === recipientUid
          ? "self"
          : "opponent",
    winner:
      battle.winnerUid === undefined
        ? undefined
        : battle.winnerUid === recipientUid
          ? "self"
          : "opponent",
    self: combatantState(self),
    opponent: combatantState(opponent),
  };
}

function combatant(
  uid: string,
  name: string,
  fighters: BattleFighter[],
): BattleCombatant {
  return {
    uid,
    name,
    fighters,
    health: fighters.map(maxHealthFor),
    activeIndex: 0,
    energy: 0,
    shield: 0,
    energyHits: 0,
    energyMisses: 0,
    combo: 0,
    bestCombo: 0,
    ready: false,
    nextSpawnId: 0,
  };
}

function combatantState(player: BattleCombatant): Record<string, unknown> {
  return {
    health: player.health,
    activeIndex: player.activeIndex,
    energy: player.energy,
    shield: player.shield,
    energyHits: player.energyHits,
    energyMisses: player.energyMisses,
    combo: player.combo,
    bestCombo: player.bestCombo,
  };
}

function maxHealthFor(fighter: BattleFighter): number {
  return 180 + bitLength(fighter.power + 1) * 24 + clamp(fighter.level, 1, 200);
}

function attackFor(fighter: BattleFighter): number {
  return 24 + bitLength(fighter.power + 1) * 9 + clamp(Math.floor(fighter.level / 8), 0, 35);
}

function bitLength(value: number): number {
  return value <= 0 ? 0 : Math.floor(Math.log2(value)) + 1;
}

function applyEffect(
  actor: BattleCombatant,
  defender: BattleCombatant,
  fighter: BattleFighter,
  ability: {
    effect: "damage" | "shield" | "heal" | "drain";
    effectScale: number;
  },
): void {
  const amount = Math.max(1, Math.round(attackFor(fighter) * ability.effectScale));
  switch (ability.effect) {
    case "damage":
      return;
    case "shield":
      actor.shield += amount;
      return;
    case "heal":
      actor.health[actor.activeIndex] = Math.min(
        maxHealthFor(fighter),
        actor.health[actor.activeIndex] + amount,
      );
      return;
    case "drain": {
      const drained = Math.min(defender.energy, Math.round(ability.effectScale));
      defender.energy -= drained;
      actor.energy = Math.min(maxEnergy, actor.energy + drained);
    }
  }
}

function playerFor(
  battle: BattleSession,
  uid: string,
): BattleCombatant | undefined {
  return battle.players.find((player) => player.uid === uid);
}

function opponentFor(
  battle: BattleSession,
  uid: string,
): BattleCombatant | undefined {
  return battle.players.find((player) => player.uid !== uid);
}

function spawnDelay(random: RandomSource): number {
  return 380 + Math.floor(random() * 420);
}

function clearClock(battle: BattleSession): void {
  for (const player of battle.players) {
    player.nextSpawnAt = undefined;
    player.activeSpawnId = undefined;
    player.activeSpawnGolden = undefined;
    player.spawnExpiresAt = undefined;
  }
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, value));
}
