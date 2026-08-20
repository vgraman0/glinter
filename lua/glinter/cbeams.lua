local diag = require("glinter.diag")
local sentence = require("glinter.sentence")
local util = require("glinter.util")
local words = require("glinter.cbeams_words")

local M = {}

local SUBJECT_SOFT = 50
local SUBJECT_HARD = 72
local BODY_WRAP = 72

local function is_upper_start(s)
  local b = s:byte(1)
  if not b then
    return false
  end
  if b >= 65 and b <= 90 then
    return true
  end
  if b >= 128 then
    return true
  end
  return false
end

local function ends_with_punct(s)
  local last = s:sub(-1)
  return last == "." or last == "!" or last == "?"
end

local function gerund_first(word)
  local w = util.lower_ascii(word)
  w = w:gsub("%p+$", "")
  if words.imperative_ing[w] then
    return false
  end
  return #w >= 5 and w:sub(-3) == "ing"
end

local function first_how_verb(text)
  for w in text:gmatch("[A-Za-z']+") do
    local lw = util.lower_ascii(w)
    if words.how_verbs[lw] then
      return lw
    end
    if lw ~= "the" and lw ~= "a" and lw ~= "an" then
      return nil
    end
  end
  return nil
end

local function has_why_signal(text)
  for i = 1, #words.why_signals do
    if util.find_word(text, words.why_signals[i]) then
      return true
    end
  end
  return false
end

local function add_s0(out, parsed)
  if parsed.generated then
    return
  end
  if parsed.subject and not util.is_blank(parsed.subject.text) then
    return
  end
  local lnum = 0
  local text = ""
  if parsed.subject then
    lnum = parsed.subject.lnum
    text = parsed.subject.text
  end
  out[#out + 1] = diag.make("S0", {
    lnum = lnum,
    col = 0,
    end_col = #text,
    message = "Subject is empty",
  })
end

local function add_s1(out, parsed)
  if parsed.generated then
    return
  end
  if parsed.has_body and parsed.missing_blank then
    local first = parsed.body_lines[1] or parsed.trailer_lines[1]
    if not first then
      return
    end
    out[#out + 1] = diag.make("S1", {
      lnum = first.lnum,
      col = 0,
      end_col = #first.text,
      message = "Separate subject from body with a blank line",
    })
  end
end

local function add_s2_s3(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local text = parsed.subject.text
  local n = util.char_len(text)
  local lnum = parsed.subject.lnum
  if n > SUBJECT_HARD then
    local soft = util.char_to_byte(text, SUBJECT_SOFT)
    local hard = util.char_to_byte(text, SUBJECT_HARD)
    out[#out + 1] = diag.make("S2", {
      lnum = lnum,
      col = soft,
      end_col = hard,
      message = string.format(
        "Subject is %d characters; keep it to %d",
        n,
        SUBJECT_SOFT
      ),
    })
    out[#out + 1] = diag.make("S3", {
      lnum = lnum,
      col = hard,
      end_col = #text,
      message = string.format(
        "Subject is %d characters; keep it to %d",
        n,
        SUBJECT_HARD
      ),
    })
  elseif n > SUBJECT_SOFT then
    local soft = util.char_to_byte(text, SUBJECT_SOFT)
    out[#out + 1] = diag.make("S2", {
      lnum = lnum,
      col = soft,
      end_col = #text,
      message = string.format(
        "Subject is %d characters; keep it to %d",
        n,
        SUBJECT_SOFT
      ),
    })
  end
end

local function add_s4(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local text = parsed.subject.text
  if util.is_blank(text) then
    return
  end
  local first = text:sub(1, 1)
  if first:find("%s") then
    out[#out + 1] = diag.make("S4", {
      lnum = parsed.subject.lnum,
      col = 0,
      end_col = 1,
      message = "Subject must not start with a space",
    })
    return
  end
  if not is_upper_start(text) then
    out[#out + 1] = diag.make("S4", {
      lnum = parsed.subject.lnum,
      col = 0,
      end_col = util.char_to_byte(text, 1),
      message = "Capitalize the subject line",
    })
  end
end

local function add_s5(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local text = parsed.subject.text
  if util.is_blank(text) then
    return
  end
  if ends_with_punct(text) then
    out[#out + 1] = diag.make("S5", {
      lnum = parsed.subject.lnum,
      col = #text - 1,
      end_col = #text,
      message = "Do not end the subject line with punctuation",
    })
  end
end

local function add_s6(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local text = parsed.subject.text
  if util.is_blank(text) then
    return
  end
  local word = util.first_word(text)
  if not word then
    return
  end
  local bare = word:gsub("%p+$", "")
  local lower = util.lower_ascii(bare)
  local reason = nil
  if words.past_tense_first[lower] then
    reason = "Use the imperative mood in the subject line"
  elseif words.pronoun_first[lower] then
    reason = "Use the imperative mood in the subject line"
  elseif gerund_first(bare) then
    reason = "Use the imperative mood in the subject line"
  end
  if reason then
    local s, e = text:find(word, 1, true)
    out[#out + 1] = diag.make("S6", {
      lnum = parsed.subject.lnum,
      col = (s or 1) - 1,
      end_col = e or #word,
      message = reason,
    })
  end
end

local function add_s7(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local word = util.first_word(parsed.subject.text)
  if not word then
    return
  end
  local bare = util.lower_ascii(word:gsub("%p+$", ""))
  if bare == "wip" then
    local s, e = parsed.subject.text:find(word, 1, true)
    out[#out + 1] = diag.make("S7", {
      lnum = parsed.subject.lnum,
      col = (s or 1) - 1,
      end_col = e or #word,
      message = "Subject starts with WIP",
    })
  end
end

local function add_b1(out, parsed)
  if parsed.generated then
    return
  end
  for i = 1, #parsed.body_lines do
    local line = parsed.body_lines[i]
    if not util.is_url_line(line.text) then
      local n = util.char_len(line.text)
      if n > BODY_WRAP then
        out[#out + 1] = diag.make("B1", {
          lnum = line.lnum,
          col = util.char_to_byte(line.text, BODY_WRAP),
          end_col = #line.text,
          message = string.format(
            "Body line is %d characters; wrap at %d",
            n,
            BODY_WRAP
          ),
        })
      end
    end
  end
end

local function add_c1(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local ranges = sentence.ranges(parsed, parsed.body_lines)
  for i = 1, #ranges do
    local sent = ranges[i]
    if first_how_verb(sent.text) and not has_why_signal(sent.text) then
      out[#out + 1] = diag.make("C1", {
        lnum = sent.lnum,
        col = sent.col,
        end_lnum = sent.end_lnum,
        end_col = sent.end_col,
        message = "Use the body to explain why, not how",
      })
    end
  end
end

function M.apply(out, parsed)
  add_s0(out, parsed)
  add_s1(out, parsed)
  add_s2_s3(out, parsed)
  add_s4(out, parsed)
  add_s5(out, parsed)
  add_s6(out, parsed)
  add_s7(out, parsed)
  add_b1(out, parsed)
  add_c1(out, parsed)
end

M.SUBJECT_SOFT = SUBJECT_SOFT
M.SUBJECT_HARD = SUBJECT_HARD
M.BODY_WRAP = BODY_WRAP

return M
