-- Cursor hover: show rule id and recommendation for the span under the cursor.
local M = {}

local config = {
  delay_ms = 300,
}

local diags_by_buf = {}
local hover_win = nil
local hover_buf = nil
local timer = nil
local attached = {}

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

function M.update(buf, diags)
  diags_by_buf[buf] = diags or {}
end

function M.contains(d, row, col)
  local end_lnum = d.end_lnum or d.lnum
  local end_col = d.end_col or d.col
  if row < d.lnum or row > end_lnum then
    return false
  end
  if d.lnum == end_lnum then
    if end_col <= d.col then
      return col == d.col
    end
    -- end_col is exclusive; include it so insert-mode cursor after the span hits.
    return col >= d.col and col <= end_col
  end
  if row == d.lnum then
    return col >= d.col
  end
  if row == end_lnum then
    return col <= end_col
  end
  return true
end

function M.at_cursor(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local diags = diags_by_buf[buf]
  if not diags then
    return {}
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]
  local hits = {}
  for i = 1, #diags do
    if M.contains(diags[i], row, col) then
      hits[#hits + 1] = diags[i]
    end
  end
  table.sort(hits, function(a, b)
    local pa = PRIORITY[a.rule] or 0
    local pb = PRIORITY[b.rule] or 0
    if pa ~= pb then
      return pa > pb
    end
    return a.rule < b.rule
  end)
  return hits
end

local function format_line(d)
  local extra = ""
  if d.replacement then
    extra = " → " .. d.replacement
  end
  return string.format("[%s] %s%s", d.rule, d.message, extra)
end

function M.hide()
  if hover_win and vim.api.nvim_win_is_valid(hover_win) then
    pcall(vim.api.nvim_win_close, hover_win, true)
  end
  hover_win = nil
  hover_buf = nil
end

function M.show(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local hits = M.at_cursor(buf)
  if #hits == 0 then
    M.hide()
    return nil
  end
  local lines = {}
  local width = 8
  for i = 1, #hits do
    local line = format_line(hits[i])
    lines[i] = line
    if #line > width then
      width = #line
    end
  end
  if width > 80 then
    width = 80
  end
  M.hide()
  hover_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(hover_buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(hover_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(hover_buf, "bufhidden", "wipe")
  local ok, win = pcall(vim.api.nvim_open_win, hover_buf, false, {
    relative = "cursor",
    row = 1,
    col = 1,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
    noautocmd = true,
  })
  if not ok then
    hover_buf = nil
    return nil
  end
  hover_win = win
  vim.api.nvim_win_set_option(hover_win, "wrap", false)
  return hover_win
end

local function schedule(buf)
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  timer = vim.loop.new_timer()
  timer:start(config.delay_ms, 0, vim.schedule_wrap(function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
    if vim.api.nvim_get_current_buf() ~= buf then
      return
    end
    M.show(buf)
  end))
end

function M.attach(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if attached[buf] then
    return
  end
  attached[buf] = true
  local group = vim.api.nvim_create_augroup("GlinterHover" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      M.hide()
      schedule(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    group = group,
    buffer = buf,
    callback = function()
      M.hide()
    end,
  })
  vim.keymap.set("n", "K", function()
    M.show(buf)
  end, { buffer = buf, desc = "Glinter recommendation", silent = true })
end

function M.detach(buf)
  attached[buf] = nil
  diags_by_buf[buf] = nil
  M.hide()
end

function M.setup(opts)
  opts = opts or {}
  if opts.hover_ms then
    config.delay_ms = opts.hover_ms
  end
  if vim.g.glinter_hover_loaded then
    return
  end
  vim.g.glinter_hover_loaded = true
  vim.api.nvim_create_user_command("GlinterHover", function()
    M.show()
  end, {})
end

function M.window()
  return hover_win
end

return M
