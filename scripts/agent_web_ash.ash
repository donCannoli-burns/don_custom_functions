script "agent_web_ash.ash";
// Read-only Agent Web HTML loader; an HTML document cannot be imported as ASH.
string agent_web_path(string name) {
    if (name != "don_custom_functions" && name != "don_master_lib") return "";
    return "agentWeb/" + name + "_micro_agent.html";
}
buffer agent_web_html(string name) {
    string html_file_name = agent_web_path(name);
    if (html_file_name == "") {
        buffer empty;
        return empty;
    }
    return file_to_buffer(html_file_name);
}
boolean agent_web_ready(string name) {
    buffer document = agent_web_html(name);
    return document.length() > 0;
}
void agent_web_about() {
    print("Agent Web v0.1: static read-only ASH source map. Open relay_agent_web.ash in the relay browser.");
}
