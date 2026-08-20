local parse = require("glinter.parse")

local lint = {}

local TYPES = {
  build = true,
  chore = true,
  ci = true,
  docs = true,
  feat = true,
  fix = true,
  perf = true,
  refactor = true,
  revert = true,
  style = true,
  test = true,
}

local TYPE_LIST = {
  "build", "chore", "ci", "docs", "feat", "fix",
  "perf", "refactor", "revert", "style", "test",
}

local HEADER_MAX = 72

local function violation(rule, message, hint)
  return {
    rule = rule,
    message = message,
    hint = hint,
  }
end

function lint.allowed_types()
  return TYPE_LIST
end

function lint.lint(message)
  if parse.is_ignored(message) then
    return {
      ok = true,
      ignored = true,
      violations = {},
      commit = parse.parse(message),
    }
  end

  local trimmed = (message or ""):gsub("^%s+", ""):gsub("%s+$", "")
  local commit = parse.parse(message)
  local violations = {}

  if trimmed == "" then
    violations[#violations + 1] = violation(
      "message-empty",
      "commit message is empty",
      "Use Conventional Commits, for example: feat: add parser"
    )
    return { ok = false, ignored = false, violations = violations, commit = commit }
  end

  if not commit.valid_header then
    violations[#violations + 1] = violation(
      "header-format",
      "header must be `type(scope)?: subject`",
      "Example: feat(cli): add lint command"
    )
    return { ok = false, ignored = false, violations = violations, commit = commit }
  end

  if not commit.space_after_colon then
    violations[#violations + 1] = violation(
      "header-format",
      "missing space after the colon in the header",
      "Write `" .. commit.type .. ": " .. (commit.subject ~= "" and commit.subject or "subject") .. "`"
    )
  end

  if not TYPES[commit.type:lower()] then
    violations[#violations + 1] = violation(
      "type-enum",
      "type `" .. commit.type .. "` is not allowed",
      "Use one of: " .. table.concat(TYPE_LIST, ", ")
    )
  elseif commit.type ~= commit.type:lower() then
    violations[#violations + 1] = violation(
      "type-case",
      "type must be lowercase",
      "Use `" .. commit.type:lower() .. "` instead of `" .. commit.type .. "`"
    )
  end

  if commit.subject == "" then
    violations[#violations + 1] = violation(
      "subject-empty",
      "subject must not be empty",
      "Describe what changed, for example: feat: add conventional commit parser"
    )
  else
    local first = commit.subject:sub(1, 1)
    if first:match("%u") then
      violations[#violations + 1] = violation(
        "subject-case",
        "subject must not start with an uppercase letter",
        "Use `" .. first:lower() .. commit.subject:sub(2) .. "`"
      )
    end
    if commit.subject:sub(-1) == "." then
      violations[#violations + 1] = violation(
        "subject-full-stop",
        "subject must not end with a period",
        "Drop the trailing `.`"
      )
    end
  end

  if #commit.header > HEADER_MAX then
    violations[#violations + 1] = violation(
      "header-max-length",
      "header is " .. #commit.header .. " characters (max " .. HEADER_MAX .. ")",
      "Keep the first line short; move detail into the body"
    )
  end

  if commit.body and not commit.blank_after_header then
    violations[#violations + 1] = violation(
      "body-leading-blank",
      "body must be separated from the header by a blank line",
      "Insert an empty line after the subject"
    )
  end

  return {
    ok = #violations == 0,
    ignored = false,
    violations = violations,
    commit = commit,
  }
end

return lint
