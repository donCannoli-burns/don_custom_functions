# Agent Web 0.1 — AA/BB/CC/DD test

This is a **read-only static source map**. It does not execute mapped functions, invoke LLMs, or produce numeric embeddings. KoLmafia ASH cannot import an HTML file as source: use `import <agent_web_ash.ash>;` and `agent_web_html("don_custom_functions")` instead.

## AA — nomenclature and threshold rule

An ASH function is an **agent node**; each script's nodes are an **agent ladder**. A directed static call is an **agent filament**. A cross-script connection is an **agent ladder rope**. `||` in this design is shorthand for `and/or argument`, NOT an overridden ASH operator.

Cross-ladder percentage = 100 × distinct *resolved directed call edges to another script* / all *resolved directed call edges from that script*. Import links are excluded. This gives a **static coupling proportion**, not runtime safety, performance, or a merge instruction. Below 25% = sparse; [25,35)% = agent-web-weak; [35,50)% = agent-web-medium; [50,75)% = agent-web-strong; [75,100]% = agent-web-review-for-merge. Inclusive lower bounds remove boundary gaps.

## BB — filament semantics

Format: `agent_filament_<state>_<position>_<capability>`.

States: `strong` (syntax-resolved), `weak` (inferred), `cob` (unresolved), `dead` (removed vs an earlier verified snapshot). Only strong is emitted now; no dead links can be proven without a prior baseline.

Positions: `anchor` (root/dependency), `frame` (structural call), `guy` (stabilizer), `attachment` (specialized connection). Version 0.1 emits strong/anchor/attachment_bond for explicit imported dependency; strong/frame/bridge_thread for cross-script calls; strong/frame/bearing_guy for same-script calls.

Reserved anchor capabilities: attachment_bond, filament_bundle, convergent_junction, combination-of-two. Frame: bleeding_edge, bridge_thread, bearing_guy, combination-of-two. Guy: load_sharing, redundant_positive, redundant_negative, absorption_impact, combination-of-two. Attachment: anchor_junction_x, anchor_junction_y, anchor_junction_z, combination-of-two. Dynamic capabilities remain undefined and are NOT invented.

These labels classify **static evidence and structure**, not assurances of runtime correctness. Overloaded functions are distinct nodes; call resolution links to same-name overloads conservatively without ASH type checking. Calls to built-ins and dynamic CLI commands are intentionally not represented as graph edges.

## CC — source and index

`function_index11.N.1` maps to `data/agentWeb/agent_web_index/don_custom_functions.html5`.
`function_actual11.N.2` maps to `data/agentWeb/agent_web_actual/don_custom_functions.html5`.
For `don_master_lib`, the script number is 12 and the filename is `don_master_lib.html5`.

Each index has source path/line, signature, deterministic lexical keywords and hyperlinks. The actual page contains HTML-escaped original ASH source (view-only). The micro-agent merges these views with browser keyword filtering and cross-referenced function links. Function ordinal IDs shift if source is reordered; use names + paths + line ranges and regenerate after changes. Keywords are not vector embeddings.

## DD — KoLmafia integration

`don_custom_functions.ash` now imports `agent_web_ash.ash` (not HTML). `relay/relay_agent_web.ash` reads prebuilt `data/agentWeb/<script>_micro_agent.html`, serves a viewer, and accepts only the two known script names. This is read-only and has no action dispatch.

To rebuild outside KoLmafia, using Node.js with no npm dependencies:

```sh
node tools/build-agent-web.mjs --custom scripts/don_custom_functions.ash --master ../don-ash-lib/don-master-ash-lib/scripts/don_master_lib.ash --out data/agentWeb
```

Related research: [jsdom](https://github.com/jsdom/jsdom) for optional Node-side DOM testing; [EJS](https://github.com/mde/ejs) as an alternative template engine; [HTML template gist](https://gist.github.com/chrisvfritz/bc010e6ed25b802da7eb). None is required or bundled; do not enable arbitrary script execution in jsdom for untrusted content.

**Limitations:** lexical parser, no full ASH AST or type-aware call resolution, no current KoLmafia runtime validation here, no gameplay tests. Regenerated data should be reviewed before commit.
