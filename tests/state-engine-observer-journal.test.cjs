"use strict";
const assert = require("node:assert/strict");
const { captureKoLState } = require("../.state-build/observer.js");
const { appendObservation, observationPath, parseJournal } = require("../.state-build/journal.js");
const { makeObservationPort, makeJournalIO } = require("../.state-build/ports.js");

function reader(overrides = {}) {
  const obj = {
    myId: () => "12345",
    todayToString: () => "20261030",
    myAscensions: () => 32,
    myTurncount: () => 17,
    myAdventures: () => 88,
    myInebriety: () => 14,
    myFullness: () => 11,
    mySpleenUse: () => 3,
    inebrietyLimit: () => 19,
    fullnessLimit: () => 15,
    spleenLimit: () => 15,
    myMeat: () => 20000,
    myClosetMeat: () => 70000,
    myStorageMeat: () => 3000,
    myPath: () => "11037 Leagues Under the Sea",
    myClass: () => "Pastamancer",
    canInteract: () => false,
    gamedayToInt: () => 13,
    getProperty: key => key === "ascensionsToday" ? "1" :
      key === "kingLiberated" ? "false" : ""
  };
  return Object.assign(obj, overrides);
}
const TIME = "2026-10-30T08:00:00Z";
const caught = captureKoLState(reader(), TIME);
let cases = 0;
function check(name, fn) { fn(); cases++; }
function failure(name, fn, code) {
  check(name, () => assert.throws(fn, e => e.message === code));
}
check("read-only observation values", () => {
  assert.equal(caught.snapshot.meatOnHand, 20000);
  assert.equal(caught.snapshot.meatCloset, 70000);
  assert.equal(caught.snapshot.meatStorage, 3000);
  assert.equal(caught.snapshot.rolloverDay, "20261030");
  assert.equal(caught.snapshot.totalAscensions, 32);
  assert.equal(caught.snapshot.liverUsed, 14);
  assert.equal(caught.snapshot.kingLiberated, false);
  assert.equal(caught.snapshot.inRonin, null);
  assert.equal(caught.snapshot.isHalloween, null);
  assert.equal(caught.source, "kolmafia_cached");
  assert.equal(caught.snapshot.canInteract, false);
});
failure("missing ascensionsToday", () => captureKoLState(reader({
  getProperty: key => key === "kingLiberated" ? "false" : ""
}), TIME), "DON_OBSERVER_INVALID_ASCENSIONSTODAY");
failure("missing king state", () => captureKoLState(reader({
  getProperty: key => key === "ascensionsToday" ? "1" : ""
}), TIME), "DON_OBSERVER_INVALID_KINGLIBERATED");
failure("negative adventure", () => captureKoLState(reader({myAdventures: () => -1}), TIME), "DON_OBSERVER_INVALID_ADVENTURES");
failure("unknown player identity", () => captureKoLState(reader({myId: () => "../users"}), TIME), "DON_OBSERVER_INVALID_PLAYER");
failure("invalid timestamp", () => captureKoLState(reader(), "tomorrow"), "DON_OBSERVER_INVALID_TIMESTAMP");
failure("partial turn change", () => {
  let n = 0;
  captureKoLState(reader({myTurncount: () => ++n}), TIME);
}, "DON_OBSERVER_SCOPE_DRIFT");
failure("rollover during read", () => {
  let n = 0;
  captureKoLState(reader({todayToString: () => (++n === 1 ? "20261030" : "20261031")}), TIME);
}, "DON_OBSERVER_SCOPE_DRIFT");
failure("ascension during read", () => {
  let n = 0;
  captureKoLState(reader({myAscensions: () => (++n === 1 ? 32 : 33)}), TIME);
}, "DON_OBSERVER_SCOPE_DRIFT");

function memIO(canWrite = true) {
  const files = new Map();
  let writes = 0;
  return {
    files,
    get writes() { return writes; },
    holdsExclusiveLease: () => canWrite,
    readText: p => files.get(p) || "",
    appendText: (p, v) => { writes++; files.set(p, (files.get(p) || "") + v); return true; }
  };
}
check("journal path is scope partitioned", () => {
  assert.equal(observationPath(caught.snapshot),
    "don_Data/state-engine/12345/20261030/life-32/observations.jsonl");
});
check("append one observation", () => {
  const io = memIO();
  const r = appendObservation(io, caught, "login-0001");
  assert.equal(r.disposition, "written");
  assert.equal(r.event.sequence, 1);
  assert.equal(r.event.prevEventId, null);
  assert.equal(io.writes, 1);
  assert.equal(parseJournal(io.readText(r.path), caught.snapshot).length, 1);
});
check("idempotent replay has no second write", () => {
  const io = memIO();
  const first = appendObservation(io, caught, "login-0001");
  const again = appendObservation(io, caught, "login-0001");
  assert.equal(again.disposition, "duplicate");
  assert.equal(first.event.eventId, again.event.eventId);
  assert.equal(io.writes, 1);
});
failure("same key different content is conflict", () => {
  const io = memIO();
  appendObservation(io, caught, "login-0001");
  const changed = { ...caught, snapshot: {...caught.snapshot, adventures: 89} };
  appendObservation(io, changed, "login-0001");
}, "DON_JOURNAL_IDEMPOTENCY_CONFLICT");
check("second key chains", () => {
  const io = memIO();
  appendObservation(io, caught, "login-0001");
  const r = appendObservation(io, caught, "login-0002");
  assert.equal(r.event.sequence, 2);
  assert.equal(r.event.prevEventId, "login-0001");
});
failure("lock missing aborts before reading or writing", () => {
  const io = memIO(false);
  appendObservation(io, caught, "login-0001");
}, "DON_JOURNAL_NO_EXCLUSIVE_LEASE");
failure("truncated journal quarantined", () => {
  const io = memIO();
  const p = observationPath(caught.snapshot);
  io.files.set(p, '{"oops":1}');
  appendObservation(io, caught, "login-0002");
}, "DON_JOURNAL_PARTIAL_TAIL");
failure("garbled journal quarantined", () => {
  const io = memIO();
  const p = observationPath(caught.snapshot);
  io.files.set(p, '{garbled}\n');
  appendObservation(io, caught, "login-0002");
}, "DON_JOURNAL_CORRUPT_JSON_LINE_1");
failure("invalid request id never creates paths", () =>
  appendObservation(memIO(), caught, "../../evil"),
  "DON_JOURNAL_INVALID_REQUEST_ID");
failure("write failure stops", () => {
  const io = memIO();
  io.appendText = () => false;
  appendObservation(io, caught, "login-0002");
}, "DON_JOURNAL_APPEND_FAILED");
failure("corrupt native append fails readback", () => {
  const io = memIO();
  io.appendText = (p, text) => { io.files.set(p, text.slice(0,-3)); return true; };
  appendObservation(io, caught, "login-0002");
}, "DON_JOURNAL_PARTIAL_TAIL");
check("rollover starts a distinct path", () => {
  const io = memIO();
  const another = { ...caught, snapshot: { ...caught.snapshot, rolloverDay: "20261031" } };
  const a = appendObservation(io, caught, "login-0001");
  const b = appendObservation(io, another, "login-0001");
  assert.notEqual(a.path, b.path);
  assert.equal(b.event.sequence, 1);
});
check("new ascension starts a distinct path", () => {
  const io = memIO();
  const another = { ...caught, snapshot: { ...caught.snapshot, totalAscensions: 33 } };
  assert.notEqual(appendObservation(io, caught, "login-0001").path,
    appendObservation(io, another, "login-0001").path);
});
failure("cross-player data stops", () => {
  const io = memIO();
  const foreign = { ...caught, snapshot: {...caught.snapshot, playerId: "1079722"} };
  const foreignPath = observationPath(foreign.snapshot);
  const event = appendObservation(io, caught, "login-0001").event;
  io.files.set(foreignPath, JSON.stringify(event) + "\n");
  appendObservation(io, foreign, "login-0002");
}, "DON_JOURNAL_CORRUPT_CHAIN_LINE_1");

check("read port denies other preference names", () => {
  const port = makeObservationPort(reader());
  assert.equal(port.getProperty("kingLiberated"), "false");
  assert.throws(() => port.getProperty("password"), /DON_OBSERVER_PREF_NOT_ALLOWLISTED/);
});
check("native port appends only with injected lease", () => {
  const files = new Map();
  const native = {
    fileToBuffer: p => files.get(p) || "",
    toBuffer: s => String(s),
    appendBufferToFile: (buf, p) => {
      files.set(p, (files.get(p) || "") + buf);
      return true;
    }
  };
  const io = makeJournalIO(native, () => true);
  const recorded = appendObservation(io, caught, "native-0001");
  assert.equal(recorded.disposition, "written");
  assert.equal(parseJournal(io.readText(recorded.path), caught.snapshot).length, 1);
});
failure("old mafia revision blocks append instead of rewrite", () => {
  const io = makeJournalIO({
    fileToBuffer: () => "",
    toBuffer: s => s
  }, () => true);
  appendObservation(io, caught, "legacy-0001");
}, "DON_JOURNAL_NEEDS_KOLMAFIA_R29125");
check("write port retains strict lease boundary", () => {
  let calls = 0;
  const io = makeJournalIO({
    fileToBuffer: () => { calls++; return ""; },
    toBuffer: s => s
  }, () => false);
  assert.throws(() => appendObservation(io, caught, "no-lease"), /DON_JOURNAL_NO_EXCLUSIVE_LEASE/);
  assert.equal(calls, 0);
});

console.log("Don State Engine observer and journal scenarios: " + cases +
            " passed; no KoL requests, commands or live player writes.");
