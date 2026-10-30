# C2Talon / Select2 ASH extraction audit — 2026-10-29

Status: **REVIEWED; FIRST READ-ONLY ADAPTERS ADDED; GAMEPLAY EXECUTORS NOT PORTED**.

This audit inventories the upstream projects supplied for candidate adoption into
`don_custom_functions` and `don-ash-lib`. It is NOT authorization to run
their scripts. GitHub source was inspected; no live KoL operations were performed
and no KoLmafia compilation was available in the review environment.

## Recorded upstream source versions

| Repository | Inspected tree SHA | Purpose / disposition |
| --- | --- | --- |
| [C2Talon/c2t_kol_scripts](https://github.com/C2Talon/c2t_kol_scripts) | `1361354f6713e49eef302b6ea230562a8380d635` | 16 small command and utility scripts; split by side effects |
| [C2Talon/liba](https://github.com/C2Talon/liba) | `be832258074fae6036debae3afac9782ae8fc566` | Strongest typed IotM library patterns |
| [C2Talon/c2t_lib](https://github.com/C2Talon/c2t_lib) | `903a2210d878852b8a609e6b1ab912e5800e7aeb` | Mixed shared functions; inspect and port selectively |
| [C2Talon/c2t_megg](https://github.com/C2Talon/c2t_megg) | `7b59be574dce7ed69f9939f6a755748f36f223d3` | Egg bank state, donate, extract, fight + relay |
| [C2Talon/c2t_megg_relayCombat](https://github.com/C2Talon/c2t_megg_relayCombat) | `f2c9cf1610aa63e27f2c8887a0e0fa9487248a48` | Fight-page readout; composable transformer only |
| [C2Talon/c2t_ascend](https://github.com/C2Talon/c2t_ascend) | `19f30df3e9157282ef77e9c31d676577aeb17b53` | Valhalla execution; do not automatically absorb |
| [C2Talon/c2t_hccs](https://github.com/C2Talon/c2t_hccs) | `b4b648f0de6ac257fa97994e21c1daa5ff233f08` | Player-specific HCCS orchestration; extract only isolated planning/checks |
| [C2Talon/c2t_takerSpace_relay](https://github.com/C2Talon/c2t_takerSpace_relay) | `46de209fa9569a48c58e0db6af11a7e80ba03a45` | Recipe sorting, supply/affordability UI (choice 1537) |
| [C2Talon/c2t_peridot_relay](https://github.com/C2Talon/c2t_peridot_relay) | `07c4ee4e39b8492fc4c760db03ab60dc5bac05ca` | Monster ID disambiguation UI (choice 1557) |
| [donCannoli-burns/don_insertSelect2](https://github.com/donCannoli-burns/don_insertSelect2) | `6f1a26a448ba4695049c22c95c261fe9921f59b3` | Searchable HTML SELECT pattern, originally by C2Talon |
| [donCannoli-burns/don_insertSelect2-relays](https://github.com/donCannoli-burns/don_insertSelect2-relays) | `1e74d891dea7a44b8476a254a648aac7e6f1691a` | Choice 1463 and 1588 overrides; avoid duplicate owners |

## Detailed c2t_kol_scripts extraction

All paths below are within `kolmafia/scripts/c2t/`. The intention is to build
new **don_-namespaced** functions, not keep a second copy of command names.

| Source | Reusable function boundary | Risk / adoption |
| --- | --- | --- |
| `c2t_advent.ash` | calendar availability / eligible day test | Opening advent boxes changes daily state; keep execution separate |
| `c2t_apriling.ash` | typed effect, item and instrument request validation | Generates items/effects and spends limited uses; next targeted adapter |
| `c2t_capeMe.ash` | semantic cape mode parser and mode-to-command map | `retrocape` equipment/mode change; do not trigger on import |
| `c2t_cartographyHunt.ash` | monster/location preflight, choice 1435 validation | Begins a combat; stop on unexpected wanderer/choice |
| `c2t_cast.ash` | separate health-cost and glove-charge cast planners | Can spend HP/charges; never auto-burn remaining resources |
| `c2t_coldMedicineTracker.ash` | read offered items from workshed choice into snapshot | Leaves the player in a choice and writes a preference; no quiet background scrape |
| `c2t_fixHomemadeRobot.ash` | reconcile API weight against saved preference | Swaps familiar/equipment and edits preference; transactional restoration |
| `c2t_harvest_battery.ash` | availability precheck + explicit battery harvest | Spends limited power-plant resource; choice 1448 |
| `c2t_lprom.ash` | recording recipe and MP/sausage budget planner | Potential large MP/sausage cost; choice 821 |
| `c2t_mapgrim.ash` | plan required pills and map budget | Consumes maps; must be explicitly authorized |
| `c2t_choices_mapgrim.ash` | deterministic choice path and readback | Coupled to mapgrim; no arbitrary `choice` CLI fallback |
| `c2t_mayam.ash` | symbols/slots/resonance resolver, used-symbol guard | Existing `don_mayam()` duplicates a purpose; extend it rather than create conflicts |
| `c2t_reminisce.ash` | locket monster identity and availability validation | Enters combat via choice 1463; never auto-run a fight |
| `c2t_shrugall.ash` | filter eligible removable effects | Mass effect removal is not import-safe or an acceptable default |
| `c2t_stacheTracker.ash` | predictive helmet-buff state and confidence | Tracking can drift if buff sequence is skipped; flag uncertain instead of fabricating a state |
| `c2t_trainSet.ash` | 8-position layout validator and train piece enum | Choice 1485 / workshed edit; use dry-run before changing configuration |

## Reusable library split

### C2Talon/liba

- **Small pure helpers:** `liba_clamp`, `liba_containsToken`,
  `liba_inChoice`, `liba_priority`. Compare with existing `don_clamp`,
  preference, inventory and choice helpers before porting; skip duplicates.
- **Wrapped mutations:** `liba_equipCast`, `liba_rawUse`,
  `liba_incProperty` require resource policy/readback. Do not expose raw
  arbitrary commands through a generic agent function.
- **IotM modules:** `liba_coolerYeti` (choice 1560, options 2/3/4/5,
  400/225/100/25 XP); `liba_peridot` (target planning);
  `liba_eternityCodpiece` (five-slot gem layout);
  `liba_heartstone` (buff/skill mappings); plus radio backpack,
  April shield, beret, leprecondo, zirconia, umbrella, genie, LP-ROM,
  photo booth, black rose garden, baseball diamond and others.
- **Critical point for `getCool()`:** check `coolerYetiMode` before
  starting, remember and restore the familiar's *equipped item* as well
  as the previous familiar; do not submit follow-up choice options
  without identifying the current choice and available action.

### C2Talon/c2t_lib

Candidate read-only helpers include voter/sausage/void timing predicates,
`c2t_inChoice`, familiar weight and item priority. High-risk procedures
include clan membership/whitelisting, `c2t_wishFight`, equipment/casting,
combat macro helpers, bulk purchases, PvP/stone mutations. Split into
pure planning, bounded state changes and explicitly authorized gameplay;
do not import the whole file.

### Standalone and relay projects

- `c2t_megg`: separate read-only egg inventory/max-donation view from
  donate, extract, combat and periodic pre-adventure refresh. The
  `c2t_megg_relayCombat` readout depends on freshness of that view.
- `c2t_ascend`: do **not** port the Valhalla executor. Only consider
  a read-only preflight checklist and staged plan; ascension is an
  irreversible state transition with user confirmation.
- `c2t_hccs`: personalized resource assumptions; use as examples for
  IotM budgeting and per-test threshold validation, never as
  immediately portable main automation.
- `c2t_takerSpace_relay`: useful separation of recipes, affordability,
  inventory counts and display ordering; page mutation must not
  change server choices.
- `c2t_peridot_relay`: disambiguate equal monster names by ID.
- `don_insertSelect2` and `don_insertSelect2-relays`: searchable
  selects and choice 1463/1588 are UI compositors. **Only one
  `relay/choice.<id>.ash` can own a given page.** Compose into the
  existing owning relay rather than shipping duplicate override files.

## First additions made here

1. `don-ash-lib/don-master-ash-lib/scripts/don_iotm_catalog.ash`:
   import-safe `don_iotm_catalog()`, `don_iotm_find(key)`,
   `don_iotm_status(key)`. It lists **10 capability entries** (not
   10 ready executors) and exposes simple read-only state hints.
2. `don_custom_functions/scripts/don_iotm.ash`: CLI
   `don_iotm list` and `don_iotm cooler-yeti-adventures`.
   Calls no game actions.
3. `don_custom_functions/scripts/don_iotm_smoke.ash`: static choice
   metadata assertions; read-only.
4. `don-ash-lib/don-master-ash-lib/scripts/don_relay_select2.ash`:
   `don_relay_tag_searchable_selects(page)` is a pure string
   transformer. It does not load remote assets, initialize Select2,
   or own a relay override. The caller supplies frontend JS/CSS
   separately if interactive searching is desired.
5. `don_custom_functions/scripts/don_relay_select2_smoke.ash`:
   checks class preservation and idempotence.

These additions are meant as **capability evidence for Agent Web**, not
authority to execute: `catalog entry -> literal source/pref mapping ->
read-only preflight -> explicitly approved typed executor -> readback ->
ledger`. The `don_iotm` command does NOT execute the operation just
because the capability key is named.

## Installation / non-mutating verification

In KoLmafia GCLI (use exact checkout names from `git list`):

```text
git update donCannoli-burns-don-ash-lib-main
git update donCannoli-burns-don_custom_functions-main
verify don_iotm_catalog.ash
verify don_iotm.ash
verify don_relay_select2.ash
call don_iotm_smoke.ash
call don_relay_select2_smoke.ash
don_iotm list
don_iotm cooler-yeti-adventures
```

Local runtime verification is outstanding. Do **not** treat static
GitHub commits as successful ASH compilation or successful live actions.

## License and provenance

C2Talon repositories inspected contain MIT licenses (individual copyright
years vary). The original select2 pattern attribution and 2026 MIT text
are preserved in `don-ash-lib/don-master-ash-lib/third_party/C2Talon-MIT.txt`.
Any further direct source incorporation must carry its corresponding
upstream license and provenance. The initial IotM catalog is a new
metadata API informed by these sources, not a copy of their executors.

## Next gated implementation candidates

1. Add a deterministic eight-slot train-set validator returning a typed
   preview and expected diff; opt-in executor after tests.
2. Extract the Mayam *symbol resolver* into the shared lib, replacing
   hardcoded caller sequences without changing established consumption policy.
3. Extend `codMaster` to plan and reconcile Eternity Codpiece gems
   while preserving existing `data/cod_master/saves/<name>.txt`.
4. Build read-only mimic egg and peridot target indexes for Agent Web.
5. Independently review relay ownership before adding Select2 initialization
   into an existing choice handler.

Do not combine code from these distinct upstream projects into the
existing monolithic core until compatibility tests, daily-resource
boundaries, attribution and source-index rebuilds pass.
