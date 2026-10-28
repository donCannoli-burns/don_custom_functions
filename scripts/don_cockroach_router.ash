script "don_cockroach_router.ash";

/*
  PirateRealm cockroach target setup (opt-in).
  Based on the staging strategy in Garbo's CockroachSetup/CockroachFinish,
  adapted for the player's existing lowerstats.ash workflow.
  This is not Garbo code and does not require Garbo.
  Game actions occur ONLY when this script is called, never on import.
*/

int don_cr_step() {
    string raw = get_property("_questPirateRealm");
    if (raw == "" || raw == "unstarted") return -1;
    if (raw == "started") return 0;
    if (raw == "finished") return 100;
    if (starts_with(raw, "step")) return substring(raw, 4).to_int();
    return -2;
}

boolean don_cr_choose(int option) {
    if (!handling_choice()) {
        print("PirateRealm: expected an active choice before option " + option, "red");
        return false;
    }
    string[int] options = available_choice_options();
    if (options[option] == "") {
        print("PirateRealm: option " + option + " unavailable in choice " + last_choice(), "red");
        return false;
    }
    run_choice(option);
    return true;
}

int don_cr_crew() {
    int best = 1;
    int score = -1;
    int i = 1;
    while (i <= 3) {
        string crew = get_property("_pirateRealmCrewmate" + i);
        int candidate = 0;
        if (contains_text(crew, "Coxswain")) candidate = 40;
        else if (contains_text(crew, "Harquebusier")) candidate = 30;
        if (contains_text(crew, "Wide-Eyed")) candidate += 5;
        else if (contains_text(crew, "Gluttonous")) candidate += 4;
        if (candidate > score) {
            best = i;
            score = candidate;
        }
        i += 1;
    }
    return best;
}

boolean don_cr_stats() {
    if (!have_equipped($item[PirateRealm eyepatch])) {
        print("PirateRealm: eyepatch was removed; stopping.", "red");
        return false;
    }
    // External stat-delving implementation; not imported into the library.
    // Its <=100 check matches the actual PirateRealm rule.
    if (!cli_execute("call lowerstats.ash")) {
        print("PirateRealm: lowerstats.ash failed.", "red");
        return false;
    }
    foreach st in $stats[] {
        if (my_buffedstat(st) > 100) {
            print("PirateRealm: " + st + "=" + my_buffedstat(st) + " (>100). Use modtrace before retry.", "red");
            return false;
        }
    }
    return true;
}

boolean don_cr_windicle() {
    item windy = $item[windicle];
    if (item_amount(windy) > 0) return true;
    if (closet_amount(windy) > 0 && !take_closet(1, windy))
        return false;
    if (item_amount(windy) > 0) return true;
    int cap = 3 * get_property("valueOfAdventure").to_int();
    int price = mall_price(windy);
    if (cap <= 0 || price <= 0 || price > cap) return false;
    return buy(1, windy, cap) > 0;
}

boolean don_cr_start() {
    visit_url("place.php?whichplace=realm_pirate&action=pr_port");
    if (!don_cr_choose(1)) return false;
    if (!don_cr_choose(don_cr_crew())) return false;
    if (!don_cr_choose(4)) {
        print("PirateRealm: anemometer must be available.", "red");
        return false;
    }
    if (!don_cr_choose(get_property("pirateRealmUnlockedClipper").to_boolean() ? 4 : 3))
        return false;
    return don_cr_choose(1);
}

void don_cr_set_route_choices() {
    set_property("choiceAdventure1352", "1");
    set_property("choiceAdventure1365", "1");
    set_property("choiceAdventure1364", "2");
    set_property("choiceAdventure1361", "1");
    set_property("choiceAdventure1357",
                 get_property("_pirateRealmGold").to_int() >= 50 ? "3" : "4");
    set_property("choiceAdventure1360", "6");
    set_property("choiceAdventure1356", "3");
    set_property("choiceAdventure1362",
                 get_property("_pirateRealmShipSpeed").to_int() -
                 get_property("_pirateRealmSailingTurns").to_int() >= 2 ? "2" : "1");
    set_property("choiceAdventure1363", "2");
    set_property("choiceAdventure1359", "1");
    set_property("choiceAdventure1358", "1");
    set_property("choiceAdventure1367", "2"); // Avoid unverified glue-dependent option
    set_property("choiceAdventure1355", "1");
    set_property("choiceAdventure1368", "1");
    set_property("choiceAdventure1385", "1");
    set_property("choiceAdventure1353", "5");
}

boolean don_cr_route() {
    if (get_property("_lastPirateRealmIsland") == "Trash Island") return true;
    if (my_inebriety() > inebriety_limit()) {
        print("PirateRealm: overdrunk. Refusing route.", "red");
        return false;
    }
    int step = don_cr_step();
    if (step == -2 || step >= 100) {
        print("PirateRealm: unsupported quest state " + get_property("_questPirateRealm"), "red");
        return false;
    }
    if (step < 1 && my_adventures() < 40) {
        print("PirateRealm: need at least 40 adventures to start (no automatic eating/drinking).", "red");
        return false;
    }
    if (step <= 0 &&
        !get_property("prAlways").to_boolean() &&
        !get_property("_prToday").to_boolean()) {
        print("PirateRealm: no active daily access.", "red");
        return false;
    }
    if (step <= 0 && !get_property("pirateRealmUnlockedAnemometer").to_boolean()) {
        print("PirateRealm: anemometer not unlocked.", "red");
        return false;
    }
    if (handling_choice()) {
        print("PirateRealm: another choice is already open; finish it manually.", "red");
        return false;
    }

    if (item_amount($item[PirateRealm eyepatch]) == 0 &&
        !have_equipped($item[PirateRealm eyepatch]))
        visit_url("place.php?whichplace=realm_pirate&action=pr_port");
    if (item_amount($item[PirateRealm eyepatch]) == 0 &&
        !have_equipped($item[PirateRealm eyepatch])) {
        print("PirateRealm: unable to obtain eyepatch.", "red");
        return false;
    }
    item priorAcc1 = equipped_item($slot[acc1]);
    if (!equip($slot[acc1], $item[PirateRealm eyepatch])) {
        print("PirateRealm: failed to equip eyepatch.", "red");
        return false;
    }

    // Saving all affected choices makes the router less invasive.
    int[int] choices;
    choices[0] = 1352;
    choices[1] = 1365;
    choices[2] = 1364;
    choices[3] = 1361;
    choices[4] = 1357;
    choices[5] = 1360;
    choices[6] = 1356;
    choices[7] = 1362;
    choices[8] = 1363;
    choices[9] = 1359;
    choices[10] = 1358;
    choices[11] = 1367;
    choices[12] = 1355;
    choices[13] = 1368;
    choices[14] = 1385;
    choices[15] = 1353;
    string[int] originals;
    foreach index, choice in choices
        originals[choice] = get_property("choiceAdventure" + choice);

    boolean success = false;
    boolean running = true;
    int spentAtStart = my_adventures();
    int attempts = 0;
    int stageAttempts = 0;
    int oldStep = -999;
    string seaMacro = "if hasskill sing along;skill sing along;endif;if hasskill saucegeyser;skill saucegeyser;endif;attack with your weapon;repeat";
    string windMacro = "if hascombatitem windicle;use windicle;endif;" + seaMacro;

    while (running && attempts < 30 &&
           my_adventures() > 0 &&
           spentAtStart - my_adventures() < 30) {
        if (get_property("_lastPirateRealmIsland") == "Trash Island") {
            success = true;
            break;
        }
        step = don_cr_step();
        // Unstarted voyage enters the same port-setup path as "started".
        if (step == -1) step = 0;
        if (step < 0 || step >= 7) {
            running = false;
            break;
        }
        if (step != oldStep) {
            stageAttempts = 0;
            oldStep = step;
        }
        stageAttempts += 1;
        attempts += 1;
        don_cr_set_route_choices();
        print("PirateRealm step " + step + ", attempt " + stageAttempts, "teal");

        if (step == 0) {
            running = stageAttempts <= 1 && don_cr_start();
        } else {
            if (!don_cr_stats()) {
                running = false;
            } else if (step == 1 && stageAttempts <= 2) {
                adv1($location[Sailing the PirateRealm Seas], -1, seaMacro);
            } else if (step == 2 && stageAttempts <= 8) {
                adv1($location[Sailing the PirateRealm Seas], -1, seaMacro);
            } else if (step == 3 && stageAttempts <= 2) {
                adv1($location[Sailing the PirateRealm Seas], -1, seaMacro);
            } else if (step == 4 && stageAttempts <= 8) {
                location island = to_location(get_property("_lastPirateRealmIsland"));
                if (island == $location[none]) {
                    print("PirateRealm: no first island location is known.", "red");
                    running = false;
                } else {
                    boolean useWind = !get_property("_pirateRealmWindicleUsed").to_boolean()
                        && get_property("_pirateRealmIslandMonstersDefeated").to_int() <= 1
                        && don_cr_windicle();
                    adv1(island, -1, useWind ? windMacro : seaMacro);
                }
            } else if (step == 5 && stageAttempts <= 2) {
                location island = to_location(get_property("_lastPirateRealmIsland"));
                if (island == $location[none]) running = false;
                else adv1(island, -1, seaMacro);
            } else if (step == 6 && stageAttempts <= 2) {
                adv1($location[Sailing the PirateRealm Seas], -1, seaMacro);
            } else {
                print("PirateRealm: per-stage attempt limit reached.", "red");
                running = false;
            }
        }
    }
    success = success || get_property("_lastPirateRealmIsland") == "Trash Island";

    foreach choice, original in originals
        set_property("choiceAdventure" + choice, original);
    if (priorAcc1 != $item[PirateRealm eyepatch] &&
        !equip($slot[acc1], priorAcc1))
        print("PirateRealm: could not restore prior acc1; check equipment.", "red");

    print("PirateRealm result: " + (success ? "Trash Island selected" : "incomplete / stopped"), success ? "green" : "red");
    return success;
}

void main() {
    set_property("_don_cockroachRouteResult", "failed");
    if (!cli_execute("verify lowerstats.ash")) {
        print("PirateRealm: required lowerstats.ash is missing or fails verification.", "red");
        return;
    }
    if (don_cr_route()) set_property("_don_cockroachRouteResult", "success");
}
