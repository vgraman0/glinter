local rules = require("glinter.rules")

local M = {}

local function usage()
  io.stderr:write("Usage: glinter FILE\n")
  io.stderr:write("       glinter --stdin\n")
  io.stderr:write("       glinter --range REV\n")
  os.exit(2)
end

local function read_file(path)
  local f, err = io.open(path, "r")
  if not f then
    io.stderr:write("glinter: " .. err .. "\n")
    os.exit(2)
  end
  local text = f:read("*a") or ""
  f:close()
  return text
end

local function format_diag(filename, d)
  local sev = d.severity
  local line = d.lnum + 1
  local col = d.col + 1
  local extra = ""
  if d.replacement then
    extra = string.format(" (simpler: %s)", d.replacement)
  end
  return string.format(
    "%s:%d:%d: %s: [%s] %s%s",
    filename,
    line,
    col,
    sev,
    d.rule,
    d.message,
    extra
  )
end

local function print_diags(filename, text, opts)
  local diags = rules.lint(text, opts)
  for i = 1, #diags do
    io.stdout:write(format_diag(filename, diags[i]) .. "\n")
  end
  return #diags
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Lua 5.1 returns a numeric status; 5.2+ returns a boolean.
local function shell_ok(status)
  return status == true or status == 0
end

local function lint_range(range)
  local qrange = shell_quote(range)
  if not shell_ok(os.execute("git rev-list --quiet " .. qrange .. " >/dev/null 2>&1")) then
    io.stderr:write("glinter: git rev-list failed\n")
    os.exit(2)
  end
  local cmd = "git rev-list --reverse " .. qrange
  local h = io.popen(cmd, "r")
  if not h then
    io.stderr:write("glinter: could not run git rev-list\n")
    os.exit(2)
  end
  local shas = {}
  for line in h:lines() do
    if line ~= "" then
      shas[#shas + 1] = line
    end
  end
  if not shell_ok(h:close()) then
    io.stderr:write("glinter: git rev-list failed\n")
    os.exit(2)
  end
  local failed = 0
  for i = 1, #shas do
    local sha = shas[i]
    local mh = io.popen("git log -1 --format=%B " .. shell_quote(sha), "r")
    if not mh then
      io.stderr:write("glinter: could not run git log\n")
      os.exit(2)
    end
    local text = mh:read("*a") or ""
    if not shell_ok(mh:close()) then
      io.stderr:write("glinter: git log failed\n")
      os.exit(2)
    end
    -- Stored messages keep # headings / #123 refs; they are not git comments.
    local n = print_diags(sha:sub(1, 7), text, { comment_char = false })
    if n > 0 then
      failed = failed + 1
    end
  end
  return failed
end

function M.run(args)
  args = args or {}
  -- nvim -l and lua disagree about arg[0]; skip flags-only vs files.
  local i = 1
  if args[i] == nil and args[0] and args[0]:find("glinter") then
    i = 1
  end
  local mode = args[i]
  if not mode then
    usage()
  end
  local n
  if mode == "--help" or mode == "-h" then
    usage()
  elseif mode == "--stdin" then
    local text = io.stdin:read("*a") or ""
    n = print_diags("<stdin>", text)
  elseif mode == "--range" then
    local range = args[i + 1]
    if not range then
      usage()
    end
    n = lint_range(range)
  elseif mode:sub(1, 1) == "-" then
    usage()
  else
    n = print_diags(mode, read_file(mode))
  end
  if n > 0 then
    os.exit(1)
  end
end

return M
