script "don_custom_functions.ash";
import <don_master_lib.ash>;
import <agent_web_ash.ash>;

/*
  DON CUSTOM FUNCTIONS
  --------------------
  Companion to don_master_lib.ash. The master library supplies the canonical
  state, logging, inventory, wand, outfit, familiar, and legacy alias helpers.
  No third-party legacy imports are required.

  Importing this file does not run gameplay, make HTTP requests, or change
  preferences. All mutating operations are inside explicitly called functions.

  Compatibility: the six legacy global state variables below are load-time
  snapshots. Prefer the don_* live helpers from don_master_lib.ash in loops.
*/

item night_cap = $item[Vintage Smart Drink];
boolean amBuzzed = don_is_buzzed();
boolean haveAdv = my_adventures() > 2; // Legacy >2 threshold, unlike don_have_adv().
boolean amFull = don_is_full();
boolean amHigh = don_is_spleen_full();
string kingLiberated = get_property("kingLiberated");
boolean inAftercore = don_in_aftercore();
int ascensionsToday = get_property("ascensionsToday").to_int();
boolean don_leg1 = ascensionsToday == 0;

string donPurp = "9400D3";
string donGreen = "32CD32";
string MediumAquamarine = "66CDAA";
string Fuchsia = "FF00FF";
string Orange = "FFA500";
string Crimson = "DC143C";

string CadetBlue = "5F9EA0";
string SteelBlue = "4682B4";
string LightSteelBlue = "B0C4DE";
string PowderBlue = "B0E0E6";
string LightBlue = "ADD8E6";
string SkyBlue = "87CEEB";
string LightSkyBlue = "87CEFA";
string DeepSkyBlue = "00BFFF";
string CornflowerBlue = "6495ED";
string MediumSlateBlue = "7B68EE";
string RoyalBlue = "4169E1";
string Blue = "0000FF";
string MediumBlue = "0000CD";
string DarkBlue = "00008B";
string Navy = "000080";
string MidnightBlue = "191970";

string don_prompt_mayam = "don_mayam";
boolean used_don_mayam = get_property("_don_mayam_done").to_boolean();

// Already supplied by don_master_lib.ash (do not redefine):
// don_is_buzzed, don_have_adv, don_is_full, don_is_spleen_full,
// don_in_aftercore, don_is_overdrunk, saucegeyserAll, needToAcquireItem,
// needToAcquirePullItem, getanduse, save_outfit, trainfam,
// WaitMinutes, don_breaker, don_header, don_sub, don_footer,
// don_good, don_caution, don_warning, don_error, MuscleClass,
// MoxieClass, MysticalityClass, FindWand, WandUseable,
// MinutesToRollover, and Day.

// -------------------------------------------------------------------------
// Read-only / legacy item helpers
// -------------------------------------------------------------------------

boolean possessItem(item thingy) {
    // Historically this function unequipped matching equipment; retain that
    // behavior for callers relying on it. For a pure test, use don_have().
    if (item_amount(thingy) > 0 || closet_amount(thingy) > 0) return true;
    if (!have_equipped(thingy)) return false;
    if (!cli_execute("unequip " + thingy)) {
        don_warning("possessItem(): could not unequip " + thingy);
    }
    return true;
}

boolean IamLegendary() {
    if (MuscleClass())
        return possessItem($item[Hammer of Smiting]) ||
               possessItem($item[Chelonian Morningstar]);
    if (MoxieClass())
        return possessItem($item[Shagadelic Disco Banjo]) ||
               possessItem($item[Squeezebox of the Ages]);
    if (MysticalityClass())
        return possessItem($item[Greek Pasta Spoon of Peril]) ||
               possessItem($item[17-alarm Saucepan]);
    return false;
}

boolean IamEpic() {
    if (IamLegendary()) return true;
    if (MuscleClass())
        return possessItem($item[Bjorn's Hammer]) ||
               possessItem($item[Mace of the Tortoise]);
    if (MoxieClass())
        return possessItem($item[Rock and Roll Legend]) ||
               possessItem($item[Disco Banjo]);
    if (MysticalityClass())
        return possessItem($item[Pasta Spoon of Peril]) ||
               possessItem($item[5-Alarm Saucepan]);
    return false;
}

string CheckFortune(boolean autoeat) {
    // Bounded: at most one fortune cookie consumed per invocation.
    string counters = get_property("relayCounters");
    matcher finder = create_matcher("(\\d+):Fortune Cookie", counters);
    int[int] turns;
    int index = 0;

    while (finder.find()) {
        int remaining = finder.group(1).to_int() - my_turncount();
        if (remaining > 0) {
            index += 1;
            turns[index] = remaining;
        }
    }

    if (index == 0 && my_fullness() < fullness_limit() && my_meat() > 40) {
        boolean approve = autoeat;
        if (!autoeat) approve = user_confirm("Eat one fortune cookie?");
        if (approve) {
            if (!eatsilent(1, $item[fortune cookie])) {
                return "<b><font color=#ff0000>Failed to eat a Fortune Cookie.</font></b>";
            }
            // Only re-read counters. Do not recurse into another eat/prompt.
            counters = get_property("relayCounters");
            finder = create_matcher("(\\d+):Fortune Cookie", counters);
            while (finder.find()) {
                int remaining = finder.group(1).to_int() - my_turncount();
                if (remaining > 0) {
                    index += 1;
                    turns[index] = remaining;
                }
            }
        }
    }

    string result = "";
    if (index > 0) {
        result = "<b><font color=#365f91>Semi-rare counters active: " + index + ".<br />";
        foreach i, remaining in turns {
            result += "Semi-rare in <font color=#00b0f0>" + remaining + "</font> turns.<br />";
        }
        result += "</font></b>";
    } else if (my_fullness() >= fullness_limit()) {
        result = "<b><font color=#ff0000>No future fortune counter; too full to eat a cookie.<br /></font></b>";
    } else {
        result = "<b><font color=#ff0000>No future fortune counter detected.<br /></font></b>";
    }
    result += "<b><font color=#365f91>Last semi-rare: <font color=#00b0f0>" +
              get_property("semirareLocation") + "</font></font></b>";
    return result;
}

string ListItems(int[item] Closet, int mode) {
    string names = "";
    foreach it in Closet {
        boolean include = false;
        switch (mode) {
            case 1: include = closet_amount(it) == 0; break;
            case 2: include = closet_amount(it) > 0; break;
            case 3: include = item_amount(it) == 0; break;
            case 4: include = item_amount(it) > 0; break;
            case 5: include = stash_amount(it) == 0; break;
            case 6: include = stash_amount(it) > 0; break;
        }
        if (include) names = don_list_add(names, it.to_string());
    }
    if (names == "") return "<EMPTY>";
    return names;
}

int day_of_week() {
    // Use the date parser in don_master_lib rather than the old broken
    // yyyyMMdd slicing formula. 0 = Sunday, 6 = Saturday.
    string name = Day();
    switch (name) {
        case "Sunday": return 0;
        case "Monday": return 1;
        case "Tuesday": return 2;
        case "Wednesday": return 3;
        case "Thursday": return 4;
        case "Friday": return 5;
        case "Saturday": return 6;
    }
    return -1;
}

// -------------------------------------------------------------------------
// Consumption and daily tasks
// -------------------------------------------------------------------------

void consume() {
    refresh_status();
    print("Fullness: " + my_fullness() + "/" + fullness_limit());
    print("Inebriety: " + my_inebriety() + "/" + inebriety_limit());
    print("Spleen: " + my_spleen_use() + "/" + spleen_limit());

    int today = get_property("ascensionsToday").to_int();
    if (today == 0) {
        set_property("CONSUME.ALLOWLIFETIMELIMITED", "true");
        set_property("valueOfAdventure", "7100");
        if (!cli_execute("CONSUME ALL")) don_error("Leg 1 CONSUME failed.");
    } else if (today == 1) {
        set_property("CONSUME.ALLOWLIFETIMELIMITED", "false");
        set_property("valueOfAdventure", "6400");
        if (!cli_execute("CONSUME ALL")) don_error("Leg 2 CONSUME failed.");
    } else {
        don_warning("consume(): no rule for ascensionsToday=" + today);
    }
}

void BeachAccess() {
    if (available_amount($item[134]) > 0 ||
        available_amount($item[4770]) > 0 ||
        available_amount($item[4769]) > 0 ||
        available_amount($item[6775]) > 0) return;

    if (!retrieve_item(1, $item[bitchin' meatcar]))
        don_error("Unable to retrieve a bitchin' meatcar for beach access.");
}

void advManager() {
    // Legacy branch that tried day-shorteners was unreachable; do not guess
    // at a spending policy in a library function.
    if (my_adventures() > 50) abort("advManager(): more than 50 adventures.");
    if (my_adventures() >= 5)
        don_warning("advManager(): no supported day-shortener action.");
}

void eat_sausage() {
    int needed = max(0, 23 - get_property("_sausagesEaten").to_int());
    if (needed <= 0) {
        don_warning("No magical sausages remaining in configured daily target.");
        return;
    }
    if (!cli_execute("eat " + needed + " magical sausage"))
        don_error("Unable to eat all configured magical sausages.");
}

void Sweat() {
    if (!have_skill($skill[Sweat Out Some Booze])) {
        don_warning("Sweat Out Some Booze not available.");
        return;
    }
    int attempts = 0;
    while (attempts < 3 &&
           get_property("_sweatOutSomeBoozeUsed").to_int() < 3 &&
           get_property("sweat").to_int() >= 25 &&
           my_inebriety() > 0) {
        attempts += 1;
        if (!use_skill(1, $skill[Sweat Out Some Booze])) {
            don_error("Sweat Out Some Booze failed; stopping.");
            return;
        }
    }
}

void startBarf() {
    int before = get_property("_juneCleaverEncounters").to_int();
    if (!cli_execute("barfascend.txt")) {
        don_error("barfascend.txt failed.");
        return;
    }
    if (get_property("_juneCleaverEncounters").to_int() != before) {
        don_warning("June Cleaver changed; retrying barfascend once.");
        cli_execute("uneffect beaten up");
        if (!cli_execute("barfascend.txt"))
            don_error("barfascend.txt retry failed.");
    }
}

void comboAll() {
    int turns = my_adventures() - 1;
    if (turns <= 0) {
        don_warning("comboAll(): no spare adventures.");
        return;
    }
    if (!cli_execute("combo " + turns)) don_error("combo failed.");
}

void comb() {
    if (my_adventures() < 1) use(1, $item[Law of Averages]);
    if (get_property("_freeBeachWalksUsed").to_int() != 11) {
        if (!cli_execute("combo.js")) don_error("combo.js failed.");
    } else {
        don_log("All configured free beach walks used.");
    }
}

void raffle() {
    int count = don_owned_amount($item[raffle ticket]);
    if (count > 0) {
        don_log("Already holding " + count + " raffle tickets.");
        return;
    }
    if (!cli_execute("raffle 111")) {
        don_error("Raffle command failed.");
        return;
    }
    count = don_owned_amount($item[raffle ticket]);
    if (count < 1) don_error("No raffle tickets acquired.");
    else don_good("Raffle tickets acquired: " + count);
}

void autoBot() {
    if (get_property("_autumnatonQuests").to_int() != 0) return;
    location target = $location[none];
    foreach loc in $locations[The Deep Machine Tunnels, A Smoldering Pelvis, Shadow Rift] {
        if (can_adventure(loc)) target = loc;
    }
    if (target == $location[none]) {
        don_warning("No available autumn-aton destination.");
        return;
    }
    if (!cli_execute("autumnaton send " + target))
        don_error("Could not send autumn-aton to " + target);
}

// -------------------------------------------------------------------------
// Dungeons of Doom and Cooler Yeti
// -------------------------------------------------------------------------

void DOD() {
    if (my_meat() < 5000) {
        don_error("At least 5000 meat required for DOD.");
        return;
    }
    if (available_amount($item[dead mimic]) > 0) {
        don_good("Dead mimic acquired; ready to use.");
        return;
    }
    if (!can_adventure($location[The Dungeons of Doom])) {
        don_error("The Dungeons of Doom are not accessible.");
        return;
    }
    equip($slot[acc1], $item[none]);
    set_property("choiceAdventure25", "2");
    while (item_amount($item[dead mimic]) == 0 && my_adventures() > 0) {
        if (!adventure(1, $location[The Dungeons of Doom])) break;
    }
    if (available_amount($item[dead mimic]) > 0) don_good("Dead mimic acquired.");
    else don_error("Stopped without obtaining dead mimic.");
}

void EGTS() {
    string page = visit_url("da.php");
    if (contains_text(page, "The Dungeons of Doom")) {
        DOD();
        return;
    }
    if (!can_adventure($location[The Enormous Greater-Than Sign])) {
        don_error("Greater-Than Sign is not accessible.");
        return;
    }
    set_property("choiceAdventure3", "3");
    set_property("choiceAdventure451", "3");
    while (available_amount($item[plus sign]) == 0 && my_adventures() > 0) {
        if (!adventure(1, $location[The Enormous Greater-Than Sign])) break;
    }
    if (available_amount($item[plus sign]) == 0) {
        don_error("Could not obtain a plus sign.");
        return;
    }
    set_property("choiceAdventure451", "5");

    if (available_amount($item[ring of teleportation]) == 0 &&
        can_interact() && my_meat() > 100000)
        cli_execute("buy 1 ring of teleportation");

    if (available_amount($item[ring of teleportation]) == 0) {
        don_error("Ring of teleportation unavailable.");
        return;
    }

    item previous = equipped_item($slot[acc1]);
    if (!equip($slot[acc1], $item[ring of teleportation])) {
        don_error("Unable to equip teleportation ring.");
        return;
    }
    while (get_property("lastEncounter") != "The Oracle Will See You Now" &&
           my_adventures() > 0) {
        if (!adventure(1, $location[The Enormous Greater-Than Sign])) break;
    }

    if (get_property("lastEncounter") != "The Oracle Will See You Now") {
        don_error("Could not reach the Oracle.");
        equip($slot[acc1], previous);
        return;
    }
    if (!use(1, $item[plus sign])) don_error("Could not use plus sign.");
    equip($slot[acc1], previous);
    if (can_adventure($location[The Dungeons of Doom])) DOD();
}

void zapWand() {
    if (my_meat() < 6000) {
        don_error("At least 6000 meat required for zap wand quest.");
        return;
    }
    string page = visit_url("da.php");
    if (contains_text(page, "The Enormous Greater-Than Sign")) EGTS();
    else if (contains_text(page, "The Dungeons of Doom")) DOD();
    else don_warning("Cannot determine dungeon access from da.php.");
}

void chowDown() {
    if (!outfit("chowDown")) {
        don_error("Missing chowDown outfit.");
        return;
    }
    cli_execute("refresh all");
    wait(5);
    consume();
    set_property("_don_chowdownCount", "1");
}

void chowDown2() {
    if (!outfit("chowDown2")) {
        don_error("Missing chowDown2 outfit.");
        return;
    }
    cli_execute("refresh all");
    wait(5);
    consume();
    set_property("_don_chowdownCount", "2");
}

void openDungeon() {
    familiar yeti = $familiar[cooler yeti];
    int xp = yeti.experience;
    if (!outfit("yetibuff")) {
        don_error("Missing yetibuff outfit.");
        return;
    }
    don_log("Cooler Yeti: " + xp + "/400 XP.");
    if (xp < 400 && contains_text(visit_url("da.php"), "The Enormous Greater-Than Sign"))
        zapWand();
}

void yetiAdv() {
    familiar yeti = $familiar[cooler yeti];
    if (!have_familiar(yeti)) {
        don_error("Cooler Yeti not owned.");
        return;
    }
    if (current_mcd() != 11) change_mcd(11);
    if (current_mcd() != 11) change_mcd(10);
    autoBot();
    if (!outfit("yetibuff")) {
        don_error("Missing yetibuff outfit.");
        return;
    }
    if (!use_familiar(yeti)) {
        don_error("Unable to equip Cooler Yeti.");
        return;
    }
    if (!cli_execute("CONSUME ALL VALUE 7500")) {
        don_error("CONSUME command failed.");
        return;
    }
    string dungeon = visit_url("da.php");
    if (contains_text(dungeon, "The Enormous Greater-Than Sign")) {
        openDungeon();
    }
    if (!can_adventure($location[The Dungeons of Doom])) {
        don_error("Dungeons of Doom not accessible.");
        return;
    }
    while (my_adventures() > 2 && yeti.experience < 400) {
        don_log("Cooler Yeti XP: " + yeti.experience + "/400.");
        if (!adventure(1, $location[The Dungeons of Doom])) {
            don_error("Adventure failed while training Yeti.");
            return;
        }
    }
    if (yeti.experience >= 400) don_good("Cooler Yeti drink buff ready.");
    else don_warning("Cooler Yeti needs " + max(0, 400 - yeti.experience) + " XP.");
}

// -------------------------------------------------------------------------
// Effects, Mayam and breakfast
// -------------------------------------------------------------------------

void stooperDis() {
    cli_execute("cast Communism!");
    familiar stooper = $familiar[Stooper];
    if (!have_familiar(stooper)) {
        don_warning("Stooper not available.");
        return;
    }
    if (!use_familiar(stooper)) return;
    if (my_inebriety() < inebriety_limit() &&
        (available_amount($item[tiny stillsuit]) > 0 ||
         have_equipped($item[tiny stillsuit]))) {
        cli_execute("drink stillsuit distillate");
    }
}

// Return actual success so the post-run controller does not advance on a failed choice.
boolean don_get_cool() {
    if (!outfit("maxo")) {
        don_warning("getCool: missing maxo outfit.");
        return false;
    }
    refresh_status();
    if (!get_property("_communismUsed").to_boolean() &&
        my_inebriety() == inebriety_limit() - 1)
        stooperDis();

    familiar previous = my_familiar();
    familiar yeti = $familiar[cooler yeti];
    if (!have_familiar(yeti) || yeti.experience < 400) {
        don_warning("Cooler Yeti missing or below 400 XP.");
        return false;
    }
    if (!use_familiar(yeti)) {
        don_error("Unable to equip Cooler Yeti.");
        return false;
    }
    if (!cli_execute("cast ode to booze")) {
        if (previous != $familiar[none]) use_familiar(previous);
        return false;
    }

    buffer page = visit_url("main.php?talktoyeti=1", false, true);
    buffer_to_file(page, "_yeti_talk2.html");
    string[int] choices = available_choice_options();
    if (!handling_choice() || choices[2] == "") {
        don_error("Cooler Yeti did not offer expected first option 2.");
        if (previous != $familiar[none]) use_familiar(previous);
        return false;
    }
    run_choice(2);
    choices = available_choice_options();
    if (!handling_choice() || choices[1] == "") {
        don_error("Cooler Yeti did not offer expected follow-up option 1.");
        if (previous != $familiar[none]) use_familiar(previous);
        return false;
    }
    run_choice(1);
    if (handling_choice()) {
        don_error("Cooler Yeti follow-up choice remains open.");
        if (previous != $familiar[none]) use_familiar(previous);
        return false;
    }
    if (previous != $familiar[none]) use_familiar(previous);
    don_good("Yeti drink enhancement sequence submitted.");
    return true;
}

// Preserve the original public callable signature.
void getCool() { don_get_cool(); }
void get_cool() { don_get_cool(); }


void shrugAT() {
    cli_execute("shrug Stevedave's Shanty of Superiority");
    cli_execute("shrug Power Ballad of the Arrowsmith");
    cli_execute("shrug The Moxious Madrigal");
    cli_execute("shrug The Magical Mojomuscular Melody");
    cli_execute("shrug Cletus's Canticle of Celerity");
    cli_execute("shrug Jackasses' Symphony of Destruction");
    cli_execute("shrug Brawnee's Anthem of Absorption");
}

void don_mayam() {
    if (available_amount($item[Mayam Calendar]) == 0 ||
        get_property("_don_mayam_done").to_boolean()) return;

    familiar mimic = $familiar[chest mimic];
    if (!have_familiar(mimic)) {
        don_warning("Chest Mimic not available; skipping Mayam.");
        return;
    }
    familiar previous = my_familiar();
    if (!use_familiar(mimic)) {
        don_error("Cannot equip Chest Mimic.");
        return;
    }
    boolean ok1 = cli_execute("mayam rings fur meat eyepatch yam");
    boolean ok2 = cli_execute("mayam rings yam lightning yam clock");
    boolean ok3 = cli_execute("mayam rings vessel yam cheese explosion");
    if (previous != $familiar[none]) use_familiar(previous);

    if (ok1 && ok2 && ok3) {
        set_property("_don_mayam_done", "true");
        used_don_mayam = true;
        don_good("Mayam commands completed.");
    } else {
        don_error("Mayam command failed; completion pref unchanged.");
    }
}

// Explicitly called integration: stages PirateRealm until Trash Island is
// selected. It does not start Garbo or initiate any cockroach combats itself.
// See don_cockroach_router.ash for its bounded, resumable route.
boolean cockroach_fight_prep() {
    if (get_property("_lastPirateRealmIsland") == "Trash Island") {
        don_log("PirateRealm already points to Trash Island.");
        return true;
    }
    if (my_inebriety() > inebriety_limit()) {
        don_warning("Cockroach prep skipped: character is overdrunk.");
        return false;
    }
    set_property("_don_cockroachRouteResult", "not-run");
    if (!cli_execute("call don_cockroach_router.ash")) {
        don_warning("Cockroach router failed or is unavailable.");
        return false;
    }
    boolean done = get_property("_don_cockroachRouteResult") == "success" &&
                   get_property("_lastPirateRealmIsland") == "Trash Island";
    if (!done) don_warning("Cockroach preparation incomplete; review router logs.");
    return done;
}

// Don Breakfast modes are persistent preferences. Importing this file does
// not set preferences or launch any farming commands.
// A mode turned on with donBreakfast.ash turns the other modes off.
boolean don_breakfast_is_pastamancer(class character_class) {
    return character_class == $class[Pastamancer];
}

int don_breakfast_combo_turns(int adventures_available) {
    if (adventures_available <= 15) return 0;
    return adventures_available - 15;
}

// Only the new don_breakfast_* names are written after migration.
// Legacy values are consulted if the new name has not yet been saved.
string don_breakfast_legacy_preference(string canonical) {
    if (canonical == "don_breakfast_barf") return "donBreakfastBarf";
    if (canonical == "don_breakfast_nobarf") return "donBreakfastNobarf";
    if (canonical == "don_breakfast_cowo") return "donBreakfastCowo";
    if (canonical == "don_breakfast_nobarf_combo") return "donBreakfastNobarfCombo";
    if (canonical == "don_breakfast_cockroach") return "don_breakfastCockroach";
    return "";
}

boolean don_breakfast_preference_enabled(string canonical) {
    string saved_value = get_property(canonical);
    if (saved_value == "") {
        string legacy_name = don_breakfast_legacy_preference(canonical);
        if (legacy_name != "") saved_value = get_property(legacy_name);
    }
    return saved_value.to_boolean();
}

void don_breakfast_migrate_one(string canonical) {
    if (get_property(canonical) != "") return;
    string legacy_name = don_breakfast_legacy_preference(canonical);
    if (legacy_name == "") return;
    string legacy_value = get_property(legacy_name);
    if (legacy_value == "") return;
    set_property(canonical, legacy_value.to_boolean() ? "true" : "false");
}

void don_breakfast_migrate_preferences() {
    don_breakfast_migrate_one("don_breakfast_barf");
    don_breakfast_migrate_one("don_breakfast_nobarf");
    don_breakfast_migrate_one("don_breakfast_cowo");
    don_breakfast_migrate_one("don_breakfast_nobarf_combo");
    don_breakfast_migrate_one("don_breakfast_cockroach");
}

int don_breakfast_active_modes() {
    int active = 0;
    if (get_property("don_breakfast_barf").to_boolean()) active += 1;
    if (get_property("don_breakfast_nobarf").to_boolean()) active += 1;
    if (get_property("don_breakfast_cowo").to_boolean()) active += 1;
    if (get_property("don_breakfast_nobarf_combo").to_boolean()) active += 1;
    return active;
}

string don_breakfast_mode_preference(string mode_name) {
    if (mode_name == "barf") return "don_breakfast_barf";
    if (mode_name == "nobarf") return "don_breakfast_nobarf";
    if (mode_name == "cowo") return "don_breakfast_cowo";
    if (mode_name == "nobarfcombo" || mode_name == "nobarf-combo")
        return "don_breakfast_nobarf_combo";
    if (mode_name == "cockroach" || mode_name == "roaches")
        return "don_breakfast_cockroach";
    return "";
}

// Called by the command wrapper; changes only preferences, not gameplay state.
boolean don_breakfast_set_mode(string mode_name, boolean enabled) {
    string preference_name = don_breakfast_mode_preference(mode_name);
    if (preference_name == "") {
        don_warning("Unknown breakfast mode: " + mode_name);
        return false;
    }

    don_breakfast_migrate_preferences();

    if (preference_name == "don_breakfast_cockroach") {
        if (!enabled && don_breakfast_active_modes() > 0) {
            don_warning("Cannot turn off cockroach prep while a farming mode is enabled.");
            return false;
        }
        set_property(preference_name, enabled ? "true" : "false");
        return true;
    }

    if (enabled && preference_name == "don_breakfast_cowo" &&
        !don_breakfast_is_pastamancer(my_class())) {
        set_property("don_breakfast_cowo", "false");
        don_warning("Cowo requires Pastamancer. don_breakfast_cowo reset to false.");
        return false;
    }

    if (enabled) {
        // Only one farming mode may be active. Roach preparation is required.
        set_property("don_breakfast_barf", "false");
        set_property("don_breakfast_nobarf", "false");
        set_property("don_breakfast_cowo", "false");
        set_property("don_breakfast_nobarf_combo", "false");
        set_property(preference_name, "true");
        set_property("don_breakfast_cockroach", "true");
    } else {
        set_property(preference_name, "false");
    }
    return true;
}

// Read-only listing, including any settings supplied directly through 'set'.
void don_breakfast_help() {
    don_header("donBreakfast preferences");
    print("don_breakfast_barf = " + don_breakfast_preference_enabled("don_breakfast_barf"));
    print("don_breakfast_nobarf = " + don_breakfast_preference_enabled("don_breakfast_nobarf"));
    print("don_breakfast_cowo = " + don_breakfast_preference_enabled("don_breakfast_cowo") +
          " (Pastamancer only; eligible: " +
          don_breakfast_is_pastamancer(my_class()) + ")");
    print("don_breakfast_nobarf_combo = " +
          don_breakfast_preference_enabled("don_breakfast_nobarf_combo") +
          " (nobarf, refresh all, combo with 15 adventures reserved)");
    print("don_breakfast_cockroach = " +
          don_breakfast_preference_enabled("don_breakfast_cockroach") +
          " (required for every farming mode)");
    print("All modes default to false when their preference is unset.");
    print("Old preference values appear until migrated during mode changes or run.");
    print("donBreakfast help | status | run");
    print("donBreakfast barf|nobarf|cowo|nobarfcombo on|off");
    print("donBreakfast cockroach on|off");
    print("Using 'on' disables competing farming modes and enables cockroach prep.");
    print("Direct CLI 'set' changes are validated when breakfast runs.");
}

// Ensures direct 'set' values cannot cause multiple farming commands to run.
// Direct preference writes cannot be intercepted at the moment of assignment.
boolean don_breakfast_validate_modes() {
    don_breakfast_migrate_preferences();
    if (get_property("don_breakfast_cowo").to_boolean() &&
        !don_breakfast_is_pastamancer(my_class())) {
        set_property("don_breakfast_cowo", "false");
        don_warning("Non-Pastamancer: don_breakfast_cowo reset to false.");
    }
    int active = don_breakfast_active_modes();
    if (active > 1) {
        don_error("Conflicting breakfast modes: no farming will run. Use donBreakfast <mode> on or turn the unwanted preferences off.");
        return false;
    }
    if (active == 1 && !get_property("don_breakfast_cockroach").to_boolean()) {
        set_property("don_breakfast_cockroach", "true");
        don_log("Enabled cockroach prep for the active breakfast farming mode.");
    }
    return true;
}

void don_breakfast_run_farming_mode() {
    if (get_property("don_breakfast_cowo").to_boolean()) {
        if (!don_breakfast_is_pastamancer(my_class())) {
            set_property("don_breakfast_cowo", "false");
            don_warning("Cowo skipped: only Pastamancers may enable it.");
            return;
        }
        if (!cli_execute("cowo")) don_error("cowo CLI command failed.");
        return;
    }

    if (get_property("don_breakfast_nobarf_combo").to_boolean()) {
        if (!cli_execute("nobarf")) {
            don_error("nobarf failed. Skipping refresh and combo.");
            return;
        }
        if (!cli_execute("refresh all")) {
            don_error("refresh all failed. Skipping combo.");
            return;
        }
        int combo_turns = don_breakfast_combo_turns(my_adventures());
        if (combo_turns == 0) {
            don_log("nobarf finished; 15-adventure reserve leaves no combo turns.");
            return;
        }
        if (!cli_execute("combo " + combo_turns))
            don_error("combo failed after nobarf and refresh.");
        return;
    }

    if (get_property("don_breakfast_nobarf").to_boolean()) {
        if (!cli_execute("nobarf")) don_error("nobarf CLI command failed.");
        return;
    }
    if (get_property("don_breakfast_barf").to_boolean() &&
        !cli_execute("barf")) don_error("barf CLI command failed.");
}

// Breakfast's daily tasks are independent of KoLmafia's breakfastCompleted flag.
// PirateRealm runs when explicitly enabled or required by a farming mode.
void augmentBreakfast() {
    if (!don_breakfast_validate_modes()) return;

    if (!get_property("breakfastCompleted").to_boolean()) {
        if (!cli_execute("breakfast"))
            don_warning("Native breakfast command failed.");
    } else {
        don_log("Native breakfast already completed; checking Don daily tasks.");
    }

    raffle();

    if (!get_property("_aprilShower").to_boolean() &&
        !cli_execute("shower ice"))
        don_warning("April shower ice command failed.");

    if (get_property("bankedKarma").to_int() > 2000 &&
        available_amount($item[The Big Book of Every Skill]) > 0 &&
        !use(1, $item[The Big Book of Every Skill]))
        don_warning("Unable to use The Big Book of Every Skill.");

    don_mayam();

    if (get_property("don_breakfast_cockroach").to_boolean()) {
        if (!cockroach_fight_prep()) {
            don_warning("Cockroach setup incomplete; any requested farming mode was NOT started.");
            return;
        }
    } else {
        don_log("PirateRealm cockroach route skipped (don_breakfast_cockroach=false).");
    }

    don_breakfast_run_farming_mode();
}

void Baseline() {
    shrugAT();
    cli_execute("hagnk all");
    cli_execute("refresh all");
    cli_execute("mood apathetic");
    cli_execute("ccs don_default");
    set_property("hpAutoRecovery", "0.65");
    set_property("hpAutoRecoveryTarget", "0.95");
    set_property("mpAutoRecovery", "0.65");
    set_property("mpAutoRecoveryTarget", "0.95");
    effect sparky = $effect[1927];
    item antidote = $item[Soft green echo eyedrop antidote];
    if (have_effect(sparky) > 0) {
        if (item_amount(antidote) < 1) buy(1, antidote);
        cli_execute("uneffect " + sparky);
    }
}

// Nightcap prices are KoLmafia mall_price estimates (usually fifth-lowest).
// No import-time preference writes; 5227 is the fallback item ID.
int don_nightcap_configured_id(string preference_name) {
    int chosen_id = get_property(preference_name).to_int();
    if (chosen_id <= 0) return 5227;
    return chosen_id;
}

int don_nightcap_price_limit() {
    int stored = get_property("don_nightcap_buy_limit").to_int();
    return stored > 0 ? stored : 175000;
}

item don_nightcap_pick() {
    string selector = get_property("don_event");
    if (!selector.to_boolean())
        return to_item(don_nightcap_configured_id("don_defaultNightcap"));

    item first = to_item(8553);
    item second = to_item(8554);
    int price_first = first == $item[none] ? 0 : mall_price(first);
    int price_second = second == $item[none] ? 0 : mall_price(second);
    int limit_price = don_nightcap_price_limit();

    // Owned items have no new purchase cost; prefer them before mall shopping.
    if (first != $item[none] && (item_amount(first) > 0 || closet_amount(first) > 0))
        return first;
    if (second != $item[none] && (item_amount(second) > 0 || closet_amount(second) > 0))
        return second;

    if (price_first > 0 && price_first <= limit_price &&
        (price_second <= 0 || price_first <= price_second))
        return first;
    if (price_second > 0 && price_second <= limit_price) return second;

    don_warning("Neither event item 8553 nor 8554 has an acceptable mall estimate; using don_eventNightcap fallback.");
    return to_item(don_nightcap_configured_id("don_eventNightcap"));
}

boolean don_nightcap() {
    if (my_inebriety() > inebriety_limit()) {
        don_log("Already overdrunk: will not consume a second nightcap.");
        return true;
    }
    item selected = don_nightcap_pick();
    if (selected == $item[none]) {
        don_error("Configured nightcap item ID is invalid.");
        return false;
    }
    int cap = don_nightcap_price_limit();
    don_log("Nightcap selection: " + selected + " (item " + selected.id + "; buy limit " + cap + ").");
    if (item_amount(selected) < 1 && closet_amount(selected) > 0 &&
        !take_closet(1, selected)) {
        don_error("Could not retrieve nightcap from closet.");
        return false;
    }
    if (item_amount(selected) < 1) {
        int estimate = mall_price(selected);
        if (estimate <= 0 || estimate > cap) {
            don_error("Nightcap mall estimate unavailable or above cap: " + estimate);
            return false;
        }
        if (buy(1, selected, cap) < 1) {
            don_error("Could not buy nightcap within configured cap.");
            return false;
        }
    }
    int before_inebriety = my_inebriety();
    if (!overdrink(1, selected) || my_inebriety() <= before_inebriety) {
        don_error("Nightcap did not increase inebriety.");
        return false;
    }
    don_good("Nightcap completed: " + selected + ".");
    return true;
}

void nightcap() { don_nightcap(); }


void don_dpills() {
    cli_execute("ccs don_default");
    cli_execute("outfit wineglass");
    cli_execute("mood apathetic");
    if (!cli_execute("dpills " + my_adventures())) {
        don_error("dpills command failed.");
        return;
    }
    set_property("_don_dailyPills", my_adventures() < 5 ? "true" : "false");
}

void don_Midcap() {
    item midcap = $item[bucket of wine];
    if (needToAcquireItem(midcap)) buy(1, midcap, 15000);
    if (available_amount(midcap) == 0) {
        don_error("Bucket of wine unavailable within 15000 meat limit.");
        return;
    }
    familiar stooper = $familiar[Stooper];
    if (!have_familiar(stooper)) {
        don_warning("Stooper unavailable; not overdrinking.");
        return;
    }
    familiar previous = my_familiar();
    if (!use_familiar(stooper)) return;
    if (!overdrink(1, midcap)) don_error("Overdrink failed.");
    if (previous != $familiar[none]) use_familiar(previous);
}

void don_Midcap_Pills() {
    if (!don_is_overdrunk() && my_adventures() >= 50) {
        int spare = my_adventures() - 50;
        if (spare > 0 && !cli_execute("combo " + spare)) {
            don_error("combo failed; not launching dpills.");
            return;
        }
    }
    don_dpills();
}

void newstuff() {
    int profitOffset = 100;
    string page = visit_url("campground.php?action=inspectdwelling");
    if (contains_text(page, "Clockwork Maid") ||
        contains_text(page, "Meat Butler") ||
        contains_text(page, "Meat Maid")) {
        don_log("Maid or butler already installed.");
        return;
    }
    int voa = get_property("valueOfAdventure").to_int();
    if (available_amount($item[Clockwork Maid]) > 0 ||
        buy(1, $item[Clockwork Maid], max(0, 8 * voa - profitOffset)) == 1) {
        if (!use(1, $item[Clockwork Maid])) don_error("Clockwork Maid install failed.");
        return;
    }
    if (available_amount($item[Meat Butler]) > 0 ||
        buy(1, $item[Meat Butler], max(0, 4 * voa - profitOffset)) == 1) {
        if (!use(1, $item[Meat Butler])) don_error("Meat Butler install failed.");
        return;
    }
    if (available_amount($item[Meat Maid]) > 0 ||
        buy(1, $item[Meat Maid], max(0, 4 * voa - profitOffset)) == 1) {
        if (!use(1, $item[Meat Maid])) don_error("Meat Maid install failed.");
        return;
    }
    don_warning("Maid / butler options are all outside price range.");
}


// -------------------------------------------------------------------------
// Don post-run: explicit, resumable workflow; none of this runs on import.
// The prior Yeti functions remain directly callable; this workflow keeps
// a separate 20-adventure floor to protect the later WaterSheep transition.
// -------------------------------------------------------------------------
void don_post_run_sync_date() {
    string today = today_to_string();
    if (get_property("don_post_run_date") == today) return;
    set_property("don_post_run_date", today);
    set_property("don_post_run_stage", "new");
    set_property("don_post_run_eod_step", "0");
}

boolean don_post_run_step_done(string step_name) {
    return get_property("don_post_run_stage") == step_name;
}

void don_post_run_track(string label) {
    // Optional, non-authoritative telemetry; never a required import.
    if (!get_property("don_post_run_ptrack").to_boolean()) return;
    if (!cli_execute("call ptrack.ash add " + label))
        don_warning("ptrack checkpoint unavailable: " + label);
}

void don_post_run_status() {
    print("don_post_run_date = " + get_property("don_post_run_date"));
    print("don_post_run_stage = " + get_property("don_post_run_stage"));
    print("don_post_run_eod_step = " + get_property("don_post_run_eod_step"));
    print("don_defaultNightcap = " + don_nightcap_configured_id("don_defaultNightcap") +
          " (" + to_item(don_nightcap_configured_id("don_defaultNightcap")) + ")");
    print("don_event = " + get_property("don_event").to_boolean());
    print("don_eventNightcap = " + don_nightcap_configured_id("don_eventNightcap") +
          " (" + to_item(don_nightcap_configured_id("don_eventNightcap")) + ")");
    print("don_nightcap_buy_limit = " + don_nightcap_price_limit());
    print("don_post_run_philter = " + get_property("don_post_run_philter").to_boolean());
    print("don_post_run_ptrack = " + get_property("don_post_run_ptrack").to_boolean());
    print("Yeti XP = " + $familiar[cooler yeti].experience + "/400");
    print("Adventures = " + my_adventures());
    print("Fullness = " + my_fullness() + "/" + fullness_limit() +
          "; spleen = " + my_spleen_use() + "/" + spleen_limit() +
          "; inebriety = " + my_inebriety() + "/" + inebriety_limit());
}

boolean don_post_run_prepare() {
    don_post_run_sync_date();
    if (!get_property("_don_famMax").to_boolean() &&
        my_inebriety() <= inebriety_limit()) {
        if (!cli_execute("maximize familiar exp")) {
            don_error("Familiar experience maximizer failed.");
            return false;
        }
        set_property("_don_famMax", "true");
    }
    if (!outfit("maxorgan")) {
        don_error("Missing required maxorgan outfit.");
        return false;
    }
    stooperDis();
    if (!cli_execute("CONSUME ALL VALUE 6500")) {
        don_error("CONSUME ALL VALUE 6500 failed.");
        return false;
    }
    set_property("don_post_run_stage", "prepared");
    don_post_run_track("postrun_prepared");
    return true;
}

// Alternative to legacy yetiAdv(): stop with at least 20 adventures unspent.
boolean don_post_run_yeti_stage() {
    don_post_run_sync_date();
    familiar yeti = $familiar[cooler yeti];
    if (!have_familiar(yeti)) {
        don_error("No Cooler Yeti owned.");
        return false;
    }
    don_log("Cooler Yeti XP: " + yeti.experience + "/400.");
    if (yeti.experience >= 400) {
        set_property("don_post_run_stage", "yeti_ready");
        return true;
    }
    if (my_adventures() <= 20) {
        don_warning("Yeti is below 400 XP and no adventures remain above the 20-turn reserve.");
        return false;
    }
    if (get_property("don_post_run_chow").to_boolean()) {
        if (have_outfit("chowDown")) chowDown();
        if (have_outfit("chowDown2")) chowDown2();
    }
    item bow = $item[toy cupid bow];
    if (available_amount(bow) > 0 || have_equipped(bow)) {
        foreach other in $familiars[] {
            if (other != yeti && familiar_equipped_equipment(other) == bow)
                if (!equip(other, $item[none])) {
                    don_error("Cannot release toy cupid bow from " + other);
                    return false;
                }
        }
        if (familiar_equipped_equipment(yeti) != bow && !equip(yeti, bow)) {
            don_error("Cannot equip toy cupid bow on Cooler Yeti.");
            return false;
        }
    } else {
        don_warning("Toy cupid bow unavailable; training without it.");
    }
    if (!can_adventure($location[The Dungeons of Doom])) {
        // The legacy dungeon unlockers may spend all remaining adventures.
        // Never run them automatically under a 20-adventure reserve.
        don_error("Dungeons of Doom locked. Run openDungeon()/EGTS()/DOD() independently before resuming.");
        return false;
    }
    if (!outfit("yetibuff") || !use_familiar(yeti)) {
        don_error("Could not prepare Yeti outfit/familiar.");
        return false;
    }
    while (my_adventures() > 20 && yeti.experience < 400) {
        if (!adventure(1, $location[The Dungeons of Doom])) {
            don_error("Yeti training adventure failed.");
            return false;
        }
    }
    don_log("Cooler Yeti XP now " + yeti.experience + "/400.");
    if (yeti.experience < 400) return false;
    set_property("don_post_run_stage", "yeti_ready");
    don_post_run_track("postrun_yeti_ready");
    return true;
}

// Useful independent ASH entrypoint. Does not call the legacy 2-turn drain.
void don_yeti_adv() { don_post_run_yeti_stage(); }

boolean don_post_run_combo_stage() {
    don_post_run_sync_date();
    if ($familiar[cooler yeti].experience < 400) {
        don_error("Cooler Yeti below 400 XP: refusing to start WaterSheep.");
        return false;
    }
    string stage_name = get_property("don_post_run_stage");
    if (stage_name == "combo_done" || stage_name == "done") return true;
    int turns = my_adventures();
    if (turns > 2) {
        if (!cli_execute("combo watersheep-" + turns)) {
            don_error("WaterSheep combo command failed.");
            return false;
        }
    } else don_log("At two or fewer adventures; no WaterSheep turns needed.");
    set_property("don_post_run_stage", "combo_done");
    don_post_run_track("postrun_combo_done");
    return true;
}

boolean don_post_run_eod_ready() {
    if (my_adventures() > 2) return false;
    if (my_fullness() < fullness_limit()) return false;
    if (my_spleen_use() < spleen_limit()) return false;
    if (my_inebriety() < inebriety_limit()) return false;
    if (my_familiar() != $familiar[Stooper]) return false;
    if (!is_wearing_outfit("maxorgan")) return false;
    return true;
}

boolean don_eod_process() {
    don_post_run_sync_date();
    if (get_property("don_post_run_stage") == "done") {
        don_log("Post-run already completed for " + today_to_string());
        return true;
    }
    int checkpoint = get_property("don_post_run_eod_step").to_int();
    // The nightcap and later Left-Hand Man steps change the state used by
    // the gate. Require original readiness only before the first EOD action.
    if (checkpoint == 0 && !don_post_run_eod_ready()) {
        don_warning("EOD gate: need maxorgan, Stooper, full stomach/spleen/liver and <=2 adventures.");
        don_post_run_status();
        return false;
    }
    if (checkpoint < 1) {
        if ($familiar[cooler yeti].experience >= 400 && !don_get_cool()) return false;
        set_property("don_post_run_eod_step", "1");
    }
    if (checkpoint < 2) {
        // getCool() equips maxo and may change the current familiar.
        if (!outfit("maxorgan")) {
            don_error("Could not restore maxorgan before nightcap.");
            return false;
        }
        if (my_familiar() != $familiar[Stooper] &&
            !use_familiar($familiar[Stooper])) {
            don_error("Could not restore Stooper before nightcap.");
            return false;
        }
        if (!don_nightcap()) return false;
        set_property("don_post_run_eod_step", "2");
    }
    if (checkpoint < 3) {
        familiar lefty = $familiar[Left-Hand Man];
        if (!have_familiar(lefty) || !use_familiar(lefty)) {
            don_warning("Left-Hand Man unavailable. Retry EOD later.");
            return false;
        }
        set_property("don_post_run_eod_step", "3");
    }
    if (checkpoint < 4) {
        if (!cli_execute("genie effect offhand remarkable")) return false;
        set_property("don_post_run_eod_step", "4");
    }
    if (checkpoint < 5) {
        if (!cli_execute("max adv")) return false;
        set_property("don_post_run_eod_step", "5");
    }
    if (checkpoint < 6) {
        // No auto-answer to Philter's uncategorized-item prompt is assumed.
        if (get_property("don_post_run_philter").to_boolean()) {
            if (!cli_execute("philter")) {
                don_error("Philter failed or cancelled.");
                return false;
            }
        } else don_log("Philter skipped: don_post_run_philter=false.");
        set_property("don_post_run_eod_step", "6");
    }
    if (checkpoint < 7) {
        if (!cli_execute("mall-manager reprice")) return false;
        set_property("don_post_run_eod_step", "7");
    }
    if (checkpoint < 8) {
        if (!cli_execute("call buy-script.js")) return false;
        set_property("don_post_run_eod_step", "8");
    }
    if (checkpoint < 9) {
        int have_tickets = don_owned_amount($item[raffle ticket]);
        int need_tickets = max(0, 111 - have_tickets);
        if (need_tickets > 0 && !cli_execute("raffle " + need_tickets)) return false;
        set_property("don_post_run_eod_step", "9");
    }
    don_post_run_track("postrun_eod_complete");
    set_property("don_post_run_stage", "done");
    don_good("Don post-run EOD complete.");
    return true;
}

// Keep the requested spelling and offer the corrected spelling as well.
boolean eod_proccess() { return don_eod_process(); }
boolean eod_process() { return don_eod_process(); }

boolean don_post_run_from(string entry_stage) {
    don_post_run_sync_date();
    if (entry_stage == "nightcap") return don_nightcap();
    if (entry_stage == "eod") return eod_proccess();
    if (entry_stage == "cool") return don_get_cool() && eod_proccess();
    if (entry_stage == "yeti") {
        if (!don_post_run_yeti_stage()) return false;
    } else if (entry_stage == "" || entry_stage == "start") {
        if (get_property("don_post_run_stage") == "done") return true;
        if (get_property("don_post_run_stage") == "new") {
            if (!don_post_run_prepare()) return false;
        }
        if (get_property("don_post_run_stage") == "prepared") {
            if (!don_post_run_yeti_stage()) return false;
        }
    } else {
        don_warning("Unknown post-run stage: " + entry_stage);
        return false;
    }

    if (!don_post_run_combo_stage()) return false;
    // Reapply the EOD gate setup after the Yeti and farming stages.
    if (!outfit("maxorgan")) return false;
    if (have_familiar($familiar[Stooper]) &&
        !use_familiar($familiar[Stooper])) return false;
    if (!don_post_run_eod_ready()) {
        don_warning("WaterSheep returned; EOD requirements not met. Resume later with don-post-run eod.");
        return false;
    }
    return eod_proccess();
}

void don_post_run() { don_post_run_from("start"); }

