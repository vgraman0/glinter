package = "glinter"
version = "scm-1"
source = {
  url = "git+https://github.com/vgraman0/Glinter.git"
}
description = {
  summary = "Write better commit messages. Instant feedback.",
  detailed = [[
Glinter is a zero-dependency Lua CLI that lints commit messages against
the Conventional Commits spec and prints instant, actionable feedback.
]],
  homepage = "https://github.com/vgraman0/Glinter",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["glinter"] = "glinter/init.lua",
    ["glinter.parse"] = "glinter/parse.lua",
    ["glinter.lint"] = "glinter/lint.lua",
    ["glinter.report"] = "glinter/report.lua",
    ["glinter.cli"] = "glinter/cli.lua",
    ["glinter.hook"] = "glinter/hook.lua"
  },
  install = {
    bin = {
      glinter = "bin/glinter"
    }
  }
}
