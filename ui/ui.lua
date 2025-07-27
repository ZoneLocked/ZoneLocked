function ZoneLocked.CreateUI()
    if ZoneLockedUI then return end -- already created

    local frame = CreateFrame("Frame", "ZoneLockedUI", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(850, 550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if self:IsMovable() then self:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -10)
    frame.title:SetText("ZoneLocked Status")

    -- Scrollable content area
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -30)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    frame.content = content
    frame.scrollFrame = scrollFrame

    -- Reset All button (bottom right, with confirmation)
    local resetBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("BOTTOMRIGHT", -10, 10)
    resetBtn:SetText("Reset All")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("ZONELOCKED_CONFIRM_RESET")
    end)

    frame:Hide()
end

function ZoneLocked.CreateUnlockConfirmFrame()
    if ZoneLocked_ConfirmFrame then return end

    local f = CreateFrame("Frame", "ZoneLocked_ConfirmFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(350, 140)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.text:SetPoint("TOP", 0, -30)
    f.text:SetText("")

    f.confirm = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.confirm:SetSize(100, 25)
    f.confirm:SetPoint("BOTTOMLEFT", 20, 15)
    f.confirm:SetText("Unlock")

    f.cancel = CreateFrame("Button", nil, f, "GameMenuButtonTemplate")
    f.cancel:SetSize(100, 25)
    f.cancel:SetPoint("BOTTOMRIGHT", -20, 15)
    f.cancel:SetText("Cancel")
    f.cancel:SetScript("OnClick", function()
        f:Hide()
    end)
end

-- Define WoW Token check
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

function ZoneLocked.CreateDangerFrame()
    if ZoneLocked_DangerFrame then return end

    local f = CreateFrame("Frame", "ZoneLocked_DangerFrame", UIParent)
    f:SetAllPoints(UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")

    f.texture = f:CreateTexture(nil, "BACKGROUND")
    f.texture:SetAllPoints()
    f.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
    f.texture:SetVertexColor(1, 0, 0, 0.6) -- red tint with transparency
    f:Hide()

    f.fade = f:CreateAnimationGroup()

    f.fadeOut = f.fade:CreateAnimation("Alpha")
    f.fadeOut:SetFromAlpha(0.6)
    f.fadeOut:SetToAlpha(0.2)
    f.fadeOut:SetDuration(0.6)
    f.fadeOut:SetOrder(1)

    f.fadeIn = f.fade:CreateAnimation("Alpha")
    f.fadeIn:SetFromAlpha(0.2)
    f.fadeIn:SetToAlpha(0.6)
    f.fadeIn:SetDuration(0.6)
    f.fadeIn:SetOrder(2)

    f.fade:SetLooping("REPEAT")
end

function ZoneLocked.ShowUnlockAnimation(finalMapID, available)
    if not finalMapID or not available then return end

    local zoneName = C_Map.GetMapInfo(finalMapID) and C_Map.GetMapInfo(finalMapID).name or "a zone"

    local f = ZoneLocked_UnlockFrame or CreateFrame("Frame", "ZoneLocked_UnlockFrame", UIParent, "BackdropTemplate")
    f:SetSize(300, 100)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Show()

    if not f.text then
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.text:SetPoint("CENTER")
    end

    -- Spinning animation
    local currentTick = 0
    local totalTicks = 25
    local ticker

    ticker = C_Timer.NewTicker(0.08, function()
        currentTick = currentTick + 1
        local randomIndex = math.random(#available)
        local spinningMapID = available[randomIndex]
        local name = C_Map.GetMapInfo(spinningMapID)
        f.text:SetText("Rolling...\n|cff00ff00" .. (name and name.name or "???") .. "|r")

        if currentTick >= totalTicks then
            ticker:Cancel()

            -- Final reveal
            f.text:SetText("Unlocked:\n|cff00ff00" .. zoneName .. "|r")
            
            -- Update the floating token button display
            ZoneLocked.UpdateFloatingTokenButton()

            -- Delay chat message slightly after visual
            C_Timer.After(0.5, function()
                ZoneLocked.RefreshMode()
                print("|cff00ccffZoneLocked:|r |cff00ff00" .. zoneName .. " unlocked!|r")
            end)

            -- Auto close after a bit
            C_Timer.After(2.5, function()
                f:Hide()
            end)
        end
    end)
end
