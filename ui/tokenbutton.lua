function ZoneLocked.CreateFloatingTokenButton()
    if ZoneLocked.FloatingTokenButton then return end
    if not ZoneLockedData.randomUnlock then return end


    local btn = CreateFrame("Button", "ZoneLockedFloatingTokenBtn", UIParent, "BackdropTemplate")
    btn:SetSize(48, 48)

    local pos = ZoneLockedData.floatingButtonPos
    if not pos or type(pos.x) ~= "number" or type(pos.y) ~= "number" then
        pos = { x = 0, y = 0 }
    end
    btn:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Icons\\Ability_BossMagistrix_TimeWarp2")

    btn:SetMovable(true)
    btn:EnableMouse(true)

    btn:SetScript("OnMouseDown", function(self, button)
        if IsAltKeyDown() then
            self:StartMoving()
        end
    end)

    btn:SetScript("OnMouseUp", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetLeft(), self:GetBottom()
        ZoneLockedData.floatingButtonPos = { x = x, y = y }
    end)

    btn:SetScript("OnClick", function()
        if IsAltKeyDown() then return end
        ZoneLocked.RedeemToken()
    end)

    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(btn, "ANCHOR_TOP")
        GameTooltip:SetText("Redeem Token")
        GameTooltip:AddLine("Click to use a token and unlock a new zone.", 1, 1, 1, true)
        GameTooltip:AddLine("Hold ALT to move this button.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:Hide()
    ZoneLocked.FloatingTokenButton = btn
end

function ZoneLocked.UpdateFloatingTokenButton()
    if not ZoneLocked.FloatingTokenButton then
        ZoneLocked.DebugPrint("⚠️ Button not created yet")
        return
    end

    ZoneLocked.DebugPrint("🔁 UpdateFloatingTokenButton called. Tokens:",  ZoneLockedData.tokens)

    if  ZoneLockedData.tokens > 0 then
        ZoneLocked.DebugPrint("▶️ Showing FloatingTokenButton")
        ZoneLocked.FloatingTokenButton:Show()
    else
        ZoneLocked.DebugPrint("⏹ Hiding FloatingTokenButton")
        ZoneLocked.FloatingTokenButton:Hide()
    end
end

function ZoneLocked.UnlockRandomZone()
    local available = ZoneLocked.GetAvailableConnectedZones()

    if #available == 0 then
        print("|cffff2020ZoneLocked:|r No connected zones are available to unlock (based on your settings).")
        return
    end

    local chosenMapID = available[math.random(#available)]

    ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
    ZoneLockedData.unlocked[chosenMapID] = true

    local linked = ZoneLocked.unlockLinked[chosenMapID]
    if linked then
        for _, id in ipairs(linked) do
            ZoneLockedData.unlocked[id] = true
        end
    end

    ZoneLocked.UpdateFloatingTokenButton()
    ZoneLocked.ShowUnlockAnimation(chosenMapID, available)
end