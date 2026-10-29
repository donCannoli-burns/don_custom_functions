# BoneFarm / BoneTrack absorption audit — 2026-10-29

## Decision and ownership

- **Installable runtime:** `don_custom_functions/scripts/boneFarm.ash`, `scripts/boneTrack.ash`, `relay/relay_BoneTrack.ash`.
- **Shared import-safe primitives:** `don-ash-lib/don-master-ash-lib/scripts/don_bone_lib.ash` with read-only `don_bone_smoke.ash`.
- **Dependency:** existing `don_custom_functions/dependencies.txt` already points to `github donCannoli-burns/don-ash-lib main`. The library's root `manifest.json` already installs only `don-master-ash-lib/` and is unchanged.
- **Source repositories retained:** neither original GitHub repository is deleted, archived, or rewritten by this absorption.

## Exact original source identity

| Component | Upstream main commit | Original Git blob SHA |
| --- | --- | --- |
| `boneFarm/scripts/boneFarm.ash` | `fe0c953243b9637f564295e2ce3b18c3c03a9190` | `7c483dc8d10d9396db288e87990cc1bcd06e11b7` |
| `boneTrack.ash/scripts/boneTrack.ash` | `4cd400c7d5fc94579124943236a512b86589e938` | `f33b317c5ccf2ba8a9513618d04f369b590c2d9d` |
| `boneTrack.ash/relay/relay_BoneTrack.ash` | `4cd400c7d5fc94579124943236a512b86589e938` | `28f478f2d773d9bb6683faeb7c071b98195a5243` |

Files were copied with the following **deliberate minimal changes**:
1. `boneFarm.ash` imports `don_bone_lib.ash` and uses `don_bone_daily_drops()` / `don_bone_rest_drops()` instead of reading those same preferences inline.
2. `boneTrack.ash` imports that library and delegates owned amount plus those same live counters to the corresponding read-only helpers.
3. `relay_BoneTrack.ash` is byte-for-byte unchanged.
4. Historical `data/boneTrack/` storage structure, player preference names, and farm behavior are unchanged. No player data was copied.

## Safety and runtime boundaries

The new shared library does not issue KoL actions, set preferences, read untrusted input paths, or write tracked data. The farm **does** spend adventures, change MCD/mood/CCS/equipment, sometimes resolve the known Skeleton Store choice, and invoke its optional reporting hook. The tracker **does** write data maps and may prompt or open a wiki, controlled by `boneTrackEnableWiki`; the relay dashboard remains read-only.

Old `boneFarm` and `boneTrack.ash` installed checkouts can collide on filename ownership after `git sync`. Inspect `git list` before updating, back up `data/boneTrack/<player>/` plus any locally edited scripts, and keep the original repositories for provenance. If collision is detected, stop and resolve explicitly: never delete historic tracking data and never blindly run `git delete` on another project.

## Verification checklist

- Static gate: import names, single-source ownership, helper purity, daily-count arithmetic, original source preservation, and root manifest scope.
- Compile-only KoLmafia gCLI: `verify don_bone_lib.ash`, `verify don_bone_smoke.ash`, `verify boneFarm.ash`, `verify boneTrack.ash`, `verify relay_BoneTrack.ash`.
- Read-only smoke: `call don_bone_smoke.ash`.
- CI workflow: `.github/workflows/bone-tools-verify.yml` runs KoLmafia `verify` on push/PR; a green action run is required to claim that environment's compilation passed.
- Requires human testing in KoLmafia before gameplay: inspect `git list` collisions, confirm historical data preserved, reporting value parity, pending-choice behavior, and farm's try/finally restorations. **No live player actions were executed by this migration.**

This document does **not** assert successful KoLmafia runtime verification until an actual run provides evidence. No source repositories were destroyed and no user data was changed.
