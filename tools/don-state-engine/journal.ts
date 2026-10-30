/**
 * Fail-closed, append-only observation ledger (v0.2).
 *
 * This module has no KoLmafia dependency or top-level I/O.
 * The host MUST provide a real exclusive writer lease. A plain property
 * is not an adequate OS-level lock. Without an exclusive lease, no writes.
 *
 * KoLmafia r29125+ has append_buffer_to_file; older versions must stop,
 * never silently replace journal files with buffer_to_file().
 */
import type { Observation } from "./registry";
import type { ObserverResult } from "./observer";

export interface JournalIO {
  readText(path: string): string;
  appendText(path: string, text: string): boolean;
  holdsExclusiveLease(): boolean;
}
export interface ObservationEvent {
  schema: "don-observation-event-v0.2";
  eventId: string;
  sequence: number;
  prevEventId: string | null;
  scope: { playerId: string; rolloverDay: string; totalAscensions: number };
  kind: "observation";
  source: "kolmafia_cached";
  snapshot: Observation;
}
export interface JournalResult {
  disposition: "written" | "duplicate";
  path: string;
  event: ObservationEvent;
}
const MAX_JOURNAL_BYTES = 2 * 1024 * 1024;
const MAX_EVENTS = 2000;

export function observationPath(s: Observation): string {
  if (!/^[0-9]{1,12}$/.test(s.playerId) ||
      !/^[0-9]{8}$/.test(s.rolloverDay) ||
      !Number.isInteger(s.totalAscensions) || s.totalAscensions < 0)
    throw new Error("DON_JOURNAL_INVALID_SCOPE");
  return "don_Data/state-engine/" + s.playerId + "/" +
    s.rolloverDay + "/life-" + s.totalAscensions + "/observations.jsonl";
}
function parseRow(line: string, expected: Observation, index: number,
                  prev: ObservationEvent | null): ObservationEvent {
  let row: ObservationEvent;
  try {
    row = JSON.parse(line) as ObservationEvent;
  } catch (_error) {
    throw new Error("DON_JOURNAL_CORRUPT_JSON_LINE_" + (index + 1));
  }
  if (!row || row.schema !== "don-observation-event-v0.2" ||
      row.kind !== "observation" || row.source !== "kolmafia_cached" ||
      !row.scope || !row.snapshot ||
      !/^[A-Za-z0-9_-]{1,80}$/.test(row.eventId) ||
      row.sequence !== index + 1 ||
      row.prevEventId !== (prev ? prev.eventId : null) ||
      row.scope.playerId !== expected.playerId ||
      row.scope.rolloverDay !== expected.rolloverDay ||
      row.scope.totalAscensions !== expected.totalAscensions ||
      row.snapshot.playerId !== expected.playerId ||
      row.snapshot.rolloverDay !== expected.rolloverDay ||
      row.snapshot.totalAscensions !== expected.totalAscensions) {
    throw new Error("DON_JOURNAL_CORRUPT_CHAIN_LINE_" + (index + 1));
  }
  return row;
}
export function parseJournal(text: string, expected: Observation): ObservationEvent[] {
  if (typeof text !== "string" || text.length > MAX_JOURNAL_BYTES)
    throw new Error("DON_JOURNAL_OVERSIZE");
  if (text === "") return [];
  if (text.charAt(text.length - 1) !== "\n")
    throw new Error("DON_JOURNAL_PARTIAL_TAIL");
  const lines = text.slice(0, -1).split("\n");
  if (lines.length > MAX_EVENTS) throw new Error("DON_JOURNAL_TOO_MANY_EVENTS");
  const rows: ObservationEvent[] = [];
  for (let i = 0; i < lines.length; i++) {
    if (!lines[i]) throw new Error("DON_JOURNAL_BLANK_LINE");
    const event = parseRow(lines[i], expected, i, rows.length ? rows[rows.length - 1] : null);
    // No repeated IDs: even a matching second record is a broken journal.
    if (rows.some(r => r.eventId === event.eventId))
      throw new Error("DON_JOURNAL_REPEATED_EVENT_ID");
    rows.push(event);
  }
  return rows;
}
export function appendObservation(io: JournalIO, observation: ObserverResult,
                                  requestId: string): JournalResult {
  if (!observation || observation.schema !== "don-observation-v0.2" ||
      observation.source !== "kolmafia_cached")
    throw new Error("DON_JOURNAL_UNTRUSTED_OBSERVATION");
  if (typeof requestId !== "string" || !/^[A-Za-z0-9_-]{1,80}$/.test(requestId))
    throw new Error("DON_JOURNAL_INVALID_REQUEST_ID");
  const snap = observation.snapshot;
  const path = observationPath(snap);
  if (!io.holdsExclusiveLease()) throw new Error("DON_JOURNAL_NO_EXCLUSIVE_LEASE");
  const existing = parseJournal(io.readText(path), snap);
  const found = existing.find(row => row.eventId === requestId);
  if (found) {
    if (JSON.stringify(found.snapshot) !== JSON.stringify(snap))
      throw new Error("DON_JOURNAL_IDEMPOTENCY_CONFLICT");
    return { disposition: "duplicate", path, event: found };
  }
  if (existing.length >= MAX_EVENTS) throw new Error("DON_JOURNAL_TOO_MANY_EVENTS");
  const prev = existing.length ? existing[existing.length - 1] : null;
  const event: ObservationEvent = {
    schema: "don-observation-event-v0.2",
    eventId: requestId,
    sequence: existing.length + 1,
    prevEventId: prev ? prev.eventId : null,
    scope: { playerId: snap.playerId, rolloverDay: snap.rolloverDay,
             totalAscensions: snap.totalAscensions },
    kind: "observation",
    source: "kolmafia_cached",
    snapshot: snap
  };
  const line = JSON.stringify(event) + "\n";
  const before = existing.length ? existing.map(x => JSON.stringify(x) + "\n").join("") : "";
  if (before.length + line.length > MAX_JOURNAL_BYTES)
    throw new Error("DON_JOURNAL_OVERSIZE");
  if (!io.appendText(path, line)) throw new Error("DON_JOURNAL_APPEND_FAILED");
  const checked = parseJournal(io.readText(path), snap);
  if (checked.length !== existing.length + 1 ||
      JSON.stringify(checked[checked.length - 1]) !== JSON.stringify(event))
    throw new Error("DON_JOURNAL_READBACK_FAILED");
  return { disposition: "written", path, event };
}
