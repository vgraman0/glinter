-- :checkhealth glinter
-- Answers the usual "it does not work" questions: Neovim version, a git
-- work tree, and whether a commit-msg hook runs glinter.
local M = {}

local function reporter()
  local h = vim.health or require("health")
  return {
    start = h.start or h.report_start,
    ok = h.ok or h.report_ok,
    warn = h.warn or h.report_warn,
    error = h.error or h.report_error,
    info = h.info or h.report_info,
  }
end

local function git(args)
  local out = vim.fn.system(args)
  return vim.v.shell_error, vim.trim(out)
end

local function is_absolute(path)
  return path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
end

function M.nvim_version()
  local v = vim.version()
  return {
    major = v.major,
    minor = v.minor,
    patch = v.patch,
    supported = vim.fn.has("nvim-0.7") == 1,
  }
end

function M.git_toplevel()
  if vim.fn.executable("git") ~= 1 then
    return nil, "git is not on PATH"
  end
  local code, out = git({ "git", "rev-parse", "--show-toplevel" })
  if code ~= 0 then
    return nil, "not inside a git work tree"
  end
  return out, nil
end

function M.commit_msg_hook()
  local missing = { found = false, runs_glinter = false, path = nil }
  if vim.fn.executable("git") ~= 1 then
    return missing
  end
  local root = M.git_toplevel()
  if not root then
    return missing
  end
  local code, path = git({
    "git",
    "-C",
    root,
    "rev-parse",
    "--git-path",
    "hooks/commit-msg",
  })
  if code ~= 0 or path == "" then
    return missing
  end
  if not is_absolute(path) then
    path = root .. "/" .. path
  end
  path = vim.fn.fnamemodify(path, ":p")
  -- :p on a file keeps the trailing slash off; strip if a directory probe
  -- added one anyway.
  path = path:gsub("[/\\]+$", "")
  if vim.fn.filereadable(path) ~= 1 then
    return { found = false, runs_glinter = false, path = path }
  end
  local ok, lines = pcall(vim.fn.readfile, path)
  local text = ""
  if ok then
    text = table.concat(lines, "\n")
  end
  return {
    found = true,
    runs_glinter = text:find("glinter", 1, true) ~= nil,
    executable = vim.fn.executable(path) == 1,
    path = path,
  }
end

function M.check()
  local h = reporter()
  h.start("glinter")

  local ver = M.nvim_version()
  local ver_str = string.format("%d.%d.%d", ver.major, ver.minor, ver.patch)
  if ver.supported then
    h.ok("Neovim " .. ver_str .. " (need 0.7 or newer)")
  else
    h.error("Neovim " .. ver_str .. " is too old; glinter needs 0.7 or newer")
  end

  if vim.fn.executable("git") ~= 1 then
    h.error("git is not on PATH")
    h.info("Skip the work-tree and hook checks until git is installed")
    return
  end

  local root, err = M.git_toplevel()
  if not root then
    h.warn(err .. ". Highlighting still runs in a gitcommit buffer.")
    h.info("The commit-msg hook and `glinter --range` need a repository.")
    return
  end
  h.ok("Inside a git work tree: " .. root)

  local hook = M.commit_msg_hook()
  if hook.found and hook.runs_glinter then
    if vim.fn.has("win32") == 0 and hook.executable == false then
      h.warn(
        "commit-msg hook runs glinter but is not executable: " .. hook.path
      )
    else
      h.ok("commit-msg hook runs glinter: " .. hook.path)
    end
  elseif hook.found then
    h.info("commit-msg hook exists but does not run glinter: " .. hook.path)
    h.info("The plugin still highlights. To enforce on commit,")
    h.info("point the hook at bin/glinter.")
  else
    h.info("commit-msg hook is not installed (optional).")
    h.info("In a clone of glinter, `make hooks` points git at .githooks.")
  end
end

return M
