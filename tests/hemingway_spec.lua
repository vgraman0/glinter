local catalog = require("glinter.catalog")
local rules = require("glinter.rules")

local function lint(text)
  return rules.lint(text)
end

set_current("catalog-hemingway")
local ids = { "H1", "H2", "H3", "H4", "H5", "H6" }
for i = 1, #ids do
  is_true(catalog[ids[i]] ~= nil, "catalog has " .. ids[i])
end

set_current("H1/H2")
do
  local words21 = {}
  for i = 1, 21 do
    words21[i] = "word"
  end
  local msg = "Fix length\n\n" .. table.concat(words21, " ") .. ".\n"
  is_true(has_rule(lint(msg), "H1"), "21 words is hard")
  is_true(has_no_rule(lint(msg), "H2"), "21 is not very hard")
  local words31 = {}
  for i = 1, 31 do
    words31[i] = "word"
  end
  local msg2 = "Fix length\n\n" .. table.concat(words31, " ") .. ".\n"
  is_true(has_rule(lint(msg2), "H2"), "31 words is very hard")
  is_true(has_no_rule(lint(msg2), "H1"), "H2 replaces H1")
end

set_current("H3")
is_true(has_rule(lint("Fix the really bad wrap\n"), "H3"), "really")
is_true(has_rule(lint("Fix the quickly broken wrap\n"), "H3"), "-ly adverb")
is_true(has_no_rule(lint("Fix only the parser\n"), "H3"), "only is allowed")
is_true(has_no_rule(lint("Apply the patch\n"), "H3"), "apply is not an adverb")
is_true(has_rule(lint("Fix too large buffers\n"), "H3"), "too + adjective")

set_current("H4")
is_true(has_rule(lint("Fix voice\n\nThe file was written by the hook.\n"), "H4"), "was written")
is_true(has_rule(lint("Fix voice\n\nThe tests were added later.\n"), "H4"), "were added")
is_true(has_no_rule(lint("Fix voice\n\nThe hook writes the file.\n"), "H4"), "active")

set_current("H5")
is_true(has_rule(lint("Fix the maybe broken wrap\n"), "H5"), "maybe")
is_true(has_rule(lint("Fix wrap\n\nI think the cache is cold.\n"), "H5"), "I think")
is_true(has_rule(lint("Just fix the wrap\n"), "H5"), "just")

set_current("H6")
do
  local d = has_rule(lint("Fix wrap\n\nDo not utilize the old API.\n"), "H6")
  is_true(d, "utilize")
  if d then
    eq(d.replacement, "use", "utilize -> use")
  end
  is_true(has_rule(lint("Fix wrap\n\nThis is needed in order to boot.\n"), "H6"), "in order to")
  is_true(has_no_rule(lint("Fix wrap\n\nKeep it short however you wrap it.\n"), "H6"), "mid-sentence however")
  is_true(has_rule(lint("Fix wrap\n\nHowever the old path leaked.\n"), "H6"), "sentence-initial however")
end

set_current("comments")
do
  local text = "Fix wrap\n\nKeep comments out of prose checks.\n# really utilize maybe was written\n"
  local diags = lint(text)
  is_true(has_no_rule(diags, "H3"), "no adverb in comment")
  is_true(has_no_rule(diags, "H5"), "no qualifier in comment")
  is_true(has_no_rule(diags, "H6"), "no simpler-word in comment")
  is_true(has_no_rule(diags, "H4"), "no passive in comment")
end

set_current("example-fail")
do
  local text = table.concat({
    "fixed the thing.",
    "",
    "Added a really comprehensive implementation that utilizes the new",
    "framework so that highlighting can basically be applied in a way that is",
    "very easily understood by users who might perhaps want to leverage it.",
  }, "\n")
  local diags = lint(text)
  is_true(has_rule(diags, "S4"), "example S4")
  is_true(has_rule(diags, "S5"), "example S5")
  is_true(has_rule(diags, "S6"), "example S6")
  is_true(has_rule(diags, "H3"), "example H3")
  is_true(has_rule(diags, "H5"), "example H5")
  is_true(has_rule(diags, "H6"), "example H6")
end

set_current("example-pass")
do
  local text = table.concat({
    "Fix overflow on long commit subjects",
    "",
    "Subjects longer than 72 characters break git log and GitHub.",
    "Cap the hard limit and warn at 50 so the line stays a summary.",
  }, "\n")
  eq(#lint(text), 0, "plan pass example is clean")
end
