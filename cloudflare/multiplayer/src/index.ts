import { DurableObject } from "cloudflare:workers";

import {
  readFirebaseProtocol,
  verifyFirebaseSession,
  type SessionCapabilities,
} from "./auth";
import {
  authoritativeFighter,
  collectEnergy,
  createBattle,
  expireReconnect,
  forfeitBattle,
  markReady,
  nextBattleEventAt,
  pauseBattle,
  processBattleClock,
  resumeBattle,
  stateFor,
  switchFighter,
  useAbility,
  type BattleMutation,
  type BattleSession,
} from "./battle";

type SocketAttachment = {
  uid: string;
  capabilities: SessionCapabilities;
  state: "ready" | "queued" | "matched" | "replaced";
  queuedAt?: number;
  player?: PlayerSnapshot;
  matchId?: string;
  peerUid?: string;
  windowStartedAt: number;
  messageCount: number;
};

type FighterSnapshot = {
  animalId: string;
  mutationId: string;
  level: number;
  power: number;
};

type PlayerSnapshot = {
  playerId: string;
  displayName: string;
  username: string;
  avatarColorValue: number;
  rating: number;
  team: FighterSnapshot[];
};

type ArenaAccount = {
  uid: string;
  rating: number;
  win_streak: number;
  wins: number;
  losses: number;
};

type ArenaSettlement = {
  receipt_id: string;
  match_id: string;
  uid: string;
  won: number;
  rating_change: number;
  coins: number;
  battle_tokens: number;
  server_rating: number;
};

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

const reconnectGraceMs = 30_000;

export default {
  async fetch(request, env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/ws/health") {
      return Response.json(
        { status: "ok", service: "nestarium-multiplayer", protocol: 1 },
        { headers: jsonHeaders },
      );
    }
    if (url.pathname !== "/ws") {
      return new Response("Not found", { status: 404 });
    }
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("WebSocket upgrade required", { status: 426 });
    }

    let session;
    try {
      const token = readFirebaseProtocol(request);
      session = await verifyFirebaseSession(token, env);
    } catch (error) {
      console.warn("Rejected multiplayer session", {
        reason: error instanceof Error ? error.message : "unknown",
      });
      return new Response("Unauthorized", {
        status: 401,
        headers: { "Cache-Control": "no-store" },
      });
    }

    const headers = new Headers(request.headers);
    headers.delete("X-Nestarium-Uid");
    headers.delete("X-Nestarium-Capabilities");
    headers.set("X-Nestarium-Uid", session.uid);
    headers.set(
      "X-Nestarium-Capabilities",
      JSON.stringify(session.capabilities),
    );
    const pool = env.MATCHMAKING.getByName(env.MATCHMAKING_POOL);
    return pool.fetch(new Request(request, { headers }));
  },
} satisfies ExportedHandler<Env>;

export class MatchmakingPool extends DurableObject<Env> {
  constructor(ctx: DurableObjectState, env: Env) {
    super(ctx, env);
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        match_id TEXT PRIMARY KEY,
        first_uid TEXT NOT NULL,
        second_uid TEXT NOT NULL,
        status TEXT NOT NULL,
        first_player_json TEXT,
        second_player_json TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    `);
    this.ensureColumn("sessions", "first_player_json", "TEXT");
    this.ensureColumn("sessions", "second_player_json", "TEXT");
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS battles (
        match_id TEXT PRIMARY KEY,
        state_json TEXT NOT NULL,
        status TEXT NOT NULL,
        next_event_at INTEGER,
        updated_at INTEGER NOT NULL
      )
    `);
    this.ctx.storage.sql.exec(`
      CREATE TABLE IF NOT EXISTS arena_accounts (
        uid TEXT PRIMARY KEY,
        rating INTEGER NOT NULL,
        win_streak INTEGER NOT NULL,
        wins INTEGER NOT NULL,
        losses INTEGER NOT NULL,
        coins_earned INTEGER NOT NULL,
        tokens_earned INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS settlements (
        receipt_id TEXT PRIMARY KEY,
        match_id TEXT NOT NULL,
        uid TEXT NOT NULL,
        won INTEGER NOT NULL,
        rating_change INTEGER NOT NULL,
        coins INTEGER NOT NULL,
        battle_tokens INTEGER NOT NULL,
        server_rating INTEGER NOT NULL,
        acknowledged INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        UNIQUE(match_id, uid)
      );
      CREATE INDEX IF NOT EXISTS settlements_pending
        ON settlements(uid, acknowledged, created_at);
    `);
  }

  async fetch(request: Request): Promise<Response> {
    if (request.headers.get("Upgrade")?.toLowerCase() !== "websocket") {
      return new Response("WebSocket upgrade required", { status: 426 });
    }
    const uid = request.headers.get("X-Nestarium-Uid");
    const rawCapabilities = request.headers.get("X-Nestarium-Capabilities");
    if (!uid || !rawCapabilities) {
      return new Response("Unauthorized", { status: 401 });
    }
    const capabilities = JSON.parse(rawCapabilities) as SessionCapabilities;
    if (!capabilities.onlineBattle) {
      return new Response("Forbidden", { status: 403 });
    }

    for (const socket of this.ctx.getWebSockets()) {
      const attachment = socket.deserializeAttachment() as
        | SocketAttachment
        | undefined;
      if (attachment?.uid === uid) {
        socket.serializeAttachment({
          ...attachment,
          state: "replaced",
          matchId: undefined,
          peerUid: undefined,
        } satisfies SocketAttachment);
        socket.close(4001, "A newer multiplayer session was opened");
      }
    }

    const pair = new WebSocketPair();
    const [client, server] = Object.values(pair);
    const attachment: SocketAttachment = {
      uid,
      capabilities,
      state: "ready",
      windowStartedAt: Date.now(),
      messageCount: 0,
    };
    server.serializeAttachment(attachment);
    this.ctx.acceptWebSocket(server);
    const resumed = await this.resumeSession(server, attachment);
    if (!resumed) this.sendPendingSettlements(server, uid);
    return new Response(null, {
      status: 101,
      webSocket: client,
      headers: { "Sec-WebSocket-Protocol": "nestarium-v1" },
    });
  }

  async webSocketMessage(
    socket: WebSocket,
    message: string | ArrayBuffer,
  ): Promise<void> {
    let attachment = socket.deserializeAttachment() as SocketAttachment;
    if (typeof message !== "string" || message.length > 16_384) {
      socket.close(1009, "Message too large");
      return;
    }
    attachment = enforceRateLimit(socket, attachment);
    if (attachment.messageCount > 30) return;

    let data: Record<string, unknown>;
    try {
      data = JSON.parse(message) as Record<string, unknown>;
    } catch {
      sendError(socket, "Invalid multiplayer message.");
      return;
    }
    switch (data.type) {
      case "queue":
        await this.queue(socket, attachment, data.player);
        break;
      case "cancel":
        this.cancel(socket, attachment);
        break;
      case "ackSettlement":
        this.acknowledgeSettlement(socket, attachment, data.receiptId);
        break;
      case "ready":
      case "collectEnergy":
      case "ability":
      case "switch":
      case "leave":
        await this.handleBattle(socket, attachment, data);
        break;
      default:
        sendError(
          socket,
          "This protected multiplayer capability is not available yet.",
        );
    }
  }

  async webSocketClose(socket: WebSocket): Promise<void> {
    await this.remove(socket);
  }

  async webSocketError(socket: WebSocket): Promise<void> {
    await this.remove(socket);
  }

  private async queue(
    socket: WebSocket,
    attachment: SocketAttachment,
    value: unknown,
  ): Promise<void> {
    if (attachment.state === "matched") {
      sendError(socket, "Leave the current match before searching again.");
      return;
    }
    const suppliedPlayer = parsePlayerSnapshot(value);
    if (!suppliedPlayer) {
      sendError(socket, "Choose a valid team before matchmaking.");
      return;
    }
    const account = this.arenaAccount(attachment.uid);
    const player = {
      ...(await peerSafeSnapshot(attachment.uid, suppliedPlayer)),
      rating: account.rating,
    };
    const updated: SocketAttachment = {
      ...attachment,
      state: "queued",
      queuedAt: Date.now(),
      player,
    };
    socket.serializeAttachment(updated);

    const opponent = this.waitingSocket(attachment.uid);
    if (!opponent) {
      send(socket, {
        type: "queued",
        message: "Waiting for another protected playtester...",
      });
      return;
    }
    await this.createMatch(socket, opponent);
  }

  private waitingSocket(exceptUid: string): WebSocket | undefined {
    return this.ctx
      .getWebSockets()
      .filter((candidate) => candidate.readyState === WebSocket.OPEN)
      .filter((candidate) => {
        const attachment =
          candidate.deserializeAttachment() as SocketAttachment;
        return attachment.state === "queued" && attachment.uid !== exceptUid;
      })
      .sort((first, second) => {
        const a = first.deserializeAttachment() as SocketAttachment;
        const b = second.deserializeAttachment() as SocketAttachment;
        return (a.queuedAt ?? 0) - (b.queuedAt ?? 0);
      })[0];
  }

  private async createMatch(
    firstSocket: WebSocket,
    secondSocket: WebSocket,
  ): Promise<void> {
    const first = firstSocket.deserializeAttachment() as SocketAttachment;
    const second = secondSocket.deserializeAttachment() as SocketAttachment;
    if (!first.player || !second.player) return;
    const matchId = crypto.randomUUID();
    const now = Date.now();
    const matchedFirst: SocketAttachment = {
      ...first,
      state: "matched",
      matchId,
      peerUid: second.uid,
      queuedAt: undefined,
    };
    const matchedSecond: SocketAttachment = {
      ...second,
      state: "matched",
      matchId,
      peerUid: first.uid,
      queuedAt: undefined,
    };
    firstSocket.serializeAttachment(matchedFirst);
    secondSocket.serializeAttachment(matchedSecond);
    this.ctx.storage.sql.exec(
      "INSERT INTO sessions (match_id, first_uid, second_uid, status, first_player_json, second_player_json, created_at, updated_at) VALUES (?, ?, ?, 'matched', ?, ?, ?, ?)",
      matchId,
      first.uid,
      second.uid,
      JSON.stringify(first.player),
      JSON.stringify(second.player),
      now,
      now,
    );
    const battle = createBattle(
      matchId,
      first.uid,
      first.player.displayName,
      first.player.team,
      second.uid,
      second.player.displayName,
      second.player.team,
    );
    this.ctx.storage.sql.exec(
      "INSERT INTO battles (match_id, state_json, status, next_event_at, updated_at) VALUES (?, ?, 'waiting', NULL, ?)",
      matchId,
      JSON.stringify(battle),
      now,
    );
    send(firstSocket, {
      type: "matched",
      matchId,
      opponent: second.player,
    });
    send(secondSocket, {
      type: "matched",
      matchId,
      opponent: first.player,
    });
    await this.scheduleNextAlarm();
  }

  private async handleBattle(
    socket: WebSocket,
    attachment: SocketAttachment,
    data: Record<string, unknown>,
  ): Promise<void> {
    if (
      attachment.state !== "matched" ||
      !attachment.matchId ||
      data.matchId !== attachment.matchId
    ) {
      sendError(socket, "That protected test match is no longer active.");
      return;
    }
    const battle = this.readBattle(attachment.matchId);
    if (!battle || battle.finished) {
      sendError(socket, "That protected test match has ended.");
      return;
    }
    if ((battle.disconnectedUids?.length ?? 0) > 0 && data.type !== "leave") {
      send(
        socket,
        stateFor(
          battle,
          attachment.uid,
          "The battle is paused while a player reconnects.",
        ),
      );
      return;
    }
    const now = Date.now();
    let mutation: BattleMutation;
    switch (data.type) {
      case "ready":
        mutation = markReady(battle, attachment.uid, now);
        break;
      case "collectEnergy":
        mutation = collectEnergy(
          battle,
          attachment.uid,
          integerInRange(data.spawnId, 1, Number.MAX_SAFE_INTEGER) ?? -1,
          now,
        );
        break;
      case "ability":
        mutation = useAbility(
          battle,
          attachment.uid,
          integerInRange(data.abilityIndex, 0, 2) ?? -1,
        );
        break;
      case "switch":
        mutation = switchFighter(
          battle,
          attachment.uid,
          integerInRange(data.fighterIndex, 0, 2) ?? -1,
        );
        break;
      case "leave":
        mutation = forfeitBattle(battle, attachment.uid);
        break;
      default:
        mutation = { changed: false };
    }
    if (!mutation.changed) return;
    this.sendBattleNotices(mutation);
    if (mutation.message) {
      battle.revision += 1;
      this.broadcastBattle(battle, mutation.message, mutation.actorUid);
    }
    this.writeBattle(battle);
    if (battle.finished) {
      this.settleBattle(battle);
      this.releaseBattleSockets(battle);
    }
    await this.scheduleNextAlarm();
  }

  async alarm(): Promise<void> {
    const now = Date.now();
    const rows = this.ctx.storage.sql.exec<{ state_json: string }>(
      "SELECT state_json FROM battles WHERE status IN ('active', 'reconnecting')",
    );
    for (const row of rows) {
      const battle = JSON.parse(row.state_json) as BattleSession;
      const expired = expireReconnect(battle, now);
      if (expired.changed) {
        battle.revision += 1;
        this.writeBattle(battle);
        this.endInterruptedBattle(battle, expired.message!);
        continue;
      }
      const mutation = processBattleClock(battle, now);
      if (!mutation.changed) continue;
      this.sendBattleNotices(mutation);
      if (mutation.message) {
        battle.revision += 1;
        this.broadcastBattle(battle, mutation.message, mutation.actorUid);
      }
      this.writeBattle(battle);
    }
    await this.scheduleNextAlarm();
  }

  private readBattle(matchId: string): BattleSession | undefined {
    const row = [
      ...this.ctx.storage.sql.exec<{ state_json: string }>(
        "SELECT state_json FROM battles WHERE match_id = ? AND status IN ('waiting', 'active', 'reconnecting')",
        matchId,
      ),
    ][0];
    return row ? (JSON.parse(row.state_json) as BattleSession) : undefined;
  }

  private writeBattle(battle: BattleSession): void {
    const status = battle.finished
      ? battle.winnerUid === undefined
        ? "interrupted"
        : "finished"
      : (battle.disconnectedUids?.length ?? 0) > 0
        ? "reconnecting"
        : battle.started
          ? "active"
          : "waiting";
    const nextEventAt = nextBattleEventAt(battle) ?? null;
    const now = Date.now();
    this.ctx.storage.sql.exec(
      "UPDATE battles SET state_json = ?, status = ?, next_event_at = ?, updated_at = ? WHERE match_id = ?",
      JSON.stringify(battle),
      status,
      nextEventAt,
      now,
      battle.matchId,
    );
    this.ctx.storage.sql.exec(
      "UPDATE sessions SET status = ?, updated_at = ? WHERE match_id = ?",
      status,
      now,
      battle.matchId,
    );
  }

  private sendBattleNotices(mutation: BattleMutation): void {
    for (const notice of mutation.notices ?? []) {
      if (!notice.targetUid) continue;
      const socket = this.socketForUid(notice.targetUid);
      if (socket) send(socket, notice.payload);
    }
  }

  private broadcastBattle(
    battle: BattleSession,
    message: string,
    actorUid?: string,
  ): void {
    for (const player of battle.players) {
      const socket = this.socketForUid(player.uid);
      if (socket) send(socket, stateFor(battle, player.uid, message, actorUid));
    }
  }

  private socketForUid(uid: string): WebSocket | undefined {
    return this.ctx.getWebSockets().find((socket) => {
      const attachment = socket.deserializeAttachment() as
        | SocketAttachment
        | undefined;
      return attachment?.uid === uid && socket.readyState === WebSocket.OPEN;
    });
  }

  private releaseBattleSockets(battle: BattleSession): void {
    for (const player of battle.players) {
      const socket = this.socketForUid(player.uid);
      if (!socket) continue;
      const attachment = socket.deserializeAttachment() as SocketAttachment;
      socket.serializeAttachment({
        ...attachment,
        state: "ready",
        matchId: undefined,
        peerUid: undefined,
        player: undefined,
      } satisfies SocketAttachment);
    }
  }

  private async scheduleNextAlarm(): Promise<void> {
    let earliest: number | undefined;
    const rows = this.ctx.storage.sql.exec<{ next_event_at: number | null }>(
      "SELECT next_event_at FROM battles WHERE status IN ('active', 'reconnecting') AND next_event_at IS NOT NULL",
    );
    for (const row of rows) {
      if (row.next_event_at === null) continue;
      earliest =
        earliest === undefined
          ? row.next_event_at
          : Math.min(earliest, row.next_event_at);
    }
    if (earliest === undefined) {
      await this.ctx.storage.deleteAlarm();
    } else {
      await this.ctx.storage.setAlarm(Math.max(Date.now(), earliest));
    }
  }

  private cancel(socket: WebSocket, attachment: SocketAttachment): void {
    if (attachment.state === "matched") {
      sendError(socket, "The current match cannot be canceled from the queue.");
      return;
    }
    socket.serializeAttachment({
      ...attachment,
      state: "ready",
      queuedAt: undefined,
      player: undefined,
    } satisfies SocketAttachment);
    send(socket, { type: "ready" });
  }

  private async remove(socket: WebSocket): Promise<void> {
    const attachment = socket.deserializeAttachment() as
      | SocketAttachment
      | undefined;
    if (!attachment?.matchId || attachment.state !== "matched") return;
    const battle = this.readBattle(attachment.matchId);
    if (!battle || battle.finished) return;
    const now = Date.now();
    const mutation = pauseBattle(
      battle,
      attachment.uid,
      now,
      now + reconnectGraceMs,
    );
    if (!mutation.changed) return;
    battle.revision += 1;
    this.writeBattle(battle);
    const peer = this.socketForUid(attachment.peerUid ?? "");
    if (peer) {
      send(
        peer,
        stateFor(battle, attachment.peerUid!, mutation.message!),
      );
    }
    await this.scheduleNextAlarm();
  }

  private async resumeSession(
    socket: WebSocket,
    attachment: SocketAttachment,
  ): Promise<boolean> {
    const row = [
      ...this.ctx.storage.sql.exec<{
        match_id: string;
        first_uid: string;
        second_uid: string;
        first_player_json: string | null;
        second_player_json: string | null;
      }>(
        "SELECT match_id, first_uid, second_uid, first_player_json, second_player_json FROM sessions WHERE (first_uid = ? OR second_uid = ?) AND status = 'reconnecting' ORDER BY updated_at DESC LIMIT 1",
        attachment.uid,
        attachment.uid,
      ),
    ][0];
    if (!row) return false;
    const battle = this.readBattle(row.match_id);
    if (!battle || !(battle.disconnectedUids ?? []).includes(attachment.uid)) {
      return false;
    }
    const now = Date.now();
    if (
      battle.reconnectDeadline === undefined ||
      battle.reconnectDeadline <= now
    ) {
      const expired = expireReconnect(battle, now);
      if (expired.changed) {
        battle.revision += 1;
        this.writeBattle(battle);
        this.endInterruptedBattle(battle, expired.message!);
      }
      return false;
    }

    const first = row.first_uid === attachment.uid;
    const own = parseStoredPlayer(
      first ? row.first_player_json : row.second_player_json,
    );
    const opponent = parseStoredPlayer(
      first ? row.second_player_json : row.first_player_json,
    );
    if (!own || !opponent) return false;
    const peerUid = first ? row.second_uid : row.first_uid;
    const resumedAttachment: SocketAttachment = {
      ...attachment,
      state: "matched",
      matchId: row.match_id,
      peerUid,
      player: own,
    };
    socket.serializeAttachment(resumedAttachment);
    send(socket, {
      type: "matched",
      matchId: row.match_id,
      opponent,
      resumed: true,
    });

    const mutation = resumeBattle(battle, attachment.uid, now);
    if (mutation.changed) battle.revision += 1;
    this.writeBattle(battle);
    if ((battle.disconnectedUids?.length ?? 0) === 0) {
      this.broadcastBattle(battle, mutation.message ?? "Battle resumed.");
    } else {
      send(
        socket,
        stateFor(
          battle,
          attachment.uid,
          mutation.message ?? "Waiting for the other player.",
        ),
      );
    }
    await this.scheduleNextAlarm();
    return true;
  }

  private endInterruptedBattle(battle: BattleSession, message: string): void {
    for (const player of battle.players) {
      const socket = this.socketForUid(player.uid);
      if (!socket) continue;
      const attachment = socket.deserializeAttachment() as SocketAttachment;
      socket.serializeAttachment({
        ...attachment,
        state: "ready",
        matchId: undefined,
        peerUid: undefined,
        player: undefined,
      } satisfies SocketAttachment);
      send(socket, { type: "matchInterrupted", message });
    }
  }

  private arenaAccount(uid: string): ArenaAccount {
    const now = Date.now();
    this.ctx.storage.sql.exec(
      "INSERT OR IGNORE INTO arena_accounts (uid, rating, win_streak, wins, losses, coins_earned, tokens_earned, updated_at) VALUES (?, 1000, 0, 0, 0, 0, 0, ?)",
      uid,
      now,
    );
    return this.ctx.storage.sql
      .exec<ArenaAccount>(
        "SELECT uid, rating, win_streak, wins, losses FROM arena_accounts WHERE uid = ?",
        uid,
      )
      .one();
  }

  private settleBattle(battle: BattleSession): ArenaSettlement[] {
    if (!battle.winnerUid) return [];
    const settlements = this.ctx.storage.transactionSync(() => {
      const existing = this.settlementsForMatch(battle.matchId);
      if (existing.length > 0) return existing;

      const now = Date.now();
      const accounts = new Map(
        battle.players.map((player) => [player.uid, this.arenaAccount(player.uid)]),
      );
      for (const player of battle.players) {
        const account = accounts.get(player.uid)!;
        const opponent = battle.players.find((entry) => entry.uid !== player.uid)!;
        const opponentAccount = accounts.get(opponent.uid)!;
        const won = player.uid === battle.winnerUid;
        const reward = hostedArenaReward(
          won,
          account.rating,
          opponentAccount.rating,
          account.win_streak,
        );
        const serverRating = clampInteger(
          account.rating + reward.ratingChange,
          0,
          10_000,
        );
        const nextStreak = won ? account.win_streak + 1 : 0;
        const receiptId = `${battle.matchId}:${player.uid}`;
        this.ctx.storage.sql.exec(
          "UPDATE arena_accounts SET rating = ?, win_streak = ?, wins = wins + ?, losses = losses + ?, coins_earned = coins_earned + ?, tokens_earned = tokens_earned + ?, updated_at = ? WHERE uid = ?",
          serverRating,
          nextStreak,
          won ? 1 : 0,
          won ? 0 : 1,
          reward.coins,
          reward.battleTokens,
          now,
          player.uid,
        );
        this.ctx.storage.sql.exec(
          "INSERT INTO settlements (receipt_id, match_id, uid, won, rating_change, coins, battle_tokens, server_rating, acknowledged, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?)",
          receiptId,
          battle.matchId,
          player.uid,
          won ? 1 : 0,
          reward.ratingChange,
          reward.coins,
          reward.battleTokens,
          serverRating,
          now,
        );
      }
      return this.settlementsForMatch(battle.matchId);
    });
    for (const settlement of settlements) {
      const socket = this.socketForUid(settlement.uid);
      if (socket) this.sendSettlement(socket, settlement);
    }
    return settlements;
  }

  private settlementsForMatch(matchId: string): ArenaSettlement[] {
    return this.ctx.storage.sql
      .exec<ArenaSettlement>(
        "SELECT receipt_id, match_id, uid, won, rating_change, coins, battle_tokens, server_rating FROM settlements WHERE match_id = ? ORDER BY uid",
        matchId,
      )
      .toArray();
  }

  private sendPendingSettlements(socket: WebSocket, uid: string): void {
    const pending = this.ctx.storage.sql.exec<ArenaSettlement>(
      "SELECT receipt_id, match_id, uid, won, rating_change, coins, battle_tokens, server_rating FROM settlements WHERE uid = ? AND acknowledged = 0 ORDER BY created_at LIMIT 20",
      uid,
    );
    for (const settlement of pending) this.sendSettlement(socket, settlement);
  }

  private sendSettlement(socket: WebSocket, settlement: ArenaSettlement): void {
    send(socket, {
      type: "settlement",
      receiptId: settlement.receipt_id,
      matchId: settlement.match_id,
      won: settlement.won === 1,
      ratingChange: settlement.rating_change,
      coins: settlement.coins,
      battleTokens: settlement.battle_tokens,
      serverRating: settlement.server_rating,
    });
  }

  private acknowledgeSettlement(
    socket: WebSocket,
    attachment: SocketAttachment,
    value: unknown,
  ): void {
    if (typeof value !== "string" || value.length < 1 || value.length > 200) {
      sendError(socket, "Invalid settlement receipt.");
      return;
    }
    this.ctx.storage.sql.exec(
      "UPDATE settlements SET acknowledged = 1 WHERE receipt_id = ? AND uid = ?",
      value,
      attachment.uid,
    );
  }

  private ensureColumn(table: string, column: string, type: string): void {
    const columns = [
      ...this.ctx.storage.sql.exec<{ name: string }>(`PRAGMA table_info(${table})`),
    ];
    if (!columns.some((entry) => entry.name === column)) {
      this.ctx.storage.sql.exec(
        `ALTER TABLE ${table} ADD COLUMN ${column} ${type}`,
      );
    }
  }
}

function enforceRateLimit(
  socket: WebSocket,
  attachment: SocketAttachment,
): SocketAttachment {
  const now = Date.now();
  const reset = now - attachment.windowStartedAt >= 10_000;
  const updated = {
    ...attachment,
    windowStartedAt: reset ? now : attachment.windowStartedAt,
    messageCount: reset ? 1 : attachment.messageCount + 1,
  };
  socket.serializeAttachment(updated);
  if (updated.messageCount === 31) {
    sendError(socket, "Too many multiplayer requests. Try again shortly.");
  }
  return updated;
}

function parsePlayerSnapshot(value: unknown): PlayerSnapshot | undefined {
  if (!value || typeof value !== "object") return undefined;
  const player = value as Record<string, unknown>;
  if (!Array.isArray(player.team) || player.team.length !== 3) return undefined;
  const team = player.team.map(parseFighterSnapshot);
  if (team.some((fighter) => !fighter)) return undefined;
  const rating = integerInRange(player.rating, 0, 10_000);
  const avatarColorValue = integerInRange(
    player.avatarColorValue,
    -2_147_483_648,
    4_294_967_295,
  );
  if (rating === undefined || avatarColorValue === undefined) return undefined;
  return {
    playerId: "",
    displayName: "",
    username: "",
    avatarColorValue,
    rating,
    team: team as FighterSnapshot[],
  };
}

function parseFighterSnapshot(value: unknown): FighterSnapshot | undefined {
  if (!value || typeof value !== "object") return undefined;
  const fighter = value as Record<string, unknown>;
  const animalId = safeIdentifier(fighter.animalId);
  const mutationId = safeIdentifier(fighter.mutationId);
  const level = integerInRange(fighter.level, 1, 1_000);
  if (!animalId || !mutationId || level === undefined) {
    return undefined;
  }
  return authoritativeFighter(animalId, mutationId, level);
}

function safeIdentifier(value: unknown): string | undefined {
  return typeof value === "string" && /^[a-z0-9_-]{1,40}$/i.test(value)
    ? value
    : undefined;
}

function integerInRange(
  value: unknown,
  minimum: number,
  maximum: number,
): number | undefined {
  return typeof value === "number" &&
    Number.isSafeInteger(value) &&
    value >= minimum &&
    value <= maximum
    ? value
    : undefined;
}

function hostedArenaReward(
  won: boolean,
  playerRating: number,
  opponentRating: number,
  currentStreak: number,
): { ratingChange: number; coins: number; battleTokens: number } {
  const difference = opponentRating - playerRating;
  if (!won) {
    return {
      ratingChange: -clampInteger(12 - Math.trunc(difference / 25), 6, 18),
      coins: 0,
      battleTokens: 0,
    };
  }
  const ratingChange = clampInteger(
    18 + Math.trunc(difference / 25),
    12,
    28,
  );
  const nextStreak = currentStreak + 1;
  return {
    ratingChange,
    // Hosted rewards deliberately do not depend on client-supplied fighter power.
    coins: 250,
    battleTokens:
      1 + (opponentRating >= 1250 ? 1 : 0) + (nextStreak % 5 === 0 ? 1 : 0),
  };
}

function clampInteger(value: number, minimum: number, maximum: number): number {
  return Math.max(minimum, Math.min(maximum, Math.trunc(value)));
}

async function peerSafeSnapshot(
  uid: string,
  supplied: PlayerSnapshot,
): Promise<PlayerSnapshot> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(uid),
  );
  const code = [...new Uint8Array(digest).slice(0, 3)]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
  return {
    ...supplied,
    playerId: `peer-${code}`,
    displayName: `Player ${code}`,
    username: `nest-${code.toLowerCase()}`,
  };
}

function send(socket: WebSocket, value: Record<string, unknown>): void {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(value));
}

function sendError(socket: WebSocket, message: string): void {
  send(socket, { type: "error", message });
}

function parseStoredPlayer(value: string | null): PlayerSnapshot | undefined {
  if (!value) return undefined;
  try {
    const player = JSON.parse(value) as Record<string, unknown>;
    const normalized = parsePlayerSnapshot(player);
    const playerId = safeIdentifier(player.playerId);
    const username = safeIdentifier(player.username);
    const displayName = player.displayName;
    if (
      !normalized ||
      !playerId ||
      !username ||
      typeof displayName !== "string" ||
      !/^Player [A-F0-9]{6}$/.test(displayName)
    ) {
      return undefined;
    }
    return { ...normalized, playerId, username, displayName };
  } catch {
    return undefined;
  }
}
