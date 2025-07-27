ZoneLocked.tabs = {}

function ZoneLocked.CreateMenuIconButton(parent, texturePath, tooltip, tabIndex, posIndex)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(44, 44)
    btn:SetPoint("TOPRIGHT", parent, "TOPLEFT", -6, -20 - ((posIndex - 1) * 50))

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.6)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetPoint("BOTTOMRIGHT", -6, 6)
    icon:SetTexture(texturePath)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    btn:SetScript("OnClick", function()
        ZoneLocked.SwitchTab(tabIndex)
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", GameTooltip_Hide)

    return btn
end

function ZoneLocked.ShowMainUI()
    if ZoneLockedMainFrame then
        if ZoneLockedMainFrame:IsShown() then
            ZoneLockedMainFrame:Hide()
        else
            ZoneLockedMainFrame:Show()
        end
        return
    end

    local f = CreateFrame("Frame", "ZoneLockedMainFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(800, 600)
    f:SetPoint("CENTER")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.title:SetPoint("TOP", 0, -10)
    f.title:SetText("ZoneLocked Menu")

    ZoneLocked.tabs = {}

    ZoneLocked.tabs[1] = ZoneLocked.CreateMenuIconButton(f, "Interface\\Icons\\achievement_bg_killxenemies_generalsroom", "Mode", 1, 1)
    ZoneLocked.tabs[2] = ZoneLocked.CreateMenuIconButton(f, "Interface\\Icons\\achievement_zone_kalimdor_01", "Zones", 2, 2)
    ZoneLocked.tabs[3] = ZoneLocked.CreateMenuIconButton(f, "Interface\\Icons\\inv_gizmo_02", "Settings", 3, 3)

    f.contentFrames = {}

    for i = 1, 3 do
        local frame = CreateFrame("Frame", nil, f)
        frame:SetSize(740, 520)
        frame:SetPoint("TOPLEFT", 50, -40)
        frame:Hide()
        f.contentFrames[i] = frame
    end

    ZoneLocked.MainUI = f
    ZoneLockedMainFrame = f

    if not tContains(UISpecialFrames, "ZoneLockedMainFrame") then
        table.insert(UISpecialFrames, "ZoneLockedMainFrame")
    end

    ZoneLocked.SwitchTab(1)
    f:Show()
end

function ZoneLocked.SwitchTab(tabIndex)
    local f = ZoneLocked.MainUI
    if not f then return end

    if not f:IsShown() then
        f:Show()
    end

    for _, frame in ipairs(f.contentFrames or {}) do
        frame:Hide()
    end

    if tabIndex == 1 then
        ZoneLocked.CreateModeTab(f.contentFrames[1])
    elseif tabIndex == 2 then
        ZoneLocked.CreateZonesTab(f.contentFrames[2])
    elseif tabIndex == 3 then
        ZoneLocked.CreateSettingsTab(f.contentFrames[3])
    end

    if f.contentFrames[tabIndex] then
        f.contentFrames[tabIndex]:Show()
    end
end

function ZoneLocked.CreateModeTab(parent)
    if parent.modeTab then
        parent.modeTab:Show()
        return
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()
    parent.modeTab = frame
    local mode = ZoneLockedData.mode or "none"
    local content = frame.content or frame

    if mode == "easy" then
        ZoneLocked.CreateEasyModeSummaryTab(content)
    elseif mode == "medium" then
        ZoneLocked.CreateWarEffortUI(content)
    elseif mode == "skill" then
        ZoneLocked.CreateSkillModeSummaryTab(content)
    elseif mode == 'att' then
        ZoneLocked.CreateATTProgressSummaryTab(content)
    elseif mode == "manual" then
        ZoneLocked.ShowManualTab(content)
    else
        local info = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        info:SetPoint("TOPLEFT", 20, -60)
        info:SetWidth(600)
        info:SetJustifyH("LEFT")
        info:SetText("No UI is available for this mode yet.\nFunctionality is handled automatically in the background.")
    end
end

function ZoneLocked.CreateZonesTab(parent)
    if parent.zonesTab then
        parent.zonesTab:Show()
        return
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    content:SetSize(700, 1200)

    local unlocked = {}
    local locked = {}

    for continentID, zoneList in pairs(ZoneLocked.ZonePositions) do
        for zoneID in pairs(zoneList) do
            local info = C_Map.GetMapInfo(zoneID)
            if info and info.name then
                -- 🚫 Hopp over hvis Outland eller Northrend er deaktivert
                local continent = ZoneLocked.GetContinentForZone(zoneID)
                if not (
                    (continent == 101 and not ZoneLockedData.enableOutland) or
                    (continent == 113 and not ZoneLockedData.enableNorthrend)
                ) then
                    local isUnlocked = ZoneLockedData.unlocked and ZoneLockedData.unlocked[zoneID]
                    local zoneData = {
                        name = info.name,
                        unlocked = isUnlocked or false
                    }
                    if zoneData.unlocked then
                        table.insert(unlocked, zoneData)
                    else
                        table.insert(locked, zoneData)
                    end
                end
            end
        end
    end

    table.sort(unlocked, function(a, b) return a.name < b.name end)
    table.sort(locked, function(a, b) return a.name < b.name end)

    local combined = {}
    for _, z in ipairs(unlocked) do table.insert(combined, z) end
    for _, z in ipairs(locked) do table.insert(combined, z) end

    -- Layout: 3 kolonner
    local columns = 3
    local spacingX = 220
    local spacingY = 22
    local index = 0

    for _, zone in ipairs(combined) do
        local col = index % columns
        local row = math.floor(index / columns)

        local x = col * spacingX
        local y = -row * spacingY

        local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("TOPLEFT", x, y)
        label:SetText((zone.unlocked and "|cff00ff00" or "|cffff2020") .. zone.name)

        index = index + 1
    end

    parent.zonesTab = frame
end


function ZoneLocked.CreateSettingsTab(parent)
    if parent.settingsTab then
        parent.settingsTab:Show()
        return
    end

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints()

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ZoneLocked Settings")

    -- 📘 Introtext
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    desc:SetWidth(600)
    desc:SetJustifyH("LEFT")
    desc:SetText("These options let you control which expansions are available to unlock.\n" ..
                 "If disabled, connected zones from that expansion will be ignored.")

    local spacingX = 260
    local startX = 16
    local startY = -90
    local perRowHeight = 28
    local columns = 2

    for i, entry in ipairs(ZoneLocked.ExpansionOrder) do
        local expansion = entry.key
        local displayName = entry.name
        local enabled = ZoneLockedData.expansions and ZoneLockedData.expansions[expansion]
        local zoneList = ZoneLocked.ExpansionZones and ZoneLocked.ExpansionZones[expansion]
        local hasZones = zoneList and #zoneList > 0
        local forcedExpansions = ZoneLocked.GetForcedExpansionsByRace()
        local isForced = forcedExpansions[expansion]


        local column = ((i - 1) % columns)
        local row = math.floor((i - 1) / columns)

        local checkbox = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", startX + (column * spacingX), startY + (row * -perRowHeight))
        checkbox.Text:SetText("Enable " .. displayName)

        checkbox:SetChecked(enabled)
        checkbox:SetEnabled(hasZones)

        checkbox:SetChecked(enabled)
        checkbox:SetEnabled(hasZones and not isForced)

        if isForced then
            checkbox.Text:SetText("|cffaaaaaa" .. displayName .. " (required by race)|r")
            checkbox:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(displayName .. " is required by your character's race.")
                GameTooltip:AddLine("This expansion cannot be disabled.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            checkbox:SetScript("OnLeave", GameTooltip_Hide)
        elseif not hasZones then
            checkbox.Text:SetText("|cff888888Enable " .. displayName .. " (coming soon)|r")
            checkbox:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(displayName .. " is not supported yet.")
                GameTooltip:AddLine("No zones are defined for this expansion.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            checkbox:SetScript("OnLeave", GameTooltip_Hide)
        else
            checkbox:SetScript("OnClick", function(self)
                ZoneLockedData.expansions[expansion] = self:GetChecked()
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            end)
        end
    end

    -- 🔄 Reset Section Title
    local totalRows = math.ceil(#ZoneLocked.ExpansionOrder / columns)
    local resetTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetTitle:SetPoint("TOPLEFT", startX, startY + (totalRows * -perRowHeight) - 20)
    resetTitle:SetText("Reset Progress")

    local resetDesc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetDesc:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -4)
    resetDesc:SetWidth(500)
    resetDesc:SetJustifyH("LEFT")
    resetDesc:SetText("This will remove all unlocked zones and reset your mode.\nYour token balance will remain unchanged.")

    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(160, 24)
    resetBtn:SetText("Reset All Data")
    resetBtn:SetPoint("TOPLEFT", resetDesc, "BOTTOMLEFT", 0, -10)
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("ZONELOCKED_CONFIRM_RESET")
    end)

    parent.settingsTab = frame
    return frame
end

function ZoneLocked.UpdateModeTab()
    if ZoneLocked.MainUI and ZoneLocked.MainUI.contentFrames then
        local parent = ZoneLocked.MainUI.contentFrames[1]
        if parent and parent.modeTab then
            parent.modeTab:Hide()
            parent.modeTab:SetParent(nil)
            parent.modeTab = nil
        end
        ZoneLocked.SwitchTab(1)
    end
end

function ZoneLocked.CreateSkillModeSummaryTab(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT")

    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    content:SetSize(parent:GetWidth() - 20, 600)

    local skillPoints = ZoneLockedData.skillPoints or 0
    local tokensFromSkill = ZoneLockedData.tokensFromSkill or 0
    local nextCost = ZoneLocked.GetSkillTokenCost()

    -- Header
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 5, -10)
    title:SetText("|cffccccffZoneLocked Skill Mode|r")

    -- Info section
    local info = {
        "Skill Points earned: |cff00ff00" .. skillPoints .. "|r",
        "Tokens earned via skill: |cff00ff00" .. tokensFromSkill .. "|r",
        "Cost for next token: |cffffff00" .. nextCost .. " Skill Points|r",
        "",
        "Gain Skill Points by leveling your character or professions.",
        "Redeem tokens with: |cffffff00/zl token redeem|r"
    }

    local y = -40
    for _, text in ipairs(info) do
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 5, y)
        label:SetText(text)
        y = y - 18
    end

    -- Profession Progress Section
    local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", 5, y - 10)
    header:SetText("Profession Progress")

    local professionData = ZoneLockedData.professionProgress or {}

    -- Expansion max levels
    local expansionMax = {
        ["Classic"] = 300, ["Outland"] = 75, ["Northrend"] = 75,
        ["Cataclysm"] = 75, ["Pandaria"] = 75, ["Draenor"] = 100,
        ["Legion"] = 100, ["Kul Tiran"] = 175, ["Zandalari"] = 175,
        ["Shadowlands"] = 100, ["Dragon Isles"] = 100, ["Khaz Algar"] = 100,
    }

    -- Build 3-column layout
    local columns = {}
    local colIndex = 1
    local spacingX = 240
    local startX = 5
    local startY = y - 35

    for profession, expansions in pairs(professionData) do
        if type(expansions) == "table" then
            columns[colIndex] = columns[colIndex] or {}
            table.insert(columns[colIndex], { profession = profession, expansions = expansions })
            colIndex = colIndex + 1
            if colIndex > 3 then colIndex = 1 end
        end
    end

    -- Determine max number of sub-entries in any profession
    local maxSub = 0
    for _, col in ipairs(columns) do
        for _, entry in ipairs(col) do
            local count = 0
            for _ in pairs(entry.expansions) do count = count + 1 end
            if count > maxSub then maxSub = count end
        end
    end

    for i, col in ipairs(columns) do
        local x = startX + ((i - 1) * spacingX)
        local yOffset = startY

        for _, entry in ipairs(col) do
            local profLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            profLabel:SetPoint("TOPLEFT", x, yOffset)
            profLabel:SetText(entry.profession)
            yOffset = yOffset - 18

            local subCount = 0
            for name, level in pairs(entry.expansions) do
                local expansion = name:match("^(%w+)")
                local max = expansionMax[expansion] or 100

                local bg = CreateFrame("Frame", nil, content, "BackdropTemplate")
                bg:SetPoint("TOPLEFT", x, yOffset)
                bg:SetSize(220, 16)
                bg:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
                bg:SetBackdropColor(0.3, 0, 0.5, 0.6)

                local bar = CreateFrame("StatusBar", nil, bg)
                bar:SetAllPoints()
                bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                bar:SetStatusBarColor(0.2, 0.6, 1)
                bar:SetMinMaxValues(0, max)
                bar:SetValue(level)

                local txt = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                txt:SetPoint("CENTER")
                txt:SetText(level .. " / " .. max .. " - " .. name)

                yOffset = yOffset - 20
                subCount = subCount + 1
            end

            -- Pad with invisible rows to match tallest
            while subCount < maxSub do
                local spacer = CreateFrame("Frame", nil, content)
                spacer:SetPoint("TOPLEFT", x, yOffset)
                spacer:SetSize(220, 16)
                yOffset = yOffset - 20
                subCount = subCount + 1
            end
        end
    end
end

function ZoneLocked.ShowATTProgressUI()
    if not ZoneLockedData or ZoneLockedData.mode ~= "att" then return end
    if not ATT or not ATT.GetProgressForMap then return end

    -- Opprett UI hvis den ikke finnes
    if not ZoneLocked_ATT_UI then
        local f = CreateFrame("Frame", "ZoneLocked_ATT_UI", UIParent, "BasicFrameTemplateWithInset")
        f:SetSize(260, 90)
        f:SetPoint("TOPLEFT", 20, -100)
        f:SetMovable(true)
        f:EnableMouse(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.title:SetPoint("TOP", 0, -10)

        f.progressText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.progressText:SetPoint("TOP", f.title, "BOTTOM", 0, -6)

        f.progressBar = CreateFrame("StatusBar", nil, f)
        f.progressBar:SetSize(200, 16)
        f.progressBar:SetPoint("TOP", f.progressText, "BOTTOM", 0, -4)
        f.progressBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        f.progressBar:GetStatusBarTexture():SetHorizTile(false)
        f.progressBar:SetMinMaxValues(0, 100)
        f.progressBar:SetValue(0)
        f.progressBar:SetStatusBarColor(0.3, 1, 0.3)

        -- Lagre referanse
        ZoneLocked_ATT_UI = f
    end

    local frame = ZoneLocked_ATT_UI
    local mapID = C_Map.GetBestMapForUnit("player")

    -- Ikke vis hvis ikke i hovedsone
    if not mapID or not ZoneLocked.ATT_IsMainZone(mapID) then
        frame:Hide()
        return
    end

    local info = C_Map.GetMapInfo(mapID)
    local percent = ZoneLocked.ATT_GetProgress(mapID) or 0

    -- Dynamisk farge (rød → gul → grønn)
    local r = math.min(1, (100 - percent) / 50)
    local g = math.min(1, percent / 50)

    frame.title:SetText(info and info.name or "Unknown Zone")
    frame.progressText:SetText(string.format("Progress: %.1f%%", percent))
    frame.progressBar:SetValue(percent)
    frame.progressBar:SetStatusBarColor(r, g, 0)

    frame:Show()
end