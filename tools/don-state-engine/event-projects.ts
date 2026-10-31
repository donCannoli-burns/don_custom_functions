/**
 * Safe built-in passive observation recipes. The registry only observes
 * typed local facts provided by the future host adapter. No page scraping,
 * shell calls, preference mutations, page visits, or Kmail.
 *
 * These are EXAMPLES of extensible event projects, not a claim that KoLmafia
 * has confirmed a successful combat, choice, quest or workflow flag.
 */
import type { EventProject, EvidenceDatum } from "./event-observer";

function local(key: string, value: string | number | boolean): EvidenceDatum {
  return {
    key,
    value,
    source: "kolmafia_cached",
    confidence: "observed",
  };
}

function isNonnegativeInt(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isSafeInteger(value) &&
    value >= 0
  );
}

export const COOKBOOKBAT_QUEST: EventProject = {
  id: "cookbookbat_quest",
  hooks: ["COMBAT_ROUND"],
  extract: (input) => {
    if (input.facts.currentRound !== 0 ||
        input.facts.activeFamiliar !== "Cookbookbat")
      return null;
    const location = input.facts.cookbookbatQuestLocation;
    if (typeof location !== "string" || !location.trim())
      return null;
    return [local("cookbookbat.quest_location", location.trim())];
  },
};

export const CHOICE_CONTEXT: EventProject = {
  id: "choice_context",
  hooks: ["CHOICE_VISIT"],
  extract: (input) => {
    if (!isNonnegativeInt(input.facts.choiceId) ||
        input.facts.choiceId === 0)
      return null;
    return [{
      key: "choice.available_id",
      value: input.facts.choiceId,
      source: "event_metadata",
      confidence: "observed",
    }];
  },
};

export const RESOURCE_TICK: EventProject = {
  id: "resource_tick",
  hooks: ["COMBAT_ROUND", "CHOICE", "PVP"],
  extract: (input) => {
    const { turnsThisAscension, adventures } = input.facts;
    if (!isNonnegativeInt(turnsThisAscension) ||
        !isNonnegativeInt(adventures))
      return null;
    return [
      local("resources.turns_this_ascension", turnsThisAscension),
      local("resources.adventures", adventures),
    ];
  },
};

/** Explicit project registry; no automatic hook registration or side effects. */
export const PASSIVE_EVENT_PROJECTS: readonly EventProject[] = [
  COOKBOOKBAT_QUEST,
  CHOICE_CONTEXT,
  RESOURCE_TICK,
];
