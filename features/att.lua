function ZoneLocked.ATT_IsMainZone(mapID)
    local parentInfo = C_Map.GetMapInfo(mapID)
    return parentInfo and parentInfo.mapType == Enum.UIMapType.Zone
end

function ZoneLocked.ATT_GetProgress(mapID)
    if not app then
        print("app is nil, ATT not loaded?")
        return 0
    end

    local searchResults = app.SearchForField and app.SearchForField("mapID", mapID)
    if not searchResults or #searchResults == 0 then
        -- Try parent map
        local info = C_Map.GetMapInfo(mapID)
        if info and info.parentMapID then
            searchResults = app.SearchForField("mapID", info.parentMapID)
        end
    end

    if searchResults then
        for _, node in ipairs(searchResults) do
            if node.total and node.progress then
                return (node.progress / node.total) * 100
            end
        end
    end

    return 0
end

function ZoneLocked.EnableATTMode()
    ZoneLocked.DebugPrint("EnableATTMode() called")

    if not ZoneLocked.ATTEventFrame then
        local f = CreateFrame("Frame")
        f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function()
            C_Timer.After(2, ZoneLocked.ATT_CheckCurrentZone)
        end)
        ZoneLocked.ATTEventFrame = f
    end
end

function ZoneLocked.ATT_CheckZoneCompletion(mapID)
    if not mapID or not ZoneLocked.ATT_IsMainZone(mapID) then return end
    if ZoneLocked.lastCompletedZones[mapID] or ZoneLockedData.attClaimedZones[mapID] then return end

    if ZoneLockedData.unlocked and ZoneLockedData.unlocked[mapID] then return end

    local percent = ZoneLocked.ATT_GetProgress(mapID)
    if not percent then return end

    if percent >= 100 then
        ZoneLocked.lastCompletedZones[mapID] = true
        ZoneLockedData.attClaimedZones[mapID] = true

        if ZoneLockedData.randomUnlock then
            local next = ZoneLocked.GetRandomConnectedZone()
            if next then
                ZoneLocked.UnlockZoneWithLinked(next)
                ZoneLocked.Print("Completed zone! Randomly unlocked: " .. C_Map.GetMapInfo(next).name)
            else
                ZoneLocked.Print("Completed zone, but no zones are available to unlock.")
            end
        else
            ZoneLocked.AddToken(1)
            ZoneLocked.Print("Completed zone! +1 Unlock Token earned.")
        end
    end
end

function ZoneLocked.ATT_CheckCurrentZone()
    local mapID = C_Map.GetBestMapForUnit("player")
    if mapID then
        ZoneLocked.ATT_CheckZoneCompletion(mapID)
    end
end

local attFrame = CreateFrame("Frame")
attFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
attFrame:SetScript("OnEvent", function()
    C_Timer.After(2, ZoneLocked.ATT_CheckCurrentZone)
end)

function ZoneLocked.CreateATTProgressSummaryTab(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT")

    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    content:SetSize(parent:GetWidth() - 20, 100)

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or not ZoneLocked.ATT_IsMainZone(mapID) then
        local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        info:SetPoint("TOPLEFT", 20, -20)
        info:SetText("You are not currently in a tracked zone.")
        return
    end

    local info = C_Map.GetMapInfo(mapID)
    local percent = ZoneLocked.ATT_GetProgress(mapID) or 0
    local r = math.min(1, (100 - percent) / 50)
    local g = math.min(1, percent / 50)

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText(info.name or "Unknown Zone")

    local progressText = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOP", title, "BOTTOM", 0, -6)
    progressText:SetText(string.format("Progress: %.1f%%", percent))

    local progressBar = CreateFrame("StatusBar", nil, content)
    progressBar:SetSize(240, 16)
    progressBar:SetPoint("TOP", progressText, "BOTTOM", 0, -8)
    progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    progressBar:GetStatusBarTexture():SetHorizTile(false)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(percent)
    progressBar:SetStatusBarColor(r, g, 0)
end

function ZoneLocked.UpdateATTProgress(parent)
    if not ZoneLocked.ATT or not ZoneLocked.ATT.GetProgressForMap then return end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID or not ZoneLocked.ATT_IsMainZone(mapID) then
        local info = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        info:SetPoint("TOPLEFT", 20, -20)
        info:SetText("You are not currently in a tracked zone.")
        return
    end

    local info = C_Map.GetMapInfo(mapID)
    local percent = ZoneLocked.ATT_GetProgress(mapID) or 0
    local r = math.min(1, (100 - percent) / 50)
    local g = math.min(1, percent / 50)

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText(info.name or "Unknown Zone")

    local progressText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("TOP", title, "BOTTOM", 0, -6)
    progressText:SetText(string.format("Progress: %.1f%%", percent))

    local progressBar = CreateFrame("StatusBar", nil, parent)
    progressBar:SetSize(240, 16)
    progressBar:SetPoint("TOP", progressText, "BOTTOM", 0, -8)
    progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    progressBar:GetStatusBarTexture():SetHorizTile(false)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(percent)
    progressBar:SetStatusBarColor(r, g, 0)
end
