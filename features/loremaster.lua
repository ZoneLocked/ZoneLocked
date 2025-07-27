local function FormatZoneIDs(ids)
    return type(ids) == "table" and table.concat(ids, ", ") or tostring(ids)
end

function ZoneLocked.LoremasterSoftLockCheck()
    if ZoneLockedData.tokens > 0 then
        ZoneLocked.DebugPrint("More than 0 tokens available, softlock check not needed.")
        return false
    end

    for _, achievement in ipairs(ZoneLocked.LoremasterAchievements) do
        if ZoneLockedData.LoremasterAchieved[achievement.id] then
            for d, zoneId in pairs(achievement.idList) do
                if not ZoneLockedData.unlocked[zoneId] then
                    return false
                end
            end
        end
    end

    return true
end

function ZoneLocked.EnableLoremasterMode()
    ZoneLocked.DebugPrint("EnableLoremasterMode() called")

    if not ZoneLockedData.LoremasterStartingZoneChecked then
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
        ZoneLockedData.LoremasterStartingZoneChecked = true
    end

    if not ZoneLocked.SkillEventFrame then
        local f = CreateFrame("Frame")
        f:RegisterEvent("ACHIEVEMENT_EARNED")
        f:SetScript("OnEvent", ZoneLocked.Loremaster_OnEvent)
        ZoneLocked.SkillEventFrame = f
    end
end

function ZoneLocked.UpdateLoremasterAchievements()
    ZoneLocked.DebugPrint("UpdateLoremasterAchievements() called")
    ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
    ZoneLockedData.LoremasterAchieved = ZoneLockedData.LoremasterAchieved or {}

    for _, zoneID in pairs(ZoneLocked.RaceDefaults) do
        if zoneID ~= 2112 then
            ZoneLockedData.unlocked[zoneID] = true
            ZoneLocked.DebugPrint("Unlocked starting zone with ID: " .. zoneID)
        end
    end

    for _, zoneID in pairs(ZoneLocked.LoremasterAutoUnlocks) do
        if not ZoneLockedData.unlocked[zoneID] then
            ZoneLockedData.unlocked[zoneID] = true
            ZoneLocked.DebugPrint("Unlocked auto unlock zone with ID: " .. zoneID)
        end
    end

    for _, achievement in pairs(ZoneLocked.LoremasterAchievements) do
        local achieved = select(4, GetAchievementInfo(achievement.id))
        if achieved and not ZoneLockedData.LoremasterAchieved[achievement.id] then
            ZoneLocked.DebugPrint("Found completed achievement: " .. tostring(achievement.id))
            ZoneLocked.CheckAchievementZone(achievement.id)
        end
    end

    local softlocked = ZoneLocked.LoremasterSoftLockCheck()

    if softlocked then
        ZoneLocked.DebugPrint("Player softlocked! Granting a token.")
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
    else
        ZoneLocked.DebugPrint("Player not softlocked.")
    end
end

function ZoneLocked.Loremaster_OnEvent(self, event, ...)
    ZoneLocked.DebugPrint("Loremaster_OnEvent fired: " .. tostring(event))

    if event == "ACHIEVEMENT_EARNED" then
        local achievementID, alreadyEarned = ...
        ZoneLocked.DebugPrint("ACHIEVEMENT_EARNED: " .. tostring(achievementID) ..
            ", Already Earned: " .. tostring(alreadyEarned))

        if alreadyEarned then
            ZoneLocked.DebugPrint("Achievement already earned, ignoring.")
            return
        end

        if not ZoneLocked.CheckAchievementZone(achievementID) then
            ZoneLocked.DebugPrint("Achievement not linked to any unlocks.")
            return
        end

        if achievementID == 12456 or achievementID == 12455 then
            ZoneLocked.DebugPrint("Achievement is double zone achievement, not unlocking zones.")
            return
        end

        if achievementID == 4906 or achievementID == 4905 then
            local NorthSTVAchieved = select(4, GetAchievementInfo(4906))
            local CapeSTVAchieved = select(4, GetAchievementInfo(4905))

            if not NorthSTVAchieved or not CapeSTVAchieved then
                ZoneLocked.DebugPrint("You must complete both North and Cape Stormwind to unlock this zone.")
                return
            end
        end

        ZoneLocked.Print("Achievement earned: " .. select(2, GetAchievementInfo(achievementID)))
        ZoneLocked.Print("You have earned +1 Unlock Token!")

        ZoneLocked.UpdateLoremasterAchievements()
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
    else
        ZoneLocked.DebugPrint("Unhandled event: " .. tostring(event))
    end
end

function ZoneLocked.CheckAchievementZone(achievementID)
    for _, zoneInfo in ipairs(ZoneLocked.LoremasterAchievements) do
        if zoneInfo.id == achievementID then
            if ZoneLocked.debug then
                ZoneLocked.DebugPrint("Achievement for zone(s): " ..
                    zoneInfo.name .. " (IDs: " .. FormatZoneIDs(zoneInfo.idList) .. ")")
            end

            for _, zoneID in ipairs(zoneInfo.idList) do
                if not ZoneLockedData.unlocked[zoneID] then
                    ZoneLockedData.unlocked[zoneID] = true
                    ZoneLocked.Print("Unlocked zone with ID: " .. zoneID)
                end
            end

            ZoneLockedData.LoremasterAchieved[achievementID] = true
            return true
        end
    end

    return false
end
