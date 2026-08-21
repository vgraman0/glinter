local catalog = require("glinter.catalog")
local rules = require("glinter.rules")

local function lint(text)
  return rules.lint(text)
end

set_current("catalog-cbeams")
local ids = { "S0", "S1", "S3", "S4", "S5", "S6", "S7", "B1", "C1" }
for i = 1, #ids do
  is_true(catalog[ids[i]] ~= nil, "catalog has " .. ids[i])
end
is_true(catalog.S2 == nil, "S2 is removed")

set_current("cbeams-clean")
do
  local text = table.concat({
    "Fix overflow on long commit subjects",
    "",
    "Subjects longer than 72 characters break git log.",
  }, "\n")
  local diags = lint(text)
  local beams = 0
  for i = 1, #diags do
    if diags[i].rule:sub(1, 1) ~= "H" then
      beams = beams + 1
    end
  end
  eq(beams, 0, "good message has no Chris Beams hits: " .. rules_of(diags))
end

do
  local diags = lint("Merge branch 'main'\n")
  eq(#diags, 0, "merge is exempt")
end

set_current("S0")
is_true(has_rule(lint("\n# comment\n"), "S0"), "empty subject")

set_current("S1")
do
  local diags = lint("Fix the thing\nBody without a blank line\n")
  local d = has_rule(diags, "S1")
  is_true(d, "missing blank line")
  if d then
    eq(d.lnum, 1, "S1 highlights first body line")
  end
  is_true(has_no_rule(lint("Fix the thing\n\nExplain why it broke.\n"), "S1"), "blank is ok")
end

set_current("S3")
do
  local mid = "Fix " .. string.rep("x", 50)
  local diags = lint(mid .. "\n")
  is_true(has_no_rule(diags, "S3"), "54 chars is not hard overflow")
  local hard = "Fix " .. string.rep("y", 80)
  local h = lint(hard .. "\n")
  local s3 = has_rule(h, "S3")
  is_true(s3, "hard overflow")
  if s3 then
    eq(s3.col, 72, "S3 starts at column 73")
  end
end

set_current("S4")
is_true(has_rule(lint("fixed the bug\n"), "S4"), "lowercase subject")
is_true(has_rule(lint(" Fix the bug\n"), "S4"), "leading space")
is_true(has_no_rule(lint("Fix the bug\n"), "S4"), "capital is ok")

set_current("S5")
is_true(has_rule(lint("Fix the bug.\n"), "S5"), "trailing period")
is_true(has_rule(lint("Fix the bug!\n"), "S5"), "trailing bang")
is_true(has_no_rule(lint("Fix the U.S. parser\n"), "S5"), "interior period")

set_current("S6")
is_true(has_rule(lint("Fixed overflow\n"), "S6"), "past tense")
is_true(has_rule(lint("Fixing overflow\n"), "S6"), "gerund")
is_true(has_rule(lint("This fixes overflow\n"), "S6"), "this")
is_true(has_no_rule(lint("Fix overflow in subject highlighting\n"), "S6"), "imperative")
is_true(has_no_rule(lint("Bring back the old parser\n"), "S6"), "bring is imperative")
is_true(has_no_rule(lint("Don't leak the token\n"), "S6"), "don't is imperative")

set_current("S7")
is_true(has_rule(lint("WIP Fix overflow\n"), "S7"), "WIP")
is_true(has_rule(lint("wip\n"), "S7"), "lowercase wip")

set_current("B1")
do
  local long = "Fix wrap\n\n" .. string.rep("word ", 20) .. "\n"
  local d = has_rule(lint(long), "B1")
  is_true(d, "body wrap")
  if d then
    eq(d.col, 72, "B1 starts at column 73")
  end
  local url = "Fix wrap\n\nhttps://example.com/" .. string.rep("a", 80) .. "\n"
  is_true(has_no_rule(lint(url), "B1"), "URL line exempt")
end

set_current("C1")
is_true(has_rule(lint("Fix wrap\n\nUpdated the parser.\n"), "C1"), "how without why")
is_true(has_no_rule(lint("Fix wrap\n\nUpdated the parser because it crashed.\n"), "C1"), "because is why")

set_current("live-coords")
do
  local util = require("glinter.util")
  local padded = "Fix " .. string.rep("a", 69)
  eq(util.char_len(padded), 73, "73 chars")
  local d = has_rule(lint(padded), "S3")
  is_true(d, "73rd char errors")
  if d then
    eq(d.col, 72, "highlight from 0-based col 72")
  end
  local soft = "Fix " .. string.rep("a", 47)
  eq(util.char_len(soft), 51, "51 chars")
  is_true(has_no_rule(lint(soft), "S3"), "51 chars is under the hard limit")
end
