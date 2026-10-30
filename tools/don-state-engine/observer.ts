/**
 * v0.2 local-state observer. No network refresh, no disk writes, no CLI.
 * Inject the KoLmafia read-only functions instead of importing an executor.
 *
 * A captured snapshot is a statement about KoLmafia's local cached state;
 * it is NOT independent evidence that a server-side action completed.
 */
import type { Observation } from "./registry";

export interface KoLReadPort {
  myId(): string;
  todayToString(): string;   // KoL rollover-aligned YYYYMMDD
  myAscensions(): number;    // Lifetime ascension number
  myTurncount(): number;     // Turns this ascension
  myAdventures(): number;
  myInebriety(): number;
  myFullness(): number;
  mySpleenUse(): number;
  inebrietyLimit(): number;
  fullnessLimit(): number;
  spleenLimit(): number;
  myMeat(): number;
  myClosetMeat(): number;
  myStorageMeat(): number;
  myPath(): { toString(): string } | string;
  myClass(): { toString(): string } | string;
  canInteract(): boolean;
  gamedayToInt(): number;
  getProperty(name: string): string;
}
export interface ObserverResult {
  schema: "don-observation-v0.2";
  snapshot: Observation;
  source: "kolmafia_cached";
  limitations: readonly ["no_refresh", "no_network", "no_independent_server_receipt"];
}

function intField(value: unknown, name: string): number {
  if (typeof value !== "number" || !Number.isFinite(value) ||
      !Number.isInteger(value) || value < 0) {
    throw new Error("DON_OBSERVER_INVALID_" + name);
  }
  return value;
}
function propertyInt(value: string, name: string): number {
  if (!/^(0|[1-9][0-9]*)$/.test(value)) throw new Error("DON_OBSERVER_INVALID_" + name);
  return intField(Number(value), name);
}
function boolProperty(value: string, name: string): boolean {
  if (value === "true") return true;
  if (value === "false") return false;
  throw new Error("DON_OBSERVER_INVALID_" + name);
}
function textField(value: unknown, name: string): string {
  const result = String(value);
  if (!result || result === "undefined" || result === "null" || result.length > 200)
    throw new Error("DON_OBSERVER_INVALID_" + name);
  return result;
}
function identity(k: KoLReadPort) {
  const playerId = textField(k.myId(), "PLAYER");
  const rolloverDay = textField(k.todayToString(), "DAY");
  if (!/^[0-9]{1,12}$/.test(playerId)) throw new Error("DON_OBSERVER_INVALID_PLAYER");
  if (!/^[0-9]{8}$/.test(rolloverDay)) throw new Error("DON_OBSERVER_INVALID_DAY");
  return {
    playerId,
    rolloverDay,
    totalAscensions: intField(k.myAscensions(), "ASCENSIONS"),
    ascensionsToday: propertyInt(k.getProperty("ascensionsToday"), "ASCENSIONSTODAY"),
    turnsThisAscension: intField(k.myTurncount(), "TURNS"),
  };
}
function sameIdentity(a: ReturnType<typeof identity>,
                      b: ReturnType<typeof identity>): boolean {
  return a.playerId === b.playerId && a.rolloverDay === b.rolloverDay &&
    a.totalAscensions === b.totalAscensions &&
    a.ascensionsToday === b.ascensionsToday &&
    a.turnsThisAscension === b.turnsThisAscension;
}
export function captureKoLState(k: KoLReadPort, observedAt: string): ObserverResult {
  if (!/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)$/.test(observedAt))
    throw new Error("DON_OBSERVER_INVALID_TIMESTAMP");

  const before = identity(k);
  const snap: Observation = {
    ...before,
    adventures: intField(k.myAdventures(), "ADVENTURES"),
    liverUsed: intField(k.myInebriety(), "LIVER"),
    stomachUsed: intField(k.myFullness(), "STOMACH"),
    spleenUsed: intField(k.mySpleenUse(), "SPLEEN"),
    liverLimit: intField(k.inebrietyLimit(), "LIVERLIMIT"),
    stomachLimit: intField(k.fullnessLimit(), "STOMACHLIMIT"),
    spleenLimit: intField(k.spleenLimit(), "SPLEENLIMIT"),
    meatOnHand: intField(k.myMeat(), "MEAT"),
    meatCloset: intField(k.myClosetMeat(), "CLOSETMEAT"),
    meatStorage: intField(k.myStorageMeat(), "STORAGEMEAT"),
    kingLiberated: boolProperty(k.getProperty("kingLiberated"), "KINGLIBERATED"),
    canInteract: k.canInteract(),
    // canInteract is NOT synonymous with exiting Ronin, especially in hardcore.
    inRonin: null,
    path: textField(k.myPath(), "PATH"),
    className: textField(k.myClass(), "CLASS"),
    gamedayIndex: intField(k.gamedayToInt(), "GAMEDAY"),
    // Holiday and event predictions belong to a separate validated adapter.
    nextHalloween: null,
    daysTillHalloween: null,
    isHalloween: null,
    eveOfHalloween: null,
    eventEvidence: "unknown",
    observedAt
  };
  if (typeof snap.canInteract !== "boolean")
    throw new Error("DON_OBSERVER_INVALID_CANINTERACT");
  if (snap.liverLimit < 0 || snap.stomachLimit < 0 || snap.spleenLimit < 0)
    throw new Error("DON_OBSERVER_INVALID_LIMIT");
  const after = identity(k);
  if (!sameIdentity(before, after)) throw new Error("DON_OBSERVER_SCOPE_DRIFT");
  return {
    schema: "don-observation-v0.2",
    snapshot: snap,
    source: "kolmafia_cached",
    limitations: ["no_refresh", "no_network", "no_independent_server_receipt"]
  };
}
