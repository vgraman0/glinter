local lint = require("glinter.lint")

describe("glinter.lint", function()
  it("accepts a conventional commit", function()
    local result = lint.lint("feat: add parser")
    assert.is_true(result.ok)
    assert.equal(0, #result.violations)
  end)

  it("rejects an empty message", function()
    local result = lint.lint("   \n")
    assert.is_false(result.ok)
    assert.equal("message-empty", result.violations[1].rule)
  end)

  it("rejects a free-form header", function()
    local result = lint.lint("updated stuff")
    assert.is_false(result.ok)
    assert.equal("header-format", result.violations[1].rule)
  end)

  it("rejects an unknown type", function()
    local result = lint.lint("wip: try something")
    assert.is_false(result.ok)
    assert.equal("type-enum", result.violations[1].rule)
  end)

  it("rejects an uppercase type", function()
    local result = lint.lint("Feat: add parser")
    assert.is_false(result.ok)
    assert.equal("type-case", result.violations[1].rule)
  end)

  it("rejects an empty subject", function()
    local result = lint.lint("feat:")
    assert.is_false(result.ok)
    local rules = {}
    for i = 1, #result.violations do
      rules[result.violations[i].rule] = true
    end
    assert.is_true(rules["subject-empty"])
  end)

  it("rejects a subject that starts with a capital letter", function()
    local result = lint.lint("feat: Add parser")
    assert.is_false(result.ok)
    assert.equal("subject-case", result.violations[1].rule)
  end)

  it("rejects a trailing period in the subject", function()
    local result = lint.lint("feat: add parser.")
    assert.is_false(result.ok)
    assert.equal("subject-full-stop", result.violations[1].rule)
  end)

  it("rejects a header longer than 72 characters", function()
    local result = lint.lint("feat: " .. string.rep("a", 70))
    assert.is_false(result.ok)
    assert.equal("header-max-length", result.violations[1].rule)
  end)

  it("requires a blank line before the body", function()
    local result = lint.lint("feat: add parser\nmore detail")
    assert.is_false(result.ok)
    assert.equal("body-leading-blank", result.violations[1].rule)
  end)

  it("accepts a body after a blank line", function()
    local result = lint.lint("feat: add parser\n\nmore detail")
    assert.is_true(result.ok)
  end)

  it("ignores merge commits", function()
    local result = lint.lint("Merge pull request #12 from vgraman0/glinter")
    assert.is_true(result.ok)
    assert.is_true(result.ignored)
  end)
end)
