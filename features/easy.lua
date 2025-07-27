function ZoneLocked.CreateEasyModeSummaryTab(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT")
    
    local content = CreateFrame("Frame", nil, scroll)
    scroll:SetScrollChild(content)
    content:SetSize(parent:GetWidth() - 20, 100)

    local totalGold = ZoneLockedData.goldSent or 0
    local tokensFromGold = ZoneLockedData.tokensFromGold or 0
    local nextThreshold = ZoneLocked.Easy_NextThreshold()
    local bankAlt = ZoneLockedData.bankAlt or "not set"

    local lines = {
        "|cff00ccffZoneLocked Easy Mode|r",
        "",
        "Total gold sent to bank alt: |cff00ff00" .. math.floor(totalGold) .. "g|r",
        "Next unlock token at: |cffffff00" .. math.floor(nextThreshold) .. "g|r",
        "Tokens earned via gold: |cff00ff00" .. tokensFromGold .. "|r",
        "",
        "Send gold to |cffffcc00" .. bankAlt .. "|r via in-game mail to progress.",
        "To set your bank alt, use: |cffffff00/zl bank <name>|r",
        "Tokens are granted automatically when you pass each threshold."
    }

    local y = -10
    for _, text in ipairs(lines) do
        local label = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 10, y)
        label:SetWidth(content:GetWidth() - 20)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(true)
        label:SetText(text)
        y = y - 20
    end
end

function ZoneLocked.Easy_NextThreshold()
    local level = UnitLevel("player")
    local tokensEarned = ZoneLockedData.tokensFromGold or 0

    -- Jevn økning per token
    local baseThreshold = 750 + (tokensEarned * 250)

    -- For hver 10. level → gang med 5
    local multiplier = math.max(1, math.floor(level / 10)) * 5

    return baseThreshold * multiplier
end

hooksecurefunc("SendMail", function(recipient, subject, body)
    local gold = GetSendMailMoney() / COPPER_PER_GOLD
    local bankAlt = ZoneLockedData.bankAlt and ZoneLockedData.bankAlt:lower()
    local to = recipient and recipient:lower()

    if not gold or gold <= 0 or gold ~= gold then return end
    if not bankAlt or to ~= bankAlt then return end

    ZoneLockedData.goldSent = (ZoneLockedData.goldSent or 0) + gold
    ZoneLocked.Print("Sent " .. gold .. "g to " .. recipient .. ". Total sent: " .. ZoneLockedData.goldSent .. "g")

    while true do
        local threshold = ZoneLocked.Easy_NextThreshold()
        if ZoneLockedData.goldSent < threshold then break end

        ZoneLockedData.tokensFromGold = (ZoneLockedData.tokensFromGold or 0) + 1
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
        ZoneLocked.Print("+1 Unlock Token earned for sending " .. threshold .. "g!", 0, 1, 0)
    end

    ZoneLocked.UpdateFloatingTokenButton()
end)