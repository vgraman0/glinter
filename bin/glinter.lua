local function script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  local dir = src:match("(.+)/")
  return dir or "."
end

local root = script_dir() .. "/.."
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

-- nvim -l puts CLI args in `arg`; lua does too. Skip the script name.
local args = {}
local list = arg or {}
local start = 1
if list[0] and tostring(list[0]):find("glinter", 1, true) then
  start = 1
end
for i = start, #list do
  args[#args + 1] = list[i]
end

require("glinter.cli").run(args)
