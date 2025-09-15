AutoQuest = AutoQuest or {}

local private = {
  slash1 = "/aq",
  slash2 = "/autoquest",
}

function private.ParseVersion(versionString)
  -- Converts "1.12.1" → 11201 (Blizzard-style)
  local major, minor, patch = string.match(versionString or "", "(%d+)%.(%d+)%.(%d+)")
  major = tonumber(major) or 0
  minor = tonumber(minor) or 0
  patch = tonumber(patch) or 0

  return major * 10000 + minor * 100 + patch
end

function private.Print(...)
    local output = {}
    for i = 1, arg.n do
        local val = arg[i]
        if val == nil then
            table.insert(output, "nil")
        else
            table.insert(output, tostring(val))
        end
    end
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(table.concat(output, " "))
    end
end

local function print(...)
  private.Print(unpack(arg))
end

local function debug_print(...)
  AutoQuest:DebugPrint(unpack(arg))
end

function AutoQuest:Init()
  local build = GetBuildInfo()
  self.isTW = private.ParseVersion(build) > private.ParseVersion("1.12.1") 
              and private.ParseVersion(build) < private.ParseVersion("2.0.0")

  -- Event listener frame
  local f = CreateFrame("Frame")
  AutoQuest.eventFrame = f

  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("QUEST_DETAIL")
  f:RegisterEvent("QUEST_PROGRESS")
  f:RegisterEvent("QUEST_COMPLETE")
  f:RegisterEvent("QUEST_GREETING")
  f:RegisterEvent("GOSSIP_SHOW")
  f:RegisterEvent("UI_INFO_MESSAGE")

  f:SetScript("OnEvent", function(_, event, arg1, arg2)
    AutoQuest:EventHandler(event, arg1, arg2)
  end)

  -- Slash commands
  SLASH_AUTOQUEST1 = private.slash1
  SLASH_AUTOQUEST2 = private.slash2
  SlashCmdList["AUTOQUEST"] = function(msg)
    AutoQuest:SlashHandler(msg)
  end
end

function AutoQuest:InitModules()
  if self.initialized then return end
  self.initialized = true

  debug_print("Initializing AutoQuest modules...")

  -- Core systems
  self:InitDB()
  self:InitSettings()

  debug_print("✅ AutoQuest fully initialized.")
end

function AutoQuest:HookTourGuideAddon()
  if self.isTourGuideHooked then return end

  local TG = TourGuide or _G["TourGuide"]

  if TG and type(TG.IsQuestAcceptable) == "function" then
    self.TG = TG
    self.isTourGuideHooked = true

    debug_print("✅ Hooked TourGuide successfully.")
  else
    debug_print("TourGuide not found.")
  end
end

function AutoQuest:IsItemUsable(itemId)
  if not itemId then
    debug_print("IsItemUsable: invalid itemId")
    return nil
  end

  local tooltip = AutoQuest.ScanTooltip
  if not tooltip then
    tooltip = CreateFrame("GameTooltip", "ScanTooltip", UIParent, "GameTooltipTemplate")
    AutoQuest.ScanTooltip = tooltip
  end

  if not tooltip or not tooltip.SetHyperlink then
    debug_print("IsItemUsable: tooltip failed to initialize")
    return nil
  end

  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:SetHyperlink("item:" .. itemId)

  local usable = true

  for i = 1, tooltip:NumLines() do
    local leftText = _G["ScanTooltipTextLeft" .. i]
    local rightText = _G["ScanTooltipTextRight" .. i]

    local function isRed(textObj)
      if textObj then
        local r, g, b = textObj:GetTextColor()
        return r > 0.9 and g < 0.2 and b < 0.2
      end
      return false
    end

    if isRed(leftText) or isRed(rightText) then
      usable = false
      break
    end
  end

  debug_print("IsItemUsable:", itemId, usable)
  return usable
end

-- OLD
-- function AutoQuest:IsItemUsable(itemId)
--     local tooltip = CreateFrame("GameTooltip", "ScanTooltip", nil, "GameTooltipTemplate")
--     tooltip:SetOwner(UIParent, "ANCHOR_NONE")
--     tooltip:SetHyperlink("item:" .. itemId)

--     for i = 1, tooltip:NumLines() do
--         local leftText = _G["ScanTooltipTextLeft" .. i]
--         local rightText = _G["ScanTooltipTextRight" .. i]

--         local function isRed(textObj)
--             if textObj then
--                 local r, g, b = textObj:GetTextColor()
--                 return r > 0.9 and g < 0.2 and b < 0.2
--             end
--             return false
--         end

--         if isRed(leftText) or isRed(rightText) then
--             return false
--         end
--     end

--     return true
-- end


function AutoQuest:GetVendorPrice(itemId)
  local _, _, _, _, _, _, _, _, _, _, price = GetItemInfo(itemId)

  if price and price > 0 then
    debug_print("Vendor price from GetItemInfo:", itemId, price)
    return price
  end

  local fallback = self.DB.StaticVendorPrices and self.DB.StaticVendorPrices[itemId]
  if fallback then
    debug_print("Fallback vendor price from DB:", itemId, fallback)
    return fallback
  end

  debug_print("No vendor price found for item:", itemId)
  return nil
end

function AutoQuest:ShouldAccept(name)
  return not self.Settings.followTourGuide or (self.TG and self.TG:IsQuestAcceptable(name))
end

function AutoQuest:IsQuestComplete(name)
  for i = 1, GetNumQuestLogEntries() do
    local title, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)

    if not isHeader and name == title and isComplete then
      debug_print("Completed quest in log: " .. title)
      return true
    end
  end
end

function AutoQuest:EventHandler(...)
  local event, arg1, arg2 = unpack(arg)

  -- Initializing modules
  if event == "PLAYER_ENTERING_WORLD" then
    self:InitModules()
    self:HookTourGuideAddon()

  -- Testing if we can get "Speak to ..." quests completed flag
  elseif event == "UI_INFO_MESSAGE" then
    debug_print(event, arg1, arg2)
  end

  if IsShiftKeyDown() then return end

  -- Handling quest events
  if event == "QUEST_DETAIL" then
    debug_print(event)
    local title = GetTitleText()
    debug_print("ShouldAccept:", self:ShouldAccept(title))
    if self:ShouldAccept(title) then AcceptQuest() end

  elseif event == "QUEST_PROGRESS" then
    debug_print(event)
    if IsQuestCompletable() then CompleteQuest() end

  elseif event == "QUEST_COMPLETE" then
    debug_print(event)
    local numRewards = GetNumQuestChoices()
    if numRewards <= 1 then
      GetQuestReward(1)
    else
      local bestIndex, bestValue = nil, 0
      local allUnusable = true

      for i = 1, numRewards do
        local link = GetQuestItemLink("choice", i)
        local _, _, itemId = string.find(link or "", "item:(%d+):")
        itemId = tonumber(itemId)

        if itemId then
          local usable = self:IsItemUsable(itemId)
          local price = self:GetVendorPrice(itemId)
          debug_print("Item:", link, "Usable:", usable, "Price:", price)

          if usable then allUnusable = false end
          if price and price > bestValue then
            bestValue, bestIndex = price, i
          end
        end
      end

      debug_print("Reward selection:", bestIndex, bestValue)
      if self.Settings.autoReward and (not self.Settings.autoRewardUnusable or allUnusable) then
        GetQuestReward(bestIndex)
      end
    end

  elseif event == "QUEST_GREETING" then
    debug_print(event)

    -- Handling currently active quests
    for i = 1, GetNumActiveQuests() do
      local title = GetActiveTitle(i)
      debug_print("Completed Quest:", title, self:IsQuestComplete(title))
      if self:IsQuestComplete(title) then SelectActiveQuest(i) end
    end

    -- Handling available quests
    for i = 1, GetNumAvailableQuests() do
      local title = GetAvailableTitle(i)
      debug_print("Available Quest:", title)
      if self:ShouldAccept(title) then SelectAvailableQuest(i) end
    end

  elseif event == "GOSSIP_SHOW" then
    debug_print(event)

    -- Handling currently active quests
    local active = { GetGossipActiveQuests() }
    local activeChunk = self.isTW and 2 or 6
    local numActive = table.getn(active) / activeChunk
    debug_print("numActiveQuests:", numActive)

    for i = 1, numActive do
      local title = active[i * activeChunk - 1]
      debug_print("Completed Gossip Quest:", title)
      if self:IsQuestComplete(title) then SelectGossipActiveQuest(i) end
    end

    -- Handling available quests
    local avail = { GetGossipAvailableQuests() }
    local availChunk = self.isTW and 2 or 7
    local numAvail = table.getn(avail) / availChunk
    debug_print("numAvailQuests:", format("%s(%s)", numAvail, table.getn(avail)))

    for i = 1, numAvail do
      local title = avail[i * availChunk - 1]
      debug_print("Available Gossip Quest:", title)
      if self:ShouldAccept(title) then SelectGossipAvailableQuest(i) end
    end
  end
end

function AutoQuest:SlashHandler(msg)
  if not msg or msg == "" then
    self:Print("List of available settings:")
    for key, default in pairs(self.SettingsDefaultValues) do
      local value = self:GetSetting(key)
      print(" -", key, "=", tostring(value))
    end
    print(format("Usage: /%s (%s) <setting> [on|off|true|false|1|0]", tostring(private.slash1), tostring(private.slash2)))
    return
  end

  local args = {}
  for word in string.gfind(msg, "%S+") do
    table.insert(args, word)
  end

  local setting = args[1]
  local value = args[2]

  if not self.SettingsDefaultValues[setting] then
    self:Print("Unknown setting:", setting)
    return
  end

  if not value then
    -- Toggle if no value provided
    local current = self:GetSetting(setting)
    self:SetSetting(setting, not current)
    self:Print(setting .. " toggled to " .. tostring(not current))
    return
  end

  local normalized
  if value == "on" or value == "true" or value == "1" then
    normalized = true
  elseif value == "off" or value == "false" or value == "0" then
    normalized = false
  else
    self:Print("Invalid value:", value)
    return
  end

  self:SetSetting(setting, normalized)
  self:Print(setting .. " set to " .. tostring(normalized))
end

function AutoQuest:Print(...)

  local titleFormatStr = self:ColorText("%s", "turtle")

  private.Print(format(titleFormatStr, "AutoQuest:"), unpack(arg))
end

function AutoQuest:DebugPrint(...)
  if self.Settings.debug then
    local titleFormatStr = self:ColorText("%s", "red")

    self:Print(format(titleFormatStr, "[DEBUG]:"), unpack(arg))
  end
end

function AutoQuest:Greetings()
  local build = GetBuildInfo()
  local locale = GetLocale()
  local client = self.isTW and "Turtle WoW" or "Vanilla WoW"

  self:Print("Your questing assistant is ON. No more clicking through 37 gossip options! :)")
  debug_print("Client:", client, "Build:", build, "Locale:", locale)
  self:Print(format("Use %s or %s to configure settings.", tostring(private.slash1), tostring(private.slash2)))
  self:Print("Now go forth, brave soul. May your bags be empty and your rewards be shiny!")
end

-- initializing addon
AutoQuest:Init()