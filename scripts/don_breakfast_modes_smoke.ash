script "don_breakfast_modes_smoke.ash";
import <don_custom_functions.ash>;

// Pure checks only: no preferences are written and no gameplay CLI is called.
void main() {
    if (!don_breakfast_is_pastamancer($class[Pastamancer]))
        abort("Pastamancer eligibility check failed");
    if (don_breakfast_is_pastamancer($class[Seal Clubber]))
        abort("Non-Pastamancer was allowed into cowo");
    if (don_breakfast_combo_turns(0) != 0 ||
        don_breakfast_combo_turns(14) != 0 ||
        don_breakfast_combo_turns(15) != 0 ||
        don_breakfast_combo_turns(16) != 1 ||
        don_breakfast_combo_turns(100) != 85)
        abort("15-adventure combo reserve failed");
    if (don_breakfast_mode_preference("cowo") != "donBreakfastCowo" ||
        don_breakfast_mode_preference("nobarfcombo") != "donBreakfastNobarfCombo" ||
        don_breakfast_mode_preference("barf") != "donBreakfastBarf")
        abort("Breakfast mode preference mapping failed");
    don_good("Don Breakfast mode pure smoke PASS; no gameplay or preference writes.");
}
