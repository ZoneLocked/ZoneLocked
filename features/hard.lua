function ZoneLocked.CheckAndConvertWoWToken()
    local tokenID = 122284
    local cooldownSeconds = 48 * 60 * 60 -- 48 timer

    local lastRedeem = ZoneLockedData.lastWoWTokenRedeem or 0
    local now = time()

    if now - lastRedeem < cooldownSeconds then
        local remaining = cooldownSeconds - (now - lastRedeem)
        local hours = math.floor(remaining / 3600)
        local minutes = math.floor((remaining % 3600) / 60)
        ZoneLocked.Print(string.format("You can redeem another WoW Token in %d hours and %d minutes.", hours, minutes))
        return false
    end

    if not ZoneLocked.PlayerHasItem(tokenID) then
        ZoneLocked.DebugPrint("No WoW Token found in your bags.")
        return false
    end

    ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
    ZoneLockedData.tokensFromToken = (ZoneLockedData.tokensFromToken or 0) + 1
    ZoneLockedData.lastWoWTokenRedeem = now

    ZoneLocked.Print("|cff88ff88+1 Unlock Token redeemed from WoW Token!|r (Cooldown: 48h)")
    ZoneLocked.UpdateFloatingTokenButton()

    return true
end

function ZoneLocked.CreateTokenRedeemButton()
    if ZoneLockedTokenButton then return end

    local btn = CreateFrame("Button", "ZoneLockedTokenButton", UIParent, "UIPanelButtonTemplate")
    btn:SetSize(160, 30)
    btn:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    btn:SetText("Redeem Unlock Token")

    btn:SetScript("OnClick", function()
        if ZoneLockedData.tokens and ZoneLockedData.tokens > 0 then
            if ZoneLockedData.randomUnlock then
                ZoneLocked.RedeemToken()
            else
                ZoneLocked.Print("You have a token! Open the map to choose a zone.")
            end
        else
            ZoneLocked.Print("You don't have any unlock tokens.")
        end

        ZoneLocked.UpdateFloatingTokenButton()
    end)

    btn:Hide()
    ZoneLocked.TokenRedeemButton = btn
end


function ZoneLocked.PlayerHasItem(itemID)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local id = C_Container.GetContainerItemID(bag, slot)
            if id == itemID then
                return true
            end
        end
    end
    return false
end
