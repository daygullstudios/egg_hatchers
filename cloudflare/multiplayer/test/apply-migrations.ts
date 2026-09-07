import { env } from "cloudflare:workers";
import { applyD1Migrations, type D1Migration } from "cloudflare:test";

const testEnv = env as Env & { TEST_MIGRATIONS: D1Migration[] };

await applyD1Migrations(
  testEnv.SAFETY_AUTHORITY,
  testEnv.TEST_MIGRATIONS,
);
