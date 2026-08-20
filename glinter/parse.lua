-- Parse Conventional Commits messages.
-- https://www.conventionalcommits.org/en/v1.0.0/

local parse = {}

local function normalize_newlines(text)
  return (text:gsub("\r\n", "\n"):gsub("\r", "\n"))
end

local function parse_header(header)
  local type_, rest = header:match("^([%a][%w]*)(.*)$")
  if not type_ then
    return nil
  end

  local scope
  if rest:sub(1, 1) == "(" then
    local inner, after = rest:match("^%(([^%)]+)%)(.*)$")
    if not inner then
      return nil
    end
    scope = inner
    rest = after
  end

  local breaking = false
  if rest:sub(1, 1) == "!" then
    breaking = true
    rest = rest:sub(2)
  end

  if rest:sub(1, 1) ~= ":" then
    return nil
  end

  return type_, scope, breaking, rest:sub(2)
end

local function trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_sections(raw)
  raw = normalize_newlines(raw)
  raw = raw:gsub("\n+$", "")
  local header, rest = raw:match("^(.-)\n\n(.*)$")
  if header then
    return header, rest, true
  end
  local first, more = raw:match("^(.-)\n(.*)$")
  if first then
    if more:match("^%s*$") then
      return first, nil, false
    end
    return first, more, false
  end
  return raw, nil, false
end

function parse.is_ignored(message)
  local header = normalize_newlines(message):match("^[^\n]*") or ""
  if header:match("^Merge ") then
    return true
  end
  if header:match("^Revert \"") then
    return true
  end
  if header:match("^v?%d+%.%d+%.%d+") then
    return true
  end
  return false
end

function parse.parse(message)
  message = message or ""
  local header, rest, blank_after_header = split_sections(message)
  local commit = {
    raw = message,
    header = header,
    body = rest,
    blank_after_header = blank_after_header,
    type = nil,
    scope = nil,
    breaking = false,
    subject = nil,
    valid_header = false,
    space_after_colon = false,
  }

  local type_, scope, breaking, after_colon = parse_header(header)
  if not type_ then
    return commit
  end

  commit.valid_header = true
  commit.type = type_
  commit.scope = scope
  commit.breaking = breaking
  after_colon = after_colon or ""
  if after_colon:sub(1, 1) == " " then
    commit.space_after_colon = true
    commit.subject = after_colon:sub(2)
  else
    commit.subject = after_colon
  end
  commit.subject = trim(commit.subject or "")
  return commit
end

return parse
