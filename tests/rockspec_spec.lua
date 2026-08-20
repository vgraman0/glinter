-- The rockspec template is filled in by CI, so nothing else would catch a
-- typo in it until a tag is already pushed. Render it here with stand-in
-- values, load it, and check what the rock installs.
local function here()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("(.+)/") or "."
end

set_current("rockspec")

-- Every placeholder the action fills in. An unknown one fails the test.
-- The template quotes some of these itself, so those stand-ins are bare.
local stand_ins = {
  git_ref = "v0.1.0",
  modrev = "0.1.0",
  specrev = "1",
  repo_url = "https://github.com/vgraman0/glinter",
  package = "glinter",
  summary = "Live highlighting for git commit messages.",
  homepage = "https://github.com/vgraman0/glinter",
  repo_name = "glinter",
  archive_dir_suffix = "0.1.0",
  detailed_description = "[[Longer text.]]",
  labels = "{ 'neovim' }",
  license = "license = 'MIT'",
  dependencies = "{ 'lua >= 5.1' }",
  test_dependencies = "{}",
  copy_directories = "{ 'doc', 'plugin' }",
}

local f = io.open(here() .. "/../rockspec.template", "r")
is_true(f ~= nil, "rockspec.template exists")
if f then
  local text = f:read("*a") or ""
  f:close()

  local unknown = {}
  local rendered = text:gsub("%$([%a_][%w_]*)", function(name)
    local value = stand_ins[name]
    if not value then
      unknown[#unknown + 1] = name
      return "nil"
    end
    return value
  end)
  eq(table.concat(unknown, ","), "", "template uses only known placeholders")

  local env = {}
  local chunk, err = load(rendered, "rockspec", "t", env)
  is_true(chunk ~= nil, "rendered rockspec parses: " .. tostring(err))
  if chunk then
    local ok, run_err = pcall(chunk)
    is_true(ok, "rendered rockspec runs: " .. tostring(run_err))
    eq(env.package, "glinter", "package name")
    eq(env.version, "0.1.0-1", "version joins modrev and specrev")
    eq(env.rockspec_format, "3.0", "rockspec format")
    eq(env.build and env.build.type, "builtin", "builtin build")
    local bin = env.build and env.build.install and env.build.install.bin
    eq(bin and bin.glinter, "bin/glinter.lua", "installs the glinter command")
  end
end

-- The rock installs what the rockspec names, so the file has to be there.
do
  local script = io.open(here() .. "/../bin/glinter.lua", "r")
  is_true(script ~= nil, "bin/glinter.lua exists")
  if script then
    script:close()
  end
end
