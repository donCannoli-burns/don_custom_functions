/**
 * v0.3 passive event ledger. A SEPARATE journal from observation snapshots.
 * Reuses the v0.2 JournalIO exclusive-lease interface. Pure until invoked.
 * The connector is not installed into KoLmafia and cannot send Kmail.
 */
import type { JournalIO } from "./journal";
import {
  assertEventScope,
  validateEvidence,
  type EventDispatch,
  type EventEvidence,
  type EventScope,
} from "./event-observer";

export interface StoredEventEvidence extends EventEvidence {
  readonly sequence: number;
  readonly prevEventId: string | null;
}
export interface EventAppendResult {
  readonly path: string;
  readonly written: number;
  readonly duplicates: number;
  readonly finalSequence: number;
}
const MAX_JOURNAL_CHARS = 2 * 1024 * 1024;
const MAX_EVENTS = 2000;
const EXPECTED_ROW_KEYS = [
  "schema", "evidenceId", "requestId", "projectId", "hook",
  "scope", "observedAt", "source", "fieldSource", "confidence",
  "key", "value", "interpretation", "sequence", "prevEventId"
].sort();

function sameScope(a: EventScope, b: EventScope): boolean {
  return a.playerId === b.playerId &&
    a.rolloverDay === b.rolloverDay &&
    a.totalAscensions === b.totalAscensions;
}

export function eventJournalPath(scope: EventScope): string {
  assertEventScope(scope);
  return `don_Data/state-engine/${scope.playerId}/${scope.rolloverDay}/life-${scope.totalAscensions}/events.jsonl`;
}

function sameRecord(a: StoredEventEvidence, b: EventEvidence): boolean {
  const { sequence: _sequence, prevEventId: _prevEventId, ...payload } = a;
  // Structural equality is independent of JS object property insertion order.
  return a.schema === b.schema &&
    a.evidenceId === b.evidenceId &&
    a.requestId === b.requestId &&
    a.projectId === b.projectId &&
    a.hook === b.hook &&
    sameScope(a.scope, b.scope) &&
    a.observedAt === b.observedAt &&
    a.source === b.source &&
    a.fieldSource === b.fieldSource &&
    a.confidence === b.confidence &&
    a.key === b.key &&
    a.value === b.value &&
    a.interpretation === b.interpretation &&
    Object.keys(payload).length === Object.keys(b).length;
}

/**
 * Rejects partial tails, mixed players/day/lives, extra fields, duplicate IDs,
 * wrong links and malformed values. No silent truncation/recovery.
 */
export function parseEventJournal(text: string, scope: EventScope): StoredEventEvidence[] {
  assertEventScope(scope);
  if (typeof text !== "string" || text.length > MAX_JOURNAL_CHARS)
    throw new Error("DON_EVENTS_OVERSIZE");
  if (text === "") return [];
  if (!text.endsWith("\n")) throw new Error("DON_EVENTS_PARTIAL_TAIL");
  const lines = text.slice(0, -1).split("\n");
  if (lines.length > MAX_EVENTS) throw new Error("DON_EVENTS_TOO_MANY");
  const seen = new Set<string>();
  const parsed: StoredEventEvidence[] = [];
  for (let i = 0; i < lines.length; i++) {
    let row: StoredEventEvidence;
    try {
      row = JSON.parse(lines[i]) as StoredEventEvidence;
    } catch (_error) {
      throw new Error("DON_EVENTS_INVALID_JSON");
    }
    if (!row || typeof row !== "object" ||
        JSON.stringify(Object.keys(row).sort()) !== JSON.stringify(EXPECTED_ROW_KEYS))
      throw new Error("DON_EVENTS_INVALID_ROW");
    validateEvidence(row);
    if (!sameScope(scope, row.scope) ||
        row.sequence !== i + 1 ||
        row.prevEventId !== (i === 0 ? null : parsed[i - 1].evidenceId) ||
        seen.has(row.evidenceId))
      throw new Error("DON_EVENTS_CORRUPT_CHAIN");
    seen.add(row.evidenceId);
    parsed.push(row);
  }
  return parsed;
}

/** This requires a real cross-process exclusive lease, not a KoL preference. */
export function appendEventDispatch(io: JournalIO, batch: EventDispatch): EventAppendResult {
  if (!batch || batch.schema !== "don-event-dispatch-v0.3" ||
      !Array.isArray(batch.records) || batch.records.length > 32)
    throw new Error("DON_EVENTS_INVALID_BATCH");
  const path = eventJournalPath(batch.scope);
  if (!/^[A-Za-z0-9_-]{1,32}$/.test(batch.requestId))
    throw new Error("DON_EVENTS_INVALID_BATCH");
  const inBatch = new Set<string>();
  for (const record of batch.records) {
    validateEvidence(record);
    if (record.requestId !== batch.requestId ||
        !sameScope(record.scope, batch.scope) ||
        inBatch.has(record.evidenceId))
      throw new Error("DON_EVENTS_MIXED_BATCH");
    inBatch.add(record.evidenceId);
  }

  if (batch.records.length === 0)
    return { path, written: 0, duplicates: 0, finalSequence: 0 };

  if (!io.holdsExclusiveLease()) throw new Error("DON_EVENTS_NO_EXCLUSIVE_LEASE");
  const current = io.readText(path);
  const existing = parseEventJournal(current, batch.scope);
  const existingById = new Map(existing.map(row => [row.evidenceId, row]));
  const pending: EventEvidence[] = [];
  let duplicates = 0;
  for (const incoming of batch.records) {
    const previous = existingById.get(incoming.evidenceId);
    if (previous) {
      if (!sameRecord(previous, incoming))
        throw new Error("DON_EVENTS_IDEMPOTENCY_CONFLICT");
      duplicates++;
    } else {
      pending.push(incoming);
    }
  }
  if (existing.length + pending.length > MAX_EVENTS)
    throw new Error("DON_EVENTS_TOO_MANY");
  if (pending.length === 0)
    return { path, written: 0, duplicates, finalSequence: existing.length };

  const newRows: StoredEventEvidence[] = [];
  let lastId: string | null =
    existing.length ? existing[existing.length - 1].evidenceId : null;
  for (const incoming of pending) {
    const next: StoredEventEvidence = {
      ...incoming,
      sequence: existing.length + newRows.length + 1,
      prevEventId: lastId,
    };
    newRows.push(next);
    lastId = next.evidenceId;
  }
  const serialized = newRows.map(row => JSON.stringify(row) + "\n").join("");
  if (current.length + serialized.length > MAX_JOURNAL_CHARS)
    throw new Error("DON_EVENTS_OVERSIZE");
  if (!io.appendText(path, serialized))
    throw new Error("DON_EVENTS_APPEND_FAILED");
  const readback = io.readText(path);
  const verified = parseEventJournal(readback, batch.scope);
  if (verified.length !== existing.length + newRows.length ||
      JSON.stringify(verified) !== JSON.stringify([...existing, ...newRows]))
    throw new Error("DON_EVENTS_READBACK_FAILED");
  return {
    path,
    written: pending.length,
    duplicates,
    finalSequence: verified.length,
  };
}
