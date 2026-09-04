-- Closed word lists for clear-English checks.
-- Keys are lowercase ASCII. Not CS vocabulary.
local function set(list)
  local t = {}
  for i = 1, #list do
    t[list[i]] = true
  end
  return t
end

local M = {}

M.adverb_allow = set({
  "ally",
  "anomaly",
  "apply",
  "assembly",
  "belly",
  "bully",
  "butterfly",
  "comply",
  "daily",
  "dragonfly",
  "early",
  "family",
  "firefly",
  "fly",
  "folly",
  "gully",
  "holly",
  "imply",
  "italy",
  "jelly",
  "july",
  "likely",
  "lily",
  "monthly",
  "monopoly",
  "multiply",
  "only",
  "rally",
  "rely",
  "reply",
  "supply",
  "tally",
  "weekly",
  "yearly",
})

M.intensifiers = set({
  "extremely",
  "quite",
  "rather",
  "really",
  "too",
  "very",
})

M.irregular_participles = set({
  "broken",
  "built",
  "chosen",
  "come",
  "done",
  "driven",
  "fed",
  "felt",
  "forgotten",
  "found",
  "given",
  "gone",
  "got",
  "gotten",
  "held",
  "hidden",
  "hit",
  "kept",
  "known",
  "left",
  "lost",
  "made",
  "meant",
  "met",
  "paid",
  "put",
  "read",
  "run",
  "said",
  "seen",
  "sent",
  "set",
  "shown",
  "sold",
  "spent",
  "struck",
  "taken",
  "taught",
  "told",
  "understood",
  "won",
  "written",
})

M.qualifiers = {
  "i believe",
  "i think",
  "i feel",
  "sort of",
  "kind of",
  "try to",
  "a bit",
  "basically",
  "essentially",
  "maybe",
  "perhaps",
  "possibly",
  "probably",
  "seemingly",
  "slightly",
  "somewhat",
  "seemed",
  "seems",
  "just",
}

M.be_verbs = set({
  "am",
  "is",
  "are",
  "was",
  "were",
  "be",
  "been",
  "being",
})

return M
