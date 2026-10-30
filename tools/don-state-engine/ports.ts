/**
 * Uninstalled KoLmafia host adapter. No top-level KoLmafia import.
 *
 * Import/call only through a future explicit CLI entrypoint after live
 * KoLmafia verify and a real exclusive-writer lease have been established.
 */
import type { KoLReadPort } from "./observer";
import type { JournalIO } from "./journal";

export interface KoLNativeFilePort {
  fileToBuffer(path: string): unknown;
  toBuffer(text: string): unknown;
  appendBufferToFile?: (buffer: unknown, path: string) => boolean;
}
/** Read functions are deliberately supplied by a narrow injected port. */
export function makeObservationPort(port: KoLReadPort): KoLReadPort {
  return {
    myId: () => port.myId(),
    todayToString: () => port.todayToString(),
    myAscensions: () => port.myAscensions(),
    myTurncount: () => port.myTurncount(),
    myAdventures: () => port.myAdventures(),
    myInebriety: () => port.myInebriety(),
    myFullness: () => port.myFullness(),
    mySpleenUse: () => port.mySpleenUse(),
    inebrietyLimit: () => port.inebrietyLimit(),
    fullnessLimit: () => port.fullnessLimit(),
    spleenLimit: () => port.spleenLimit(),
    myMeat: () => port.myMeat(),
    myClosetMeat: () => port.myClosetMeat(),
    myStorageMeat: () => port.myStorageMeat(),
    myPath: () => port.myPath(),
    myClass: () => port.myClass(),
    canInteract: () => port.canInteract(),
    gamedayToInt: () => port.gamedayToInt(),
    getProperty: (name: string) => {
      if (name !== "ascensionsToday" && name !== "kingLiberated")
        throw new Error("DON_OBSERVER_PREF_NOT_ALLOWLISTED");
      return port.getProperty(name);
    }
  };
}
/**
 * A callback that merely returns true is NOT a real lease. The caller is
 * responsible for implementing/validating cross-process exclusivity.
 * No writer endpoint is installed in this prototype.
 */
export function makeJournalIO(port: KoLNativeFilePort,
                              exclusiveWriterHeld: () => boolean): JournalIO {
  return {
    holdsExclusiveLease: () => exclusiveWriterHeld(),
    readText: path => {
      if (typeof port.fileToBuffer !== "function")
        throw new Error("DON_JOURNAL_NO_FILE_READER");
      return String(port.fileToBuffer(path));
    },
    appendText: (path, text) => {
      if (typeof port.appendBufferToFile !== "function" ||
          typeof port.toBuffer !== "function")
        throw new Error("DON_JOURNAL_NEEDS_KOLMAFIA_R29125");
      return port.appendBufferToFile(port.toBuffer(text), path) === true;
    }
  };
}
