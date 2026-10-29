script "don_login.ash";
import <don_custom_functions.ash>;

// Explicit entry point; no alias installation on import or verify.
void main(string arguments) {
    if (arguments == "help") { don_login_help(); return; }
    if (arguments == "status") { don_login_status(); return; }
    if (arguments == "install") {
        if (!don_login_install_aliases()) don_warning("Some aliases were not installed.");
        return;
    }
    if (arguments == "" || arguments == "start" || arguments == "breakfast_1") {
        if (!don_login_breakfast_1()) don_warning("breakfast_1 paused; see don-login status.");
        return;
    }
    if (arguments == "breakfast_2" || arguments == "postascend") {
        if (!don_login_breakfast_2()) don_warning("breakfast_2 rejected or stopped.");
        return;
    }
    if (arguments == "eod") {
        if (!don_login_eod()) don_warning("EOD not ready or stopped.");
        return;
    }
    don_warning("Unknown don-login argument: " + arguments);
    don_login_help();
}
