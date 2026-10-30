# Don State Engine v0.2 — Observe -> Journal (stacked draft)

> Phase gate: pure TypeScript interfaces, offline-tested implementations, no live KoLmafia script installed, no player-state mutation.
> Base: PR #4 import registry and pure planner. This phase deliberately does not build any gameplay dispatcher.

## Architecture

  KoLmafia local read APIs  ->  whitelisted KoLReadPort
                                   |
                            captureKoLState()
                                   |
                       ObserverResult (not authority)
                                   |
                   optional operator-invoked record
                                   |
                   exclusive-writer lease required
                                   |
                     appendObservation() journal
                                   |
                      parse + readback verify
                                   |
                     planner/reconciliation input

### Boundary 1: observe (no side effects)

tools/don-state-engine/observer.ts captures: player ID, KoL rollover day (todayToString), lifetime and daily ascensions, turns, adventures, organ usage/capacities, liquid Meat in inventory/closet/storage, current class/path, kingLiberated, canInteract, and KoL day index.

Capture has no refreshStatus(), visitUrl(), cliExecute(), buy(), adventure(), setProperty(), file writes, event scheduling or network calls. It reads KoLmafia's **cached** state, not a new server-sourced receipt. An independent executor or adjudicator must collect validated after-action evidence for a gameplay transition.

Capture rereads player/day/ascensions/turncount after collecting state, aborting with DON_OBSERVER_SCOPE_DRIFT if any changed. It fails on missing/invalid ascensionsToday and kingLiberated preferences instead of substituting zero/false. TodayToString is KoL's rollover-aligned YYYYMMDD, distinct from gamedayToInt (the 96-day game calendar) and the machine-local wall clock.

Important unknowns: inRonin is null, since canInteract is not equivalent to Ronin or path victory; all Halloween fields are null and eventEvidence=unknown until the separately versioned calendar adapter supplies verified evidence. No valuation or item transfers happen during observation.

### Boundary 2: journal (local file mutation ONLY)

tools/don-state-engine/journal.ts creates data paths relative to KoLmafia's data directory:

  don_Data/state-engine/<numeric-player-id>/<rollover-YYYYMMDD>/life-<lifetime-ascensions>/observations.jsonl

Only the read-only observer result and a caller-supplied **stable requestId** are admitted. The ID is reused across retries of the *same* observation. The journal supplies event sequence, previous event ID, scope and a complete snapshot. It does not assign workflow completion status or override evidence. Append is separate from observation and requires a genuine exclusive writer lease.

Before appending: validate the exact source schema, strict player/day/life identifiers, request ID, previous newline-delimited JSON, monotonic sequence, previous-ID chain, scope consistency and no duplicate event IDs. Repeat of the same request ID and identical snapshot returns duplicate without a write; same ID with different data fails. Incomplete trailing lines, malformed JSON, wrong scope, writer lease failure and oversize journals STOP with no recovery by truncation. After append, reread/validate the full file and exact new final event.

**A previous event-ID chain detects accidental sequence corruption but is not a cryptographic tamper-evidence mechanism.** Crash after a partial append may leave a truncated final line: quarantine file and manually repair from backups after forensic inspection. Never silently truncate, overwrite, or continue after a corrupt tail. For future reliability, prefer a dedicated guarded single-writer native file service with fsync and atomic rotation; KoLmafia-only append does not guarantee OS-level atomic multi-writer behavior.

KoLmafia r29125 introduced append_buffer_to_file; tools/don-state-engine/ports.ts checks availability before native append, uses toBuffer and fileToBuffer, and refuses to downgrade to destructive buffer_to_file. Verify file/directory creation, native buffer conversion and readback behavior **inside the user's actual KoLmafia build** before installing any entrypoint.

Maximum per-file size is a conservative 2 million characters (approximately 2 MiB for ASCII) and 2000 events. This is a bounded prototype, NOT yet a high-throughput every-turn event sink. Directory and file rotation need their own designed version.

## State and flag projection

- Identity key: playerId + todayToString() + myAscensions() + segment instance. An ascension opens a new life directory; rollover opens a new day directory. Old files remain immutable.
- The observable in snapshot is not an action success claim. Event.kind='observation' and source='kolmafia_cached'.
- Flag state transitions 0 pending, 1 started, 2 finished, 3 skipped, 4 failed, 5 needs_reconciliation remain governed by PR #4, and have **not** been implemented as journal writers here.
- Don Track will eventually project relevant event IDs into a materialized view for _last_flag_activation, _last_flag_edit, _next_flag_expected, and the first five discrepancy flags. No direct preference writes are needed for these projections.
- JSONL is the canonical audit history; index.json and dashboard HTML are rebuildable materialized views, not authorities.

## Life-cycle snapshots (future CLI workflow; no live command installed)

1. At login/start_day: observe once; if scope stable, operator may explicitly record start_day observation.
2. Before each guarded action: record a planned immutable receipt, observe, and store pre-state observation.
3. Perform authorized action only via don_kolfix T1/T2/T3 policy gates and a typed adapter; journal itself may not invoke it.
4. After the action: read back state and reconcile with its own receipt; use a new event ID; preserve even inconclusive results.
5. For Valhalla: pre-hook writes intent and pre-state before any transition, post-hook only records early evidence, and delayed GET/read-only reconciliation checks after 30 seconds or the next resume. No blind second ascension.
6. At rollover: create a new day scope; never reset existing journals or merge a partially completed previous day into the new day's success.

## Accounting continuity

- The current v0.2 snapshot includes only liquid Meat balances, not inventory valuation or realized profit. Neither is inferred from a Meat balance delta.
- v0.3 may add a separate *item inventory snapshot* port: item ID, inventory/closet/storage/store quantity, bound/tradeable status, provenance, price and quote age. Keep dTrack parity fixtures and no-double-counting tests.
- Preserve data/boneTrack/, Profit Tracking/, TimeTracking/, cod_master/saves/, don_combo_*, pUpdates/, dUpdates/, ledger.db and unrelated scripts unchanged.
- Never scan or rewrite the entire data directory during login, rollover or every turn.

## Offline acceptance tests

- Observer numeric bounds, missing prefs, rollover and ascension scope drift, absence of Ronin/Halloween inference.
- Journal first append, monotonic chain, same-ID idempotency, conflict detection, cross-player scope, bad request IDs, corrupt/truncated tails, readback failure, max-size boundary.
- Injected KoLmafia native port: preference whitelist, missing append_buffer_to_file, missing real lease, no destructive fallback.
- Strict TypeScript compile plus Node synthetic replay of the state-engine planner.

## Remaining production blockers

1. Implement and verify a true exclusive-writer lease across all potential processes; do not accept a boolean preference as a lock.
2. Confirm KoLmafia runtime revision and available native append/to_buffer/file_to_buffer implementations using compile-only and non-player-changing filesystem tests in a backed-up test profile.
3. Verify that directory creation, file-to-buffer missing-file behavior and appending are reliable on the actual KoLmafia installation.
4. Decide how to generate/retain requestIds before any write, and handle recovery when the caller dies after append but before seeing a receipt.
5. Produce an opt-in, read-only 'don_state status' entrypoint with no login hook or background daemon; a separate operator-approved 'don_state record' may follow once the writer gate passes.
6. Add an independently tested stale-data and server-evidence reconciliation adapter before any 'finished' flag may rely on observed changes.

Only after these gates may a runtime adapter be installed. Until then, files remain in tools/, tests/, and docs/: no live KoLmafia behavior changes.
