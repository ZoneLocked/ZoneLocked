function ZoneLocked.CreateWarEffortUI(parent)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 10, -10)
    title:SetText("War Effort Contributions")

    local iconSize = 32
    local columns = 4
    local colWidth = 180
    local rowHeight = 60
    local itemIndex = 0

    for _, item in ipairs(ZoneLocked.WarEffortRequirements or {}) do
        local itemID = item.itemID
        local timesRedeemed = (ZoneLockedData.redeemedItems and ZoneLockedData.redeemedItems[itemID]) or 0
        local requiredAmount = item.required * (2 ^ timesRedeemed)
        local playerCount = ZoneLocked.CountItemInBags(itemID)

        local col = itemIndex % columns
        local row = math.floor(itemIndex / columns)
        local x = 10 + col * colWidth
        local y = -40 - row * rowHeight

        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(colWidth, rowHeight)
        frame:SetPoint("TOPLEFT", x, y)

        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("TOPLEFT", 0, -4)

        local itemObj = Item:CreateFromItemID(itemID)
        itemObj:ContinueOnItemLoad(function()
            icon:SetTexture(itemObj:GetItemIcon() or "Interface\\Icons\\INV_Misc_QuestionMark")
        end)

        local nameLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameLabel:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
        nameLabel:SetText(item.name or ("Item " .. itemID))

        local progress = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        progress:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
        progress:SetText(playerCount .. "/" .. requiredAmount)

        if playerCount >= requiredAmount then
            local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
            btn:SetSize(60, 20)
            btn:SetPoint("LEFT", progress, "RIGHT", 8, 0)
            btn:SetText("Redeem")

            btn:SetScript("OnClick", function()
                btn:Disable()
                btn:SetText("Redeemed!")

                -- Consumable logic
                ZoneLocked.ConsumeItems(itemID, requiredAmount)
                ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1

                -- Track redemption
                ZoneLockedData.redeemedItems = ZoneLockedData.redeemedItems or {}
                ZoneLockedData.redeemedItems[itemID] = timesRedeemed + 1

                ZoneLocked.Print("Redeemed 1 token using " .. (item.name or "item") .. "!")

                ZoneLocked.SwitchTab(1) -- Refresh UI
                ZoneLocked.UpdateFloatingTokenButton()
            end)
        end

        itemIndex = itemIndex + 1
    end

    local tokenLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    tokenLabel:SetPoint("BOTTOM", 0, 12)
    tokenLabel:SetText("Current Unlock Tokens: " .. (ZoneLockedData.tokens or 0))
end
