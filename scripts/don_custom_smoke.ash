script "don_custom_smoke.ash";
import <don_custom_functions.ash>;

// Read-only compatibility and dependency check. No adventures, purchases,
// equipment changes, preferences writes, or relay choice submissions.
void main() {
    print("DON Custom Functions — dependency check");
    if (DON_MASTER_VERSION == "") abort("don_master_lib.ash version missing.");
    print("don_master_lib.ash: " + DON_MASTER_VERSION);
    if (!don_master_smoke()) abort("don_master_lib.ash smoke test failed.");
    if (day_of_week() < 0 || day_of_week() > 6)
        abort("day_of_week() mapping failed.");
    if (don_list_add("one", "two") != "one, two")
        abort("don_master_lib helper check failed.");
    int[item] no_items;
    if (ListItems(no_items, 1) != "<EMPTY>")
        abort("ListItems() empty-case check failed.");
    don_good("don_custom_functions.ash import and smoke checks PASS.");
}
