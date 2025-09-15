AutoQuest = AutoQuest or {}

-- Default values
local defaults = {
  debug = false,
  autoAccept = true,
  autoReward = true,
  autoRewardUnusable = true,
  followTourGuide = false,
}

function AutoQuest:InitSettings()
  AutoQuest.Settings = AutoQuestCharDB

  setmetatable(AutoQuest.Settings, {
    __index = defaults
  })

  self.SettingsDefaultValues = defaults
end

function AutoQuest:ResetSettings()
  AutoQuestCharDB = {}
  AutoQuest:InitSettings()
end

-- Getter
function AutoQuest:GetSetting(setting)
    return self.Settings[setting]
end

-- Setter
function AutoQuest:SetSetting(setting, value)
  self.Settings[setting] = value
end