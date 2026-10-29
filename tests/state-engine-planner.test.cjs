"use strict";
const assert = require("node:assert/strict");
const { planNext } = require("../.state-build/planner.js");
const { SEGMENTS, FLAG_CODE } = require("../.state-build/registry.js");

function state(overrides = {}) {
  return Object.assign({
    playerId: "12345", rolloverDay: "20261029", totalAscensions: 10,
    ascensionsToday: 0, turnsThisAscension: 24, adventures: 30,
    liverUsed: 4, stomachUsed: 8, spleenUsed: 2,
    liverLimit: 14, stomachLimit: 15, spleenLimit: 15,
    meatOnHand: 13000, meatCloset: 2000,
    kingLiberated: true, canInteract: true, inRonin: false,
    path: "None", className: "Pastamancer", gamedayIndex: 35,
    nextHalloween: null, daysTillHalloween: null,
    isHalloween: null, eveOfHalloween: null, eventEvidence: "unknown",
    observedAt: "2026-10-29T12:00:00-05:00"
  }, overrides);
}
function policy(overrides = {}) {
  return Object.assign({
    loopRun: true, stopForDiscrepancy: true, autoFallback: false,
    nextExpectedFlag: null, nextFallbackFlag: null,
    maxAutomaticAdventureSpend: 30, requireExplicitAscensionApproval: true
  }, overrides);
}
function stage(target, overrides = {}) {
  const flags = Object.create(null);
  for (const segment of SEGMENTS) flags[segment.id] = FLAG_CODE.finished;
  if (target) flags[target] = FLAG_CODE.pending;
  return Object.assign(flags, overrides);
}
function decide(flag, overrides = {}) {
  const input = Object.assign({
    observation: state(), policy: policy(), flags: stage(flag),
    discrepancyCount: 0, leg1Mode: "barf", leg2Mode: "barf"
  }, overrides);
  return planNext(input);
}
let cases = 0;
function check(label, decision, expected, flag = undefined) {
  assert.equal(decision.kind, expected, label);
  assert.equal(decision.executionAuthorized, false, label + " no-execute invariant");
  if (flag !== undefined) assert.equal(decision.flag, flag, label + " flag");
  cases += 1;
}
check("first phase", decide("start_day"), "ready", "start_day");
check("all complete", decide(null), "done", null);
check("garbo phase ready", decide("leg1_farm"), "ready", "leg1_farm");
check("cowo only Pastamancer", decide("leg1_farm", { leg1Mode: "cowo", observation: state({className: "Seal Clubber"}) }), "blocked");
check("cowo Pastamancer", decide("leg1_farm", { leg1Mode: "cowo" }), "ready");
check("missing farm mode", decide("leg1_farm", { leg1Mode: null }), "blocked");
check("freeze all halts", decide("leg1_farm", { leg1Mode: "freeze_all" }), "stop");
check("Halloween unproven", decide("leg1_farm", { leg1Mode: "trick_or_treat" }), "blocked");
check("Halloween conflict", decide("leg1_farm", { leg1Mode: "trick_or_treat", observation: state({isHalloween: true, eventEvidence: "conflict"}) }), "blocked");
check("Halloween confirmed", decide("leg1_farm", { leg1Mode: "trick_or_treat", observation: state({isHalloween: true, eventEvidence: "confirmed"}) }), "ready");
check("event fallback is only proposal", decide("leg1_farm", { leg1Mode: "event" }), "fallback_proposed");
check("in progress needs reconcile", decide("leg1_farm", { flags: stage("leg1_farm", {leg1_farm: 1}) }), "reconcile");
check("reconciliation flag", decide("leg1_farm", { flags: stage("leg1_farm", {leg1_farm: 5}) }), "reconcile");
check("failed flag halts", decide("leg1_farm", { flags: stage("leg1_farm", {leg1_farm: 4}) }), "stop");
check("discrepancy blocks", decide("leg1_farm", { discrepancyCount: 2 }), "stop");
check("overspend budget", decide("leg1_farm", {requestedAdventureSpend: 31}), "blocked");
check("expected flag mismatch", decide("start_day", {policy: policy({nextExpectedFlag: "setup_l1"})}), "blocked");
check("unknown expected flag", decide("start_day", {policy: policy({nextExpectedFlag: "fake"})}), "stop");
check("nonloop skips ascension", decide("ascension", {policy: policy({loopRun: false})}), "skip_proposed");
check("loop needs ascension approval", decide("ascension"), "approval_required");
check("post-hook before ascension", decide("post_ascension_hook"), "reconcile");
check("path run before ascension", decide("path_run"), "blocked");
check("leg2 before ascension", decide("leg2_farm"), "blocked");
check("leg2 after ascension", decide("leg2_farm", {observation: state({ascensionsToday: 1})}), "ready");
check("unexpected second ascension", decide("start_day", {observation: state({ascensionsToday: 2})}), "reconcile");
check("bad identity", decide("start_day", {observation: state({rolloverDay: ""})}), "stop");
console.log("Don State Engine planner offline scenarios: " + cases + " passed; 0 live actions.");
