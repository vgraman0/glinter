local parse = require("glinter.parse")

local M = {}

M.parse = parse.classify
M.lint = require("glinter.rules").lint
M.rules = require("glinter.rules")
M.catalog = require("glinter.catalog")

return M
