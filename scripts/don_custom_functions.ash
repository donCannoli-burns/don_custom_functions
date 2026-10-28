script "don_custom_functions.ash";
import <don_master_lib.ash>;

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
    while (get_property("_sweatOutSomeBoozeUsed").to_int() < 3 &&
           get_property("sweat").to_int() >= 25 &&
           my_inebriety() > 0) {
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
    int count = total_amount($item[raffle ticket]);
    if (count > 0) {
        don_log("Already holding " + count + " raffle tickets.");
        return;
    }
    if (!cli_execute("raffle 111")) {
        don_error("Raffle command failed.");
        return;
    }
    count = total_amount($item[raffle ticket]);
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

void getCool() {
    outfit("maxo");
    refresh_status();
    if (!get_property("_communismUsed").to_boolean() &&
        my_inebriety() == inebriety_limit() - 1)
        stooperDis();

    familiar previous = my_familiar();
    familiar yeti = $familiar[cooler yeti];
    if (!have_familiar(yeti) || yeti.experience < 400) {
        don_warning("Cooler Yeti missing or below 400 XP.");
        return;
    }
    if (!use_familiar(yeti)) {
        don_error("Unable to equip Cooler Yeti.");
        return;
    }
    cli_execute("cast ode to booze");

    // This is the original scripted choice sequence. Only run by explicit call.
    buffer page = visit_url("main.php?talktoyeti=1", false, true);
    buffer_to_file(page, "_yeti_talk2.html");
    run_choice(2);
    run_choice(1);

    if (previous != $familiar[none]) use_familiar(previous);
    don_good("Yeti drink enhancement sequence submitted.");
}

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

void augmentBreakfast() {
    if (get_property("breakfastCompleted").to_boolean()) {
        don_log("Breakfast already completed.");
        return;
    }
    if (!cli_execute("breakfast")) don_warning("Native breakfast command failed.");
    raffle();
    if (!get_property("_aprilShower").to_boolean())
        cli_execute("shower ice");
    if (get_property("bankedKarma").to_int() > 2000 &&
        available_amount($item[The Big Book of Every Skill]) > 0)
        use(1, $item[The Big Book of Every Skill]);
    don_mayam();
    if (!cli_execute("call don_praccess.ash"))
        don_warning("Optional don_praccess.ash failed or is not installed.");
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

void nightcap() {
    if (total_amount(night_cap) == 0) buy(1, night_cap, 175000);
    if (total_amount(night_cap) == 0) {
        don_error("Nightcap unavailable within 175000 meat limit.");
        return;
    }
    if (!overdrink(1, night_cap))
        don_error("Could not drink " + night_cap);
}

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
