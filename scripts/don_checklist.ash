// Native DON checklist entrypoint. Read-only unless future explicit features are added.
script "don_checklist";
import <don_checklist_lib.ash>;
void main(string arg) { don_checklist_run(arg); }
