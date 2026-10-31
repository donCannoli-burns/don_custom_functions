script "don_iotm.ash";
import <don_iotm_catalog.ash>;

/*
 * Read-only capability browser, not an IotM execution command.
 * Run: don_iotm list
 *      don_iotm cooler-yeti-adventures
 */
void main(string requested) {
    string key = replace_all(create_matcher("^\\s+|\\s+$", requested), "");
    don_iotm_capability[int] entries = don_iotm_catalog();

    if (key == "" || key == "help" || key == "list") {
        print("DON IotM capability index (read-only; no game actions)");
        foreach i, entry in entries {
            print(entry.key + " - " + entry.action);
        }
        print("Details: don_iotm <capability-key>");
        return;
    }

    don_iotm_capability entry = don_iotm_find(key);
    if (entry.key == "") {
        print("Unknown IotM capability: " + key, "red");
        return;
    }

    print("Capability: " + entry.key);
    print("Resource: " + entry.resource);
    print("Action: " + entry.action);
    print("Upstream reference: " + entry.upstream);
    if (entry.choice_id > 0) {
        print("Choice: " + entry.choice_id + "; option: " + entry.option);
    }
    if (entry.familiar_experience_cost > 0) {
        print("Familiar XP cost: " + entry.familiar_experience_cost);
    }
    if (entry.usage_property != "") print("Usage property: " + entry.usage_property);
    if (entry.mode_property != "") print("Mode property: " + entry.mode_property);
    print("Observed status: " + don_iotm_status(key));
    print("ADVISORY ONLY: no automation was executed.", "blue");
}
