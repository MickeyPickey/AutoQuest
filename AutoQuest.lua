-- AutoQuest.lua
-- Vanilla WoW (1.x) - Instant auto-accept / auto-turn-in

local f = CreateFrame("Frame")
f:RegisterEvent("QUEST_DETAIL")
f:RegisterEvent("QUEST_PROGRESS")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("GOSSIP_SHOW")

f:SetScript("OnEvent", function()
    if event == "QUEST_DETAIL" then
        AcceptQuest()

    elseif event == "QUEST_PROGRESS" then
        if IsQuestCompletable() then
            CompleteQuest()
        end

    elseif event == "QUEST_COMPLETE" then
        local numRewards = GetNumQuestChoices()
        if numRewards <= 1 then
            GetQuestReward(1)
        else
            local bestIndex, bestValue = 1, 0
            for i = 1, numRewards do
                local link = GetQuestItemLink("choice", i)
                if link then
                    local _, _, itemId = string.find(link, "item:(%d+):")
                    if itemId then
                        local _, _, _, _, _, _, _, _, _, _, price = GetItemInfo(tonumber(itemId))
                        if price and price > bestValue then
                            bestValue, bestIndex = price, i
                        end
                    end
                end
            end
            GetQuestReward(bestIndex)
        end

    elseif event == "GOSSIP_SHOW" then
        local avail = { GetGossipAvailableQuests() }
        for i = 1, table.getn(avail), 7 do
            SelectGossipAvailableQuest((i + 6) / 7)
        end
    
        local active = { GetGossipActiveQuests() }
        for i = 1, table.getn(active), 6 do
            SelectGossipActiveQuest((i + 5) / 6)
        end
    end
end)
