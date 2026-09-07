import { env, exports } from "cloudflare:workers";
import { SignJWT, importJWK } from "jose";
import { describe, expect, it } from "vitest";

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
    expect(firstMatch.matchId).toBe(secondMatch.matchId);

    first.send(JSON.stringify({ type: "grantReward", coins: 999999 }));
    await expect(firstMessages.next()).resolves.toMatchObject({
      type: "error",
      message: expect.stringContaining("not available"),
    });
    first.close(1000, "done");
    second.close(1000, "done");
  });
});

async function tokenFor(
  uid: string,
  { projectId = env.FIREBASE_PROJECT_ID }: { projectId?: string } = {},
): Promise<string> {
  const key = await importJWK(privateJwk, "RS256");
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({ auth_time: now - 1 })
    .setProtectedHeader({ alg: "RS256", kid: "test-key" })
    .setSubject(uid)
    .setAudience(projectId)
    .setIssuer(`https://securetoken.google.com/${projectId}`)
    .setIssuedAt(now - 1)
    .setExpirationTime(now + 300)
    .sign(key);
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

function player(playerId: string): Record<string, unknown> {
  return {
    playerId,
    displayName: "Unsafe supplied name",
    username: "unsafe-name",
    avatarColorValue: 4_285_712_800,
    rating: 1000,
    team: [
      { animalId: "chicken", mutationId: "normal", level: 1, power: 10 },
      { animalId: "mouse", mutationId: "normal", level: 1, power: 10 },
      { animalId: "rabbit", mutationId: "normal", level: 1, power: 10 },
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
