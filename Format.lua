AutoQuest = AutoQuest or {}

-- Some predefined colors
local private = {
	ColorPresets = {
		red     = "ff0000", -- Error, disabled, critical
	  green   = "00ff00", -- Enabled, success, active
	  yellow  = "ffff00", -- Warning, caution
	  gold    = "ffd700", -- Highlight, premium, reward
	  gray    = "aaaaaa", -- Common, default, neutral
	  white   = "ffffff", -- Neutral, clean
	  blue    = "3399ff", -- Info, link, tooltip
	  orange  = "ff9900", -- Actionable, toggle, hotkey
	  purple  = "cc66ff", -- Rare, advanced, debug
	  turtle  = "33cc99", -- 🐢
	},
}

function AutoQuest:GetStatusColor(boolean)
  return private.ColorPresets[boolean and "green" or "red"]
end

function AutoQuest:ColorText(text, color)
  if not text or not color then return tostring(text) end

  -- Named preset lookup
  local hex = private.ColorPresets[color] or color
  hex = string.gsub(hex, "^#", "")

  if string.len(hex) ~= 6 then
    debug_print("Invalid color:", color)
    return tostring(text)
  end

  return "|cff" .. hex .. tostring(text) .. "|r"
end

