import { cloudflareTest } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

const testPublicJwk = {
  kty: "RSA",
  n: "x4gEcTeUTeJWc3DAQgeKHZLL2qFdXyjrxHIi7L6UENwJhhD5q8LfXBTXXWk6xD3RFFIDw2l-j0xLOjgMdsQCz5AgYZPd47CR0mBJuZFxI4HZo5gsK-F8_Btf2NxjDgy7ZonXdn9YR3UpAEK3KE7FTSUChKPYnXpWmakliI2Z9B1QW8oYMbPyV5JKq75tfvwIjvC7pIBaJ82kyS9rGD5BQx0FvGWCC0wQNYOsV9CoqUkmSe-QhzCyvRjRb7m0UZGZBd4w4AB6nTRYJTurPWpLscLqAmnSkKJVaVFuJteOfTt9Z_9U3g8T9CoJulZzI-rkRIcFXzBQyEhOc0Q1us_v1w",
  e: "AQAB",
  kid: "test-key",
  use: "sig",
  alg: "RS256",
};

export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: "./wrangler.jsonc" },
      miniflare: {
        bindings: {
          FIREBASE_TEST_PUBLIC_JWK_JSON: JSON.stringify(testPublicJwk),
        },
      },
    }),
  ],
  test: {
    sequence: { concurrent: false },
  },
});
