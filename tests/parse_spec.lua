local parse = require("glinter.parse")
local util = require("glinter.util")

set_current("parse")
do
  local text = table.concat({
    "Fix overflow on long commit subjects",
    "",
    "Subjects longer than 72 characters break git log.",
    "# Please enter the commit message for your changes.",
    "# ------------------------ >8 ------------------------",
    "diff --git a/lua/glinter/rules.lua b/lua/glinter/rules.lua",
  }, "\n")
  local p = parse.classify(text)
  is_true(p.subject ~= nil, "has subject")
  eq(p.subject.lnum, 0, "subject lnum")
  eq(p.subject.text, "Fix overflow on long commit subjects", "subject text")
  eq(#p.body_lines, 1, "one body line")
  eq(p.body_lines[1].lnum, 2, "body keeps buffer line")
  eq(p.kinds[4], parse.KIND_COMMENT, "comment kind")
  eq(p.kinds[5], parse.KIND_IGNORED, "scissors ignored")
  eq(p.kinds[6], parse.KIND_IGNORED, "diff ignored")
end

do
  local p = parse.classify("Fix foo\n\nSigned-off-by: A U Thor <a@b.c>\n")
  eq(p.kinds[3], parse.KIND_TRAILER, "trailer kind")
  eq(#p.trailer_lines, 1, "one trailer")
  eq(#p.body_lines, 0, "trailers are not prose body")
end

do
  -- Committed messages (--range) keep # headings and issue refs.
  local text = table.concat({
    "# Heading that is the subject",
    "",
    "#123 caused the wrap because git stored the hash.",
  }, "\n")
  local comments = parse.classify(text)
  eq(comments.subject, nil, "default still drops hash lines")
  local stored = parse.classify(text, { comment_char = false })
  is_true(stored.subject ~= nil, "stored hash subject kept")
  eq(stored.subject.text, "# Heading that is the subject", "hash heading is subject")
  eq(#stored.body_lines, 1, "hash body line kept")
  eq(stored.body_lines[1].text, "#123 caused the wrap because git stored the hash.", "issue ref kept")
end

do
  is_true(util.is_generated_subject("Merge branch 'main'"), "merge")
  is_true(util.is_generated_subject("Revert \"Fix foo\""), "revert")
  is_true(util.is_generated_subject("fixup! Fix foo"), "fixup")
end
