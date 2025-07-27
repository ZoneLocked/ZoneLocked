StaticPopupDialogs["ZONELOCKED_CONFIRM_RESET"] = {
    text = "Are you sure you want to reset all unlocked zones?\nYour token balance will be reset to 0.",
    button1 = "Reset",
    button2 = "Cancel",
    OnAccept = function()
        ZoneLockedData = {}

        -- Behold tokens
        ZoneLockedData.tokens = 0
        ZoneLockedData.completedZones = {}
        ZoneLockedData.unlocked = {}

        -- Behold expansions forced by race
        ZoneLockedData.expansions = {
            Outland = false,
            Northrend = false,
            Cataclysm = false,
            Pandaria = false,
            Draenor = false,
            BrokenIsles = false,
            Shadowlands = false,
        }
        local forced = ZoneLocked.GetForcedExpansionsByRace()
        for k, v in pairs(forced) do
            ZoneLockedData.expansions[k] = true
        end

        -- Initial unlock (starting zone)
        local _, race = UnitRace("player")
        local defaultZone = ZoneLocked.RaceDefaults[string.lower(race)] or 37
        ZoneLocked.UnlockZoneWithLinked(defaultZone)

        -- UI updates
        if ZoneLocked_WarEffortFrame and ZoneLocked_WarEffortFrame:IsShown() then
            ZoneLocked_WarEffortFrame:Hide()
        end
        if ZoneLockedModeFrame and ZoneLockedModeFrame:IsShown() then
            ZoneLockedModeFrame:Hide()
        end

        C_Timer.After(0.1, function()
            StaticPopup_Hide("ZONELOCKED_CONFIRM_RESET")
            StaticPopup_Show("RELOAD_UI")
        end)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}


StaticPopupDialogs["ZONELOCKED_CONFIRM_REDEEM"] = {
    text = "Turn in all required items for 1 unlock token?",
    button1 = "Redeem",
    button2 = "Cancel",
    OnAccept = function()
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
        ZoneLocked.Print("You earned 1 unlock token through War Effort!")
        if ZoneLocked_WarEffortFrame and ZoneLocked_WarEffortFrame:IsShown() then
            ZoneLocked_WarEffortFrame:Hide()
        end
        ZoneLocked.UpdateFloatingTokenButton()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["ZONELOCKED_REDEEM_TOKEN"] = {
    text = "Redeem a WoW Token for 1 unlock token?\n(This will NOT consume the token.)",
    button1 = "Redeem",
    button2 = "Cancel",
    OnAccept = function()
        local hasToken = ZoneLocked.PlayerHasWoWToken()
        if hasToken then
            ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
            ZoneLocked.Print("+1 unlock token granted!")
            ZoneLocked.UpdateFloatingTokenButton()
        else
            ZoneLocked.Print("WoW Token not found in bags.")
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}