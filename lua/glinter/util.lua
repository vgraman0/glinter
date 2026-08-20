local M = {}

function M.split_lines(text)
  local lines = {}
  if text == nil then
    return { "" }
  end
  local start = 1
  local i = 1
  local n = #text
  while i <= n do
    local b = text:byte(i)
    if b == 13 then
      lines[#lines + 1] = text:sub(start, i - 1)
      if text:byte(i + 1) == 10 then
        i = i + 2
      else
        i = i + 1
      end
      start = i
    elseif b == 10 then
      lines[#lines + 1] = text:sub(start, i - 1)
      i = i + 1
      start = i
    else
      i = i + 1
    end
  end
  lines[#lines + 1] = text:sub(start)
  return lines
end

function M.lower_ascii(s)
  return (s:gsub("%u", function(c)
    return string.char(c:byte() + 32)
  end))
end

-- Number of UTF-8 codepoints.
function M.char_len(s)
  local n = 0
  local i = 1
  local len = #s
  while i <= len do
    local c = s:byte(i)
    if not c then
      break
    elseif c < 128 then
      i = i + 1
    elseif c < 224 then
      i = i + 2
    elseif c < 240 then
      i = i + 3
    else
      i = i + 4
    end
    n = n + 1
  end
  return n
end

-- 0-based character index -> 0-based byte offset (start of that character).
-- If char_index >= char_len, returns #s.
function M.char_to_byte(s, char_index)
  if char_index <= 0 then
    return 0
  end
  local n = 0
  local i = 1
  local len = #s
  while i <= len do
    if n == char_index then
      return i - 1
    end
    local c = s:byte(i)
    if c < 128 then
      i = i + 1
    elseif c < 224 then
      i = i + 2
    elseif c < 240 then
      i = i + 3
    else
      i = i + 4
    end
    n = n + 1
  end
  return len
end

function M.trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.is_blank(s)
  return s:find("%S") == nil
end

function M.first_word(s)
  return s:match("([^%s]+)")
end

local function is_word_byte(b)
  return (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end

-- Word-bounded, case-insensitive search for `needle` in `text`.
-- Returns 1-based inclusive start, finish of the original text.
function M.find_word(text, needle, from)
  from = from or 1
  local lower = M.lower_ascii(text)
  local n = M.lower_ascii(needle)
  local i = from
  while true do
    local s, e = lower:find(n, i, true)
    if not s then
      return nil
    end
    local before = s == 1 and 0 or text:byte(s - 1)
    local after = e == #text and 0 or text:byte(e + 1)
    local left_ok = before == 0 or not is_word_byte(before)
    local right_ok = after == 0 or not is_word_byte(after)
    if left_ok and right_ok then
      return s, e
    end
    i = s + 1
  end
end

function M.word_count(s)
  local n = 0
  for w in s:gmatch("%S+") do
    if w:find("%w") then
      n = n + 1
    end
  end
  return n
end

function M.is_url_line(s)
  local t = M.trim(s)
  return t:find("^https?://%S+$") ~= nil
end

function M.comment_chars()
  return {
    ["#"] = true,
    [";"] = true,
    ["@"] = true,
    ["!"] = true,
    ["$"] = true,
    ["%"] = true,
    ["^"] = true,
    ["&"] = true,
    ["|"] = true,
    [":"] = true,
  }
end

function M.is_scissors(line)
  if #line < 52 then
    return false
  end
  local c = line:sub(1, 1)
  if not M.comment_chars()[c] then
    return false
  end
  local a, b = line:sub(2):match("^ (%-+) >8 (%-+)$")
  return a and b and #a >= 24 and #b >= 24
end

function M.is_trailer(line)
  if line:find("^%(cherry picked from commit .+%)$") then
    return true
  end
  return line:find("^[%w%-]+%s*:") ~= nil
end

function M.starts_with(s, prefix)
  return s:sub(1, #prefix) == prefix
end

function M.is_generated_subject(subject)
  local s = subject
  if M.starts_with(s, "Merge ") then
    return true
  end
  if M.starts_with(s, "Revert ") then
    return true
  end
  local lower = M.lower_ascii(s)
  if M.starts_with(lower, "fixup! ") then
    return true
  end
  if M.starts_with(lower, "squash! ") then
    return true
  end
  if M.starts_with(lower, "amend! ") then
    return true
  end
  return false
end

-- Map a 1-based byte offset in concat(texts, "\n") to 0-based lnum/col.
function M.offset_to_pos(pieces, offset)
  for i = 1, #pieces do
    local p = pieces[i]
    local last = p.start + #p.text - 1
    if offset <= last then
      return p.lnum, offset - p.start
    end
    local nl = p.start + #p.text
    if offset == nl then
      return p.lnum, #p.text
    end
  end
  local last = pieces[#pieces]
  if not last then
    return 0, 0
  end
  return last.lnum, #last.text
end

function M.assemble_pieces(spans)
  local pieces = {}
  local pos = 1
  for i = 1, #spans do
    local span = spans[i]
    pieces[#pieces + 1] = {
      start = pos,
      lnum = span.lnum,
      text = span.text,
    }
    pos = pos + #span.text + 1
  end
  local texts = {}
  for i = 1, #spans do
    texts[i] = spans[i].text
  end
  return pieces, table.concat(texts, "\n")
end

return M
