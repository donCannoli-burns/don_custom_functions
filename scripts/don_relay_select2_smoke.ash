script "don_relay_select2_smoke.ash";
import <don_relay_select2.ash>;

// Pure string transformation test; no network, choice, or state mutations.
void main() {
    string src = '<html><head></head><body><select id="one"><option>A</option></select></body></html>';
    string tagged = don_relay_tag_searchable_selects(src);
    if (!contains_text(tagged, 'class="don-searchable-select"'))
        abort("Missing select marker.");
    if (tagged != don_relay_tag_searchable_selects(tagged))
        abort("Select tagging is not idempotent.");

    string existing = '<select class="already" id="two"></select>';
    string result = don_relay_tag_searchable_selects(existing);
    if (!contains_text(result, 'already don-searchable-select'))
        abort("Existing class was not preserved.");

    print("DON select2 relay marker smoke PASS (no JS loaded).");
}
