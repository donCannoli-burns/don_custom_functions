# Don State Engine — v0.1 architecture and import contract

Status: PROPOSED / MANIFEST ONLY. This branch neither installs a dispatcher nor runs live KoL actions. The typed registry is at tools/don-state-engine/registry.ts.

## Ownership / import discipline

- don-ash-lib: live state reads, general ASH adapters, read-only bone helpers, opt-in legacy dTrack comparison, and evidence serialization.
- don_custom_functions: installable entrypoints, one-phase-at-a-time planner, orchestration and tracking reports.
- don_kolfix: code-enforced capability/classification/budget/approval checks. Never treat prompts, flags or other scripts as authority.
- dLooper: compatibility with existing resumable phase checkpoints. A returned CLI success is not proof the chunk completed.
- UnderTheSea: source of detailed sea/path receipts, not the owner of the new global life-cycle journal.
- Agent Web: read-only projected source graph and navigation. Nothing in a sliver may execute gameplay directly.

ASH import statements in approved ASH modules: import <don_master_lib.ash>; import <don_custom_functions.ash>; import <don_bone_lib.ash>; import <don_codmaster_lib.ash>. Include only what that module actually needs. For JavaScript use require('kolmafia'), and lazy require('don_master_lib.ash'), require('don_custom_functions.ash'), require('don_bone_lib.ash'), require('don_updates_lib.ash'), require('don_track_compat.ash'), require('don_codmaster_lib.ash') only for admitted actions. KoLmafia JS can import ASH public functions; ASH cannot import JS. The GPL dTrack source shelf is intentionally not an auto-runtime import.

## Live data aliases

| Proposed API | Canonical source | Semantics |
|---|---|---|
| _adv() | my_adventures() | Remaining turns; numeric |
| _liver() | my_inebriety() | Used inebriety, not capacity |
| _stomach() | my_fullness() | Used fullness |
| _spleen() | my_spleen_use() | Used spleen |
| _meat_onhand() | my_meat() | Liquid Meat carried |
| _meat_closet() | my_closet_meat() | Closeted Meat |
| _last_flag_activation | event ledger | Last start timestamp |
| _last_flag_edit | event ledger | Last edit timestamp |
| _next_flag_expected | derived plan | Canonical next phase ID |
| _next_fallback | policy | Default false, only explicit fallback allowed |
| _next_flag_fallback | derived plan | Exact known fallback phase |
| stop_for_discrepancy | policy | Default true |
| flag_discrepancy_1..5 / _note | event ledger projection | UI slots from unbounded discrepancy array |
| loop_run | policy | Default false, explicit opt-in |
| next_Halloween / days_till_Halloween | external calendar adapter | Nullable YYYYMMDD / integer |
| is_Halloween / eve_of_Halloween / eve_of_Event | event adapter | true, false, or unknown, with provenance |
| time/state_triggers | scheduler | Composite predicate |
| _don_track(flag...) | event queries | Today's snapshots, receipts and change events |

Never overwrite a live observation with a script claim. Track my_ascensions(), ascensionsToday, my_turncount(), kingLiberated, can_interact(), inRonin and path-specific victory independently. Exiting Ronin is not a universal path completion test.

## Phases and transitions

1. start_day: snapshot liquid Meat and tradeable items; preserve previous day diff; opt-in git update; breakfast.
2. setup_l1: cockroach/roach setup, diet, moon sign, optional borrowed time with scope check.
3. leg1_farm: select exactly one primary mode from registry and bound its adventures.
4. post_farm_l1: outfit maxo, stillsuit, value-of-adventure 4500 consumption, cooler/yeti; retain readbacks.
5. If loop_run=false: optional remarkable/burning cape/adv maximizer/over-100 comb, then end_day.
6. If loop_run=true: guarded drunk_farm (wineglass), pill thresholds (200 each), combo and PvP, flogger backup, sea_prep.
7. pre_ascension: garden/workshed, trophies, tokens and currency checks; confirm path/class and resources.
8. ascension: only approved don_ascend sea-pm adapter, exact one-use handoff, never auto-retry.
9. post_ascension_hook: immediate durable observation, then delayed reconciliation after 30 s or next resume.
10. path_run: UnderTheSea, with actual win/prism/king readback rather than a generic Ronin check.
11. new_life: car/maid, cook+plate, recovery settings, CCS, moon sign, raffle, outfit/familiar record+restore, consume value 6500.
12. setup_l2 / leg2_farm / post_farm_l2: MCD 11/10 when supported, optional fallbot, selected farm mode, end-of-day accounting.

Secondary flag names remain first-class sub-states: in_ronin, stillsuit_l1, stillsuit_l2, get_cool_ready, get_cool_used, organ_maxing, overdrink, max_adv, mall_managed. Status integers are 0=pending, 1=started, 2=finished, 3=skipped, 4=failed, 5=needs_reconciliation. A script return alone may not assign 2.

## Farm mode selection

Exactly one primary mode per leg: freeze_all, breakfast_only, barf, cowo (Pastamancer only), nobarf, combo, combo_nobarf, combo_watersheep (explicit bounded turns/free), oreo, oreo_nobarf, trick_or_treat, trick_or_treat_nobarf, event, event_nobarf. The two event modes are currently undefined and propose breakfast_only as an *explicitly documented* fallback rather than silently dispatching it. Halloween needs a verified IRL or KoL-game holiday; source disagreement becomes a discrepancy. Stop immediately for freeze_all. If an adapter is unknown or missing, mark blocked, not skipped or finished.

## Ascension hooks and scopes

Do not overwrite existing preAscensionScript/postAscensionScript. Only compose don_kolfix_preAscension/don_kolfix_postAscension behind a permissioned installer that remembers prior hooks. Pre-hook: check prerequisites, write before snapshot + token + intended path/class. Post-hook: record current evidence promptly, but do not infer complete Valhalla departure from one refresh; a scheduled/resume reconciliation waits 30 seconds and checks ascension count, path, class, king status, adventure count and life ID. No blind retries.

Identity = player ID + KoL rollover date (today_to_string) + lifetime ascensions + segment instance. New day/life creates a new journal; do NOT delete or rewrite previous flags. If the rollover or ascension identity changes mid-command, stop and reconcile.

## Permanent journal in KoLmafia data

Recommended relative prefix: don_Data/state-engine/<player-id>/<rollover-YYYYMMDD>/life-<ascensions>/ (KoLmafia resolves under its data/ folder). Preserve existing Profit Tracking/, TimeTracking/, data/boneTrack/, cod_master/saves/, don_combo ledgers, and dUpdates/ unchanged.

Journal collections: observations.jsonl, flag-events.jsonl, discrepancy.jsonl, command-receipts.jsonl, value-checkpoints.jsonl, reconciliation.jsonl. Single-writer ordered updates with receipt IDs and schema versions; no duplicate append on retry. The five discrepancy UI slots are a projection of the complete journal, not a limit.

Liquid flow = sum of on-hand/closet/storage Meat movement with transfers classified as transfers. Estimated assets = tradeable quantities by item, location, price source and timestamp. Realized profit = verified sales minus costs/fees; do not count shop stock and realized sale proceeds simultaneously. Include wall-clock elapsed, adventures spent/gained, each flag's inventory snapshot diff, restarts and skipped phases. dTrack pricing remains an opt-in comparative legacy calculator, not proof of liquid realized profit.

## Planner decision rules

Observe -> validate identity -> load events -> derive earliest pending phase -> check class/path/event/resource budgets -> plan one admitted adapter -> require applicable approval -> execute only through don_kolfix -> reobserve -> verify independent postcondition -> journal finished or discrepancy. A started/inconclusive flag resumes with observation and reconciliation, NEVER by blind action replay. Claims, plan and observed values must be stored separately.

## Production acceptance gate

- Typecheck registry; validate all flags, adapter paths and action IDs.
- Run import safety checks (no gameplay, CLI execution, file writes or HTTP at module load).
- Verify ASH wrappers with in-client KoLmafia, including git checkout collision audit.
- Replay synthetic rollovers, unexpected ascension count, no-Ronin paths, wrong class, missing wineglass, Halloween unknown/conflicted, false CLI success, pre/post hook timing, and interrupted sea path.
- Compare dTrack valuations and check no shop double counting, no storage pulls.
- Adversarial test false-authority claims and command budgets under don_kolfix.
- Only then implement and explicitly approve the dispatcher. No live ascend as a smoke test.

## Already absorbed

Existing main already owns boneFarm.ash, boneTrack.ash and relay_BoneTrack.ash in don_custom_functions; don_bone_lib.ash in don-ash-lib. Original repositories preserved. dUpdates has installed wrappers; the six-file GPL dTrack suite is shelved as source only pending runtime/license review. This branch does not duplicate those migrations.
