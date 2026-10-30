script "don_train_plan_smoke.ash";
import <don_train_plan.ash>;

void main() {
    if (!don_train_layout_valid("1,2,3,4,5,6,7,8"))
        abort("A valid train layout failed.");

    if (don_train_layout_valid("1,1,3,4,5,6,7,8"))
        abort("Duplicated train piece accepted.");
    if (don_train_layout_valid("1,2,3,4,5,6,7,10"))
        abort("Invalid train piece 10 accepted.");
    if (don_train_layout_valid("1,2,3,4,5,6,7"))
        abort("Seven-station layout accepted.");
    if (don_train_layout_valid("1,2,3,4,5,6,7,08"))
        abort("Noncanonical train piece accepted.");
    if (don_train_layout_valid("1,2,3,4,5,6,7,21"))
        abort("Out-of-range train piece accepted.");

    print("DON train layout planner smoke PASS (no workshed changes).");
}
