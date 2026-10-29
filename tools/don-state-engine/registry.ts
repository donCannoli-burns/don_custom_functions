/**
 * Don State Engine — import/dispatch REGISTRY ONLY (v0.1 proposal).
 * No CLI calls, no gameplay effects, no KoLmafia imports at module load.
 * This file is not loaded by a live runtime until separately compiled/admitted.
 */
export type FlagCode = 0 | 1 | 2 | 3 | 4 | 5;
export const FLAG_CODE = {
  pending: 0, started: 1, finished: 2, skipped: 3,
  failed: 4, needs_reconciliation: 5,
} as const;
export type Trust = 'observed' | 'claimed' | 'planned' | 'inferred';
export type Risk = 'none' | 'read' | 'prefs' | 'data' | 'gameplay' | 'critical';
export type DateYYYYMMDD = string;
export interface Observation {
  playerId: string; rolloverDay: DateYYYYMMDD; totalAscensions: number;
  ascensionsToday: number; turnsThisAscension: number; adventures: number;
  liverUsed: number; stomachUsed: number; spleenUsed: number;
  liverLimit: number; stomachLimit: number; spleenLimit: number;
  meatOnHand: number; meatCloset: number; meatStorage?: number;
  kingLiberated: boolean; canInteract: boolean; inRonin: boolean | null;
  path: string; className: string; gamedayIndex: number;
  nextHalloween: DateYYYYMMDD | null; daysTillHalloween: number | null;
  isHalloween: boolean | null; eveOfHalloween: boolean | null;
  eventEvidence: 'confirmed' | 'unknown' | 'conflict';
  observedAt: string;
}
export interface FlagEvent {
  eventId: string; playerId: string; day: DateYYYYMMDD;
  ascensionNumber: number; sequence: number; flag: string;
  from: FlagCode; to: FlagCode; at: string; actionId: string | null;
  planned: unknown; observed: unknown; claims: unknown[];
  source: string; discrepancyIds: string[];
}
export interface EnginePolicy {
  loopRun: boolean; stopForDiscrepancy: boolean; autoFallback: boolean;
  nextExpectedFlag: string | null; nextFallbackFlag: string | null;
  maxAutomaticAdventureSpend: number;
  requireExplicitAscensionApproval: true;
}
export const SEGMENTS = [
  {
    "id": "start_day",
    "scope": "rollover",
    "goal": "read-only start snapshot; git update and breakfast are separate gated actions",
    "action": "start_day"
  },
  {
    "id": "setup_l1",
    "scope": "rollover",
    "goal": "cockroach prep; diet; moon sign; conditional borrowed time",
    "action": "setup"
  },
  {
    "id": "leg1_farm",
    "scope": "leg1",
    "goal": "select exactly one L1 farming mode",
    "action": "farm_l1"
  },
  {
    "id": "post_farm_l1",
    "scope": "leg1",
    "goal": "organ prep, cooler, stillsuit, consumption",
    "action": "post_farm"
  },
  {
    "id": "drunk_farm",
    "scope": "leg1",
    "goal": "wineglass required for drunken turns",
    "action": "drunk_farm"
  },
  {
    "id": "pills",
    "scope": "leg1",
    "goal": "bounded pill farming; hard cap 200 per pill",
    "action": "pill_farm"
  },
  {
    "id": "pvp_fights",
    "scope": "leg1",
    "goal": "UberPvP and PVP_MAB when available",
    "action": "pvp"
  },
  {
    "id": "sea_prep",
    "scope": "leg1",
    "goal": "explicit sea-prep; cannot infer success from CLI return",
    "action": "sea_prep"
  },
  {
    "id": "pre_ascension",
    "scope": "boundary",
    "goal": "garden, workshed, coinmasters, trophies; preflight",
    "action": "pre_ascension"
  },
  {
    "id": "ascension",
    "scope": "boundary",
    "goal": "don_ascend sea-pm; only through approved adapter",
    "action": "don_ascend"
  },
  {
    "id": "post_ascension_hook",
    "scope": "boundary",
    "goal": "observe and reconcile receipt; no gameplay at hook entry",
    "action": "post_ascension"
  },
  {
    "id": "path_run",
    "scope": "path",
    "goal": "UnderTheSea path; not synonymous with Ronin exit",
    "action": "path_run"
  },
  {
    "id": "new_life",
    "scope": "leg2",
    "goal": "post-path restoration of state/outfits/familiars",
    "action": "new_life"
  },
  {
    "id": "setup_l2",
    "scope": "leg2",
    "goal": "leg2 diet, MCD and automaton checks",
    "action": "setup_l2"
  },
  {
    "id": "leg2_farm",
    "scope": "leg2",
    "goal": "select exactly one L2 farming mode",
    "action": "farm_l2"
  },
  {
    "id": "post_farm_l2",
    "scope": "leg2",
    "goal": "leg2 organs and overdrink checks",
    "action": "post_farm_l2"
  },
  {
    "id": "organ_maxing",
    "scope": "either",
    "goal": "outfit maxo and validated organ consumption",
    "action": "organs"
  },
  {
    "id": "overdrink",
    "scope": "either",
    "goal": "bucket of wine, guarded by cap and recipe availability",
    "action": "overdrink"
  },
  {
    "id": "max_adv",
    "scope": "either",
    "goal": "maximization may alter outfit and familiar",
    "action": "max_adv"
  },
  {
    "id": "mall_managed",
    "scope": "either",
    "goal": "reprice/clean via mall-manager with audit receipts",
    "action": "mall"
  },
  {
    "id": "end_day",
    "scope": "rollover",
    "goal": "final checkpoint, valuation and wall-clock totals",
    "action": "end_day"
  }
] as const;
export const FLAGS = [
  "start_day",
  "setup_l1",
  "leg1_farm",
  "post_farm_l1",
  "drunk_farm",
  "pills",
  "pvp_fights",
  "sea_prep",
  "pre_ascension",
  "ascension",
  "in_ronin",
  "post_ascension_hook",
  "path_run",
  "new_life",
  "stillsuit_l1",
  "stillsuit_l2",
  "get_cool_ready",
  "get_cool_used",
  "setup_l2",
  "leg2_farm",
  "post_farm_l2",
  "organ_maxing",
  "overdrink",
  "max_adv",
  "mall_managed",
  "end_day"
] as const;
export const FARM_MODES = [
  {
    "id": "freeze_all",
    "capability": "halt",
    "sideEffect": "never",
    "note": "No action; hard stop, no fallback"
  },
  {
    "id": "breakfast_only",
    "capability": "breakfast",
    "sideEffect": "read",
    "note": "Only native KoLmafia breakfast"
  },
  {
    "id": "barf",
    "capability": "garbo",
    "sideEffect": "mutate",
    "note": "garbo farming, budgeted adventures"
  },
  {
    "id": "cowo",
    "capability": "garbo_cowo",
    "sideEffect": "mutate",
    "note": "Pastamancer-only, fail closed otherwise"
  },
  {
    "id": "nobarf",
    "capability": "daily_resources",
    "sideEffect": "mutate",
    "note": "Daily resources only"
  },
  {
    "id": "combo",
    "capability": "don_combo",
    "sideEffect": "mutate",
    "note": "Beach combing"
  },
  {
    "id": "combo_nobarf",
    "capability": "don_combo_daily",
    "sideEffect": "mutate",
    "note": "Beach combing plus daily resources; no garbo"
  },
  {
    "id": "combo_watersheep",
    "capability": "don_combo_watersheep",
    "sideEffect": "mutate",
    "note": "Bounded turns or free-11 mode; never extrapolate"
  },
  {
    "id": "oreo",
    "capability": "oreo_farm",
    "sideEffect": "mutate",
    "note": "1970 gold farming adapter; not wired"
  },
  {
    "id": "oreo_nobarf",
    "capability": "oreo_daily",
    "sideEffect": "mutate",
    "note": "Gold + daily-only; not wired"
  },
  {
    "id": "trick_or_treat",
    "capability": "halloween_farm",
    "sideEffect": "mutate",
    "note": "Only when calendar evidence confirms Halloween"
  },
  {
    "id": "trick_or_treat_nobarf",
    "capability": "halloween_daily",
    "sideEffect": "mutate",
    "note": "Halloween without garbo; event must be confirmed"
  },
  {
    "id": "event",
    "capability": "event_adapter",
    "sideEffect": "defer",
    "note": "Undefined: explicit fallback to breakfast-only with receipt"
  },
  {
    "id": "event_nobarf",
    "capability": "event_daily_adapter",
    "sideEffect": "defer",
    "note": "Undefined: explicit fallback to breakfast-only with receipt"
  }
] as const;
export const IMPORTS = [
  {
    "id": "kolmafia_native",
    "owner": "kolmafia",
    "entrypoint": "require('kolmafia')",
    "capability": "snapshot",
    "risk": "read",
    "availability": "ready",
    "dependencies": []
  },
  {
    "id": "don_master_lib",
    "owner": "don-ash-lib",
    "entrypoint": "require('don_master_lib.ash')",
    "capability": "don_snapshot",
    "risk": "read",
    "availability": "source_present",
    "dependencies": []
  },
  {
    "id": "don_custom_functions",
    "owner": "don_custom_functions",
    "entrypoint": "require('don_custom_functions.ash')",
    "capability": "augmentBreakfast",
    "risk": "mutate",
    "availability": "source_present",
    "dependencies": [
      "don_master_lib"
    ]
  },
  {
    "id": "don_bone_lib",
    "owner": "don-ash-lib",
    "entrypoint": "require('don_bone_lib.ash')",
    "capability": "don_bone_remaining",
    "risk": "read",
    "availability": "source_present",
    "dependencies": []
  },
  {
    "id": "don_updates_lib",
    "owner": "don-ash-lib",
    "entrypoint": "require('don_updates_lib.ash')",
    "capability": "don_updates_check",
    "risk": "prefs",
    "availability": "source_present",
    "dependencies": []
  },
  {
    "id": "don_track_compat",
    "owner": "don-ash-lib",
    "entrypoint": "require('don_track_compat.ash')",
    "capability": "legacy account helpers",
    "risk": "read",
    "availability": "source_present",
    "dependencies": []
  },
  {
    "id": "don_codmaster_lib",
    "owner": "don-ash-lib",
    "entrypoint": "require('don_codmaster_lib.ash')",
    "capability": "codMaster profile functions",
    "risk": "mutate",
    "availability": "source_present",
    "dependencies": []
  },
  {
    "id": "boneFarm",
    "owner": "don_custom_functions",
    "entrypoint": "call boneFarm.ash",
    "capability": "knucklebone farming",
    "risk": "mutate",
    "availability": "source_present",
    "dependencies": [
      "don_bone_lib"
    ]
  },
  {
    "id": "boneTrack",
    "owner": "don_custom_functions",
    "entrypoint": "call boneTrack.ash",
    "capability": "daily bone accounting",
    "risk": "data",
    "availability": "source_present",
    "dependencies": [
      "don_bone_lib"
    ]
  },
  {
    "id": "don_combo",
    "owner": "don_combo release",
    "entrypoint": "don_combo/CLI adapter",
    "capability": "beach routing",
    "risk": "mutate",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "garbo",
    "owner": "loathers/garbage-collector",
    "entrypoint": "garbo/CLI adapter",
    "capability": "meat farming",
    "risk": "mutate",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "UnderTheSea",
    "owner": "UnderTheSea",
    "entrypoint": "UnderTheSea/CLI adapter",
    "capability": "sea path completion",
    "risk": "mutate",
    "availability": "external_optional",
    "dependencies": [
      "don_codmaster_lib"
    ]
  },
  {
    "id": "dLooper",
    "owner": "dLooper",
    "entrypoint": "ploop status/checkpoint adapter",
    "capability": "existing chunk evidence",
    "risk": "read",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "don_kolfix",
    "owner": "don_kolfix",
    "entrypoint": "bounded pre/post ascension hooks",
    "capability": "validation/enforcement",
    "risk": "guard",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "dTrack",
    "owner": "don-ash-lib GPL shelf",
    "entrypoint": "no unconditional import",
    "capability": "historic profit/time tracking",
    "risk": "data",
    "availability": "source_only",
    "dependencies": []
  },
  {
    "id": "dUpdates",
    "owner": "don-ash-lib",
    "entrypoint": "via don_updates_lib.ash",
    "capability": "version changes",
    "risk": "data",
    "availability": "absorbed",
    "dependencies": []
  },
  {
    "id": "don_ascend",
    "owner": "local/other script",
    "entrypoint": "don_ascend sea-pm (inspect actual install)",
    "capability": "Valhalla transition",
    "risk": "critical",
    "availability": "not_verified",
    "dependencies": []
  },
  {
    "id": "donBreakfast",
    "owner": "local/other script",
    "entrypoint": "donBreakfast/CLI adapter",
    "capability": "breakfast",
    "risk": "mutate",
    "availability": "not_verified",
    "dependencies": []
  },
  {
    "id": "sea-prep",
    "owner": "local/other script",
    "entrypoint": "sea-prep/CLI adapter",
    "capability": "ascension resource prep",
    "risk": "mutate",
    "availability": "not_verified",
    "dependencies": []
  },
  {
    "id": "flogger",
    "owner": "local/other script",
    "entrypoint": "flogger backup",
    "capability": "backup receipt",
    "risk": "data",
    "availability": "not_verified",
    "dependencies": []
  },
  {
    "id": "UberPvP",
    "owner": "loathers",
    "entrypoint": "uberpvp/CLI adapter",
    "capability": "pvp fights",
    "risk": "mutate",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "PVP_MAB",
    "owner": "Pantocyclus",
    "entrypoint": "pvp_mab/CLI adapter",
    "capability": "pvp strategy",
    "risk": "mutate",
    "availability": "external_optional",
    "dependencies": []
  },
  {
    "id": "mall_manager",
    "owner": "local/other script",
    "entrypoint": "mall-manager reprice/clean",
    "capability": "mall accounting",
    "risk": "mutate",
    "availability": "not_verified",
    "dependencies": []
  },
  {
    "id": "Halloween_calendar",
    "owner": "proposed external module",
    "entrypoint": "event snapshot adapter",
    "capability": "IRL+in-game Halloween",
    "risk": "read",
    "availability": "not_verified",
    "dependencies": []
  }
] as const;
export const ACTIONS = [
  {
    "segment": "start_day",
    "id": "snapshot.start",
    "risk": "none",
    "receipt": "player+rollover key"
  },
  {
    "segment": "start_day",
    "id": "git.update",
    "risk": "prefs",
    "receipt": "git update result (no blind git sync)"
  },
  {
    "segment": "start_day",
    "id": "breakfast.native",
    "risk": "gameplay",
    "receipt": "KoLmafia breakfast completion evidence"
  },
  {
    "segment": "setup_l1",
    "id": "cockroach.prep",
    "risk": "gameplay",
    "receipt": "preconditions and retained evidence"
  },
  {
    "segment": "setup_l1",
    "id": "diet.plan",
    "risk": "prefs",
    "receipt": "diet result"
  },
  {
    "segment": "setup_l1",
    "id": "moon.meat",
    "risk": "gameplay",
    "receipt": "moon sign after readback"
  },
  {
    "segment": "setup_l1",
    "id": "borrowed.time",
    "risk": "gameplay",
    "receipt": "item consumed once per ascension when loop=true"
  },
  {
    "segment": "leg1_farm",
    "id": "farm.mode",
    "risk": "gameplay",
    "receipt": "mode-specific invariant + adventure delta"
  },
  {
    "segment": "post_farm_l1",
    "id": "organ.maxo",
    "risk": "gameplay",
    "receipt": "readback organ values"
  },
  {
    "segment": "post_farm_l1",
    "id": "stillsuit.distillate",
    "risk": "gameplay",
    "receipt": "effect/item delta"
  },
  {
    "segment": "post_farm_l1",
    "id": "consume.4500",
    "risk": "gameplay",
    "receipt": "organ and inventory delta"
  },
  {
    "segment": "post_farm_l1",
    "id": "cooler.yeti",
    "risk": "gameplay",
    "receipt": "availability/effect readback"
  },
  {
    "segment": "drunk_farm",
    "id": "wineglass.farm",
    "risk": "gameplay",
    "receipt": "wineglass equipped + turn receipts"
  },
  {
    "segment": "pills",
    "id": "pill.farm",
    "risk": "gameplay",
    "receipt": "separate counts, each <= 200"
  },
  {
    "segment": "pvp_fights",
    "id": "uberpvp",
    "risk": "gameplay",
    "receipt": "fight count delta"
  },
  {
    "segment": "pvp_fights",
    "id": "pvp_mab",
    "risk": "gameplay",
    "receipt": "fight count delta"
  },
  {
    "segment": "sea_prep",
    "id": "flogger.backup",
    "risk": "data",
    "receipt": "backup path recorded"
  },
  {
    "segment": "sea_prep",
    "id": "sea.prep",
    "risk": "gameplay",
    "receipt": "explicit completion receipt"
  },
  {
    "segment": "pre_ascension",
    "id": "garden.workshed",
    "risk": "gameplay",
    "receipt": "readback slots"
  },
  {
    "segment": "pre_ascension",
    "id": "trophies.tokens",
    "risk": "gameplay",
    "receipt": "budgeted spend + readback"
  },
  {
    "segment": "pre_ascension",
    "id": "ascension.preflight",
    "risk": "none",
    "receipt": "plan/observed/inherited reconciliation"
  },
  {
    "segment": "ascension",
    "id": "don.ascend.sea_pm",
    "risk": "critical",
    "receipt": "ascension count and new-life evidence, no retries"
  },
  {
    "segment": "post_ascension_hook",
    "id": "don.hook.reconcile",
    "risk": "none",
    "receipt": "planned vs observed, no 30s blind check"
  },
  {
    "segment": "path_run",
    "id": "underthesea.path",
    "risk": "critical",
    "receipt": "path victory evidence, not solely canInteract/ronin"
  },
  {
    "segment": "new_life",
    "id": "car.maid",
    "risk": "gameplay",
    "receipt": "beach/maid state readback"
  },
  {
    "segment": "new_life",
    "id": "cook.plate",
    "risk": "gameplay",
    "receipt": "equipment readback"
  },
  {
    "segment": "new_life",
    "id": "recovery.ccs.mcd",
    "risk": "prefs",
    "receipt": "prefs and MCD readback"
  },
  {
    "segment": "new_life",
    "id": "raffle.111",
    "risk": "gameplay",
    "receipt": "ticket delta"
  },
  {
    "segment": "new_life",
    "id": "outfit.familiar.restore",
    "risk": "gameplay",
    "receipt": "recorded outfit/familiar readback"
  },
  {
    "segment": "new_life",
    "id": "consume.6500",
    "risk": "gameplay",
    "receipt": "organ/item/adventure delta"
  },
  {
    "segment": "setup_l2",
    "id": "autumnaton.fallbot",
    "risk": "gameplay",
    "receipt": "count/sent receipt"
  },
  {
    "segment": "leg2_farm",
    "id": "farm.mode",
    "risk": "gameplay",
    "receipt": "mode-specific invariant + adventure delta"
  },
  {
    "segment": "post_farm_l2",
    "id": "organs.overdrink",
    "risk": "gameplay",
    "receipt": "readback organ thresholds"
  },
  {
    "segment": "end_day",
    "id": "snapshot.end",
    "risk": "none",
    "receipt": "liquid+inventory+historical value and time deltas"
  }
] as const;
/**
 * Planned dispatch is not authorization: no execution until an adapter exists,
 * preconditions pass, budget/consent are checked and postcondition is verified.
 */
export function candidates(flag: string) {
  return ACTIONS.filter(action => action.segment === flag);
}
