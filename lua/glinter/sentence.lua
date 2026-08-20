local util = require("glinter.util")
local words = require("glinter.cbeams_words")

local M = {}

local function is_sentence_end(text, i)
  local ch = text:sub(i, i)
  if ch ~= "." and ch ~= "!" and ch ~= "?" then
    return false
  end
  if ch == "." then
    local after = text:sub(i + 1, i + 1)
    if after:find("%a") then
      return false
    end
    local start = i
    while start > 1 and text:sub(start - 1, start - 1):find("%S") do
      start = start - 1
    end
    local tok = util.lower_ascii(text:sub(start, i))
    if words.abbreviations[tok] then
      return false
    end
  end
  local rest = text:sub(i + 1)
  if rest:find("^%s*$") or rest:find("^%s") then
    return true
  end
  return false
end

function M.iter(concat)
  local sentences = {}
  local start = 1
  local i = 1
  local n = #concat
  while i <= n do
    if is_sentence_end(concat, i) then
      local s = concat:sub(start, i)
      if s:find("%S") then
        sentences[#sentences + 1] = { start = start, finish = i, text = s }
      end
      i = i + 1
      while i <= n and concat:sub(i, i):find("%s") do
        i = i + 1
      end
      start = i
    else
      i = i + 1
    end
  end
  if start <= n then
    local s = concat:sub(start, n)
    if s:find("%S") then
      sentences[#sentences + 1] = { start = start, finish = n, text = s }
    end
  end
  return sentences
end

-- Map sentences in `spans` to buffer ranges. end_col is exclusive.
function M.ranges(parsed, spans)
  local out = {}
  if #spans == 0 then
    return out
  end
  local pieces, concat = util.assemble_pieces(spans)
  local sentences = M.iter(concat)
  for i = 1, #sentences do
    local sent = sentences[i]
    local slnum, scol = util.offset_to_pos(pieces, sent.start)
    local elnum, ecol = util.offset_to_pos(pieces, sent.finish)
    ecol = ecol + 1
    local last_line = parsed.raw_lines[elnum + 1] or ""
    if ecol > #last_line then
      ecol = #last_line
    end
    out[#out + 1] = {
      text = sent.text,
      lnum = slnum,
      col = scol,
      end_lnum = elnum,
      end_col = ecol,
    }
  end
  return out
end

return M
