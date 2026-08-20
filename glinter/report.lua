local report = {}

local function color_enabled(opts)
  if opts and opts.no_color then
    return false
  end
  if os.getenv("NO_COLOR") then
    return false
  end
  if os.getenv("TERM") == "dumb" then
    return false
  end
  return true
end

local function paint(enabled, code, text)
  if not enabled then
    return text
  end
  return "\27[" .. code .. "m" .. text .. "\27[0m"
end

function report.render(result, opts)
  opts = opts or {}
  local color = color_enabled(opts)
  local red = function(text) return paint(color, "31", text) end
  local green = function(text) return paint(color, "32", text) end
  local dim = function(text) return paint(color, "2", text) end
  local bold = function(text) return paint(color, "1", text) end

  if result.ignored then
    return green("✔") .. " ignored (merge, revert, or version commit)\n"
  end

  if result.ok then
    return green("✔") .. " commit message looks good\n"
  end

  local lines = { red("✖") .. " " .. bold("commit message failed lint") .. "\n" }
  for i = 1, #result.violations do
    local item = result.violations[i]
    lines[#lines + 1] = "  " .. red("•") .. " " .. bold(item.rule) .. ": " .. item.message
    if item.hint then
      lines[#lines + 1] = "    " .. dim(item.hint)
    end
  end
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

return report
