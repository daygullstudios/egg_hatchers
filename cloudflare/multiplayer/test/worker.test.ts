import { env, exports } from "cloudflare:workers";
import { evictDurableObject } from "cloudflare:test";
import { SignJWT, importJWK } from "jose";
import { describe, expect, it } from "vitest";

import {
  trustedCapabilityPolicyVersion,
  verifyFirebaseSession,
} from "../src/auth";

const privateJwk = {
  kty: "RSA",
  n: "x4gEcTeUTeJWc3DAQgeKHZLL2qFdXyjrxHIi7L6UENwJhhD5q8LfXBTXXWk6xD3RFFIDw2l-j0xLOjgMdsQCz5AgYZPd47CR0mBJuZFxI4HZo5gsK-F8_Btf2NxjDgy7ZonXdn9YR3UpAEK3KE7FTSUChKPYnXpWmakliI2Z9B1QW8oYMbPyV5JKq75tfvwIjvC7pIBaJ82kyS9rGD5BQx0FvGWCC0wQNYOsV9CoqUkmSe-QhzCyvRjRb7m0UZGZBd4w4AB6nTRYJTurPWpLscLqAmnSkKJVaVFuJteOfTt9Z_9U3g8T9CoJulZzI-rkRIcFXzBQyEhOc0Q1us_v1w",
  e: "AQAB",
  d: "LExgYBpszJXRh7Oim4Y8_a_XnmRw7G2TWnvUkScGjG-tlZwzMhUDrdfasJxqNaNbxd0nhLzpIjtYAEbtTXja_uYKql8_xgsvdLt34sENk0qC3TUtqVhYfUg-kVDslPPyryMvONmw6bxzK-Gj9Ej4uNXcp0IRF3VPwLGy6Yw2f-GViXOV65ogtRiAY63TQ9rRXRSc12QG2LPqbO57iMg3K6HXBCW6fO88fEt7sftxT7k9m8FQbiVXIMBT6dORlVN7gArqbMINHUoxg7Oj7ndkTzDl8QLBrhcvRebclaF1tL2w6mdohDRAqDoppKQO3nAnr52wcPB_dEE4T8ileG-S8Q",
  p: "9HxWmzJE3GqaKszKaUwT6GKSa991iPRHXdNESFuD6aSIiGWOMUJJPuY7A_msMmrztN46DaT3IVuXYqoAx_4__rwdIP1X7HqRED1qefRN-B3iMuMFpp4pfK_kd445on7BvN5D5PxV5QE0ypp6QenQecKZRGd1IwyG9mR4i8s_KiU",
  q: "0O2u0_bP0JTwtWvGmyFPj1ZQac87VrIM_vv0fN6DhMUGGn5YYK3Qk_LFwTh4XWorZ2jXrTC8Ts06jOQ0hG6JStb11ltrMBYxbihnYrlpIWNLtIUuSP-VFFC8aVa-BqDrLBvv0TipcFJgSzcgFJwNJcmVo7bugzG7bBkNzAzTC0s",
  dp: "QxTytnaeilP9pQy35RhoxfR19H9FwqQ0CLx1Gd1yXmM0yygCUeW8LzQAsWCKLPNHlzL6fs_qtw5ohTvcJwPOD1kSLQEWZN5key4-zuOHmTKp5AiCfmsbOwkQCPXPPpTFF8tsmaHa95DTKVwle3xqJV6Nq0Uv0MQZK_X5VXIZDLk",
  dq: "Nk2w5TL_bM1pix4KLwQHc9ARco8Ec1IwAo5mS5ZiRL4ZCgXQ3sAOuIWfVMtirZUM1wHvHPrP1wOMtlYSOGGqmaMpnp-ASq1aB7HEvWpHov_2C2OaViroCrG5Zv--wGZO-dYBDTZXA_TFRod7dR_iYvH0TOsdL0hb2IrihSjIKeU",
  qi: "Gho6FwRKOcL4MSfniL_UTcnwPAWqa2rMFn5xWRHxCWEStEPND1h-iSduywmKKlU9xBnQLs1mCnV8K41akuBJLtgaaTvRIIACRp_mqF-sjXqSlvnvUQ7rAFXxjbjBCf5HFGsuFpVqxCPoS2p7RCFRWw-OBvxxFIXYMDaqYntV3fs",
  kid: "test-key",
  use: "sig",
  alg: "RS256",
};

describe("multiplayer edge authentication", () => {
  it("rejects an upgrade without a Firebase token", async () => {
    const response = await exports.default.fetch(
      new Request("https://example.com/ws", {
        headers: {
          Upgrade: "websocket",
          "Sec-WebSocket-Protocol": "nestarium-v1",
        },
      }),
    );
    expect(response.status).toBe(401);
  });

  it("rejects a validly signed token for another Firebase project", async () => {
    const token = await tokenFor("tester-a", { projectId: "other-project" });
    const response = await openSocket(token);
    expect(response.status).toBe(401);
  });

  it("fails closed unless trusted capability claims use the current policy", async () => {
    const missingDecision = await tokenFor("family-unknown", {
      claims: {
        nestariumCapabilities: {
          onlineBattle: true,
          trading: true,
        },
      },
    });
    await expect(
      verifyFirebaseSession(missingDecision, {
        FIREBASE_PROJECT_ID: env.FIREBASE_PROJECT_ID,
        CAPABILITY_MODE: "trusted_claims",
        FIREBASE_TEST_PUBLIC_JWK_JSON: JSON.stringify(publicJwk()),
      }),
    ).rejects.toThrow("hosted online capabilities are not enabled");

    const battleOnly = await tokenFor("family-battle", {
      claims: {
        nestariumCapabilities: {
          policyVersion: trustedCapabilityPolicyVersion,
          decision: "allow",
          onlineBattle: true,
          trading: false,
          presetMessages: false,
          profileDiscovery: false,
        },
      },
    });
    await expect(
      verifyFirebaseSession(battleOnly, {
        FIREBASE_PROJECT_ID: env.FIREBASE_PROJECT_ID,
        CAPABILITY_MODE: "trusted_claims",
        FIREBASE_TEST_PUBLIC_JWK_JSON: JSON.stringify(publicJwk()),
      }),
    ).resolves.toMatchObject({
      uid: "family-battle",
      capabilities: {
        onlineBattle: true,
        trading: false,
        presetMessages: false,
        profileDiscovery: false,
      },
    });

    const tradeOnly = await tokenFor("family-trade", {
      claims: {
        nestariumCapabilities: {
          policyVersion: trustedCapabilityPolicyVersion,
          decision: "allow",
          onlineBattle: false,
          trading: true,
          presetMessages: false,
          profileDiscovery: false,
        },
      },
    });
    await expect(
      verifyFirebaseSession(tradeOnly, {
        FIREBASE_PROJECT_ID: env.FIREBASE_PROJECT_ID,
        CAPABILITY_MODE: "trusted_claims",
        FIREBASE_TEST_PUBLIC_JWK_JSON: JSON.stringify(publicJwk()),
      }),
    ).resolves.toMatchObject({
      uid: "family-trade",
      capabilities: { onlineBattle: false, trading: true },
    });
  });

  it("enforces battle and trade permissions independently after connection", async () => {
    const response = await openPoolSocket("trade-only-session", {
      onlineBattle: false,
      trading: true,
      presetMessages: false,
      profileDiscovery: false,
    });
    expect(response.status).toBe(101);
    const socket = response.webSocket!;
    socket.accept();
    const received = messages(socket);

    socket.send(JSON.stringify({ type: "queue", player: player("forged") }));
    await expect(received.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("Online battles are not enabled"),
    });

    socket.send(JSON.stringify({ type: "queueTrade" }));
    await expect(received.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });
    socket.close(1000, "done");
  });

  it("matches two verified identities without disclosing supplied names or ids", async () => {
    const firstResponse = await openSocket(await tokenFor("tester-a"));
    const secondResponse = await openSocket(await tokenFor("tester-b"));
    expect(firstResponse.status).toBe(101);
    expect(secondResponse.status).toBe(101);
    const first = firstResponse.webSocket!;
    const second = secondResponse.webSocket!;
    first.accept();
    second.accept();

    const firstMessages = messages(first);
    const secondMessages = messages(second);
    first.send(JSON.stringify({ type: "queue", player: player("forged-a") }));
    await expect(firstMessages.next()).resolves.toMatchObject({ type: "queued" });
    second.send(JSON.stringify({ type: "queue", player: player("forged-b") }));

    const firstMatch = await firstMessages.next();
    const secondMatch = await secondMessages.next();
    expect(firstMatch).toMatchObject({
      type: "matched",
      opponent: { displayName: expect.stringMatching(/^Player [A-F0-9]{6}$/) },
    });
    expect(secondMatch).toMatchObject({ type: "matched" });
    expect(firstMatch.opponent.playerId).not.toBe("forged-b");
    expect(firstMatch.opponent.displayName).not.toBe("Unsafe supplied name");
    expect(firstMatch.opponent.team[0].power).toBe(1);
    expect(firstMatch.matchId).toBe(secondMatch.matchId);

    first.send(JSON.stringify({ type: "ready", matchId: firstMatch.matchId }));
    second.send(JSON.stringify({ type: "ready", matchId: secondMatch.matchId }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "battleState",
      revision: 1,
      self: { energy: 0 },
    });
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "battleState",
      revision: 1,
      opponent: { energy: 0 },
    });

    first.send(JSON.stringify({ type: "grantReward", coins: 999999 }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("not available"),
    });
    first.close(1000, "done");
    second.close(1000, "done");
  });

  it("owns the online roster and rejects a forged battle team", async () => {
    const response = await openSocket(await tokenFor("inventory-owner"));
    const socket = response.webSocket!;
    socket.accept();
    const received = messages(socket);

    socket.send(JSON.stringify({ type: "getInventory" }));
    await expect(received.next()).resolves.toMatchObject({
      type: "onlineInventory",
      revision: 1,
      items: [
        { animalId: "chicken", mutationId: "none", level: 1, quantity: 2 },
        { animalId: "mouse", mutationId: "none", level: 1, quantity: 2 },
        { animalId: "rabbit", mutationId: "none", level: 1, quantity: 2 },
      ],
    });

    const forged = player("inventory-owner");
    forged.team = [
      { animalId: "dragon", mutationId: "shadow", level: 999, power: 999999 },
      { animalId: "mouse", mutationId: "none", level: 1, power: 999999 },
      { animalId: "rabbit", mutationId: "none", level: 1, power: 999999 },
    ];
    socket.send(JSON.stringify({ type: "queue", player: forged }));
    await expect(received.next()).resolves.toMatchObject({
      type: "onlineInventory",
      revision: 1,
    });
    await expect(received.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("Online Roster changed"),
    });
    socket.close(1000, "done");
  });

  it("commits a two-sided Online Roster trade exactly once", async () => {
    const firstResponse = await openSocket(await tokenFor("trade-owner-a"));
    const secondResponse = await openSocket(await tokenFor("trade-owner-b"));
    const first = firstResponse.webSocket!;
    const second = secondResponse.webSocket!;
    first.accept();
    second.accept();
    const firstMessages = messages(first);
    const secondMessages = messages(second);

    first.send(JSON.stringify({ type: "getInventory" }));
    second.send(JSON.stringify({ type: "getInventory" }));
    await firstMessages.next();
    await secondMessages.next();

    first.send(JSON.stringify({ type: "queueTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });
    second.send(JSON.stringify({ type: "queueTrade" }));
    const firstState = await firstMessages.next();
    const secondState = await secondMessages.next();
    expect(firstState).toMatchObject({
      type: "tradeState",
      opponent: { displayName: expect.stringMatching(/^Player [A-F0-9]{6}$/) },
    });
    expect(firstState.opponentInventory).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ animalId: "mouse", quantity: 2 }),
      ]),
    );
    expect(secondState).toMatchObject({
      type: "tradeState",
      tradeId: firstState.tradeId,
    });

    first.send(
      JSON.stringify({
        type: "tradeOffer",
        tradeId: firstState.tradeId,
        animal: { animalId: "chicken", mutationId: "none", level: 1 },
      }),
    );
    await firstMessages.next();
    await secondMessages.next();
    second.send(
      JSON.stringify({
        type: "tradeOffer",
        tradeId: firstState.tradeId,
        animal: { animalId: "mouse", mutationId: "none", level: 1 },
      }),
    );
    await firstMessages.next();
    await secondMessages.next();

    first.send(
      JSON.stringify({ type: "tradeConfirm", tradeId: firstState.tradeId }),
    );
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeState",
      selfConfirmed: true,
      opponentConfirmed: false,
    });
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "tradeState",
      selfConfirmed: false,
      opponentConfirmed: true,
    });
    second.send(
      JSON.stringify({ type: "tradeConfirm", tradeId: firstState.tradeId }),
    );
    const firstComplete = await firstMessages.next();
    const firstInventory = await firstMessages.next();
    const secondComplete = await secondMessages.next();
    const secondInventory = await secondMessages.next();
    expect(firstComplete).toMatchObject({
      type: "tradeComplete",
      sent: { animalId: "chicken" },
      received: { animalId: "mouse" },
    });
    expect(secondComplete).toMatchObject({
      type: "tradeComplete",
      sent: { animalId: "mouse" },
      received: { animalId: "chicken" },
    });
    expect(firstInventory).toMatchObject({
      type: "onlineInventory",
      revision: 2,
    });
    expect(secondInventory).toMatchObject({
      type: "onlineInventory",
      revision: 2,
    });
    expect(firstInventory.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ animalId: "mouse", quantity: 3 }),
      ]),
    );
    expect(secondInventory.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ animalId: "chicken", quantity: 3 }),
      ]),
    );
    expect(
      firstInventory.items.find((item: any) => item.animalId === "chicken")
        .quantity,
    ).toBe(1);
    expect(
      secondInventory.items.find((item: any) => item.animalId === "mouse")
        .quantity,
    ).toBe(1);

    second.send(
      JSON.stringify({ type: "tradeConfirm", tradeId: firstState.tradeId }),
    );
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("no longer active"),
    });

    const thirdResponse = await openSocket(await tokenFor("trade-owner-c"));
    const third = thirdResponse.webSocket!;
    third.accept();
    const thirdMessages = messages(third);
    first.send(JSON.stringify({ type: "queueTrade" }));
    await firstMessages.next();
    third.send(JSON.stringify({ type: "queueTrade" }));
    const nextFirstState = await firstMessages.next();
    await thirdMessages.next();
    first.send(
      JSON.stringify({
        type: "tradeOffer",
        tradeId: nextFirstState.tradeId,
        animal: { animalId: "chicken", mutationId: "none", level: 1 },
      }),
    );
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "onlineInventory",
      revision: 2,
    });
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("not available"),
    });
    first.send(
      JSON.stringify({ type: "leaveTrade", tradeId: nextFirstState.tradeId }),
    );
    await firstMessages.next();
    await thirdMessages.next();
    third.close(1000, "done");
    first.close(1000, "done");
    second.close(1000, "done");
  });

  it("cancels a disconnected trade without moving either roster", async () => {
    const firstToken = await tokenFor("trade-disconnect-a");
    const secondToken = await tokenFor("trade-disconnect-b");
    const firstResponse = await openSocket(firstToken);
    const secondResponse = await openSocket(secondToken);
    const first = firstResponse.webSocket!;
    const second = secondResponse.webSocket!;
    first.accept();
    second.accept();
    const firstMessages = messages(first);
    const secondMessages = messages(second);

    first.send(JSON.stringify({ type: "queueTrade" }));
    await firstMessages.next();
    second.send(JSON.stringify({ type: "queueTrade" }));
    const firstState = await firstMessages.next();
    await secondMessages.next();
    first.send(
      JSON.stringify({
        type: "tradeOffer",
        tradeId: firstState.tradeId,
        animal: { animalId: "chicken", mutationId: "none", level: 1 },
      }),
    );
    await firstMessages.next();
    await secondMessages.next();
    second.send(
      JSON.stringify({
        type: "tradeOffer",
        tradeId: firstState.tradeId,
        animal: { animalId: "mouse", mutationId: "none", level: 1 },
      }),
    );
    await firstMessages.next();
    await secondMessages.next();

    first.close(1000, "network lost before confirmation");
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "tradeCancelled",
      message: expect.stringContaining("disconnected"),
    });
    second.send(JSON.stringify({ type: "getInventory" }));
    const secondInventory = await secondMessages.next();
    expect(secondInventory).toMatchObject({
      type: "onlineInventory",
      revision: 1,
    });
    expect(secondInventory.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ animalId: "mouse", quantity: 2 }),
      ]),
    );

    const reconnectedResponse = await openSocket(firstToken);
    const reconnected = reconnectedResponse.webSocket!;
    reconnected.accept();
    const reconnectedMessages = messages(reconnected);
    reconnected.send(JSON.stringify({ type: "getInventory" }));
    const firstInventory = await reconnectedMessages.next();
    expect(firstInventory).toMatchObject({
      type: "onlineInventory",
      revision: 1,
    });
    expect(firstInventory.items).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ animalId: "chicken", quantity: 2 }),
      ]),
    );
    reconnected.close(1000, "done");
    second.close(1000, "done");
  });

  it("records preset reports and persists two-way matchmaking blocks", async () => {
    const firstToken = await tokenFor("safety-owner-a");
    const secondToken = await tokenFor("safety-owner-b");
    const firstResponse = await openSocket(firstToken);
    const secondResponse = await openSocket(secondToken);
    const first = firstResponse.webSocket!;
    const second = secondResponse.webSocket!;
    first.accept();
    second.accept();
    const firstMessages = messages(first);
    const secondMessages = messages(second);

    first.send(JSON.stringify({ type: "queueTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });
    second.send(JSON.stringify({ type: "queueTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeState",
    });
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "tradeState",
    });

    await evictDurableObject(
      env.MATCHMAKING.getByName(env.MATCHMAKING_POOL),
    );

    first.send(
      JSON.stringify({
        type: "peerSafety",
        action: "report",
        reason: "trade_concern",
        block: true,
      }),
    );
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "peerSafetyRecorded",
      success: true,
      reportRecorded: true,
      blocked: true,
      message: expect.stringContaining("not be matched"),
    });
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeCancelled",
      message: expect.stringContaining("blocked"),
    });
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "tradeCancelled",
      message: expect.stringContaining("blocked"),
    });

    first.send(
      JSON.stringify({
        type: "peerSafety",
        action: "report",
        reason: "trade_concern",
      }),
    );
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "peerSafetyRecorded",
      success: true,
      reportRecorded: false,
      blocked: false,
      message: expect.stringContaining("already saved"),
    });

    first.send(JSON.stringify({ type: "queueTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });
    second.send(JSON.stringify({ type: "queueTrade" }));
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });

    first.send(JSON.stringify({ type: "cancelTrade" }));
    second.send(JSON.stringify({ type: "cancelTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({ type: "ready" });
    await expect(secondMessages.next()).resolves.toMatchObject({ type: "ready" });

    first.send(JSON.stringify({ type: "queue", player: player("safety-a") }));
    await expect(firstMessages.next()).resolves.toMatchObject({ type: "queued" });
    second.send(JSON.stringify({ type: "queue", player: player("safety-b") }));
    await expect(secondMessages.next()).resolves.toMatchObject({ type: "queued" });

    first.close(1000, "done");
    second.close(1000, "done");
  });

  it("retires a duplicate identity session before accepting its replacement", async () => {
    const token = await tokenFor("duplicate-session-owner");
    const firstResponse = await openSocket(token);
    const first = firstResponse.webSocket!;
    first.accept();
    const firstMessages = messages(first);
    const firstClosed = new Promise<CloseEvent>((resolve) => {
      first.addEventListener("close", resolve, { once: true });
    });
    first.send(JSON.stringify({ type: "queueTrade" }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });

    const replacementResponse = await openSocket(token);
    expect(replacementResponse.status).toBe(101);
    await expect(firstClosed).resolves.toMatchObject({
      code: 4001,
      reason: expect.stringContaining("newer multiplayer session"),
    });
    const replacement = replacementResponse.webSocket!;
    replacement.accept();
    const replacementMessages = messages(replacement);
    replacement.send(JSON.stringify({ type: "queueTrade" }));
    await expect(replacementMessages.next()).resolves.toMatchObject({
      type: "tradeQueued",
    });
    replacement.close(1000, "done");
  });

  it("pauses and resumes a server-run battle after a verified reconnect", async () => {
    const firstToken = await tokenFor("reconnect-a");
    const secondToken = await tokenFor("reconnect-b");
    const firstResponse = await openSocket(firstToken);
    const secondResponse = await openSocket(secondToken);
    const first = firstResponse.webSocket!;
    const second = secondResponse.webSocket!;
    first.accept();
    second.accept();
    const firstMessages = messages(first);
    const secondMessages = messages(second);

    first.send(JSON.stringify({ type: "queue", player: player("first") }));
    await firstMessages.next();
    second.send(JSON.stringify({ type: "queue", player: player("second") }));
    const firstMatch = await firstMessages.next();
    const secondMatch = await secondMessages.next();
    first.send(JSON.stringify({ type: "ready", matchId: firstMatch.matchId }));
    second.send(JSON.stringify({ type: "ready", matchId: secondMatch.matchId }));
    await firstMessages.next();
    await secondMessages.next();

    first.close(1000, "network drop");
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "battleState",
      message: expect.stringContaining("paused"),
    });

    const resumedResponse = await openSocket(firstToken);
    expect(resumedResponse.status).toBe(101);
    const resumed = resumedResponse.webSocket!;
    resumed.accept();
    const resumedMessages = messages(resumed);
    await expect(resumedMessages.next()).resolves.toMatchObject({
      type: "matched",
      matchId: firstMatch.matchId,
      resumed: true,
      opponent: { displayName: expect.stringMatching(/^Player [A-F0-9]{6}$/) },
    });
    await expect(resumedMessages.next()).resolves.toMatchObject({
      type: "battleState",
      message: expect.stringContaining("resumed"),
    });
    await expect(secondMessages.next()).resolves.toMatchObject({
      type: "battleState",
      message: expect.stringContaining("resumed"),
    });
    resumed.close(1000, "done");
    second.close(1000, "done");
  });

  it("settles a hosted result once and redelivers it until acknowledged", async () => {
    const winnerToken = await tokenFor("settlement-winner");
    const loserToken = await tokenFor("settlement-loser");
    const winnerResponse = await openSocket(winnerToken);
    const loserResponse = await openSocket(loserToken);
    const winner = winnerResponse.webSocket!;
    const loser = loserResponse.webSocket!;
    winner.accept();
    loser.accept();
    const winnerMessages = messages(winner);
    const loserMessages = messages(loser);

    winner.send(JSON.stringify({ type: "queue", player: player("winner") }));
    await winnerMessages.next();
    loser.send(JSON.stringify({ type: "queue", player: player("loser") }));
    const winnerMatch = await winnerMessages.next();
    const loserMatch = await loserMessages.next();
    winner.send(JSON.stringify({ type: "ready", matchId: winnerMatch.matchId }));
    loser.send(JSON.stringify({ type: "ready", matchId: loserMatch.matchId }));
    await winnerMessages.next();
    await loserMessages.next();

    loser.send(JSON.stringify({ type: "leave", matchId: loserMatch.matchId }));
    await expect(winnerMessages.next()).resolves.toMatchObject({
      type: "battleState",
      winner: "self",
    });
    await expect(loserMessages.next()).resolves.toMatchObject({
      type: "battleState",
      winner: "opponent",
    });
    const winnerSettlement = await winnerMessages.next();
    const loserSettlement = await loserMessages.next();
    expect(loserSettlement).toMatchObject({
      type: "settlement",
      won: false,
      ratingChange: -12,
      coins: 0,
      battleTokens: 0,
      serverRating: 988,
      rosterReward: {
        mutationId: "none",
        level: 1,
        quantity: 1,
      },
    });
    expect(winnerSettlement).toMatchObject({
      type: "settlement",
      matchId: winnerMatch.matchId,
      won: true,
      ratingChange: 18,
      coins: 250,
      battleTokens: 1,
      serverRating: 1018,
      rosterReward: {
        mutationId: "none",
        level: 1,
        quantity: 1,
      },
    });
    await expect(winnerMessages.next()).resolves.toMatchObject({
      type: "onlineInventory",
      revision: 2,
      items: expect.arrayContaining([
        expect.objectContaining({
          animalId: winnerSettlement.rosterReward.animalId,
        }),
      ]),
    });
    await expect(loserMessages.next()).resolves.toMatchObject({
      type: "onlineInventory",
      revision: 2,
      items: expect.arrayContaining([
        expect.objectContaining({
          animalId: loserSettlement.rosterReward.animalId,
        }),
      ]),
    });

    winner.close(1000, "reconnect before acknowledging");
    const retryResponse = await openSocket(winnerToken);
    const retry = retryResponse.webSocket!;
    retry.accept();
    const retryMessages = messages(retry);
    await expect(retryMessages.next()).resolves.toMatchObject({
      type: "settlement",
      receiptId: winnerSettlement.receiptId,
      coins: 250,
    });
    retry.send(
      JSON.stringify({
        type: "ackSettlement",
        receiptId: winnerSettlement.receiptId,
      }),
    );
    retry.close(1000, "acknowledged");

    const finalResponse = await openSocket(winnerToken);
    const finalSocket = finalResponse.webSocket!;
    finalSocket.accept();
    const finalMessages = messages(finalSocket);
    const secondOpponentResponse = await openSocket(
      await tokenFor("settlement-second-opponent"),
    );
    const secondOpponent = secondOpponentResponse.webSocket!;
    secondOpponent.accept();
    const secondOpponentMessages = messages(secondOpponent);
    finalSocket.send(
      JSON.stringify({ type: "queue", player: player("winner-again") }),
    );
    await expect(finalMessages.next()).resolves.toMatchObject({ type: "queued" });
    secondOpponent.send(
      JSON.stringify({ type: "queue", player: player("second-opponent") }),
    );
    const secondWinnerMatch = await finalMessages.next();
    const secondLoserMatch = await secondOpponentMessages.next();
    finalSocket.send(
      JSON.stringify({ type: "ready", matchId: secondWinnerMatch.matchId }),
    );
    secondOpponent.send(
      JSON.stringify({ type: "ready", matchId: secondLoserMatch.matchId }),
    );
    await finalMessages.next();
    await secondOpponentMessages.next();
    secondOpponent.send(
      JSON.stringify({ type: "leave", matchId: secondLoserMatch.matchId }),
    );
    await finalMessages.next();
    await secondOpponentMessages.next();
    const secondWinnerSettlement = await finalMessages.next();
    expect(secondWinnerSettlement).toMatchObject({
      type: "settlement",
      won: true,
    });
    expect(secondWinnerSettlement).not.toHaveProperty("rosterReward");
    finalSocket.close(1000, "done");
    secondOpponent.close(1000, "done");
    loser.close(1000, "done");
  });

  it(
    "accepts and isolates 32 protected sessions, then fails closed at the pool guardrail",
    async () => {
      const tokens = await Promise.all(
        Array.from({ length: 33 }, (_, index) =>
          tokenFor(`capacity-${index.toString().padStart(2, "0")}`),
        ),
      );
      const responses = await Promise.all(tokens.slice(0, 32).map(openSocket));
      expect(responses.every((response) => response.status === 101)).toBe(true);

      const sockets = responses.map((response) => response.webSocket!);
      const inboxes = sockets.map((socket) => {
        socket.accept();
        return messages(socket);
      });
      const matchIds = new Set<string>();
      for (let index = 0; index < sockets.length; index += 2) {
        sockets[index].send(
          JSON.stringify({ type: "queue", player: player(`load-${index}`) }),
        );
        await expect(inboxes[index].next()).resolves.toMatchObject({
          type: "queued",
        });
        sockets[index + 1].send(
          JSON.stringify({
            type: "queue",
            player: player(`load-${index + 1}`),
          }),
        );
        const firstMatch = await inboxes[index].next();
        const secondMatch = await inboxes[index + 1].next();
        expect(firstMatch).toMatchObject({ type: "matched" });
        expect(secondMatch).toMatchObject({
          type: "matched",
          matchId: firstMatch.matchId,
        });
        matchIds.add(firstMatch.matchId as string);
      }
      expect(matchIds).toHaveLength(16);

      const fullResponse = await openSocket(tokens[32]);
      expect(fullResponse.status).toBe(503);
      expect(fullResponse.headers.get("Retry-After")).toBe("3");

      for (const socket of sockets) socket.close(1000, "capacity test done");
    },
    30_000,
  );
});

async function tokenFor(
  uid: string,
  {
    projectId = env.FIREBASE_PROJECT_ID,
    claims = {},
  }: { projectId?: string; claims?: Record<string, unknown> } = {},
): Promise<string> {
  const key = await importJWK(privateJwk, "RS256");
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({ auth_time: now - 1, ...claims })
    .setProtectedHeader({ alg: "RS256", kid: "test-key" })
    .setSubject(uid)
    .setAudience(projectId)
    .setIssuer(`https://securetoken.google.com/${projectId}`)
    .setIssuedAt(now - 1)
    .setExpirationTime(now + 300)
    .sign(key);
}

function publicJwk(): JsonWebKey & { kid: string } {
  return {
    kty: privateJwk.kty,
    n: privateJwk.n,
    e: privateJwk.e,
    kid: privateJwk.kid,
    use: privateJwk.use,
    alg: privateJwk.alg,
  };
}

function openSocket(token: string): Promise<Response> {
  return exports.default.fetch(
    new Request("https://example.com/ws", {
      headers: {
        Upgrade: "websocket",
        "Sec-WebSocket-Protocol": `nestarium-v1, firebase-auth.${token}`,
      },
    }),
  );
}

function openPoolSocket(
  uid: string,
  capabilities: {
    onlineBattle: boolean;
    profileDiscovery: boolean;
    presetMessages: boolean;
    trading: boolean;
  },
): Promise<Response> {
  return env.MATCHMAKING.getByName(env.MATCHMAKING_POOL).fetch(
    new Request("https://example.com/ws", {
      headers: {
        Upgrade: "websocket",
        "X-Nestarium-Uid": uid,
        "X-Nestarium-Capabilities": JSON.stringify(capabilities),
      },
    }),
  );
}

function player(playerId: string): Record<string, unknown> {
  return {
    playerId,
    displayName: "Unsafe supplied name",
    username: "unsafe-name",
    avatarColorValue: 4_285_712_800,
    rating: 1000,
    team: [
      { animalId: "chicken", mutationId: "none", level: 1, power: 10 },
      { animalId: "mouse", mutationId: "none", level: 1, power: 10 },
      { animalId: "rabbit", mutationId: "none", level: 1, power: 10 },
    ],
  };
}

function messages(socket: WebSocket): {
  next(): Promise<Record<string, any>>;
} {
  const pending: Array<(value: Record<string, any>) => void> = [];
  const queued: Record<string, any>[] = [];
  socket.addEventListener("message", (event) => {
    const value = JSON.parse(event.data as string) as Record<string, any>;
    const resolve = pending.shift();
    if (resolve) resolve(value);
    else queued.push(value);
  });
  return {
    next: () => {
      const value = queued.shift();
      return value
        ? Promise.resolve(value)
        : new Promise((resolve) => pending.push(resolve));
    },
  };
}
