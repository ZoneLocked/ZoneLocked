local function IsExpansionSupported(mode)
    for _, projectID in ipairs(mode.expansions) do
        if projectID == WOW_PROJECT_ID then
            return true
        end
    end
    return false
end


ZoneLocked.modes = {
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "skill",
        name = "Skill",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 132272,
        color = { 0.8, 0.8, 1 },
        desc = "Level your character or professions to earn tokens.",
        onClick = function(frame)
            ZoneLockedData.mode = "skill"
            ZoneLocked.Print("Mode set to |cffccccffSkill|r.")
            frame:Hide()
            ZoneLocked.EnableSkillMode()
        end
    },
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "medium",
        name = "War Effort",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 132764,
        color = { 1, 1, 0.6 },
        desc = "Farm items to help your faction's war effort.",
        onClick = function(frame)
            ZoneLockedData.mode = "medium"
            ZoneLocked.Print("Mode set to |cffffff00War Effort|r.")
            frame:Hide()
        end
    },
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "manual",
        name = "Manual",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 132336, -- Velg annet ikon om ønskelig
        color = { 0.8, 1, 0.8 },
        desc = "Manually mark zones as complete when you decide.",
        onClick = function(frame)
            ZoneLockedData.mode = "manual"
            ZoneLocked.Print("Mode set to |cff88ff88Manual|r.")
            frame:Hide()
        end
    },
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "hard",
        name = "Token",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 133786,
        color = { 1, 0.8, 0.8 },
        desc = "Redeem WoW Tokens to unlock zones.",
        onClick = function(frame)
            ZoneLockedData.mode = "hard"
            ZoneLocked.Print("Mode set to |cffff4444Token|r.")
            frame:Hide()
        end
    },
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "loremaster",
        name = "Loremaster",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 133739,
        color = { 0.8, 0.8, 1 },
        desc = "Unlock Loremaster achievements to unlock zones.",
        onClick = function(frame)
            ZoneLockedData.mode = "loremaster"
            ZoneLocked.Print("Mode set to |cffff4444Loremaster|r.")
            ZoneLocked.EnableLoremasterMode()
            ZoneLocked.UpdateLoremasterAchievements()
            frame:Hide()
        end
    },
    {
        expansions = { WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC, WOW_PROJECT_CATACLYSM_CLASSIC, WOW_PROJECT_MISTS_CLASSIC },
        id = "att",
        name = "ATT Mode",
        bg = "Interface\\FrameGeneral\\UI-Background-Rock",
        icon = 237446,
        color = { 0.6, 1, 0.6 },
        desc = "Complete zones in All The Things to unlock new areas.",
        isDisabled = function()
            -- if C_AddOns and C_AddOns.IsAddOnLoaded then
            -- return not C_AddOns.IsAddOnLoaded("AllTheThings")
            -- end
            return true
        end,
        onClick = function(frame)
            if isDisabled then
                ZoneLocked.Print("|cffff5555All The Things is not loaded. Cannot activate ATT Mode.|r")
                return
            end

            ZoneLockedData.mode = "att"
            ZoneLocked.Print("Mode set to |cff55ff55ATT Mode|r.")
            frame:Hide()
            ZoneLocked.EnableATTMode()
        end
    }
}

function ZoneLocked.ShowModeSelection()
    if ZoneLockedModeFrame then
        ZoneLockedModeFrame:Show()
        return
    end

    local frame = CreateFrame("Frame", "ZoneLockedModeFrame", UIParent, "BackdropTemplate")
    frame:SetSize(520, 480)
    frame:SetPoint("CENTER")
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("ZoneLocked: Choose Unlock Mode")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local checkbox = CreateFrame("CheckButton", nil, frame, "ChatConfigCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", 20, -45)
    checkbox.Text:SetText("Randomly unlock next zone")
    checkbox:SetChecked(ZoneLockedData.randomUnlock)
    checkbox:SetScript("OnClick", function(self)
        ZoneLockedData.randomUnlock = self:GetChecked()
        ZoneLocked.Print("Random unlock mode " .. (ZoneLockedData.randomUnlock and "enabled" or "disabled") .. ".")
    end)

    -- ScrollFrame for modes
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -80)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local spacing = 10
    local cardHeight = 80
    local totalHeight = (#ZoneLocked.modes * (cardHeight + spacing)) - spacing
    content:SetHeight(totalHeight)

    local visibleIndex = 0

    for i, mode in ipairs(ZoneLocked.modes) do
        if IsExpansionSupported(mode) then
            local yOffset = -(visibleIndex * (cardHeight + spacing))
            visibleIndex = visibleIndex + 1
            local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
            card:SetSize(440, cardHeight)
            card:SetPoint("TOPLEFT", 0, yOffset)
            card:SetBackdrop({
                bgFile = mode.bg or "Interface/Tooltips/UI-Tooltip-Background",
                edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
                tile = true,
                tileSize = 16,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            card:SetBackdropColor(0.2, 0.2, 0.2, 0.8)

            local icon = card:CreateTexture(nil, "ARTWORK")
            icon:SetSize(48, 48)
            icon:SetPoint("LEFT", 10, 0)
            icon:SetTexture(mode.icon or "Interface/Icons/INV_Misc_QuestionMark")

            local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
            name:SetText(mode.name)
            if mode.color then name:SetTextColor(unpack(mode.color)) end

            local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
            desc:SetWidth(300)
            desc:SetJustifyH("LEFT")
            desc:SetText(mode.desc)

            local button = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
            button:SetSize(80, 24)
            button:SetPoint("RIGHT", -10, 0)

            local isActive = ZoneLockedData.mode == mode.id
            local isDisabled = mode.isDisabled and mode.isDisabled()

            if isActive then
                button:SetText("Active!")
                button:Disable()
            elseif isDisabled then
                button:SetText("Unavailable")
                button:Disable()
            else
                button:SetText("Activate")
                button:SetScript("OnClick", function()
                    if mode.onClick then mode.onClick(frame) end
                end)
            end
        end
    end

    content:SetHeight(visibleIndex * (cardHeight + spacing) - spacing)
end
