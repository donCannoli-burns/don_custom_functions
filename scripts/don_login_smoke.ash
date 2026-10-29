script "don_login_smoke.ash";
import <don_custom_functions.ash>;

// Read-only logic checks: never run login stages in this script.
void main() {
    if (don_login_second_allowed(0) || !don_login_second_allowed(1))
        abort("Daily ascension gate failed.");
    if (!don_login_default_true("don_login_smoke_unset_test_key"))
        abort("Default-on preference rule failed.");
    if (don_login_default_true("don_login_bone_farm") &&
        get_property("don_login_bone_farm") == "false")
        abort("Explicit opt-out was ignored.");
    don_good("don_login smoke PASS: no gameplay or aliases executed.");
}
