function ZoneLocked.RefreshMode()
    if not ZoneLockedData or not ZoneLockedData.mode then return end

    local mode = ZoneLockedData.mode
    ZoneLocked.DebugPrint("🔁 Refreshing mode: " .. mode)

    -- Skjul alle UI-elementer først
    if ZoneLocked.SkillBarFrame then ZoneLocked.SkillBarFrame:Hide() end
    if ZoneLocked.SkillModeButton then ZoneLocked.SkillModeButton:Hide() end
    if ZoneLocked.FloatingTokenButton then ZoneLocked.FloatingTokenButton:Hide() end

    if mode == "skill" then
        ZoneLocked.EnableSkillMode()
        ZoneLocked.CreateSkillBar()
        ZoneLocked.CreateSkillModeButton()
        ZoneLocked.UpdateSkillBar()
    elseif mode == "medium" then
        -- War Effort UI
        if ZoneLocked.ShowWarEffortUI then
            ZoneLocked.ShowWarEffortUI()
        end
    elseif mode == "manual" then
        -- Ingen spesiell UI
        ZoneLocked.Print("Manual mode active. No automatic tracking.")
    elseif mode == "hard" then
        -- Token-knapp vises bare hvis randomUnlock er på og tokens > 0
        ZoneLocked.CreateFloatingTokenButton()
        ZoneLocked.UpdateFloatingTokenButton()
    elseif mode == "att" then
        ZoneLocked.EnableATTMode()
        if ZoneLocked.UpdateATTProgress then
            ZoneLocked.UpdateATTProgress()
        end
    elseif mode == "loremaster" then
        ZoneLocked.EnableLoremasterMode()
        ZoneLocked.UpdateLoremasterAchievements()
    else
        ZoneLocked.Print("Unknown mode: " .. tostring(mode))
    end
end

function ZoneLocked.GetForcedExpansionsByRace()
    local _, race = UnitRace("player")
    race = string.lower(race)

    local required = {}

    if race == "bloodelf" or race == "draenei" then
        required["Outland"] = true
    elseif race == "goblin" or race == "worgen" then
        required["Cataclysm"] = true
    elseif race == "pandaren" then
        required["Pandaria"] = true
    end

    return required
end

function ZoneLocked.CountTableKeys(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

function ZoneLocked.HandlePandarenFactionUnlock()
    if ZoneLockedData.unlocked and ZoneLocked.CountTableKeys(ZoneLockedData.unlocked) > 1 then
        return
    end

    local faction = UnitFactionGroup("player")

    if faction == "Neutral" then
        ZoneLocked.DebugPrint("Player is still Neutral. Waiting to unlock faction-specific zones.")
        return
    end

    if faction == "Alliance" then
        ZoneLocked.unlockLinked[378] = { 37 } -- Stormwind (Elwynn Forest)
    elseif faction == "Horde" then
        ZoneLocked.unlockLinked[378] = { 1 }  -- Orgrimmar (Durotar)
    end
    ZoneLocked.UnlockZoneWithLinked(378)
end

local function MigrateProfessionProgress()
    if not ZoneLockedData.professionProgress then return end
    if type(ZoneLockedData.professionProgress["Cooking"]) == "table" then
        return -- Allerede migrert
    end

    local flat = ZoneLockedData.professionProgress
    local new = {}

    for fullName, value in pairs(flat) do
        local main = fullName:match("Cooking") and "Cooking"
            or fullName:match("Fishing") and "Fishing"
            or fullName:match("Herbalism") and "Herbalism"
            or fullName:match("Skinning") and "Skinning"
            or fullName:match("Mining") and "Mining"
            or fullName:match("Blacksmithing") and "Blacksmithing"
            or fullName:match("Alchemy") and "Alchemy"
            or fullName:match("Engineering") and "Engineering"
            or fullName:match("Tailoring") and "Tailoring"
            or fullName:match("Enchanting") and "Enchanting"
            or fullName:match("Inscription") and "Inscription"
            or fullName:match("Jewelcrafting") and "Jewelcrafting"
            or fullName:match("Leatherworking") and "Leatherworking"
            or "Other"

        new[main] = new[main] or {}
        new[main][fullName] = value
    end

    ZoneLockedData.professionProgress = new
    ZoneLocked.Print("🔄 Profesjonsdata migrert.")
end

local function InitSavedData()
    ZoneLockedData = ZoneLockedData or {}
    ZoneLockedData.timesOutOfBounds = ZoneLockedData.timesOutOfBounds or 0

    -- Initialize expansion flags (before using them)
    ZoneLockedData.expansions = ZoneLockedData.expansions or {
        Outland = false,
        Northrend = false,
        Cataclysm = false,
        Pandaria = false,
        Draenor = false,
        BrokenIsles = false,
        Shadowlands = false,
    }

    ZoneLockedData.attClaimedZones = ZoneLockedData.attClaimedZones or {}
    ZoneLocked.lastCompletedZones = {}

    -- Auto-enable expansions based on race
    local forcedExpansions = ZoneLocked.GetForcedExpansionsByRace()
    for expansion, _ in pairs(forcedExpansions) do
        ZoneLockedData.expansions[expansion] = true
    end

    if ZoneLocked and CreateZoneLockedCharacterTab then
        CreateZoneLockedCharacterTab()
    end


    if not ZoneLockedData.unlocked or next(ZoneLockedData.unlocked) == nil then
        local _, race = UnitRace("player")
        race = string.lower(race)
        local defaultZone = ZoneLocked.RaceDefaults[race] or 37
        ZoneLocked.UnlockZoneWithLinked(defaultZone)
    end

    ZoneLockedData.tokens = ZoneLockedData.tokens or 0

    ZoneLockedData.LoremasterAchieved = ZoneLocked.LoremasterAchieved or {}

    ZoneLockedData.redeemedItems = ZoneLockedData.redeemedItems or {}

    MigrateProfessionProgress()

    if ZoneLockedData.mode == "hard" then
        if ZoneLocked.CreateTokenRedeemButton then
            ZoneLocked.CreateTokenRedeemButton()
        end

        C_Timer.NewTicker(5, function()
            if ZoneLocked.CheckWoWTokenStatus then
                ZoneLocked.CheckWoWTokenStatus()
            end
        end)
    end
end

local function OnMapChanged()
    local mapID = WorldMapFrame:GetMapID()
    if not mapID then return end

    local retries = 0
    local function tryDraw()
        local width = WorldMapFrame.ScrollContainer.Child:GetWidth()
        if width > 0 or retries > 5 then
            DrawLockedOverlays(mapID)
        else
            retries = retries + 1
            C_Timer.After(0.05, tryDraw)
        end
    end

    tryDraw()
end

local wasOutOfBounds = false
local outOfBoundsTimer = nil

function ZoneLocked_CheckZoneEntry()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return end

    ZoneLocked.CreateDangerFrame()

    local zoneFound = false
    for _, continent in pairs(ZoneLocked.ZonePositions) do
        if continent[mapID] then
            zoneFound = true
            break
        end
    end

    local isLocked = zoneFound and not ZoneLockedData.unlocked[mapID]

    if isLocked then
        local zoneName = C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or "Unknown Zone"
        local messages = {
            "You feel a chill... this land is not yet yours to explore.",
            "You're walking into undiscovered territory. Turn back before Kel'Thuzad's forces catch you.",
            "A shadow looms here — you've not yet claimed this place.",
            "You sense danger. This region is locked to your journey.",
            "The path ahead is veiled. Unlock it before proceeding."
        }
        local msg = messages[math.random(#messages)]

        ZoneLocked.DebugPrint("|cffff0000[ZoneLocked]|r " .. msg .. " (" .. zoneName .. ")")

        -- Vis fare-frame
        local f = ZoneLocked_DangerFrame
        f:Show()
        if not f.fade:IsPlaying() then
            f.fade:Play()
        end

        -- Start timer hvis vi ikke allerede teller
        if not wasOutOfBounds then
            wasOutOfBounds = true

            outOfBoundsTimer = C_Timer.NewTicker(1, function()
                ZoneLocked.TimeOutofBounds = (ZoneLocked.TimeOutofBounds or 0) + 1
                ZoneLockedData.TimeOutofBounds = ZoneLocked.TimeOutofBounds
                ZoneLocked.DebugPrint("|cffff0000[ZoneLocked]|r Time out of bounds: " ..
                    ZoneLocked.TimeOutofBounds .. "s")
            end)
        end
    else
        -- Skjul fare og stopp timer
        if ZoneLocked_DangerFrame then
            ZoneLocked_DangerFrame:Hide()
            ZoneLocked_DangerFrame.fade:Stop()
        end

        if wasOutOfBounds then
            wasOutOfBounds = false
            if outOfBoundsTimer then
                outOfBoundsTimer:Cancel()
                outOfBoundsTimer = nil
            end
        end
    end
end

function ZoneLocked.PlayerHasWoWToken()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID == 122284 then
                return true
            end
        end
    end
    return false
end

local function PreloadItemData()
    if not ZoneLocked.WarEffortRequirements then return end
    for _, entry in ipairs(ZoneLocked.WarEffortRequirements) do
        C_Item.RequestLoadItemDataByID(entry.itemID)
    end
end

function ZoneLocked.PreloadItemData(callback)
    local remaining = 0
    local seen = {}

    for _, item in ipairs(ZoneLocked.WarEffortRequirements) do
        if not seen[item.itemID] then
            seen[item.itemID] = true
            remaining = remaining + 1

            local itemObj = Item:CreateFromItemID(item.itemID)
            itemObj:ContinueOnItemLoad(function()
                remaining = remaining - 1
                if remaining == 0 and callback then
                    callback()
                end
            end)
        end
    end

    if remaining == 0 and callback then
        callback()
    end
end

local function OnAddonLoaded(name)
    if name ~= "ZoneLocked" then return end
    InitSavedData()
    PreloadItemData()

    ZoneLocked.DebugPrint("|cff00ccffZoneLocked|r loaded. Author: Deju")

    hooksecurefunc(WorldMapFrame, "OnMapChanged", OnMapChanged)
    ZoneLocked.RegisterCommands()
    ZoneLocked.CreateFloatingTokenButton()
    ZoneLocked.UpdateFloatingTokenButton()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(...)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        ZoneLocked_CheckZoneEntry()
        -- Sjekk ATT fullføring etter sonebytte
        C_Timer.After(1, function()
            if ZoneLockedData.mode == "att" then
                ZoneLocked.ATT_CheckCurrentZone()
                ZoneLocked.UpdateATTProgress()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not ZoneLockedData.mode then
            ZoneLocked.ShowModeSelection()
        else
            if ZoneLockedData.mode == "skill" then
                ZoneLocked.EnableSkillMode()
            elseif ZoneLockedData.mode == "att" then
                ZoneLocked.EnableATTMode()
            elseif ZoneLockedData.mode == "loremaster" then
                ZoneLocked.EnableLoremasterMode()
                ZoneLocked.UpdateLoremasterAchievements()
            end
        end

        local _, race = UnitRace("player")
        if ZoneLocked.RaceDefaults[string.lower(race)] == 378 then
            ZoneLocked.HandlePandarenFactionUnlock()
        end

        if ZoneLocked.triggerReload then
            ZoneLocked.triggerReload = false
            C_Timer.After(0.5, ReloadUI)
        end
    end
end)


function ZoneLocked.IsZoneLocked(zoneID)
    local continent = ZoneLocked.GetContinentForZone(zoneID)

    if continent == 101 and not ZoneLockedData.enableOutland then
        return true
    end
    if continent == 113 and not ZoneLockedData.enableNorthrend then
        return true
    end

    return not ZoneLockedData.unlocked or not ZoneLockedData.unlocked[zoneID]
end

local function OnBagUpdate()
    -- Sjekker og konverterer WoW Token hvis mulig
    C_Timer.After(1, function()
        ZoneLocked.CheckAndConvertWoWToken()
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:SetScript("OnEvent", function(_, event)
    if event == "BAG_UPDATE_DELAYED" then
        OnBagUpdate()
    end
end)
