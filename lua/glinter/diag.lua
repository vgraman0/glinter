local catalog = require("glinter.catalog")

local M = {}

function M.make(rule, parsed_range)
  local meta = catalog[rule]
  local d = parsed_range
  d.rule = rule
  d.name = meta.name
  d.severity = d.severity or meta.severity
  d.end_lnum = d.end_lnum or d.lnum
  d.col = d.col or 0
  d.end_col = d.end_col or d.col
  return d
end

function M.occupied(spans, lnum, col, end_col)
  for i = 1, #spans do
    local s = spans[i]
    if s.lnum == lnum and col < s.end_col and end_col > s.col then
      return true
    end
  end
  return false
end

function M.each_prose_line(parsed, fn)
  if parsed.generated then
    return
  end
  local util = require("glinter.util")
  for i = 1, #parsed.prose do
    local line = parsed.prose[i]
    if not util.is_url_line(line.text) then
      fn(line)
    end
  end
end

function M.sort(diags)
  table.sort(diags, function(a, b)
    if a.lnum ~= b.lnum then
      return a.lnum < b.lnum
    end
    if a.col ~= b.col then
      return a.col < b.col
    end
    return a.rule < b.rule
  end)
  return diags
end

return M
