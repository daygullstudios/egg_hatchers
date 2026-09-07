export type GenerationMode = "active" | "draining" | "read_only";

export type ArenaAccountMigrationRow = {
  uid: string;
  rating: number;
  win_streak: number;
  wins: number;
  losses: number;
  coins_earned: number;
  tokens_earned: number;
  updated_at: number;
};

export type InventoryAccountMigrationRow = {
  uid: string;
  revision: number;
  created_at: number;
  updated_at: number;
};

export type InventoryMigrationRow = {
  uid: string;
  item_key: string;
  animal_id: string;
  mutation_id: string;
  level: number;
  quantity: number;
  updated_at: number;
};

export type InventoryGrantMigrationRow = {
  grant_id: string;
  uid: string;
  match_id: string;
  grant_key: string;
  item_json: string;
  created_at: number;
};

export type SettlementMigrationRow = {
  receipt_id: string;
  match_id: string;
  uid: string;
  won: number;
  rating_change: number;
  coins: number;
  battle_tokens: number;
  server_rating: number;
  roster_reward_json: string | null;
  acknowledged: number;
  created_at: number;
};

export type TradeReceiptMigrationRow = {
  receipt_id: string;
  trade_id: string;
  uid: string;
  sent_json: string;
  received_json: string;
  acknowledged: number;
  created_at: number;
};

export type PlayerBlockMigrationRow = {
  blocker_uid: string;
  blocked_uid: string;
  context_type: string;
  context_id: string;
  created_at: number;
};

export type PlayerAuthorityPayload = {
  arenaAccount: ArenaAccountMigrationRow | null;
  inventoryAccount: InventoryAccountMigrationRow | null;
  inventory: InventoryMigrationRow[];
  grants: InventoryGrantMigrationRow[];
  pendingSettlements: SettlementMigrationRow[];
  pendingTradeReceipts: TradeReceiptMigrationRow[];
  blocks: PlayerBlockMigrationRow[];
};

export type PlayerAuthorityExport = {
  schemaVersion: 1;
  sourceGeneration: string;
  uid: string;
  payload: PlayerAuthorityPayload;
  checksum: string;
};

export type PlayerAuthorityImportResult = {
  uid: string;
  checksum: string;
  alreadyImported: boolean;
};

export function assertMigrationIdentifier(
  value: string,
  label: string,
  maximumLength = 128,
): void {
  if (
    value.length === 0 ||
    value.length > maximumLength ||
    /[\u0000-\u001f\u007f]/.test(value)
  ) {
    throw new Error(`invalid ${label}`);
  }
}

export function assertPlayerAuthorityExport(
  bundle: PlayerAuthorityExport,
): void {
  if (!bundle || bundle.schemaVersion !== 1 || !bundle.payload) {
    throw new Error("unsupported player authority export");
  }
  const payload = bundle.payload;
  if (
    !Array.isArray(payload.inventory) ||
    !Array.isArray(payload.grants) ||
    !Array.isArray(payload.pendingSettlements) ||
    !Array.isArray(payload.pendingTradeReceipts) ||
    !Array.isArray(payload.blocks)
  ) {
    throw new Error("invalid player authority payload");
  }
  assertMigrationIdentifier(bundle.sourceGeneration, "source generation", 80);
  assertMigrationIdentifier(bundle.uid, "migration uid");
  const ownedRows = [
    payload.arenaAccount,
    payload.inventoryAccount,
    ...payload.inventory,
    ...payload.grants,
    ...payload.pendingSettlements,
    ...payload.pendingTradeReceipts,
  ].filter((row) => row !== null);
  if (ownedRows.some((row) => row!.uid !== bundle.uid)) {
    throw new Error("player authority export contains another owner");
  }
  if (
    payload.blocks.some(
      (row) => row.blocker_uid !== bundle.uid && row.blocked_uid !== bundle.uid,
    )
  ) {
    throw new Error("player authority export contains an unrelated block");
  }
}

export async function playerAuthorityChecksum(
  bundle: Omit<PlayerAuthorityExport, "checksum">,
): Promise<string> {
  const bytes = new TextEncoder().encode(JSON.stringify(bundle));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}
