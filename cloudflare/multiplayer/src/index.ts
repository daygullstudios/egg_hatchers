import { DurableObject } from "cloudflare:workers";

import {
  readFirebaseProtocol,
  verifyFirebaseSession,
  type SessionCapabilities,
} from "./auth";

type SocketAttachment = {
  uid: string;
  capabilities: SessionCapabilities;
  state: "ready" | "queued" | "matched";
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

const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
};

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
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
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
      default:
        sendError(
          socket,
          "This protected multiplayer capability is not available yet.",
        );
    }
  }

  webSocketClose(socket: WebSocket): void {
    this.remove(socket);
  }

  webSocketError(socket: WebSocket): void {
    this.remove(socket);
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
    const player = await peerSafeSnapshot(attachment.uid, suppliedPlayer);
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
    this.createMatch(socket, opponent);
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

  private createMatch(firstSocket: WebSocket, secondSocket: WebSocket): void {
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
      "INSERT INTO sessions (match_id, first_uid, second_uid, status, created_at, updated_at) VALUES (?, ?, ?, 'matched', ?, ?)",
      matchId,
      first.uid,
      second.uid,
      now,
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

  private remove(socket: WebSocket): void {
    const attachment = socket.deserializeAttachment() as
      | SocketAttachment
      | undefined;
    if (!attachment?.matchId) return;
    this.ctx.storage.sql.exec(
      "UPDATE sessions SET status = 'abandoned', updated_at = ? WHERE match_id = ? AND status = 'matched'",
      Date.now(),
      attachment.matchId,
    );
    const peer = this.ctx.getWebSockets().find((candidate) => {
      const other = candidate.deserializeAttachment() as
        | SocketAttachment
        | undefined;
      return other?.uid === attachment.peerUid;
    });
    if (!peer) return;
    const peerAttachment = peer.deserializeAttachment() as SocketAttachment;
    peer.serializeAttachment({
      ...peerAttachment,
      state: "ready",
      matchId: undefined,
      peerUid: undefined,
      player: undefined,
    } satisfies SocketAttachment);
    sendError(peer, "The other player left the protected test session.");
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
  const power = integerInRange(fighter.power, 1, 1_000_000);
  if (!animalId || !mutationId || level === undefined || power === undefined) {
    return undefined;
  }
  return { animalId, mutationId, level, power };
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
