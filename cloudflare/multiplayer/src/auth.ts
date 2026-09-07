import {
  decodeProtectedHeader,
  importJWK,
  importX509,
  jwtVerify,
  type JWTPayload,
} from "jose";

const firebaseCertificatesUrl =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

type CertificateCache = {
  expiresAt: number;
  certificates: Record<string, string>;
};

let certificateCache: CertificateCache | undefined;

export type SessionCapabilities = {
  onlineBattle: boolean;
  profileDiscovery: boolean;
  presetMessages: boolean;
  trading: boolean;
};

export type VerifiedSession = {
  uid: string;
  capabilities: SessionCapabilities;
};

export const trustedCapabilityPolicyVersion = 1;

type AuthEnv = {
  FIREBASE_PROJECT_ID: string;
  CAPABILITY_MODE: string;
  FIREBASE_TEST_PUBLIC_JWK_JSON?: string;
};

export function readFirebaseProtocol(request: Request): string {
  const header = request.headers.get("Sec-WebSocket-Protocol") ?? "";
  if (header.length > 12_000) throw new Error("protocol header too large");
  const protocols = header
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  if (!protocols.includes("nestarium-v1")) {
    throw new Error("unsupported websocket protocol");
  }
  const authProtocol = protocols.find((value) =>
    value.startsWith("firebase-auth."),
  );
  const token = authProtocol?.slice("firebase-auth.".length);
  if (!token) throw new Error("missing Firebase identity token");
  return token;
}

export async function verifyFirebaseSession(
  token: string,
  env: AuthEnv,
): Promise<VerifiedSession> {
  if (token.length > 10_000) throw new Error("identity token too large");
  const protectedHeader = decodeProtectedHeader(token);
  if (protectedHeader.alg !== "RS256" || !protectedHeader.kid) {
    throw new Error("invalid Firebase token header");
  }

  const key = await verificationKey(protectedHeader.kid, env);
  const issuer = `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`;
  const { payload } = await jwtVerify(token, key, {
    algorithms: ["RS256"],
    audience: env.FIREBASE_PROJECT_ID,
    issuer,
    clockTolerance: 5,
  });
  validateFirebaseClaims(payload);

  const capabilities = capabilitiesFor(payload, env.CAPABILITY_MODE);
  if (!capabilities.onlineBattle && !capabilities.trading) {
    throw new Error("hosted online capabilities are not enabled");
  }
  return { uid: payload.sub!, capabilities };
}

async function verificationKey(kid: string, env: AuthEnv): Promise<CryptoKey> {
  if (env.FIREBASE_TEST_PUBLIC_JWK_JSON) {
    const jwk = JSON.parse(env.FIREBASE_TEST_PUBLIC_JWK_JSON) as JsonWebKey & {
      kid?: string;
    };
    if (jwk.kid !== kid) throw new Error("unknown Firebase signing key");
    return (await importJWK(jwk, "RS256")) as CryptoKey;
  }

  const certificates = await firebaseCertificates();
  const certificate = certificates[kid];
  if (!certificate) throw new Error("unknown Firebase signing key");
  return importX509(certificate, "RS256");
}

async function firebaseCertificates(): Promise<Record<string, string>> {
  const now = Date.now();
  if (certificateCache && certificateCache.expiresAt > now) {
    return certificateCache.certificates;
  }
  const response = await fetch(firebaseCertificatesUrl);
  if (!response.ok) throw new Error("Firebase signing keys are unavailable");
  const certificates = (await response.json()) as Record<string, string>;
  const maxAge = /(?:^|,)\s*max-age=(\d+)/i.exec(
    response.headers.get("Cache-Control") ?? "",
  );
  const lifetimeSeconds = Math.max(60, Number(maxAge?.[1] ?? 300));
  certificateCache = {
    certificates,
    expiresAt: now + lifetimeSeconds * 1000,
  };
  return certificates;
}

function validateFirebaseClaims(payload: JWTPayload): void {
  const now = Math.floor(Date.now() / 1000);
  if (!payload.sub || payload.sub.length > 128) {
    throw new Error("invalid Firebase subject");
  }
  if (typeof payload.iat !== "number" || payload.iat > now + 5) {
    throw new Error("invalid Firebase issued-at time");
  }
  const authTime = payload.auth_time;
  if (typeof authTime !== "number" || authTime > now + 5) {
    throw new Error("invalid Firebase authentication time");
  }
}

function capabilitiesFor(
  payload: JWTPayload,
  mode: string,
): SessionCapabilities {
  if (mode === "protected_playtest") {
    return {
      onlineBattle: true,
      profileDiscovery: false,
      // The Access-protected owner playtest may exercise the bounded preset
      // trade flow. Public builds still require explicit trusted claims.
      presetMessages: true,
      trading: true,
    };
  }
  const claim = payload.nestariumCapabilities;
  const capabilities =
    claim && typeof claim === "object"
      ? (claim as Record<string, unknown>)
      : {};
  // Public sessions must be enabled by a versioned, server-issued policy
  // decision. An old, partial, locally invented or otherwise unknown claim is
  // deliberately not authority. The future family-identity service owns claim
  // issuance and revocation; this Worker only enforces its signed result.
  if (
    mode !== "trusted_claims" ||
    capabilities.policyVersion !== trustedCapabilityPolicyVersion ||
    capabilities.decision !== "allow"
  ) {
    return {
      onlineBattle: false,
      profileDiscovery: false,
      presetMessages: false,
      trading: false,
    };
  }
  return {
    onlineBattle: capabilities.onlineBattle === true,
    profileDiscovery: capabilities.profileDiscovery === true,
    presetMessages: capabilities.presetMessages === true,
    trading: capabilities.trading === true,
  };
}
