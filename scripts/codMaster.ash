script "codMaster.ash";
import <don_codmaster_lib.ash>;

// Compatibility CLI. Mutations run only in explicitly selected commands.
void codmaster_help() {
    print("codMaster: Eternity Codpiece preset manager (absorbed version)", "blue");
    print("codMaster help                 - commands; no state changes");
    print("codMaster list                 - registered save names (read-only)");
    print("codMaster show <name>          - read/print saved gem config (read-only)");
    print("codMaster set                  - prompt for 5 item IDs; preferences only");
    print("codMaster save <name>          - persist the 5 preference slots");
    print("codMaster load <name>          - load saved values into preferences only");
    print("codMaster equip <name>         - read/equip named preset (live equipment mutation)");
    print("codMaster snapshot <name>      - capture currently mounted gems to a save");
    print("codMaster empty                - clear codpiece slots (live equipment mutation)");
    print("Save savefile: data/cod_master/saves/<name>.txt (unchanged)");
    print("Example: codMaster show spell ; codMaster equip spell");
}

void codmaster_list() {
    string registry = get_property("cod_master_validSaves");
    if (registry == "") {
        print("codMaster: registry empty. Old files can still be read by name, e.g. codMaster show spell.");
        return;
    }
    print("codMaster known presets (historical cod_master_validSaves preference):", "blue");
    string [int] names = split_string(registry, ",");
    foreach index, name in names {
        if (name != "") print("- " + name);
    }
}

boolean codmaster_allow_overwrite(string name) {
    string [string] current;
    string savefile = don_cod_save_path(name);
    if (savefile == "") return false;
    // Ask BEFORE any write. Historical codMaster asked after overwriting.
    if (file_to_map(savefile, current))
        return user_confirm("Overwrite existing codMaster preset '" + name + "'?");
    return true;
}

void codmaster_interactive_set() {
    string [string] choices;
    for (int i = 1; i <= 5; i = i + 1) {
        string choice = user_prompt("Gem item number for Eternity Codpiece slot " + i + " (0 = empty):");
        choices[don_cod_slot_key(i)] = choice;
    }
    if (!don_cod_valid_config(choices))
        abort("codMaster: invalid item IDs; no slot preferences changed.");
    for (int i = 1; i <= 5; i = i + 1)
        set_property(don_cod_slot_key(i), choices[don_cod_slot_key(i)]);
    print("codMaster preferences set. Use 'codMaster save <name>' to persist.", "green");
}

void main(string... args) {
    string mode = count(args) > 0 ? to_lower_case(args[0]) : "help";
    if (mode == "help" || mode == "") { codmaster_help(); return; }
    if (mode == "other") {
        print("codMaster empty - clears currently mounted gems.");
        return;
    }
    if (mode == "list" || mode == "listsaves") { codmaster_list(); return; }
    if (mode == "set") { codmaster_interactive_set(); return; }
    if (mode == "empty") {
        if (!don_cod_clear()) abort("codMaster: could not clear all five slots.");
        print("codMaster: all five slots cleared.", "green");
        return;
    }
    if (count(args) != 2)
        abort("Usage: codMaster [show|save|load|equip|snapshot] <preset>");
    string name = args[1];
    if (!don_cod_valid_name(name))
        abort("codMaster: invalid preset name; use 1-64 letters, numbers, _ or - only.");
    if (mode == "show" || mode == "status") {
        don_cod_print_saved(name);
        return;
    }
    if (mode == "save") {
        if (!codmaster_allow_overwrite(name)) abort("codMaster: save cancelled.");
        if (!don_cod_save_preferences(name, true))
            abort("codMaster: save failed; confirm all five slot preferences contain valid item IDs.");
        print("codMaster: saved configuration " + name + " at " + don_cod_save_path(name), "green");
        return;
    }
    if (mode == "snapshot" || mode == "capture") {
        if (!codmaster_allow_overwrite(name)) abort("codMaster: capture cancelled.");
        if (!don_cod_save_equipped(name, true))
            abort("codMaster: could not capture/read back mounted gems.");
        print("codMaster: captured mounted Codpiece gems as " + name, "green");
        return;
    }
    if (mode == "load") {
        if (!don_cod_load_preferences(name))
            abort("codMaster: cannot read valid preset " + name + "; no preferences changed.");
        print("codMaster: loaded preferences from " + name + "; equipment unchanged.", "green");
        return;
    }
    if (mode == "equip") {
        if (!don_cod_equip_saved(name))
            abort("codMaster: equip failed; inspect slots before retrying (partial changes possible).");
        print("codMaster: equipped and verified preset " + name, "green");
        return;
    }
    abort("Unknown codMaster command. Use 'codMaster help'.");
}
