/**
 * Pure plan-only state resolver. No KoLmafia API, CLI, disk, or gameplay access.
 * An admitted executor must separately verify all pre/postconditions.
 */
import { SEGMENTS, FLAGS, FARM_MODES, FLAG_CODE } from "./registry";
import type { EnginePolicy, FlagCode, Observation } from "./registry";

export type DecisionKind =
  | "ready" | "stop" | "reconcile" | "blocked"
  | "skip_proposed" | "fallback_proposed" | "approval_required" | "done";
export interface Decision {
  kind: DecisionKind;
  flag: string | null;
  capability: string | null;
  mode: string | null;
  reason: string;
  executionAuthorized: false;
}
export interface PlannerInput {
  observation: Observation;
  policy: EnginePolicy;
  flags: Readonly<Record<string, FlagCode | undefined>>;
  discrepancyCount: number;
  leg1Mode: string | null;
  leg2Mode: string | null;
  requestedAdventureSpend?: number;
}

const LOOP_ONLY = [
  "drunk_farm", "pills", "pvp_fights", "sea_prep", "pre_ascension",
  "ascension", "post_ascension_hook", "path_run", "new_life",
  "setup_l2", "leg2_farm", "post_farm_l2"
] as const;
const HALLOWEEN_MODES = ["trick_or_treat", "trick_or_treat_nobarf"] as const;
const FLAG_SET: ReadonlyArray<string> = FLAGS as unknown as ReadonlyArray<string>;
const NONLINEAR = ["organ_maxing", "overdrink", "max_adv", "mall_managed"] as const;

function result(kind: DecisionKind, flag: string | null,
                reason: string, capability: string | null = null,
                mode: string | null = null): Decision {
  return { kind, flag, reason, capability, mode, executionAuthorized: false };
}
function includes(haystack: ReadonlyArray<string>, needle: string): boolean {
  return haystack.indexOf(needle) !== -1;
}

export function planNext(input: PlannerInput): Decision {
  const obs = input.observation;
  const policy = input.policy;
  if (!obs.playerId || !/^\d{8}$/.test(obs.rolloverDay) ||
      !Number.isFinite(obs.totalAscensions) ||
      obs.ascensionsToday < 0 || input.discrepancyCount < 0) {
    return result("stop", null, "Invalid or incomplete live identity/observation");
  }
  if (input.discrepancyCount > 0 && policy.stopForDiscrepancy)
    return result("stop", null, "Unresolved discrepancy; manual reconciliation required");
  if (obs.ascensionsToday > 1)
    return result("reconcile", null, "Multiple ascensions today; explicit life re-scoping required");
  if (input.requestedAdventureSpend !== undefined &&
      (!Number.isInteger(input.requestedAdventureSpend) ||
       input.requestedAdventureSpend < 0 ||
       input.requestedAdventureSpend > policy.maxAutomaticAdventureSpend)) {
    return result("blocked", null, "Proposed adventure spend exceeds policy budget");
  }
  if (policy.nextExpectedFlag && !includes(FLAG_SET, policy.nextExpectedFlag))
    return result("stop", policy.nextExpectedFlag, "Unknown next-expected flag");
  if (policy.nextFallbackFlag && !includes(FLAG_SET, policy.nextFallbackFlag))
    return result("stop", policy.nextFallbackFlag, "Unknown fallback flag");

  for (const segment of SEGMENTS) {
    const id = segment.id;
    const status: FlagCode = input.flags[id] === undefined
      ? FLAG_CODE.pending : input.flags[id]!;
    if (status === FLAG_CODE.finished || status === FLAG_CODE.skipped)
      continue;
    if (status === FLAG_CODE.started || status === FLAG_CODE.needs_reconciliation)
      return result("reconcile", id, "Existing in-progress or unconfirmed flag; do not replay");
    if (status === FLAG_CODE.failed)
      return result("stop", id, "Previous phase failed; explicit repair is required");
    if (status !== FLAG_CODE.pending)
      return result("stop", id, "Invalid flag code");
    if (includes(NONLINEAR, id)) continue; // observed sub-state, not a mandatory linear gate
    if (policy.nextExpectedFlag && id !== policy.nextExpectedFlag)
      return result("blocked", id, "Expected flag and journal phase disagree");

    if (!policy.loopRun && includes(LOOP_ONLY, id))
      return result("skip_proposed", id, "Non-loop day; journal the explicit skip");
    if (segment.scope === "leg1" && obs.ascensionsToday !== 0)
      return result("reconcile", id, "Leg 1 has passed without verified segment closure");
    if (segment.scope === "leg2" && obs.ascensionsToday !== 1)
      return result("blocked", id, "Leg 2 requires observed first ascension");
    if (id === "ascension")
      return result("approval_required", id, "Ascension requires a scoped human approval");
    if (id === "post_ascension_hook" && obs.ascensionsToday < 1)
      return result("reconcile", id, "Post-ascension has no observed ascension increment");
    if (id === "path_run" && obs.ascensionsToday < 1)
      return result("blocked", id, "Path run requires new-life evidence");
    if (id === "leg1_farm" || id === "leg2_farm") {
      const mode = id === "leg1_farm" ? input.leg1Mode : input.leg2Mode;
      if (mode === "freeze_all")
        return result("stop", id, "freeze_all is an absolute halt", null, mode);
      const found = FARM_MODES.find(m => m.id === mode);
      if (!found)
        return result("blocked", id, "Missing or unknown farming mode", null, mode);
      if (mode === "cowo" && obs.className.toLowerCase() !== "pastamancer")
        return result("blocked", id, "Cowo requires Pastamancer", null, mode);
      if (includes(HALLOWEEN_MODES, mode!)) {
        if (obs.eventEvidence !== "confirmed" || obs.isHalloween !== true)
          return result("blocked", id, "Halloween unconfirmed; no holiday farming", null, mode);
      }
      if (mode === "event" || mode === "event_nobarf")
        return result("fallback_proposed", id,
          "Event adapter is undefined; require explicit breakfast_only fallback receipt",
          "breakfast", "breakfast_only");
      if (found.sideEffect === "defer")
        return result("blocked", id, "Adapter remains deferred", found.capability, mode);
      return result("ready", id, "Eligible for adapter and approval verification",
        found.capability, mode);
    }
    return result("ready", id, "Eligible for adapter and approval verification",
      segment.action);
  }
  return result("done", null, "All canonical segments have terminal receipts");
}
