local cli = require("glinter.cli")
local report = require("glinter.report")
local lint = require("glinter.lint")

local function capture(fn)
  local stdout, stderr = {}, {}
  local old_stdout, old_stderr = io.stdout, io.stderr
  io.stdout = {
    write = function(_, text)
      stdout[#stdout + 1] = text
    end,
  }
  io.stderr = {
    write = function(_, text)
      stderr[#stderr + 1] = text
    end,
  }
  local ok, code = pcall(fn)
  io.stdout, io.stderr = old_stdout, old_stderr
  assert.is_true(ok)
  return code, table.concat(stdout), table.concat(stderr)
end

describe("glinter.cli", function()
  it("prints the version", function()
    local code, stdout = capture(function()
      return cli.main({ "--version" })
    end)
    assert.equal(0, code)
    assert.matches("glinter 0%.1%.0", stdout)
  end)

  it("lints a passing argument", function()
    local code, stdout = capture(function()
      return cli.main({ "lint", "--no-color", "feat: add parser" })
    end)
    assert.equal(0, code)
    assert.matches("looks good", stdout)
  end)

  it("lints a failing argument", function()
    local code, stdout = capture(function()
      return cli.main({ "lint", "--no-color", "WIP" })
    end)
    assert.equal(1, code)
    assert.matches("header%-format", stdout)
  end)

  it("rejects an unknown command", function()
    local code, _, stderr = capture(function()
      return cli.main({ "explode" })
    end)
    assert.equal(2, code)
    assert.matches("unknown command", stderr)
  end)
end)

describe("glinter.report", function()
  it("renders violations without color", function()
    local text = report.render(lint.lint("WIP"), { no_color = true })
    assert.matches("header%-format", text)
    assert.not_matches("\27%[", text)
  end)
end)
