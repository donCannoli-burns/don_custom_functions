# Don State Engine v0.3 — Passive Event Observer (source-only)

**Status:** typed library and synthetic replay tests. Not installed as a KoLmafia script. No live hook, Kmail, external service, background process, or game action has been enabled.

## Reference lineage

[Loathers Excavator](https://github.com/loathers/excavator) uses a `spadingScript` callback with seven event types and a project registry that filters hooks by KoLmafia revision, active path and completion status. It normally forwards findings via Kmail, falling back to KoLmafia's shared `spadingData` property. **We reuse its event registry/parse architecture, not its transport or automatic activation.** No Excavator code is copied or vendored here.

[Greenbox](https://github.com/loathers/greenbox) supplies the model for separating collection, domain definitions and presentation; [Accountval](https://github.com/soolar/accountval.ash/tree/release) supplies data-driven account checks and optional valuation. Neither account pages nor price lookups are added in v0.3.

## Modules

```text
tools/don-state-engine/
  registry.ts           existing planner/flag definitions — unchanged
  observer.ts           existing read-only snapshot observer — unchanged
  journal.ts            existing v0.2 snapshot journal — unchanged
  ports.ts              existing uninstalled host ports — unchanged
  event-observer.ts     new bounded seven-hook dispatcher, privacy validator
  event-projects.ts     new sample cookbookbat, choice, resource recipes
  event-journal.ts      new separate append-only events.jsonl ledger
  event-reconciler.ts   new pure baseline/unchanged/changed comparisons
```

The event entry receives host-injected `EventIngress`, not a KoLmafia import. The host must supply two independently read scope tuples (before and after), a stable callback request ID, revision, path, timestamp and relevant typed facts. Pages and event meta are transient and subject to size limits. Their raw bytes must **never** be persisted, exported, logged, attached to an exception or passed to a journal.

The seven accepted hook names are `CHOICE`, `CHOICE_VISIT`, `CONSUME_REUSABLE`, `COMBAT_ROUND`, `DESC_ITEM`, `PLACE`, `PVP`. A hook **does not** automatically mean a relevant data point exists.

Current starter observations (synthetic/offline only):

| Project | Hooks | Emitted key | Source | What it actually proves |
| --- | --- | --- | --- | --- |
| `cookbookbat_quest` | `COMBAT_ROUND` (round 0, Cookbookbat active) | `cookbookbat.quest_location` | cached preference | Cached quest-location value, not a newly completed quest |
| `choice_context` | `CHOICE_VISIT` | `choice.available_id` | typed event metadata | Choice screen identifier, not selected outcome |
| `resource_tick` | `COMBAT_ROUND`, `CHOICE`, `PVP` | `resources.turns_this_ascension`, `resources.adventures` | cached getters | Local resource counter observations, not causal proof of a spend |

No separate collectors yet for the other hooks. Their dispatches produce an empty result rather than inventing facts. Additional recipes should declare one event hook, typed facts, evidence fields, and tests; do not place ad hoc parsing in the event dispatcher.

## Validation and privacy boundaries

- Scope = numeric player ID + KoL rollover day `YYYYMMDD` + lifetime ascension count. A differing before/after tuple rejects the **whole** dispatch. The host, not this library, is responsible for obtaining two fresh scoped reads.
- Callback request ID (1–32 ASCII identifier characters) is stable across retries of the **same event**. Reusing it with different evidence rejects replay. It MUST NOT be generated merely from current time, and must not collide across callbacks.
- Projects must be uniquely named, with explicit typed hooks. Completed projects, unsupported KoLmafia revisions, and unadmitted Two Crazy Random Summer projects are skipped.
- Each callback has an input page cap of 128 Ki characters and up to 32 output records. Emitted key/value/source/confidence fields are validated. No raw HTML, control characters, URLs, email addresses, or strings with credential-like assignment patterns may pass.
- Emitted interpretation is always `local_evidence_only`. Even `confidence: observed` means the value came from a local getter or parsed local event, **not** proof of a server-confirmed action, successful quest, legal PvP action, ascension or authorized workflow transition.
- `deriveEvidenceDeltas()` marks the first observation `baseline`, repeated values `same` and changed values `changed`. Every delta has `flagTransitionAuthorized: false`; no KoLFix preference writes occur.
- Raw page/meta may include account data: production host must additionally redact/authorize reads before invoking third-party parser modules; the current library's output filter is **not** a complete privacy DLP system.

## Event journal boundary

```text
don_Data/state-engine/<player>/<rolloverDay>/life-<ascensions>/
  observations.jsonl    v0.2 snapshot journal (unchanged)
  events.jsonl          v0.3 passive event records (new, not yet live)
```

`appendEventDispatch(io, batch)` requires the **same genuine cross-process exclusive writer lease** as the v0.2 snapshot journal. It must not be satisfied by a boolean preference or a fake always-true production callback. The function validates entire batches, checks existing chain sequence, predecessor ID, scope, duplicate event IDs, exact row fields, output size and partial tails, then appends all new records in **one append call** and verifies exact readback. Identical retries do not append; same ID with different data stops with `DON_EVENTS_IDEMPOTENCY_CONFLICT`.

No destructive overwrite, truncate, restore, file rotation, or automatic repair. Both journals are bounded to 2M characters/2000 events per player/day/life file. The predecessor-ID chain catches accidental corruption and ordering violations but is **not cryptographically tamper-evident**. A failed partial append requires human-led recovery from backed-up evidence.

## Future opt-in runtime adapter (NOT done by this PR)

1. Audit the current `spadingScript` preference, installed scripts and KoLmafia revision **read-only**. Never replace an existing spadingScript by default; Excavator or another spader may own the hook. Support controlled fan-out only with explicit operator approval and an isolated test profile.
2. Validate a native KoLmafia host adapter for `EventIngress`: verify event callback arguments, time, `myId`, `todayToString`, `myAscensions`, `getRevision`, `myPath`, and narrowly allowlisted getters. Do not refresh pages or call actions from an event callback.
3. Record only the finite `EventEvidence` output via an actually implemented exclusive-writer bridge. Never write to `spadingData`, `commandBufferGCLI`, existing login hooks, `donState_*` preferences or the v0.2 snapshot journal.
4. Define a stable event ID allocator that works across simultaneous callbacks, plugin restarts and replay. Add rate limits, queue overflow/deferred recovery and explicit provenance for source page vs cached property evidence.
5. Independently verify gameplay postconditions via a guarded executor receipt before promoting any workflow flag. The passive event stream alone cannot mark a task complete.
6. Provide an opt-in local status UI for privacy-safe evidence and discrepancies. Never silently publish account data to the web.

## Offline verification

CI typechecks the v0.1 registry/planner, v0.2 snapshot observer/journal/ports and the four new v0.3 files under strict TypeScript 5.8.3. It compiles them into `.state-build` and runs synthetic planner, snapshot/journal and passive-event tests. There is no KoLmafia runtime dependency in this gate and no effect on an installed KoLmafia account.

> **Important:** this is the event collector *core*, not a completed live event observer. A later approved hook adapter, provenance review, and actual writer lease remain production blockers.
