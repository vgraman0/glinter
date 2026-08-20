local hook = {}

local MARKER = "glinter commit-msg"

local function git_dir(repo)
  repo = repo or "."
  local command = string.format("git -C %q rev-parse --git-dir 2>/dev/null", repo)
  local pipe = io.popen(command)
  if not pipe then
    return nil, "unable to run git"
  end
  local dir = pipe:read("*l")
  local ok = pipe:close()
  if not ok or not dir or dir == "" then
    return nil, "not a git repository: " .. repo
  end
  if dir:sub(1, 1) ~= "/" then
    dir = repo:gsub("/+$", "") .. "/" .. dir
  end
  return dir
end

local function hook_path(repo)
  local dir, err = git_dir(repo)
  if not dir then
    return nil, err
  end
  return dir .. "/hooks/commit-msg"
end

local function script_root()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  local dir = src:match("^(.*)/") or "."
  local pipe = io.popen(string.format("cd %q && pwd", dir .. "/.."))
  if not pipe then
    return dir .. "/.."
  end
  local abs = pipe:read("*l")
  pipe:close()
  return abs or (dir .. "/..")
end

local function hook_body()
  local root = script_root()
  return table.concat({
    "#!/bin/sh",
    "# " .. MARKER,
    "ROOT=" .. string.format("%q", root),
    "export LUA_PATH=\"$ROOT/?.lua;$ROOT/?/init.lua;;\"",
    "exec lua \"$ROOT/bin/glinter\" lint --file \"$1\"",
    "",
  }, "\n")
end

function hook.install(repo)
  local path, err = hook_path(repo)
  if not path then
    return nil, err
  end
  local file, open_err = io.open(path, "w")
  if not file then
    return nil, "cannot write " .. path .. ": " .. tostring(open_err)
  end
  file:write(hook_body())
  file:close()
  os.execute(string.format("chmod +x %q", path))
  return path
end

function hook.uninstall(repo)
  local path, err = hook_path(repo)
  if not path then
    return nil, err
  end
  local file = io.open(path, "r")
  if not file then
    return nil, "no commit-msg hook at " .. path
  end
  local contents = file:read("*a")
  file:close()
  if not contents:find(MARKER, 1, true) then
    return nil, "commit-msg hook is not managed by glinter"
  end
  local ok, remove_err = os.remove(path)
  if not ok then
    return nil, "cannot remove " .. path .. ": " .. tostring(remove_err)
  end
  return path
end

return hook
