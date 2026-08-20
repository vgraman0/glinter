local rules = require("glinter.rules")

local M = {}

local ns = nil
local timer = nil
local attached = {}
local config = {
  debounce_ms = 40,
  colorcolumn = true,
}

local GROUPS = {
  S0 = "GlinterError",
  S1 = "GlinterError",
  S2 = "GlinterSubjectSoft",
  S3 = "GlinterSubjectHard",
  S4 = "GlinterError",
  S5 = "GlinterError",
  S6 = "GlinterWarning",
  S7 = "GlinterWarning",
  B1 = "GlinterSubjectHard",
  C1 = "GlinterWarning",
  H1 = "GlinterHard",
  H2 = "GlinterVeryHard",
  H3 = "GlinterAdverb",
  H4 = "GlinterPassive",
  H5 = "GlinterQualifier",
  H6 = "GlinterComplex",
}

local PRIORITY = {
  H1 = 50,
  H2 = 60,
  C1 = 70,
  S2 = 100,
  S3 = 110,
  B1 = 110,
  H3 = 150,
  H4 = 150,
  H5 = 150,
  H6 = 160,
  S6 = 180,
  S7 = 180,
  S0 = 200,
  S1 = 200,
  S4 = 200,
  S5 = 200,
}

-- Pastel Hemingway backgrounds with a dark foreground so light theme
-- text does not wash out on yellow/red/blue spans.
local INK = "#1b1b1b"
local INK_CTERM = 232

local function define_highlights()
  local set = vim.api.nvim_set_hl
  local function paint(name, bg, ctermbg)
    set(0, name, {
      default = true,
      fg = INK,
      ctermfg = INK_CTERM,
      bg = bg,
      ctermbg = ctermbg,
    })
  end
  paint("GlinterHard", "#ffe082", 222)
  paint("GlinterVeryHard", "#ff8a80", 210)
  paint("GlinterAdverb", "#90caf9", 117)
  paint("GlinterQualifier", "#90caf9", 117)
  paint("GlinterPassive", "#a5d6a7", 151)
  paint("GlinterComplex", "#ce93d8", 183)
  paint("GlinterSubjectSoft", "#ffe082", 222)
  paint("GlinterSubjectHard", "#ff8a80", 210)
  paint("GlinterError", "#ff8a80", 210)
  paint("GlinterWarning", "#ffe082", 222)
  set(0, "GlinterReplacement", {
    default = true,
    italic = true,
    fg = "#4a148c",
    ctermfg = 53,
    bg = "#f3e5f5",
    ctermbg = 183,
  })
end

local function comment_char(lines)
  for i = 1, #lines do
    if require("glinter.util").is_scissors(lines[i]) then
      return lines[i]:sub(1, 1)
    end
  end
  return "#"
end

local function replacements_by_line(diags)
  local by = {}
  for i = 1, #diags do
    local d = diags[i]
    if d.replacement then
      local l = d.lnum
      by[l] = by[l] or {}
      by[l][#by[l] + 1] = d.replacement
    end
  end
  local shown = {}
  for lnum, list in pairs(by) do
    local parts = {}
    local seen = {}
    for i = 1, #list do
      local r = list[i]
      if not seen[r] then
        seen[r] = true
        parts[#parts + 1] = r
      end
    end
    shown[lnum] = " → " .. table.concat(parts, ", ")
  end
  return shown
end

function M.refresh(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local text = table.concat(lines, "\n")
  local diags = rules.lint(text, { comment_char = comment_char(lines) })
  local virt = replacements_by_line(diags)
  local virt_used = {}

  for i = 1, #diags do
    local d = diags[i]
    local line = lines[d.lnum + 1] or ""
    local col = d.col or 0
    local end_row = d.end_lnum or d.lnum
    local end_col = d.end_col or col
    if col > #line then
      col = #line
    end
    local end_line = lines[end_row + 1] or ""
    if end_col > #end_line then
      end_col = #end_line
    end
    if end_row == d.lnum and end_col < col then
      end_col = col
    end

    local opts = {
      end_row = end_row,
      end_col = end_col,
      hl_group = GROUPS[d.rule] or "GlinterWarning",
      hl_mode = "replace",
      priority = PRIORITY[d.rule] or 100,
    }
    if #line == 0 and d.lnum == end_row then
      opts.hl_eol = true
      opts.virt_text = { { " " .. (d.message or d.rule), opts.hl_group } }
      opts.virt_text_pos = "eol"
    elseif virt[d.lnum] and not virt_used[d.lnum] then
      opts.virt_text = { { virt[d.lnum], "GlinterReplacement" } }
      opts.virt_text_pos = "eol"
      virt_used[d.lnum] = true
    end

    pcall(vim.api.nvim_buf_set_extmark, buf, ns, d.lnum, col, opts)
  end
end

local function schedule(buf)
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  timer = vim.loop.new_timer()
  timer:start(config.debounce_ms, 0, vim.schedule_wrap(function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
    M.refresh(buf)
  end))
end

function M.attach(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if attached[buf] then
    M.refresh(buf)
    return
  end
  attached[buf] = true
  if config.colorcolumn then
    vim.api.nvim_buf_call(buf, function()
      vim.opt_local.colorcolumn = "51,73"
    end)
  end
  local group = vim.api.nvim_create_augroup("GlinterBuf" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({
    "TextChanged",
    "TextChangedI",
    "TextChangedP",
    "BufEnter",
    "InsertLeave",
  }, {
    group = group,
    buffer = buf,
    callback = function()
      schedule(buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function()
      attached[buf] = nil
    end,
  })
  M.refresh(buf)
end

function M.setup(opts)
  opts = opts or {}
  if opts.debounce_ms then
    config.debounce_ms = opts.debounce_ms
  end
  if opts.colorcolumn ~= nil then
    config.colorcolumn = opts.colorcolumn
  end
  if ns then
    return
  end
  ns = vim.api.nvim_create_namespace("glinter")
  define_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("GlinterColors", { clear = true }),
    callback = define_highlights,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("Glinter", { clear = true }),
    pattern = "gitcommit",
    callback = function(ev)
      M.attach(ev.buf)
    end,
  })
  vim.api.nvim_create_user_command("GlinterRefresh", function()
    M.refresh()
  end, {})
  if vim.bo.filetype == "gitcommit" then
    M.attach(0)
  end
end

M.namespace = function()
  return ns
end

return M
