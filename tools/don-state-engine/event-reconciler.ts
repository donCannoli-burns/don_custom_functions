/**
 * Pure comparison of passive event records. No flag-writing or execution.
 * A change is only a change in locally observed evidence, never proof that
 * a gameplay action completed or a Don workflow flag should become "finished".
 */
import {
  assertEventScope,
  validateEvidence,
  type EventEvidence,
  type EventScope,
  type EventValue,
} from "./event-observer";

export interface EvidenceDelta {
  readonly evidenceId: string;
  readonly key: string;
  readonly projectId: string;
  readonly scope: EventScope;
  readonly current: EventValue;
  readonly previous: EventValue | null;
  readonly status: "baseline" | "same" | "changed";
  readonly flagTransitionAuthorized: false;
}

/**
 * Call with evidence in sequence order, ideally from a verified journal
 * readback. First sighting is a baseline, NOT a state transition.
 * A rollover or ascension is a separate scope, never a cross-life delta.
 */
export function deriveEvidenceDeltas(
  records: readonly EventEvidence[]
): EvidenceDelta[] {
  const seenIds = new Map<string, string>();
  const previous = new Map<string, EventValue>();
  const result: EvidenceDelta[] = [];
  let scope: EventScope | null = null;
  for (const record of records) {
    validateEvidence(record);
    assertEventScope(record.scope);
    if (scope === null) scope = record.scope;
    if (scope.playerId !== record.scope.playerId ||
        scope.rolloverDay !== record.scope.rolloverDay ||
        scope.totalAscensions !== record.scope.totalAscensions)
      throw new Error("DON_EVENT_RECONCILE_SCOPE_DRIFT");
    const fingerprint = JSON.stringify(record);
    const already = seenIds.get(record.evidenceId);
    if (already !== undefined) {
      if (already !== fingerprint) throw new Error("DON_EVENT_RECONCILE_CONFLICT");
      continue; // Same event replayed twice.
    }
    seenIds.set(record.evidenceId, fingerprint);
    const key = record.projectId + ":" + record.key;
    const exists = previous.has(key);
    const prior = exists ? previous.get(key)! : null;
    const status = !exists ? "baseline" : prior === record.value ? "same" : "changed";
    previous.set(key, record.value);
    result.push({
      evidenceId: record.evidenceId,
      key: record.key,
      projectId: record.projectId,
      scope: { ...record.scope },
      current: record.value,
      previous: prior,
      status,
      flagTransitionAuthorized: false,
    });
  }
  return result;
}
