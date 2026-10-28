script "agent_web_smoke.ash";
import <don_custom_functions.ash>;
void main() {
    if (!agent_web_ready("don_custom_functions")) abort("Missing custom function micro-agent HTML");
    if (!agent_web_ready("don_master_lib")) abort("Missing master function micro-agent HTML");
    if (agent_web_path("../unsafe") != "") abort("Agent Web path allowlist failed");
    print("Agent Web PASS: both static HTML maps readable; no gameplay actions performed.");
}
