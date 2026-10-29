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

## Compatibility notes

- The master library supplies shared helpers such as `needToAcquireItem`, `getanduse`, `save_outfit`, `trainfam`, `FindWand`, `WandUseable`, `WaitMinutes`, `Day`, `MinutesToRollover`, the `don_*` state helpers, output helpers, class predicates, and `saucegeyserAll`. They are **not redefined here**, avoiding ASH duplicate-function conflicts.
- The original `haveAdv` snapshot means **more than two** adventures, while the current master helper `don_have_adv()` means **at least one**. Older callers relying on the old threshold should use `my_adventures() > 2`.
- `possessItem` retains its legacy **unequip** side effect for equipped matches. Prefer `don_have(item)` for a read-only ownership check.
- `CheckFortune` consumes **at most one fortune cookie** per call and will not recurse into repeated auto-consumption.
- `advManager` intentionally does not implement the original unreachable day-shortener branch.
- The old unused `zlib.ash`, `ProfitTracking.ash`, `TimeTracking.ash`, and `DicsLibrary.ash` imports were removed. Functions still referenced by external callers should be migrated to the master library or handled in a separate, tested compatibility adapter, rather than reintroducing unconditional third-party imports.

## Gameplay functions have side effects

These functions are intended to be called **explicitly** and may spend Meat/adventures, consume items, change outfits/familiars/CCS/preferences, or submit choices. They include `consume`, `raffle`, `DOD`, `EGTS`, `zapWand`, `yetiAdv`, `getCool`, `don_mayam`, `augmentBreakfast`, `Baseline`, `nightcap`, `don_Midcap`, and `newstuff`.

Some are integrations, **not bundled dependencies**, requiring your other installed scripts or commands: `CONSUME`, `combo`, `combo.js`, `barfascend.txt`, `dpills`, and `don_praccess.ash`. They are not automatically downloaded and should be verified separately. Outfits `chowDown`, `chowDown2`, `yetibuff`, and `maxo` are player-defined.

## Repository layout

~~~text
dependencies.txt
README.md
scripts/
  don_custom_functions.ash
  don_custom_smoke.ash
~~~

No install hook runs arbitrary gameplay. KoLmafia handles the declared Git dependency and `git delete` lifecycle.

## Shared legacy helpers (experimental)

This repository now ships `scripts/don_lowerstats.ash` and `scripts/don_praccess.ash`, migrated from the pLooper helper scripts `lowerstats.ash` and `tapion_praccess.ash` (with credit to their original upstream authors/Tapion). These were previously duplicated in [dLooper](https://github.com/donCannoli-burns/dLooper) and are now provided here for reuse.

The `don_praccess.ash` standalone command imports `don_lowerstats.ash` and runs PirateRealm setup and gameplay, including resource acquisition and adventuring. **Experimental, use at your own risk.** The existing optional `call don_praccess.ash` invocation in `don_custom_functions.ash` now has a matching installed script. This change does not automatically activate that call; it still runs only when the enclosing function is invoked.

To check compilation without taking gameplay actions:

```text
verify don_lowerstats.ash
verify don_praccess.ash
```

## Absorbed checklist and updates commands

This repository now installs **hardened standalone commands** from Prusias-kol's MIT-licensed pChecklist/pUpdates projects:

- `pChecklist help` and `pChecklist crimbo22` (also `don_checklist`): read-only reports using `data/checklistData.txt` and existing personal checklists. The checker validates target names and bounded ID sets, and uses `don_true_owned_amount` from the master library to include equipment held by familiars. Items that are separately represented as bound and unbound objects can still require manual interpretation.
- `pUpdates help`, `pUpdates init <name>`, `pUpdates add <name> <note>`, `pUpdates check <name>`: stable old command name backed by the new `don_updates_lib.ash`. Update notes print as text (not HTML); invalid files do not advance your seen-version preference.

These commands are provided by the don_custom_functions checkout and the already declared don-ash-lib dependency. The standalone dChecklist/dUpdates checkouts are no longer needed **after** confirming the new files install and compile, and should not remain installed alongside this checkout because the file names overlap.

```text
git update donCannoli-burns-don-ash-lib-main
git update donCannoli-burns-don_custom_functions-main
git sync
verify don_checklist_lib.ash
verify pChecklist.ash
verify pUpdates.ash
pChecklist help
pUpdates help
```

The publicly shipped checklist data is preserved. **Personal checklist files are never overwritten during installation**; personal data is read from the legacy location if present. Upstream MIT notices are retained in `licenses/`. Experimental: use at your own risk. Runtime compilation has not been confirmed.

