-- Headless Neovim check: live extmarks land on message text only.
local function here()
  local src = debug.getinfo(1, "S").source:sub(2)
  return src:match("(.+)/") or "."
end

local root = vim.fn.fnamemodify(here() .. "/..", ":p")
vim.opt.runtimepath:prepend(root)
package.path = root .. "lua/?.lua;" .. root .. "lua/?/init.lua;" .. package.path

require("glinter").setup({ debounce_ms = 0, colorcolumn = false })

local failed = 0
local function check(cond, msg)
  if not cond then
    failed = failed + 1
    io.stderr:write("FAIL  nvim: " .. msg .. "\n")
  end
end

local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "fixed the really long thing.",
  "# Please enter the commit message.",
  "# really utilize this comment",
})
vim.bo[buf].filetype = "gitcommit"
vim.api.nvim_set_current_buf(buf)
require("glinter.highlight").attach(buf)
require("glinter.highlight").refresh(buf)

local ns = require("glinter.highlight").namespace()
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
check(#marks > 0, "extmarks created")

local hit_comment = false
local hit_subject = false
for i = 1, #marks do
  local m = marks[i]
  local row = m[2]
  if row >= 1 then
    hit_comment = true
  end
  if row == 0 then
    hit_subject = true
  end
end
check(hit_subject, "subject has highlights")
check(not hit_comment, "comments and later lines have no highlights")

-- Insert-mode style edit: crossing 50 characters must not highlight.
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "Fix " .. string.rep("a", 47),
})
require("glinter.highlight").refresh(buf)
marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
check(#marks == 0, "51-character subject has no highlights")

-- Crossing 72 characters must highlight.
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "Fix " .. string.rep("a", 69),
})
require("glinter.highlight").refresh(buf)
marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
local found_s3 = false
for i = 1, #marks do
  local m = marks[i]
  if m[2] == 0 and m[3] == 72 then
    found_s3 = true
  end
end
check(found_s3, "73rd character highlighted at col 72")

local hard = vim.api.nvim_get_hl(0, { name = "GlinterHard" })
check(hard.fg ~= nil, "GlinterHard sets a foreground")
check(hard.bg ~= nil, "GlinterHard sets a background")
local hl_mode
for i = 1, #marks do
  local details = marks[i][4]
  if details and details.hl_mode then
    hl_mode = details.hl_mode
    break
  end
end
check(hl_mode == "replace" or hl_mode == nil, "highlights replace theme foreground")

-- Hover shows the rule id and recommendation under the cursor.
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "Fix the really bad wrap",
})
require("glinter.highlight").refresh(buf)
-- "really" starts at byte 8: "Fix the "
vim.api.nvim_win_set_cursor(0, { 1, 8 })
local hover = require("glinter.hover")
local win = hover.show(buf)
check(win ~= nil and vim.api.nvim_win_is_valid(win), "hover window opens")
if win and vim.api.nvim_win_is_valid(win) then
  local fbuf = vim.api.nvim_win_get_buf(win)
  local text = table.concat(vim.api.nvim_buf_get_lines(fbuf, 0, -1, false), "\n")
  check(text:find("%[H3%]", 1) ~= nil, "hover names H3")
  check(text:find("stronger verb", 1, true) ~= nil, "hover shows adverb advice")
end

-- Insert-mode cursor sits on the exclusive end after the last character.
vim.api.nvim_win_set_cursor(0, { 1, 8 + #"really" })
win = hover.show(buf)
check(win ~= nil and vim.api.nvim_win_is_valid(win), "hover opens at insert cursor after span")

vim.api.nvim_win_set_cursor(0, { 1, 0 })
win = hover.show(buf)
check(win == nil, "hover closes off a highlight")

-- doc/glinter.txt: helptags has to build, and :help glinter has to land.
local doc = root .. "doc"
vim.fn.delete(doc .. "/tags")
local tagged = pcall(vim.cmd, "helptags " .. vim.fn.fnameescape(doc))
check(tagged, "helptags builds doc/glinter.txt")

local tags = {}
for _, entry in ipairs(vim.fn.readfile(doc .. "/tags")) do
  tags[entry:match("^[^\t]+")] = true
end
for _, want in ipairs({
  "glinter",
  "glinter-config",
  "glinter.setup()",
  ":GlinterHover",
}) do
  check(tags[want], "doc tags include " .. want)
end

check(pcall(vim.cmd, "help glinter"), ":help glinter opens")
check(vim.bo.filetype == "help", ":help glinter opens a help buffer")
vim.fn.delete(doc .. "/tags")

io.stdout:write(string.format("nvim highlight checks done, %d failed\n", failed))
if failed > 0 then
  os.exit(1)
end
os.exit(0)
