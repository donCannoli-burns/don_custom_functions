"use strict";
const assert = require("node:assert/strict");
const {
  EVENT_HOOKS, dispatchPassiveEvent, validateEvidence
} = require("../.state-build/event-observer.js");
const {
  PASSIVE_EVENT_PROJECTS
} = require("../.state-build/event-projects.js");
const {
  eventJournalPath, parseEventJournal, appendEventDispatch
} = require("../.state-build/event-journal.js");
const {
  deriveEvidenceDeltas
} = require("../.state-build/event-reconciler.js");

const SCOPE = Object.freeze({
  playerId: "12345", rolloverDay: "20261030", totalAscensions: 32
});
const TIME = "2026-10-30T18:00:00Z";
function sample(changes = {}) {
  return {
    hook: "COMBAT_ROUND",
    requestId: "spade0001",
    observedAt: TIME,
    scopeBefore: SCOPE,
    scopeAfter: SCOPE,
    mafiaRevision: 29125,
    pathName: "None",
    meta: "meta-secret-pwd=ABC123",
    page: "<html>page-secret-token=XYZ</html>",
    facts: {
      currentRound: 0, activeFamiliar: "Cookbookbat",
      cookbookbatQuestLocation: "The Haunted Pantry",
      turnsThisAscension: 34, adventures: 75,
    },
    ...changes,
  };
}
function dispatch(changes = {}, projects = PASSIVE_EVENT_PROJECTS) {
  return dispatchPassiveEvent(sample(changes), projects);
}
let passed = 0;
function check(name, fn) {
  fn();
  passed++;
  console.log("PASS " + name);
}
function failure(name, fn, code) {
  check(name, () => assert.throws(fn, e => e.message === code));
}
function memIO(lease = true) {
  const files = new Map();
  let writes = 0;
  return {
    files,
    get writes() { return writes; },
    holdsExclusiveLease: () => lease,
    readText: path => files.get(path) || "",
    appendText: (path, data) => {
      writes++;
      files.set(path, (files.get(path) || "") + data);
      return true;
    },
  };
}

check("all seven Excavator event hooks represented", () => {
  assert.deepEqual([...EVENT_HOOKS].sort(), [
    "CHOICE", "CHOICE_VISIT", "COMBAT_ROUND", "CONSUME_REUSABLE",
    "DESC_ITEM", "PLACE", "PVP"
  ].sort());
});
check("cookbookbat and resource projects produce three bounded facts", () => {
  const report = dispatch();
  assert.equal(report.schema, "don-event-dispatch-v0.3");
  assert.equal(report.records.length, 3);
  assert.deepEqual(report.records.map(x => x.key), [
    "cookbookbat.quest_location",
    "resources.turns_this_ascension",
    "resources.adventures"
  ]);
  assert.equal(report.records[0].value, "The Haunted Pantry");
  assert.ok(report.records.every(x => x.interpretation === "local_evidence_only"));
  assert.ok(report.records.every(x => x.confidence === "observed"));
});
check("raw HTML, meta and passwords never included in output", () => {
  const text = JSON.stringify(dispatch());
  assert.doesNotMatch(text, /page-secret|meta-secret|token=XYZ|pwd=ABC123|<html>/);
});
check("choice visit emits choice availability, not selection result", () => {
  const report = dispatch({
    hook: "CHOICE_VISIT",
    facts: { choiceId: 1560 },
  });
  assert.deepEqual(report.records.map(r => r.key), ["choice.available_id"]);
  assert.equal(report.records[0].value, 1560);
});
check("choice completion does not automatically claim chosen option", () => {
  const report = dispatch({
    hook: "CHOICE", facts: { turnsThisAscension: 35, adventures: 74 }
  });
  assert.deepEqual(report.records.map(r => r.key), [
    "resources.turns_this_ascension", "resources.adventures"
  ]);
});
check("unhandled hooks produce zero facts, never guessed state", () => {
  for (const hook of ["CONSUME_REUSABLE", "DESC_ITEM", "PLACE"]) {
    assert.equal(dispatch({ hook }).records.length, 0);
  }
});
check("no cookbookbat fact while familiar is different", () => {
  const report = dispatch({
    facts: { ...sample().facts, activeFamiliar: "Mosquito" },
  });
  assert.equal(report.records.length, 2);
});
check("no cookbookbat fact during active combat", () => {
  assert.equal(dispatch({
    facts: { ...sample().facts, currentRound: 1 },
  }).records.length, 2);
});
check("no fake resource zeroes on missing facts", () => {
  assert.equal(dispatch({ facts: {} }).records.length, 0);
});
check("completed projects are skipped", () => {
  const list = [{ ...PASSIVE_EVENT_PROJECTS[0], completed: true }];
  assert.equal(dispatch({}, list).records.length, 0);
});
check("revision minimum gates projects", () => {
  const list = [{ ...PASSIVE_EVENT_PROJECTS[0], minRevision: 999999 }];
  assert.equal(dispatch({}, list).records.length, 0);
});
check("two crazy random summer projects are gated", () => {
  assert.equal(dispatch({ pathName: "Two Crazy Random Summer" }).records.length, 0);
});
check("explicit path admission allows a project", () => {
  const list = [{ ...PASSIVE_EVENT_PROJECTS[0],
    allowInTwoCrazyRandomSummer: true }];
  assert.equal(dispatch({ pathName: "Two Crazy Random Summer" }, list).records.length, 1);
});

failure("invalid callback type", () =>
  dispatch({hook: "AUTO_ASCEND"}), "DON_EVENT_INVALID_INGRESS");
failure("oversize page rejects before parsing", () =>
  dispatch({page: "p".repeat(128 * 1024 + 1)}), "DON_EVENT_INVALID_INGRESS");
failure("bad request identity", () =>
  dispatch({requestId: "../unsafe"}), "DON_EVENT_INVALID_INGRESS");
failure("partial timestamp fails", () =>
  dispatch({observedAt: "today"}), "DON_EVENT_INVALID_INGRESS");
failure("rollover between reads aborts", () =>
  dispatch({scopeAfter: { ...SCOPE, rolloverDay: "20261031" }}),
  "DON_EVENT_SCOPE_DRIFT");
failure("ascension between reads aborts", () =>
  dispatch({scopeAfter: { ...SCOPE, totalAscensions: 33 }}),
  "DON_EVENT_SCOPE_DRIFT");
failure("player switched aborts", () =>
  dispatch({scopeAfter: { ...SCOPE, playerId: "54321" }}),
  "DON_EVENT_SCOPE_DRIFT");
failure("untrusted player path aborts", () =>
  dispatch({scopeBefore: { ...SCOPE, playerId: "../../evil" }}),
  "DON_EVENT_INVALID_SCOPE");
failure("duplicate project IDs abort", () =>
  dispatch({}, [PASSIVE_EVENT_PROJECTS[0], PASSIVE_EVENT_PROJECTS[0]]),
  "DON_EVENT_INVALID_PROJECT");
failure("malicious value from project aborts without emitting", () =>
  dispatch({}, [{ id: "attack", hooks: ["COMBAT_ROUND"],
    extract: () => [{
      key: "notes", value: "pwd=secret", source: "parsed_page", confidence: "observed"
    }] }]), "DON_EVENT_UNSAFE_VALUE");
failure("raw HTML from project aborts", () =>
  dispatch({}, [{ id: "attack", hooks: ["COMBAT_ROUND"],
    extract: () => [{
      key: "notes", value: "<html>hi</html>", source: "parsed_page", confidence: "observed"
    }] }]), "DON_EVENT_UNSAFE_VALUE");
failure("email address from project aborts", () =>
  dispatch({}, [{ id: "attack", hooks: ["COMBAT_ROUND"],
    extract: () => [{
      key: "notes", value: "person@example.com", source: "parsed_page", confidence: "observed"
    }] }]), "DON_EVENT_UNSAFE_VALUE");
failure("duplicates from a project abort", () =>
  dispatch({}, [{ id: "duplicate", hooks: ["COMBAT_ROUND"],
    extract: () => [
      {key:"x",value:1,source:"kolmafia_cached",confidence:"observed"},
      {key:"x",value:2,source:"kolmafia_cached",confidence:"observed"}
    ] }]), "DON_EVENT_DUPLICATE_FIELD");
failure("project throws do not expose raw content", () =>
  dispatch({}, [{ id: "faulty", hooks: ["COMBAT_ROUND"],
    extract: () => { throw new Error("pwd=oops"); } }]),
  "DON_EVENT_PROJECT_FAILED_faulty");
failure("more than 32 emitted fields fail", () =>
  dispatch({}, [{ id: "flood", hooks: ["COMBAT_ROUND"],
    extract: () => Array.from({length:33}, (_,i)=>({
      key:"field"+i,value:i,source:"kolmafia_cached",confidence:"observed"
    })) }]), "DON_EVENT_TOO_MANY_RECORDS");

check("event path separated from v0.2 observation journal", () => {
  assert.equal(eventJournalPath(SCOPE),
    "don_Data/state-engine/12345/20261030/life-32/events.jsonl");
});
check("write three events in a single exclusive-lease append", () => {
  const io = memIO();
  const r = appendEventDispatch(io, dispatch());
  assert.equal(r.written, 3);
  assert.equal(r.finalSequence, 3);
  assert.equal(io.writes, 1);
  const parsed = parseEventJournal(io.readText(r.path), SCOPE);
  assert.deepEqual(parsed.map(x => x.sequence), [1,2,3]);
  assert.equal(parsed[0].prevEventId, null);
  assert.equal(parsed[1].prevEventId, parsed[0].evidenceId);
  assert.equal(parsed[2].prevEventId, parsed[1].evidenceId);
});
check("replaying identical callback is idempotent", () => {
  const io = memIO();
  appendEventDispatch(io, dispatch());
  const second = appendEventDispatch(io, dispatch());
  assert.equal(second.written, 0);
  assert.equal(second.duplicates, 3);
  assert.equal(io.writes, 1);
});
check("distinct request sequences chain correctly", () => {
  const io = memIO();
  const a = dispatch();
  const b = dispatch({requestId:"spade0002"});
  appendEventDispatch(io, a);
  const r = appendEventDispatch(io, b);
  assert.equal(r.written, 3);
  assert.equal(r.finalSequence, 6);
  assert.equal(io.writes, 2);
});
failure("reused ID with changed content fails closed", () => {
  const io = memIO();
  appendEventDispatch(io, dispatch());
  appendEventDispatch(io, dispatch({facts: {
    ...sample().facts, cookbookbatQuestLocation: "The Haunted Library"
  }}));
}, "DON_EVENTS_IDEMPOTENCY_CONFLICT");
failure("journal rejects missing lease", () =>
  appendEventDispatch(memIO(false), dispatch()),
  "DON_EVENTS_NO_EXCLUSIVE_LEASE");
failure("incomplete existing tail rejects", () => {
  const io = memIO();
  io.files.set(eventJournalPath(SCOPE), "{broken");
  appendEventDispatch(io, dispatch());
}, "DON_EVENTS_PARTIAL_TAIL");
failure("invalid JSON rejects", () => {
  const io = memIO();
  io.files.set(eventJournalPath(SCOPE), "{broken}\n");
  appendEventDispatch(io, dispatch());
}, "DON_EVENTS_INVALID_JSON");
failure("mixed scope batch rejects without writing", () => {
  const io = memIO();
  const batch = dispatch();
  appendEventDispatch(io, {...batch,
    records:[{...batch.records[0],scope: {...SCOPE,playerId:"54321"}}]});
}, "DON_EVENTS_MIXED_BATCH");
failure("partial append causes postwrite corruption error", () => {
  const io = memIO();
  io.appendText = (p, text) => {
    io.files.set(p, text.slice(0,-2));
    return true;
  };
  appendEventDispatch(io, dispatch());
}, "DON_EVENTS_PARTIAL_TAIL");
failure("failed native append stops", () => {
  const io = memIO();
  io.appendText = () => false;
  appendEventDispatch(io, dispatch());
}, "DON_EVENTS_APPEND_FAILED");
failure("unexpected journal field blocks replay", () => {
  const io = memIO();
  const batch = dispatch();
  const path = eventJournalPath(SCOPE);
  const row = {
    ...batch.records[0], sequence:1, prevEventId:null,
    rawPage:"secret"
  };
  io.files.set(path, JSON.stringify(row)+"\n");
  appendEventDispatch(io, batch);
}, "DON_EVENTS_INVALID_ROW");
failure("cross-ascension journal record cannot replay in this life", () => {
  const io = memIO();
  const batch = dispatch();
  const path = eventJournalPath(SCOPE);
  io.files.set(path, JSON.stringify({
    ...batch.records[0],
    scope: {...SCOPE,totalAscensions:31},
    sequence:1,prevEventId:null
  })+"\n");
  appendEventDispatch(io, batch);
}, "DON_EVENTS_CORRUPT_CHAIN");

check("first observation is a baseline, never a completion claim", () => {
  const changes = deriveEvidenceDeltas(dispatch().records);
  assert.deepEqual(changes.map(x => x.status), ["baseline","baseline","baseline"]);
  assert.ok(changes.every(x => x.flagTransitionAuthorized === false));
});
check("same value does not manufacture a state change", () => {
  const a = dispatch();
  const b = dispatch({requestId:"spade0002"});
  assert.deepEqual(deriveEvidenceDeltas([...a.records,...b.records])
    .slice(3).map(x => x.status), ["same","same","same"]);
});
check("changed fact becomes local discrepancy candidate only", () => {
  const a = dispatch();
  const b = dispatch({requestId:"spade0002",facts:{
    ...sample().facts,adventures:74
  }});
  const changes = deriveEvidenceDeltas([...a.records,...b.records]);
  assert.equal(changes.at(-1).status, "changed");
  assert.equal(changes.at(-1).previous, 75);
  assert.equal(changes.at(-1).current, 74);
  assert.equal(changes.at(-1).flagTransitionAuthorized, false);
});
check("same evidence ID repeated exactly is ignored in reconciliation", () => {
  const a = dispatch();
  assert.equal(deriveEvidenceDeltas([...a.records,...a.records]).length, 3);
});
failure("same evidence ID with different payload conflicts", () => {
  const a = dispatch();
  deriveEvidenceDeltas([
    a.records[0],{...a.records[0],value:"The Haunted Library"}
  ]);
}, "DON_EVENT_RECONCILE_CONFLICT");
failure("two different lives may never be compared", () => {
  const a = dispatch();
  const b = dispatch({requestId:"spade0002",
    scopeBefore:{...SCOPE,totalAscensions:33},
    scopeAfter:{...SCOPE,totalAscensions:33}
  });
  deriveEvidenceDeltas([...a.records,...b.records]);
}, "DON_EVENT_RECONCILE_SCOPE_DRIFT");

console.log("Don State v0.3 passive events: "+passed+" scenarios passed. No network, gameplay, credentials or live writes.");
