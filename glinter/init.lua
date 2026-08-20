local parse = require("glinter.parse")
local lint = require("glinter.lint")
local report = require("glinter.report")
local cli = require("glinter.cli")
local hook = require("glinter.hook")

return {
  VERSION = cli.VERSION,
  parse = parse.parse,
  is_ignored = parse.is_ignored,
  lint = lint.lint,
  allowed_types = lint.allowed_types,
  render = report.render,
  main = cli.main,
  hook = hook,
}
