local parse = require("glinter.parse")

local M = {}

M.version = require("glinter.version")
M.parse = parse.classify
M.lint = require("glinter.rules").lint
M.rules = require("glinter.rules")
M.catalog = require("glinter.catalog")
M.words = require("glinter.words")

function M.setup(opts)
  require("glinter.highlight").setup(opts)
end

return M
