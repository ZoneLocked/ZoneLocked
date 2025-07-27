local function CreateZoneLockedTab()
    if not CharacterFrame or not PaperDollFrame then
        print("ZoneLocked: CharacterFrame not ready.")
        return
    end

    -- Lag ny fane
    local tabID = CharacterFrame.numTabs + 1
    local tab = CreateFrame("Button", "CharacterFrameTab" .. tabID, CharacterFrame, "CharacterFrameTabButtonTemplate")
    tab:SetID(tabID)
    tab:SetText("ZoneLocked")
    tab:SetPoint("LEFT", _G["CharacterFrameTab" .. (tabID - 1)], "RIGHT", -15, 0)
    PanelTemplates_SetNumTabs(CharacterFrame, tabID)
    PanelTemplates_EnableTab(CharacterFrame, tabID)
    CharacterFrame.numTabs = tabID

    -- Lag innholdspanel
    local content = CreateFrame("Frame", "ZoneLockedCharacterPanel", CharacterFrame)
    content:SetAllPoints(PaperDollFrame)
    content:Hide()

    content.title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    content.title:SetPoint("TOP", 0, -20)
    content.title:SetText("Zone Locked")

    content.mode = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content.mode:SetPoint("TOPLEFT", 20, -60)

    content.unlocked = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content.unlocked:SetPoint("TOPLEFT", content.mode, "BOTTOMLEFT", 0, -10)

    content.outOfBounds = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    content.outOfBounds:SetPoint("TOPLEFT", content.unlocked, "BOTTOMLEFT", 0, -10)

    local function UpdatePanel()
        local mode = ZoneLockedData and ZoneLockedData.mode or "None"
        local count = 0
        for _, zoneList in pairs(ZoneLocked.ZonePositions or {}) do
            for id in pairs(zoneList) do
                if ZoneLockedData.unlocked and ZoneLockedData.unlocked[id] then
                    count = count + 1
                end
            end
        end
        local oob = ZoneLockedData.TimeOutofBounds or 0

        content.mode:SetText("Mode played: |cff00ff00" .. mode .. "|r")
        content.unlocked:SetText("Zones unlocked: |cffffff00" .. count .. "|r")
        content.outOfBounds:SetText("Times Out of Bounds: |cffff2020" .. oob .. "|r")
    end

    -- Håndter fane-klikk
    tab:SetScript("OnClick", function()
        -- Skjul alle andre paneler
        for i = 1, CharacterFrame.numTabs do
            local otherTab = _G["CharacterFrameTab" .. i]
            if otherTab and i ~= tabID then
                PanelTemplates_DeselectTab(otherTab)
            end
        end

        PaperDollFrame:Hide()
        ReputationFrame:Hide()
        TokenFrame:Hide()
        ZoneLockedCharacterPanel:Show()
        UpdatePanel()

        PanelTemplates_SelectTab(tab)
        CharacterFrame.selectedTab = tabID
    end)
end

ZoneLocked.CreateCharacterTab = CreateZoneLockedTab
