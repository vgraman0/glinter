-- Tiny test runner. Loads every tests/*_spec.lua beside this file.
local function here()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("(.+)/") or "."
end

local root = here() .. "/.."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local passed = 0
local failed = 0
local current = "?"

local function fail(msg)
  failed = failed + 1
  io.stderr:write(string.format("FAIL  %s: %s\n", current, msg))
end

local function ok(msg)
  passed = passed + 1
  if os.getenv("GLINTER_VERBOSE") then
    io.stdout:write(string.format("ok    %s: %s\n", current, msg))
  end
end

function eq(a, b, msg)
  if a == b then
    ok(msg)
  else
    fail(string.format("%s: expected %s, got %s", msg, tostring(b), tostring(a)))
  end
end

function is_true(cond, msg)
  if cond then
    ok(msg)
  else
    fail(msg)
  end
end

function set_current(name)
  current = name
end

function rules_of(diags)
  local t = {}
  for i = 1, #diags do
    t[#t + 1] = diags[i].rule
  end
  return table.concat(t, ",")
end

function has_rule(diags, rule)
  for i = 1, #diags do
    if diags[i].rule == rule then
      return diags[i]
    end
  end
  return nil
end

function has_no_rule(diags, rule)
  return has_rule(diags, rule) == nil
end

local names = {
  "parse_spec.lua",
  "cbeams_spec.lua",
  "hemingway_spec.lua",
}
for i = 1, #names do
  local path = here() .. "/" .. names[i]
  local f = io.open(path, "r")
  if f then
    f:close()
    dofile(path)
  end
end

io.stdout:write(string.format("%d passed, %d failed\n", passed, failed))
if failed > 0 then
  os.exit(1)
end
