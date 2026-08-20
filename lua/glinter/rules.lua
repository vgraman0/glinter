local catalog = require("glinter.catalog")
local cbeams = require("glinter.cbeams")
local diag = require("glinter.diag")
local hemingway = require("glinter.hemingway")
local parse = require("glinter.parse")

local M = {}

function M.lint(text, opts)
  local parsed = parse.classify(text, opts)
  local out = {}
  cbeams.apply(out, parsed)
  hemingway.apply(out, parsed)
  return diag.sort(out), parsed
end

M.catalog = catalog
M.SUBJECT_SOFT = cbeams.SUBJECT_SOFT
M.SUBJECT_HARD = cbeams.SUBJECT_HARD
M.BODY_WRAP = cbeams.BODY_WRAP
M.HARD_SENTENCE = hemingway.HARD_SENTENCE
M.VERY_HARD_SENTENCE = hemingway.VERY_HARD_SENTENCE

return M
