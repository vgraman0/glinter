-- Word lists for Chris Beams structure and mood checks.
local function set(list)
  local t = {}
  for i = 1, #list do
    t[list[i]] = true
  end
  return t
end

local M = {}

M.imperative_ing = set({
  "bring",
  "cling",
  "ding",
  "fling",
  "ping",
  "ring",
  "sing",
  "spring",
  "sting",
  "string",
  "swing",
  "wing",
  "wring",
})

M.past_tense_first = set({
  "added",
  "adjusted",
  "changed",
  "corrected",
  "created",
  "deleted",
  "dropped",
  "fixed",
  "implemented",
  "improved",
  "introduced",
  "moved",
  "polished",
  "refactored",
  "removed",
  "renamed",
  "tweaked",
  "updated",
})

M.pronoun_first = set({
  "i",
  "i'm",
  "i've",
  "this",
  "we",
  "we're",
})

M.how_verbs = set({
  "add",
  "added",
  "change",
  "changed",
  "edit",
  "edited",
  "implement",
  "implemented",
  "replace",
  "replaced",
  "rewrite",
  "rewrote",
  "update",
  "updated",
})

M.why_signals = {
  "because",
  "so that",
  "otherwise",
  "avoids",
  "breaks",
  "needed",
  "when",
  "if",
  "to",
}

M.abbreviations = set({
  "e.g.",
  "etc.",
  "i.e.",
  "mr.",
  "mrs.",
  "ms.",
  "u.s.",
  "vs.",
})

return M
