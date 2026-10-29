script "don_post_run_smoke.ash";
import <don_custom_functions.ash>;

// No mutating function invocation. Compile and validate read-only helpers.
void main() {
    if (don_nightcap_configured_id("don_defaultNightcap") <= 0)
        abort("Nightcap ID fallback invalid.");
    if (don_nightcap_price_limit() < 1)
        abort("Nightcap price limit invalid.");
    if (get_property("don_post_run_date") == "impossible_test_date" &&
        get_property("don_post_run_stage") == "unknown")
        print("Saved state is not valid yet.");
    don_good("Post-run smoke PASS: helpers callable, no purchases or gameplay.");
}
