script "relay_agent_web.ash";
import <agent_web_ash.ash>;
void main() {
    string requested = form_field("script");
    if (requested == "") requested = "don_custom_functions";
    if (agent_web_path(requested) == "") {
        write("<!doctype html><html><body>Unknown Agent Web script.</body></html>");
        return;
    }
    buffer page = agent_web_html(requested);
    if (page.length() == 0) {
        write("<!doctype html><html><body>Agent Web data missing; run git sync.</body></html>");
        return;
    }
    write(page.to_string());
}
