local diag = require("glinter.diag")
local sentence = require("glinter.sentence")
local util = require("glinter.util")
local words = require("glinter.words")

local M = {}

local HARD_SENTENCE = 20
local VERY_HARD_SENTENCE = 30

local function add_h1_h2(out, parsed)
  if parsed.generated or not parsed.subject then
    return
  end
  local groups = {
    { { lnum = parsed.subject.lnum, text = parsed.subject.text } },
    parsed.body_lines,
  }
  for g = 1, #groups do
    local ranges = sentence.ranges(parsed, groups[g])
    for i = 1, #ranges do
      local sent = ranges[i]
      local wc = util.word_count(sent.text)
      if wc > VERY_HARD_SENTENCE then
        out[#out + 1] = diag.make("H2", {
          lnum = sent.lnum,
          col = sent.col,
          end_lnum = sent.end_lnum,
          end_col = sent.end_col,
          message = string.format("Sentence is %d words; split it", wc),
        })
      elseif wc > HARD_SENTENCE then
        out[#out + 1] = diag.make("H1", {
          lnum = sent.lnum,
          col = sent.col,
          end_lnum = sent.end_lnum,
          end_col = sent.end_col,
          message = string.format("Sentence is %d words; split it", wc),
        })
      end
    end
  end
end

local function is_ly_adverb(tok)
  local w = util.lower_ascii(tok)
  if #w < 4 or w:sub(-2) ~= "ly" then
    return false
  end
  return not words.adverb_allow[w]
end

local function is_participle(tok)
  local w = util.lower_ascii(tok)
  if words.irregular_participles[w] then
    return true
  end
  return #w >= 4 and w:sub(-2) == "ed"
end

local function add_h5(out, parsed, claimed)
  diag.each_prose_line(parsed, function(line)
    for i = 1, #words.qualifiers do
      local q = words.qualifiers[i]
      local from = 1
      while true do
        local s, e = util.find_word(line.text, q, from)
        if not s then
          break
        end
        if not diag.occupied(claimed, line.lnum, s - 1, e) then
          claimed[#claimed + 1] = { lnum = line.lnum, col = s - 1, end_col = e }
          out[#out + 1] = diag.make("H5", {
            lnum = line.lnum,
            col = s - 1,
            end_col = e,
            message = "Remove the qualifier",
          })
        end
        from = s + 1
      end
    end
  end)
end

local function add_h3(out, parsed, claimed)
  diag.each_prose_line(parsed, function(line)
    local text = line.text
    local pos = 1
    while true do
      local s, e, tok = text:find("(%a+)", pos)
      if not s then
        break
      end
      local lower = util.lower_ascii(tok)
      local flag = false
      if words.intensifiers[lower] then
        if lower == "too" then
          flag = text:sub(e + 1):find("^%s+%a") ~= nil
        else
          flag = true
        end
      elseif is_ly_adverb(tok) then
        flag = true
      end
      if flag and not diag.occupied(claimed, line.lnum, s - 1, e) then
        claimed[#claimed + 1] = { lnum = line.lnum, col = s - 1, end_col = e }
        out[#out + 1] = diag.make("H3", {
          lnum = line.lnum,
          col = s - 1,
          end_col = e,
          message = "Replace the adverb with a stronger verb",
        })
      end
      pos = e + 1
    end
  end)
end

local function add_h4(out, parsed, claimed)
  diag.each_prose_line(parsed, function(line)
    local text = line.text
    local pos = 1
    while true do
      local s, e, be = text:find("(%a+)", pos)
      if not s then
        break
      end
      if words.be_verbs[util.lower_ascii(be)] then
        local rest = text:sub(e + 1)
        local rs, re, _, part = rest:find("^(%s+)(%a+)")
        if rs and is_participle(part) then
          local start_col = s - 1
          local end_col = e + re
          if not diag.occupied(claimed, line.lnum, start_col, end_col) then
            claimed[#claimed + 1] = {
              lnum = line.lnum,
              col = start_col,
              end_col = end_col,
            }
            out[#out + 1] = diag.make("H4", {
              lnum = line.lnum,
              col = start_col,
              end_col = end_col,
              message = "Use active voice",
            })
          end
        end
      end
      pos = e + 1
    end
  end)
end

local function add_h6(out, parsed, claimed)
  diag.each_prose_line(parsed, function(line)
    local function however_ok(s)
      if s == 1 then
        return true
      end
      local before = line.text:sub(1, s - 1)
      return before:find("[%.!?]%s+$") ~= nil
    end

    local from_h = 1
    while true do
      local s, e = util.find_word(line.text, "however", from_h)
      if not s then
        break
      end
      if however_ok(s) and not diag.occupied(claimed, line.lnum, s - 1, e) then
        claimed[#claimed + 1] = { lnum = line.lnum, col = s - 1, end_col = e }
        out[#out + 1] = diag.make("H6", {
          lnum = line.lnum,
          col = s - 1,
          end_col = e,
          message = "Use a simpler word",
          replacement = "but",
        })
      end
      from_h = s + 1
    end

    for i = 1, #words.simpler do
      local item = words.simpler[i]
      local from = 1
      while true do
        local s, e = util.find_word(line.text, item.from, from)
        if not s then
          break
        end
        if not diag.occupied(claimed, line.lnum, s - 1, e) then
          claimed[#claimed + 1] = { lnum = line.lnum, col = s - 1, end_col = e }
          out[#out + 1] = diag.make("H6", {
            lnum = line.lnum,
            col = s - 1,
            end_col = e,
            message = "Use a simpler word",
            replacement = item.to,
          })
        end
        from = s + 1
      end
    end
  end)
end

function M.apply(out, parsed)
  add_h1_h2(out, parsed)
  local claimed = {}
  add_h5(out, parsed, claimed)
  add_h3(out, parsed, claimed)
  add_h4(out, parsed, claimed)
  add_h6(out, parsed, claimed)
end

M.HARD_SENTENCE = HARD_SENTENCE
M.VERY_HARD_SENTENCE = VERY_HARD_SENTENCE

return M
