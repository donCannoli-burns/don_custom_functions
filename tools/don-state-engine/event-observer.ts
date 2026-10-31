/**
 * Don State Engine v0.3 — pure passive event dispatch.
 *
 * Inspired by Excavator's hook/project registry, but not its transport.
 * No KoLmafia imports, Kmail, network, filesystem access, or top-level work.
 * This module is NOT a spadingScript entrypoint and must not be installed as one.
 *
 * Inputs can contain raw page data during dispatch. Raw page/meta never leave
 * this boundary. Every emitted field is allowlisted and bounded.
 */
export const EVENT_HOOKS = [
  "CHOICE",
  "CHOICE_VISIT",
  "CONSUME_REUSABLE",
  "COMBAT_ROUND",
  "DESC_ITEM",
  "PLACE",
  "PVP",
] as const;

export type EventHook = (typeof EVENT_HOOKS)[number];
export type EventValue = string | number | boolean;
export type EventConfidence = "observed" | "inferred";
export type EventSource = "kolmafia_cached" | "event_metadata" | "parsed_page";

export interface EventScope {
  readonly playerId: string;
  readonly rolloverDay: string; // KoL rollover-aligned YYYYMMDD
  readonly totalAscensions: number;
}
export interface EventFacts {
  readonly currentRound?: number;
  readonly activeFamiliar?: string;
  readonly cookbookbatQuestLocation?: string;
  readonly choiceId?: number;
  readonly turnsThisAscension?: number;
  readonly adventures?: number;
}
export interface EventIngress {
  readonly hook: EventHook;
  readonly requestId: string; // Stable for replay of the same callback, not a timestamp.
  readonly observedAt: string;
  readonly scopeBefore: EventScope;
  readonly scopeAfter: EventScope;
  readonly mafiaRevision: number;
  readonly pathName: string;
  readonly meta: string; // Transient, never serialized.
  readonly page: string; // Transient, never serialized.
  readonly facts: Readonly<EventFacts>;
}
export interface EvidenceDatum {
  readonly key: string;
  readonly value: EventValue;
  readonly source: EventSource;
  readonly confidence: EventConfidence;
}
export interface EventProject {
  readonly id: string;
  readonly hooks: readonly EventHook[];
  readonly minRevision?: number;
  readonly allowInTwoCrazyRandomSummer?: boolean;
  readonly completed?: boolean;
  extract(input: Readonly<EventIngress>): readonly EvidenceDatum[] | null;
}
export interface EventEvidence {
  readonly schema: "don-event-evidence-v0.3";
  readonly evidenceId: string;
  readonly requestId: string;
  readonly projectId: string;
  readonly hook: EventHook;
  readonly scope: EventScope;
  readonly observedAt: string;
  readonly source: "kolmafia_spading_hook";
  readonly fieldSource: EventSource;
  readonly confidence: EventConfidence;
  readonly key: string;
  readonly value: EventValue;
  readonly interpretation: "local_evidence_only";
}
export interface EventDispatch {
  readonly schema: "don-event-dispatch-v0.3";
  readonly scope: EventScope;
  readonly requestId: string;
  readonly records: readonly EventEvidence[];
}

const MAX_PAGE_CHARS = 128 * 1024;
const MAX_RECORDS_PER_CALLBACK = 32;
const TWO_CRAZY_RANDOM_SUMMER = "Two Crazy Random Summer";
const IDENTIFIER = /^[A-Za-z0-9_-]{1,32}$/;
const PROJECT_ID = /^[a-z][a-z0-9_-]{0,23}$/;
const FIELD_KEY = /^[a-z][a-z0-9_.-]{0,63}$/;
const TIMESTAMP = /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)$/;
const PRIVATE_TEXT = /(?:https?:\/\/|pwd\s*[:=]|password\s*[:=]|token\s*[:=]|session\s*[:=]|cookie\s*[:=]|csrf\s*[:=]|authorization\s*[:=]|@|[<>\r\n\u0000-\u001f])/i;

function isHook(value: unknown): value is EventHook {
  return EVENT_HOOKS.some((hook) => hook === value);
}
function scopeValid(scope: EventScope): boolean {
  return (
    !!scope &&
    /^[0-9]{1,12}$/.test(scope.playerId) &&
    /^[0-9]{8}$/.test(scope.rolloverDay) &&
    Number.isSafeInteger(scope.totalAscensions) &&
    scope.totalAscensions >= 0
  );
}
function sameScope(a: EventScope, b: EventScope): boolean {
  return (
    a.playerId === b.playerId &&
    a.rolloverDay === b.rolloverDay &&
    a.totalAscensions === b.totalAscensions
  );
}
export function assertEventScope(scope: EventScope): void {
  if (!scopeValid(scope)) throw new Error("DON_EVENT_INVALID_SCOPE");
}
export function validateEvidence(record: EventEvidence): void {
  if (
    !record ||
    record.schema !== "don-event-evidence-v0.3" ||
    !IDENTIFIER.test(record.requestId) ||
    !PROJECT_ID.test(record.projectId) ||
    !isHook(record.hook) ||
    !TIMESTAMP.test(record.observedAt) ||
    !scopeValid(record.scope) ||
    record.source !== "kolmafia_spading_hook" ||
    !["kolmafia_cached", "event_metadata", "parsed_page"].includes(record.fieldSource) ||
    (record.confidence !== "observed" && record.confidence !== "inferred") ||
    record.interpretation !== "local_evidence_only" ||
    !FIELD_KEY.test(record.key) ||
    !/^([A-Za-z0-9_-]{1,80})$/.test(record.evidenceId) ||
    !record.evidenceId.startsWith(record.requestId + "_" + record.projectId + "_")
  ) throw new Error("DON_EVENT_INVALID_EVIDENCE");
  const value = record.value;
  if (
    !(typeof value === "boolean" ||
      (typeof value === "number" && Number.isFinite(value) && Number.isSafeInteger(value)) ||
      (typeof value === "string" && value.length > 0 && value.length <= 160 &&
       !PRIVATE_TEXT.test(value)))
  ) throw new Error("DON_EVENT_UNSAFE_VALUE");
}
function validateIngress(input: EventIngress): void {
  if (
    !input ||
    !isHook(input.hook) ||
    !IDENTIFIER.test(input.requestId) ||
    !TIMESTAMP.test(input.observedAt) ||
    !Number.isSafeInteger(input.mafiaRevision) ||
    input.mafiaRevision < 0 ||
    typeof input.pathName !== "string" || input.pathName.length > 120 ||
    typeof input.meta !== "string" || input.meta.length > 512 ||
    typeof input.page !== "string" || input.page.length > MAX_PAGE_CHARS ||
    !input.facts || typeof input.facts !== "object"
  ) throw new Error("DON_EVENT_INVALID_INGRESS");
  assertEventScope(input.scopeBefore);
  assertEventScope(input.scopeAfter);
  if (!sameScope(input.scopeBefore, input.scopeAfter))
    throw new Error("DON_EVENT_SCOPE_DRIFT");
}

/** Never treats parsed output as a successful workflow transition. */
export function dispatchPassiveEvent(
  input: EventIngress,
  projects: readonly EventProject[]
): EventDispatch {
  validateIngress(input);
  const seen = new Set<string>();
  const records: EventEvidence[] = [];
  for (const project of projects) {
    if (!project || !PROJECT_ID.test(project.id) || seen.has(project.id) ||
        !Array.isArray(project.hooks) || project.hooks.some(h => !isHook(h)) ||
        (project.minRevision !== undefined &&
          (!Number.isSafeInteger(project.minRevision) || project.minRevision < 0)))
      throw new Error("DON_EVENT_INVALID_PROJECT");
    seen.add(project.id);
    if (project.completed || !project.hooks.includes(input.hook) ||
        (project.minRevision !== undefined && project.minRevision > input.mafiaRevision) ||
        (input.pathName === TWO_CRAZY_RANDOM_SUMMER &&
          !project.allowInTwoCrazyRandomSummer)) continue;
    let result: readonly EvidenceDatum[] | null;
    try {
      result = project.extract(input);
    } catch (_error) {
      // Do not expose raw page text or third-party parser errors in logs.
      throw new Error("DON_EVENT_PROJECT_FAILED_" + project.id);
    }
    if (result === null) continue;
    if (!Array.isArray(result)) throw new Error("DON_EVENT_INVALID_PROJECT_OUTPUT");
    if (records.length + result.length > MAX_RECORDS_PER_CALLBACK)
      throw new Error("DON_EVENT_TOO_MANY_RECORDS");
    const keys = new Set<string>();
    for (const [index, datum] of result.entries()) {
      if (!datum || keys.has(datum.key))
        throw new Error("DON_EVENT_DUPLICATE_FIELD");
      keys.add(datum.key);
      const record: EventEvidence = {
        schema: "don-event-evidence-v0.3",
        evidenceId: input.requestId + "_" + project.id + "_" + index,
        requestId: input.requestId,
        projectId: project.id,
        hook: input.hook,
        scope: { ...input.scopeBefore },
        observedAt: input.observedAt,
        source: "kolmafia_spading_hook",
        fieldSource: datum.source,
        confidence: datum.confidence,
        key: datum.key,
        value: datum.value,
        interpretation: "local_evidence_only",
      };
      validateEvidence(record);
      records.push(record);
    }
  }
  return {
    schema: "don-event-dispatch-v0.3",
    scope: { ...input.scopeBefore },
    requestId: input.requestId,
    records,
  };
}
