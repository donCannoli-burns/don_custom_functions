// Compatibility command for Prusias-kol/pUpdates, now provided by DON ASH lib.
// Original pUpdates: https://github.com/Prusias-kol/pUpdates
// Experimental; use at your own risk.
script "pUpdates";
import <don_updates_lib.ash>;

void main(string input) {
    string arg = trim(input);
    if (arg == "" || arg == "help") {
        print("pUpdates init <scriptname> | add <scriptname> <note> | check <scriptname>");
        print("Names must contain only letters, numbers, underscore or dash (up to 64 chars).");
        return;
    }

    string[int] tokens = split_string(arg, "\\s+");
    if (count(tokens) < 2 || !don_updates_valid_name(tokens[1])) {
        print("pUpdates: missing or invalid script name. Run pUpdates help.", "red");
        return;
    }
    string action = tokens[0];
    string name = tokens[1];
    if (action == "check") {
        if (count(tokens) != 2) {
            print("Usage: pUpdates check <scriptname>", "red");
            return;
        }
        don_updates_check(name);
        return;
    }
    if (action == "init") {
        if (count(tokens) != 2) {
            print("Usage: pUpdates init <scriptname>", "red");
            return;
        }
        don_updates_init(name);
        return;
    }
    if (action == "add") {
        if (count(tokens) < 3) {
            print("Usage: pUpdates add <scriptname> <note>", "red");
            return;
        }
        string note = "";
        for i from 2 to count(tokens) - 1 {
            if (note != "") note += " ";
            note += tokens[i];
        }
        don_updates_add(name, note);
        return;
    }
    print("pUpdates: unknown command. Run pUpdates help.", "red");
}
