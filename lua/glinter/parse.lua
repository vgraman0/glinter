local util = require("glinter.util")

local M = {}

local KIND_COMMENT = "comment"
local KIND_IGNORED = "ignored"
local KIND_LEAD = "lead_blank"
local KIND_SUBJECT = "subject"
local KIND_BLANK = "blank"
local KIND_BODY = "body"
local KIND_TRAILER = "trailer"

local function is_comment_line(line, comment_char)
  return line:sub(1, 1) == comment_char
end

local function find_scissors(lines)
  for i = 1, #lines do
    if util.is_scissors(lines[i]) then
      return i
    end
  end
  return nil
end

-- Message lines: { index = 1-based raw index, lnum = 0-based, text }
local function message_lines(lines, kinds)
  local msg = {}
  for i = 1, #lines do
    if kinds[i] ~= KIND_COMMENT and kinds[i] ~= KIND_IGNORED then
      msg[#msg + 1] = { index = i, lnum = i - 1, text = lines[i] }
    end
  end
  return msg
end

local function first_non_empty(msg)
  for i = 1, #msg do
    if not util.is_blank(msg[i].text) then
      return i
    end
  end
  return nil
end

local function last_non_empty(msg)
  for i = #msg, 1, -1 do
    if not util.is_blank(msg[i].text) then
      return i
    end
  end
  return nil
end

-- Trailer block: trailing trailer-shaped lines, with blank lines allowed
-- only inside/after that block.
local function trailer_start(msg, first_i, last_i)
  if not last_i or last_i < first_i then
    return nil
  end
  if not util.is_trailer(msg[last_i].text) then
    return nil
  end
  local i = last_i
  while i >= first_i do
    local text = msg[i].text
    if util.is_blank(text) or util.is_trailer(text) then
      i = i - 1
    else
      break
    end
  end
  local start = i + 1
  while start <= last_i and util.is_blank(msg[start].text) do
    start = start + 1
  end
  if start <= last_i and util.is_trailer(msg[start].text) then
    return start
  end
  return nil
end

function M.classify(text, opts)
  opts = opts or {}
  -- false disables comment stripping (committed messages, --range).
  local comment_char = opts.comment_char
  if comment_char == nil then
    comment_char = "#"
  end
  local lines = util.split_lines(text)
  local kinds = {}
  local scissors = find_scissors(lines)

  for i = 1, #lines do
    if scissors and i >= scissors then
      kinds[i] = KIND_IGNORED
    elseif comment_char and is_comment_line(lines[i], comment_char) then
      kinds[i] = KIND_COMMENT
    else
      kinds[i] = KIND_BODY
    end
  end

  local msg = message_lines(lines, kinds)
  local first_i = first_non_empty(msg)
  local last_i = last_non_empty(msg)

  local subject = nil
  local generated = false
  local body_lines = {}
  local trailer_lines = {}
  local has_body = false
  local missing_blank = false

  if first_i then
    for i = 1, first_i - 1 do
      kinds[msg[i].index] = KIND_LEAD
    end
    local sub = msg[first_i]
    kinds[sub.index] = KIND_SUBJECT
    subject = { lnum = sub.lnum, text = sub.text }
    generated = util.is_generated_subject(sub.text)

    local tstart = trailer_start(msg, first_i, last_i)

    local after = first_i + 1
    if after <= (last_i or first_i) then
      local next_msg = msg[after]
      if util.is_blank(next_msg.text) then
        kinds[next_msg.index] = KIND_BLANK
      else
        -- Body (or trailer) starts immediately. That is S1 if there is
        -- any remaining non-empty content that is not absorbed... if the
        -- next non-empty is a trailer-only message with no prose body,
        -- Git still wants a blank line before trailers when they follow
        -- a subject. Treat any content after the subject as a body for S1.
        missing_blank = true
      end
    end

    for i = first_i + 1, #msg do
      if last_i and i > last_i then
        kinds[msg[i].index] = KIND_LEAD -- trailing blanks; unused
      elseif tstart and i >= tstart then
        kinds[msg[i].index] = KIND_TRAILER
        trailer_lines[#trailer_lines + 1] = {
          lnum = msg[i].lnum,
          text = msg[i].text,
        }
      elseif i == first_i + 1 and util.is_blank(msg[i].text) then
        kinds[msg[i].index] = KIND_BLANK
      else
        kinds[msg[i].index] = KIND_BODY
        body_lines[#body_lines + 1] = {
          lnum = msg[i].lnum,
          text = msg[i].text,
        }
        if not util.is_blank(msg[i].text) then
          has_body = true
        end
      end
    end

    -- Trailers count as a body for S1 (they are extra content).
    if #trailer_lines > 0 then
      has_body = true
    end
  end

  local prose = {}
  if subject then
    prose[#prose + 1] = { lnum = subject.lnum, text = subject.text }
  end
  for i = 1, #body_lines do
    prose[#prose + 1] = body_lines[i]
  end

  return {
    raw_lines = lines,
    kinds = kinds,
    comment_char = comment_char,
    scissors_index = scissors,
    subject = subject,
    generated = generated,
    body_lines = body_lines,
    trailer_lines = trailer_lines,
    has_body = has_body,
    missing_blank = missing_blank,
    prose = prose,
  }
end

M.KIND_COMMENT = KIND_COMMENT
M.KIND_IGNORED = KIND_IGNORED
M.KIND_LEAD = KIND_LEAD
M.KIND_SUBJECT = KIND_SUBJECT
M.KIND_BLANK = KIND_BLANK
M.KIND_BODY = KIND_BODY
M.KIND_TRAILER = KIND_TRAILER

return M
