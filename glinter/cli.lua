local lint = require("glinter.lint")
local report = require("glinter.report")
local hook = require("glinter.hook")

local cli = {}

cli.VERSION = "0.1.0"

local USAGE = [[
glinter — write better commit messages. Instant feedback.

Usage:
  glinter lint [message]
  glinter lint --file <path>
  glinter hook install [--path <repo>]
  glinter hook uninstall [--path <repo>]
  glinter --help
  glinter --version

Lint a message from an argument, a file (including .git/COMMIT_EDITMSG),
or stdin. Exit status is 0 on success, 1 when the message fails lint.
]]

local function write_out(text)
  io.stdout:write(text)
end

local function write_err(text)
  io.stderr:write(text)
end

local function read_file(path)
  local file, err = io.open(path, "r")
  if not file then
    return nil, err
  end
  local contents = file:read("*a")
  file:close()
  return contents
end

local function read_stdin()
  return io.read("*a") or ""
end

local function parse_args(argv)
  local opts = {
    command = nil,
    message = nil,
    file = nil,
    repo = nil,
    no_color = false,
    help = false,
    version = false,
  }
  local i = 1
  while i <= #argv do
    local arg = argv[i]
    if arg == "--help" or arg == "-h" then
      opts.help = true
    elseif arg == "--version" or arg == "-v" then
      opts.version = true
    elseif arg == "--no-color" then
      opts.no_color = true
    elseif arg == "--file" or arg == "-f" then
      i = i + 1
      opts.file = argv[i]
      if not opts.file then
        return nil, "--file requires a path"
      end
    elseif arg == "--path" then
      i = i + 1
      opts.repo = argv[i]
      if not opts.repo then
        return nil, "--path requires a directory"
      end
    elseif arg:sub(1, 1) == "-" then
      return nil, "unknown option: " .. arg
    elseif not opts.command then
      opts.command = arg
    elseif opts.command == "lint" and not opts.message then
      opts.message = arg
    elseif (opts.command == "hook") and not opts.subcommand then
      opts.subcommand = arg
    else
      return nil, "unexpected argument: " .. arg
    end
    i = i + 1
  end
  return opts
end

local function lint_message(message, opts)
  local result = lint.lint(message)
  write_out(report.render(result, opts))
  return result.ok and 0 or 1
end

function cli.main(argv)
  argv = argv or {}
  local opts, err = parse_args(argv)
  if not opts then
    write_err("glinter: " .. err .. "\n")
    write_err(USAGE)
    return 2
  end

  if opts.help or opts.command == "help" then
    write_out(USAGE)
    return 0
  end
  if opts.version then
    write_out("glinter " .. cli.VERSION .. "\n")
    return 0
  end

  if not opts.command then
    write_err(USAGE)
    return 2
  end

  if opts.command == "lint" then
    local message
    if opts.file then
      local contents, file_err = read_file(opts.file)
      if not contents then
        write_err("glinter: cannot read " .. opts.file .. ": " .. tostring(file_err) .. "\n")
        return 2
      end
      message = contents
    elseif opts.message then
      message = opts.message
    else
      message = read_stdin()
    end
    return lint_message(message, opts)
  end

  if opts.command == "hook" then
    if opts.subcommand == "install" then
      local path, hook_err = hook.install(opts.repo)
      if not path then
        write_err("glinter: " .. hook_err .. "\n")
        return 2
      end
      write_out("installed commit-msg hook at " .. path .. "\n")
      return 0
    end
    if opts.subcommand == "uninstall" then
      local path, hook_err = hook.uninstall(opts.repo)
      if not path then
        write_err("glinter: " .. hook_err .. "\n")
        return 2
      end
      write_out("removed commit-msg hook at " .. path .. "\n")
      return 0
    end
    write_err("glinter: hook expects `install` or `uninstall`\n")
    return 2
  end

  write_err("glinter: unknown command `" .. opts.command .. "`\n")
  write_err(USAGE)
  return 2
end

return cli
