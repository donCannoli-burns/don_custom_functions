# KoLmafia legacy absorption audit — 2026-10-29

**Status:** source-level integration and static checks; KoLmafia runtime still unverified.
**Default policy:** don't silently execute gameplay, don't replace user data, don't remove historical source.

## Intake and routing

| Former repo / entrypoint | Destination | Runtime state | Original credit/license |
|---|---|---|---|
| dChecklist / `pChecklist.ash` | don_custom_functions (A), `don_checklist_lib.ash` + CLI entrypoints | Active in A after checkout, no gameplay mutations | Prusias-kol / MIT |
| dwrapper / `pwrapper.ash` | dLooper (C), `ploop_guard_lib.ash` + guarded entrypoints | Active in C after checkout; defaults to inspect-only | Prusias-kol / rewritten successor |
| dUpdates / `pUpdates.ash` | don-ash-lib (B) `don_updates_lib.ash` + A `pUpdates.ash` | Active via A/B; no separate dUpdates dependency | Prusias-kol / MIT |
| dTrack / six `ptrackSuite` files + `relay_ptrack.js` | don-ash-lib `dtrack-suite/` GPL shelf | **Source only, not auto-installed**; old dTrack runtime remains until tests | Prusias-kol, The Dictator, Thoth19 / GPL-3.0 |

## Control and data boundaries

- `pChecklist`: validates target, caps 2,001-item ID ranges and 2,000-ID lists, suppresses duplicate IDs, counts familiar equipment through `don_master_lib`. **Does not write personal checklist data.**
- `pUpdates`: strict filename characters, 64-character max name, 10,000-version cap, text not HTML rendering, no version preference write on missing/invalid update files. Historical `prusias_pUpdates_` pref remains.
- `pwrapper`: read-only by default. `run` requires positive human confirmation, then invokes fixed `ploop fullday` **once**. Catches errors, records status, never auto-fights, auto-selects choices, or auto-retries.
- `dTrack`: eliminated implicit storage pulls; constrained new checkpoint names, added bounded collision resolution, explicit Screege redeem authorization, validated relay paths and graph output filenames. Legacy accounting semantics still live in `don_track_compat` (B).
- `dTrack` main six-file suite is GPL-3.0 and deliberately not combined into the MIT-directed live A package before legal/runtime review.
- The old source repositories remain intact for recovery (except documentation and the narrow dTrack hardening commits). Never instruct automatic deletion of a `data/` directory.

## Installation verification (manual KoLmafia gCLI)

In a **clean or backed-up profile**, first use `git list` to inspect collision-prone old installations. Do not remove dTrack yet. Back up custom checklists and all `Profit Tracking` and `TimeTracking` data before changing checkouts.

```text
git update donCannoli-burns-don-ash-lib-main
git update donCannoli-burns-don_custom_functions-main
git update donCannoli-burns-dLooper-main
git update donCannoli-burns-dTrack-main
git sync
verify don_checklist_lib.ash
verify don_checklist.ash
verify pChecklist.ash
verify don_updates_lib.ash
verify pUpdates.ash
verify ploop_guard_lib.ash
verify pwrapper.ash
verify ProfitTracking.ash
verify TimeTracking.ash
verify ptrack.ash
```

After verifying there are no competing installed filenames, the **read-only commands** are `pChecklist help`, `pChecklist crimbo22`, `pUpdates help`, `pwrapper`, `ptrack help` and `ptrack list`.

**Explicit gameplay commands:** `pwrapper run` (single approved loop), `ptrack breakfast` (gameplay), `ptrack redeemScreege` (consumption/autosell after approval). Avoid them in smoke tests.

## Required runtime evidence before declaring complete

1. Clean git checkout/verify passes with no script ownership collisions.
2. Public checklist output matches the old version on a fixed inventory snapshot, including equipment on familiars; custom lists survive.
3. pUpdates roundtrip: init, add, check, no change on invalid or missing file; legacy data and preferences preserved.
4. Old and new dTrack reports agree for representative inventory, closet, store, storage, bound familiar equipment, overrides, and Irrat data.
5. `relay_ptrack.js` renders historical checkpoints, graph mode writes a safe file, and no arbitrary local path may be read via checkpoint labels.
6. `pwrapper` status does zero KoL actions, timed-out approval does nothing, and any failed execution stops without automatic recovery.

No live KoLmafia player actions or in-client `verify` calls were performed during this GitHub-only operation.
