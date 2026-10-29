script "don_post_run.ash";
import <don_custom_functions.ash>;

// First explicit invocation registers durable aliases. Never runs on import.
boolean don_post_run_install_aliases() {
    boolean ok = cli_execute("alias don-post-run => call don_post_run.ash %%");
    if (!cli_execute("alias yeti-adv => call don_post_run.ash yeti")) ok = false;
    if (!cli_execute("alias get-cool => call don_post_run.ash cool")) ok = false;
    if (!cli_execute("alias eod-process => call don_post_run.ash eod")) ok = false;
    if (!cli_execute("alias don-nightcap => call don_post_run.ash nightcap")) ok = false;
    return ok;
}

void main(string arguments) {
    if (arguments == "help" || arguments == "status") {
        if (arguments == "status") don_post_run_status();
        else {
            print("don_post_run.ash: install | status | start | yeti | cool | eod | nightcap");
            print("Start is the default. The first start/install call registers don-post-run and stage aliases.");
            print("Read-only tests: verify don_post_run.ash; call don_post_run_smoke.ash");
        }
        return;
    }
    if (!don_post_run_install_aliases()) {
        don_warning("Could not install every post-run alias. Direct call still works.");
    }
    if (arguments == "install") return;
    if (arguments == "") arguments = "start";
    if (!don_post_run_from(arguments)) don_warning("Post-run stopped or is not yet ready for the next stage.");
}
