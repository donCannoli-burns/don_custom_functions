// Hardened pChecklist library, based on Prusias-kol/pChecklist (MIT, 2022).
// Original project: https://github.com/Prusias-kol/pChecklist
// No gameplay mutation on import or when checking ownership.
script "don_checklist_lib";
import <don_master_lib.ash>;

record don_checklist_entry {
    int first;
    int last;
    int[int] list;
};

boolean don_checklist_valid_target(string target) {
    if (length(target) < 1 || length(target) > 64) return false;
    matcher m = create_matcher("^[A-Za-z0-9_-]+$", target);
    return find(m);
}

void don_checklist_print_item(int item_id) {
    if (item_id <= 0) return;
    item it = to_item(item_id);
    if (it == $item[none]) {
        print("Unknown item ID: " + item_id, "orange");
        return;
    }
    // Includes inventory, closet, display, equipment, mall shop, storage and
    // equipment attached to owned familiars, but not clan stash.
    int amount = don_true_owned_amount(it, false);
    if (amount > 0) print("O " + it + " [#" + item_id + "] owned (" + amount + ")", "green");
    else print("X " + it + " [#" + item_id + "] missing", "red");
}

boolean don_checklist_load_public(don_checklist_entry[string] result) {
    if (file_to_map("checklistData.txt", result) && count(result) > 0) return true;
    clear(result);
    return file_to_map("data/checklistData.txt", result) && count(result) > 0;
}

boolean don_checklist_load_personal(don_checklist_entry[string] result) {
    if (file_to_map("personalChecklistData.txt", result)) return true;
    clear(result);
    return file_to_map("data/personalChecklistData.txt", result);
}

void don_checklist_help() {
    print("Usage: pChecklist help | <target>");
    print("Targets are stored in checklistData.txt; personal targets in personalChecklistData.txt.");
    print("Existing custom data is read, never overwritten by this checker.");
    don_checklist_entry[string] official;
    don_checklist_entry[string] personal;
    don_checklist_load_public(official);
    don_checklist_load_personal(personal);
    print("Public checklists:");
    foreach target in official print("  " + target);
    print("Personal checklists:");
    foreach target in personal print("  " + target);
}

void don_checklist_run(string raw_target) {
    string target = trim(raw_target);
    if (target == "" || target == "help" || target == "generateCustomList") {
        don_checklist_help();
        return;
    }
    if (!don_checklist_valid_target(target)) {
        print("pChecklist: invalid target (1-64 letters/numbers/_/-).", "red");
        return;
    }
    don_checklist_entry[string] official;
    don_checklist_entry[string] personal;
    don_checklist_load_public(official);
    don_checklist_load_personal(personal);
    don_checklist_entry chosen;
    if (official contains target) chosen = official[target];
    else if (personal contains target) chosen = personal[target];
    else {
        print("pChecklist: no such target: " + target, "red");
        return;
    }

    boolean[int] seen;
    if (chosen.first != -1) {
        if (chosen.first <= 0 || chosen.last < chosen.first || chosen.last - chosen.first > 2000) {
            print("pChecklist: invalid or excessive item-ID range; no items checked.", "red");
            return;
        }
        for id from chosen.first to chosen.last {
            if (!(seen contains id)) {
                seen[id] = true;
                don_checklist_print_item(id);
            }
        }
    } else {
        if (count(chosen.list) > 2000) {
            print("pChecklist: list too large (> 2000); refusing to print.", "red");
            return;
        }
        foreach position, id in chosen.list {
            if (!(seen contains id)) {
                seen[id] = true;
                don_checklist_print_item(id);
            }
        }
    }
}
