# don_custom_functions

Reusable [KoLmafia](https://kolmafia.us/) ASH utilities by donCannoli. Designed as a **companion to** [don-ash-lib](https://github.com/donCannoli-burns/don-ash-lib), not another copy of it.

## Agent Web AA–DD read-only prototype

The checkout includes an HTML micro-agent map of `don_custom_functions` and imported `don_master_lib`. It is an indexed source viewer, **not** an executing agent.

```text
git update donCannoli-burns-don_custom_functions-main
git sync
verify agent_web_ash.ash
verify don_custom_functions.ash
call agent_web_smoke.ash
```

Open `http://127.0.0.1:60080/relay_agent_web.ash` in the KoLmafia relay browser; to inspect the master library use `?script=don_master_lib`. Static documents install into `data/agentWeb/`, with the search page at `data/agentWeb/don_custom_functions_micro_agent.html`.

**ASH cannot import HTML:** `don_custom_functions.ash` imports the read-only `agent_web_ash.ash` loader instead. See [AGENT_WEB_SPEC.md](AGENT_WEB_SPEC.md) for state/position/capability matrix, coupling ratios, CC/ DD mapping, and regeneration with `tools/build-agent-web.mjs`.

## Install in KoLmafia gCLI

~~~text
git checkout https://github.com/donCannoli-burns/don_custom_functions.git main
verify don_custom_functions.ash
call don_custom_smoke.ash
~~~

The repository includes `dependencies.txt`, so KoLmafia should **automatically check and download** the required `don-ash-lib` repository during checkout. Its `manifest.json` syncs `don-master-ash-lib/scripts/don_master_lib.ash` into KoLmafia's `scripts/` directory. The smoke test confirms that the dependency imports and that basic read-only checks pass. No paid services are required.

If the dependency was not downloaded, manually install it and retry:

~~~text
git checkout https://github.com/donCannoli-burns/don-ash-lib.git main
git sync
verify don_master_lib.ash
call don_master_smoke.ash
verify don_custom_functions.ash
call don_custom_smoke.ash
~~~

If `verify` fails, **do not run the gameplay functions** until the reported error is resolved. This repo was prepared without a live KoLmafia runtime; a successful in-client `verify` and smoke run are still required before treating it as tested.

## Update

~~~text
git list
git update donCannoli-burns-don_custom_functions-main
git update donCannoli-burns-don-ash-lib-main
~~~

Use the **exact checkout names shown by `git list`** if they differ from the examples.

## Remove using KoLmafia

~~~text
git list
git delete donCannoli-burns-don_custom_functions-main
~~~

The `git delete` command removes this checkout's installed files. Confirm the checkout name from `git list` first. **Do not delete don-ash-lib** if other scripts still depend on it. If appropriate, uninstall it separately using its own entry from `git list`.

## Import into another ASH script

~~~ash
import <don_custom_functions.ash>;

void main() {
    don_header("Don Utilities");
    don_good("Today: " + Day());
    print("Adventures: " + my_adventures());
}
~~~

The import itself does **not** call `visit_url`, `cli_execute`, `buy`, `adventure`, `set_property`, or choices. The legacy snapshot globals (`haveAdv`, `amFull`, `amBuzzed`, `amHigh`, `ascensionsToday`, etc.) exist for older callers but **do not update automatically**; prefer `my_adventures()`, `don_have_adv()`, `don_is_full()`, and related live-state functions from `don_master_lib.ash`.

## donBreakfast farming modes (feature branch)

The optional `donBreakfast.ash` gCLI entrypoint uses four persistent boolean
farming preferences. Each **defaults to false** when absent:

| Preference | True behavior |
| --- | --- |
| `don_breakfast_barf` | `cli_execute("barf")` |
| `don_breakfast_nobarf` | `cli_execute("nobarf")` |
| `don_breakfast_cowo` | `cli_execute("cowo")` **only for Pastamancers** |
| `don_breakfast_nobarf_combo` | `cli_execute("nobarf")`, after success `refresh all`, then `combo N` where `N=max(0,my_adventures()-15)` |
| `don_breakfast_cockroach` | Existing opt-in PirateRealm cockroach preparation |

### Preference-name migration

All custom breakfast preferences now use the uniform `don_breakfast_*` namespace.
When `donBreakfast run` or `donBreakfast <mode> on|off` is used,
an older saved value is copied to the new key **only if the new key is unset**.
An explicit new value (including `false`) always wins; the old key is retained
but is no longer consulted after the new one is set.

Previously saved keys: `donBreakfastBarf`, `donBreakfastNobarf`,
`donBreakfastCowo`, `donBreakfastNobarfCombo`, and
`don_breakfastCockroach`. Use the new names in the table above for manual
`set` commands. The native KoLmafia preference `breakfastCompleted`
is not renamed.

`donBreakfast help` remains read-only: before a migration it displays the
effective old value if the new key is unset, without changing preferences.

Use the gCLI wrapper to turn on a mode. This **switches off other farming
modes** and automatically enables `don_breakfast_cockroach=true`.

~~~text
donBreakfast help
donBreakfast status
donBreakfast cowo on
donBreakfast nobarfcombo on
donBreakfast nobarf on
donBreakfast barf on
donBreakfast cowo off
donBreakfast run
~~~

`donBreakfast` with no arguments also runs `augmentBreakfast()`.
`donBreakfast help` displays the current true/false value of all five
preferences without launching gameplay.

**Safety:** Cowo is rejected and its preference set false for any
non-Pastamancer. Direct KoLmafia `set don_breakfast_cowo=true` commands
cannot be intercepted immediately; the value is corrected when breakfast
next runs. If multiple farming modes are turned on manually using `set`,
breakfast refuses to run until the conflict is resolved; the `on`
wrapper is the recommended way to select one. Farming never begins if
required cockroach routing fails. This is significant because that
router spends turns and may need `lowerstats.ash`.

For NobarfCombo, no `combo` command is issued if `nobarf` fails,
`refresh all` fails, or fewer than 16 adventures remain. The 15-turn
reserve is calculated **after** `nobarf` and refresh, not before.
If the `nobarf`, `barf`, `cowo`, or `combo` gCLI commands/aliases
are missing or error, the helper reports failure; it does not provide
those external scripts.

Run read-only parser checks:

~~~text
verify don_custom_functions.ash
verify donBreakfast.ash
verify don_breakfast_modes_smoke.ash
call don_breakfast_modes_smoke.ash
donBreakfast help
~~~

Do not run `donBreakfast run` as a smoke check: it invokes live
daily and potentially farming gameplay.

## Cockroach / PirateRealm breakfast integration (opt-in)

The ASH library now exposes a callable **cockroach_fight_prep()** just above
**augmentBreakfast()**. It launches **scripts/don_cockroach_router.ash**, which
borrows Garbo's staged PirateRealm quest approach while retaining the user's
external **lowerstats.ash** stat-delving routine. It does **not** import or
require Garbo. It also does not replicate Garbo's dynamic profit maximization,
Dessert Island route selection, or encounter farming.

The router is **not** executed when this library is imported. Breakfast only
invokes it if **don_breakfast_cockroach** is set to true (defaults to off).

In the KoLmafia CLI:

~~~text
git sync
verify don_custom_functions.ash
verify don_cockroach_router.ash
verify lowerstats.ash
call don_custom_smoke.ash
set don_breakfast_cockroach = true
~~~

Then call your existing augmentBreakfast() entrypoint / don_breakfast alias,
or use an ASH wrapper script:

~~~ash
import <don_custom_functions.ash>;
void main() {
    augmentBreakfast();
}
~~~

To disable PirateRealm while retaining the other daily tasks:

~~~text
set don_breakfast_cockroach = false
~~~

To run ONLY PirateRealm setup, use an ASH wrapper that calls
cockroach_fight_prep() (or call don_cockroach_router.ash directly).

**Preflight and fail-safe behavior:** The route requires available PirateRealm
access, an unlocked anemometer, the eyepatch, sober enough status, and at least
40 adventures when starting a new voyage. It does not automatically drink
astral pilsners or use a six-pack. It selects a crewmate favoring Coxswain
and Harquebusier, chooses the Clipper when unlocked, uses bounded quest-stage
attempts instead of lastEncounter, and targets Trash Island. It makes up to
30 route actions / spends no more than 30 adventures per invocation, and
restores the affected choice preferences and accessory slot when it returns
normally. Interrupted scripts may require manual choice cleanup.

It optionally buys one windicle when its mall price is no higher than
3 * valueOfAdventure. The old lowerstats.ash is a **separate, unbundled
dependency** (from Prusias/pLooper). Verify it before enabling. PirateRealm's
stat condition is **at most 100** in each buffed stat; unlike the old
don_praccess.ash, exactly 100 is not rejected.

don_praccess.ash is left untouched and can still be run manually. The new
router does not call the legacy script or expose its old global variables.
Both scripts can change in-game state, spend turns, buy consumables, and
lower stats. Test only after a successful in-client verify; this branch
has no live KoL runtime verification.

**Breakfast semantics:** KoLmafia's breakfastCompleted preference now gates
only the native breakfast CLI command. The remaining Don tasks (raffle,
shower, Big Book, Mayam, and optionally cockroach setup) are independently
checked on every invocation. Individual tasks remain responsible for their
own daily idempotence and resource limits.

## Morning companion — don_login() / breakfast_1 / breakfast_2

Import-safe library entrypoint: `don_login()`. KoLmafia gCLI entrypoint:
`don_login.ash`. Start in dry/read-only mode:

~~~text
verify don_custom_functions.ash
verify don_login.ash
verify don_login_smoke.ash
call don_login_smoke.ash
call don_login.ash help
call don_login.ash status
~~~

To install aliases without gameplay: `call don_login.ash install`.

Aliases automatically installed **after** the morning combo and Git update:
`don-login => call don_login.ash %%`,
`don-breakfast-1 => call don_login.ash breakfast_1`,
`don-breakfast-2 => call don_login.ash breakfast_2`,
`don-login-eod => call don_login.ash eod`.

`don-login breakfast_1` runs **`combo watersheep-free` first** and
**`git update` second**, then alias setup, bounty/counters/conditions,
optional ptrack checkpoint, raffle top-up to 111 where accessible, holiday
detection, and either native in-run breakfast or aftercore Don breakfast.
Aftercore then runs boneFarm (unless disabled) followed by the selected
exclusive `don_breakfast_*` farming mode, otherwise `barf1`. If native
breakfast was completed *before* this morning run, farming is skipped.
Halloween overrides with `freecandy`; Crimbo/Time Tower with `nobarf`.
Feast of Boris is logged, continuing normal mode. Each phase uses a saved
daily `don_login_stage`; an interrupted `*_running` phase will not
silently retry paid or turn-consuming actions.

`don-login breakfast_2` / `don-login postascend` handles post-ascension
aftercore breakfast. It **requires `ascensionsToday > 0` and
`kingLiberated=true`**. A call is recorded once per daily ascension count
*before* gameplay begins; a failed/ambiguous attempt requires manual
reconciliation. It deliberately does not rerun the first login's free combo
or Git update. Use `don-login status` to inspect checkpoints.

`don-login eod` hands off to `don_post_run_from("eod")`. To
automatically hand off to the full post-run chain after farming, set
`don_login_auto_eod=true` (default false).

### Login preferences

| Preference | Default | Effect |
| --- | --- | --- |
| `don_login_bone_farm` | true | `call boneFarm.ash` |
| `don_login_default_garbo` | true | `barf1` when no breakfast farming mode selected |
| `don_login_holidays` | true | Holiday override |
| `don_login_ptrack` | false | Optional `call ptrack.ash add <name>` |
| `don_login_auto_eod` | false | Opt-in post-run chain |
| `don_login_stage` / `don_login_date` | managed | Daily checkpoints |
| `don_login_breakfast2_ascensions` | managed | Last second-breakfast attempt |

`don-login help` includes the existing `don_breakfast_*` preference
list. Shared daily breakfast setup is `don_breakfast_prepare_daily()`;
the original `augmentBreakfast()` still invokes the configured farming
mode after preparation, without running anything on import.

External `ptrack.ash`, `don_utilV2.ash`, `don_update_lib.ash`,
`TimeTracking.ash`, and `ProfitTracking.ash` remain optional; they are
not imported into this library to avoid missing-dependency compilation
failures. Git updates are handled by the requested native `git update`
command. An unverified shutdown-capable `don_update_check(false)` is not
invoked. For ptrack EOD checkpoints, use the already supported
`don_post_run_ptrack=true` switch.

**Live gameplay not tested here.** Note that `git update` can update
scripts during the current invocation; verify again before subsequent live
runs. The morning/ascension stages may spend turns and Meat.

## Don Post-Run — independent stages and full chain (feature branch)

**Safe first steps (compile / read-only):**

~~~text
verify don_custom_functions.ash
verify don_post_run.ash
verify don_post_run_smoke.ash
call don_post_run_smoke.ash
call don_post_run.ash help
call don_post_run.ash status
~~~

To **install aliases without running gameplay**, explicitly call:

~~~text
call don_post_run.ash install
~~~

This registers `don-post-run => call don_post_run.ash %%` and stage aliases
`yeti-adv`, `get-cool`, `eod-process`, and `don-nightcap`.
A first `start` call also installs them. No aliases are installed on import.
Do not append a second semicolon to the alias.

**Live invocations:**

~~~text
don-post-run start
don-post-run yeti
don-post-run cool
don-post-run eod
don-post-run nightcap
don-post-run status
~~~

ASH calls: `don_post_run();`, `don_yeti_adv();`, `get_cool();`,
`eod_proccess();` (requested spelling) or `eod_process();`, and
`nightcap();`. The original `yetiAdv()`, `getCool()`,
`DOD()`, `EGTS()`, `chowDown()`, `chowDown2()`, and
`openDungeon()` remain independently callable.

The chain maximizes familiar XP once per day (only while not overdrunk),
equips `maxorgan`, attempts `stooperDis()`, and runs
`CONSUME ALL VALUE 6500`. It checks Cooler Yeti XP and, if below 400,
trains in Dungeons of Doom with a **20-adventure reserve** and equips
a toy cupid bow when available. The existing `openDungeon()` method
can call `EGTS()` / `DOD()` if access is missing. Optional
`don_post_run_chow=true` enables invoking both saved chow outfits/
consumption routines before training; default is false due to side effects.
The old `yetiAdv()` keeps its original behavior when called directly.
At XP >=400, the chain invokes `combo watersheep-N` with
`N=my_adventures()`, once per saved stage for the day. It **will not**
repeat the combo automatically after marking `combo_done`.

EOD requires at most two adventures, full stomach, spleen and liver,
`maxorgan` outfit, and Stooper familiar. A failed readiness check stops
rather than launching a nightcap. EOD attempts the Cooler Yeti drink
upgrade, selected nightcap, Left-Hand Man, `genie effect offhand remarkable`,
`max adv`, optional Philter, `mall-manager reprice`,
`call buy-script.js`, raffle-ticket purchase up to 111,
and optionally ptrack checkpoints. The script retains a dated stage and
an EOD step counter to resume without repeating successful nightcap purchases.

**Nightcap configuration (no preference written on import):**

| Preference | Unset/default | Behavior |
| --- | --- | --- |
| `don_defaultNightcap` | `5227` | Normal nightcap item ID |
| `don_event` | `false` | Enable event mode |
| `don_eventNightcap` | `5227` | Event fallback item ID |
| `don_nightcap_buy_limit` | `175000` | Maximum buy price in Meat |
| `don_post_run_philter` | `false` | Philter is opt-in (may ask about untracked items) |
| `don_post_run_ptrack` | `false` | Optional `ptrack.ash` checkpoint calls |
| `don_post_run_chow` | `false` | Optional chowDown + chowDown2 before Yeti training |

In event mode, compare mall_price estimates of item IDs **8553 and 8554**;
choose an owned one or the cheapest candidate within the buy limit.
If neither has an acceptable estimated price, use the configured event
fallback. Note: KoLmafia's `mall_price` generally reports fifth-lowest,
not absolute lowest. The code resolves item IDs at runtime; check that
5227, 8553 and 8554 match your intended drinks before live consumption.
Overdrunk characters do not consume another nightcap.

**Philter prompt:** Upstream Philter asks about uncategorized items.
Its question is not suppressed here and no third-party script is patched.
If Philter is enabled, answer **No** manually to process only items
already covered by your ruleset. For a fully unattended run, keep
`don_post_run_philter=false` until an upstream-supported no-prompt
option is verified.

**Dependencies:** `CONSUME`, `combo watersheep-N`, `philter`,
`mall-manager`, `buy-script.js`, `ptrack.ash`, and player-created
`maxorgan`, `yetibuff` / chow outfits are external.
Missing/failing commands stop the relevant stage and are not silently
installed. The scripts do not import `TimeTracking.ash` or
`ProfitTracking.ash`: those belong to the external ptrack package.

### Resume and 20-turn protection

The automated Yeti stage will **not** invoke legacy `openDungeon()`
when Dungeons of Doom is locked: `DOD()` and `EGTS()` can use
adventures without respecting the chain's 20-turn reserve.
Unlock the dungeon independently, then rerun the stage.

EOD checkpoints are recorded after each completed action.
The full maxorgan/Stooper/full-organ/<=2-turn gate is required on
initial EOD entry; later retries resume from the saved action rather
than incorrectly reapplying the original gate after switching to
Left-Hand Man or consuming the nightcap.

**Not live-tested:** verify syntax and inspect status before any live run.

## Compatibility notes

- The master library supplies shared helpers such as `needToAcquireItem`, `getanduse`, `save_outfit`, `trainfam`, `FindWand`, `WandUseable`, `WaitMinutes`, `Day`, `MinutesToRollover`, the `don_*` state helpers, output helpers, class predicates, and `saucegeyserAll`. They are **not redefined here**, avoiding ASH duplicate-function conflicts.
- The original `haveAdv` snapshot means **more than two** adventures, while the current master helper `don_have_adv()` means **at least one**. Older callers relying on the old threshold should use `my_adventures() > 2`.
- `possessItem` retains its legacy **unequip** side effect for equipped matches. Prefer `don_have(item)` for a read-only ownership check.
- `CheckFortune` consumes **at most one fortune cookie** per call and will not recurse into repeated auto-consumption.
- `advManager` intentionally does not implement the original unreachable day-shortener branch.
- The old unused `zlib.ash`, `ProfitTracking.ash`, `TimeTracking.ash`, and `DicsLibrary.ash` imports were removed. Functions still referenced by external callers should be migrated to the master library or handled in a separate, tested compatibility adapter, rather than reintroducing unconditional third-party imports.

## Gameplay functions have side effects

These functions are intended to be called **explicitly** and may spend Meat/adventures, consume items, change outfits/familiars/CCS/preferences, or submit choices. They include `consume`, `raffle`, `DOD`, `EGTS`, `zapWand`, `yetiAdv`, `getCool`, `don_mayam`, `cockroach_fight_prep`, `augmentBreakfast`, `Baseline`, `nightcap`, `don_Midcap`, and `newstuff`.

Some are integrations, **not bundled dependencies**, requiring your other installed scripts or commands: `CONSUME`, `combo`, `combo.js`, `barfascend.txt`, `dpills`, `don_praccess.ash`, and `lowerstats.ash`. They are not automatically downloaded and should be verified separately. Outfits `chowDown`, `chowDown2`, `yetibuff`, and `maxo` are player-defined.

## Repository layout

~~~text
dependencies.txt
README.md
scripts/
  don_custom_functions.ash
  don_custom_smoke.ash
~~~

No install hook runs arbitrary gameplay. KoLmafia handles the declared Git dependency and `git delete` lifecycle.
