AutoQuest = AutoQuest or {}

-- Some predefined colors
local private = {
	colorPresets = {
	  red     = "ff0000",
	  green   = "00ff00",
	  yellow  = "ffff00",
	  gold    = "ffd700",
	  gray    = "aaaaaa",
	  white   = "ffffff",
	  blue    = "3399ff",
	  orange  = "ff9900",
	  purple  = "cc66ff",
	  turtle  = "33cc99",
	}
}

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