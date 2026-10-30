script "don_iotm_smoke.ash";
import <don_iotm_catalog.ash>;

/*
 * Read-only static/metadata smoke test. No choices or preferences are changed.
 */
void main() {
    don_iotm_capability[int] entries = don_iotm_catalog();
    if (count(entries) != 10) abort("Unexpected IotM catalog size.");

    don_iotm_capability cooler = don_iotm_find("cooler-yeti-adventures");
    if (cooler.choice_id != 1560 || cooler.option != 2 ||
        cooler.familiar_experience_cost != 400)
        abort("Cooler Yeti choice metadata mismatch.");

    don_iotm_capability missing = don_iotm_find("not-a-real-capability");
    if (missing.key != "") abort("Unknown IotM key did not fail closed.");

    don_iotm_capability train = don_iotm_find("model-train-set");
    if (train.choice_id != 1485 || train.option != 1)
        abort("Model train set metadata mismatch.");

    print("DON IotM catalog smoke PASS: 10 entries, stable choices, unknown-key rejection.");
}
