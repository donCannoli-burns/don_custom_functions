script "donBreakfast.ash";
import <don_custom_functions.ash>;

// CLI: donBreakfast help | status | run | cowo on | nobarfcombo on
void main(string arguments) {
    if (arguments == "help" || arguments == "status") {
        don_breakfast_help();
        return;
    }
    if (arguments == "" || arguments == "run") {
        augmentBreakfast();
        return;
    }

    string[int] tokens = split_string(arguments, " ");
    if (count(tokens) != 2) {
        don_breakfast_help();
        return;
    }
    boolean enabled = tokens[1] == "on" || tokens[1] == "true";
    boolean disabled = tokens[1] == "off" || tokens[1] == "false";
    if (!enabled && !disabled) {
        don_warning("Expected on/off or true/false; no settings changed.");
        return;
    }
    if (don_breakfast_set_mode(tokens[0], enabled)) {
        don_log("Saved breakfast mode " + tokens[0] + "=" + enabled);
        don_breakfast_help();
    }
}
