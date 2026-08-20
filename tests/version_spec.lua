local version = require("glinter.version")

set_current("version")
is_true(version:match("^%d+%.%d+%.%d+$") ~= nil, "version is MAJOR.MINOR.PATCH")
eq(require("glinter").version, version, "the module exposes the version")

-- A release is a tag, a version, and a changelog entry. Keep them together.
do
  local src = debug.getinfo(1, "S").source:sub(2)
  local root = (src:match("(.+)/") or ".") .. "/.."
  local f = io.open(root .. "/CHANGELOG.md", "r")
  is_true(f ~= nil, "CHANGELOG.md exists")
  if f then
    local text = f:read("*a") or ""
    f:close()
    local heading = "## [" .. version .. "]"
    is_true(text:find(heading, 1, true) ~= nil, "CHANGELOG.md has " .. heading)
  end
end
