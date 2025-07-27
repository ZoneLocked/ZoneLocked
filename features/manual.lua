function ZoneLocked.GetManualModeZones()
    if not ZoneLockedData or not ZoneLockedData.unlocked then
        return {}
    end

    local results = {}
    local unlocked = ZoneLockedData.unlocked or {}

    for _, zoneList in pairs(ZoneLocked.ZonePositions or {}) do
        for zoneID in pairs(zoneList) do
            if unlocked[zoneID] or ZoneLocked.CanUnlockZone(zoneID) == 1 then
                results[zoneID] = true
            end
        end
    end

    return results
end

function ZoneLocked.RefreshManualTab()
    if ZoneLockedMainFrame and ZoneLockedMainFrame.modeTab and ZoneLockedData.mode == "manual" then
        ZoneLockedMainFrame.modeTab:Hide()
        ZoneLockedMainFrame.modeTab = nil
        ZoneLocked.CreateModeTab(ZoneLockedMainFrame)
    end
end

function ZoneLocked.ShowManualTab(parent)
    if parent.manualScroll then
        parent.manualScroll:Hide()
        parent.manualScroll:SetParent(nil)
        parent.manualScroll = nil
    end

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -30)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    parent.manualScroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local zones = ZoneLocked.GetManualModeZones()
    local sortedIDs = ZoneLocked.GetSortedZoneIDs(zones)
    local connected = ZoneLocked.GetAvailableConnectedZones()

    local maxCols = 4
    local spacingX = 150
    local spacingY = 60
    local iconSize = 32

    local row = 0
    local col = 0

    for _, zoneID in ipairs(sortedIDs) do
        local mapInfo = C_Map.GetMapInfo(zoneID)
        if mapInfo then
            local baseX = col * spacingX
            local baseY = -row * spacingY * 2

            local icon = content:CreateTexture(nil, "ARTWORK")
            icon:SetSize(iconSize, iconSize)
            icon:SetPoint("TOPLEFT", baseX + 5, baseY)

            local isCompleted = ZoneLocked.IsZoneCompleted(zoneID)
            local isUnlocked = ZoneLocked.IsZoneUnlocked(zoneID)
            local isConnected = tContains(connected, zoneID)

            if isCompleted then
                icon:SetTexture("Interface\\Icons\\Achievement_Boss_CThun")
            elseif isUnlocked then
                icon:SetTexture("Interface\\Icons\\achievement_legionpvptier4")
            elseif isConnected then
                icon:SetTexture("Interface\\Icons\\ability_titankeeper_uncheckedcorruption")
            else
                icon:SetTexture(134400) -- fallback/default
            end

            local name = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
            name:SetText(mapInfo.name)

            local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            button:SetSize(120, 22)
            button:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -5)

            if isCompleted then
                button:SetText("Completed")
                button:Disable()
            elseif isUnlocked then
                button:SetText("Mark Complete")
                button:SetScript("OnClick", function()
                    ZoneLocked.MarkZoneCompleted(zoneID)
                    ZoneLocked.ShowManualTab(parent)
                    if ZoneLocked.RefreshManualTab then
                        ZoneLocked.RefreshManualTab()
                    end
                end)
            elseif isConnected then
                button:SetText("Not Yet Available")
                button:Disable()
            else
                button:SetText("Unavailable")
                button:Disable()
            end

            col = col + 1
            if col >= maxCols then
                col = 0
                row = row + 1
            end
        end
    end

    local completed = 0
    for _, _ in pairs(ZoneLockedData.completedZones or {}) do
        completed = completed + 1
    end

    local statusText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusText:SetPoint("TOPLEFT", 10, -(row + 1) * spacingY * 2 - 20)
    statusText:SetText("Zones Completed: " .. completed)

    content:SetSize(1, (row + 2) * spacingY * 2)
end
