function ZoneLocked.RegisterCommands()
    SLASH_ZONELOCKED1 = "/zl"
    SlashCmdList["ZONELOCKED"] = function(msg)
        local args = {}
        for word in msg:gmatch("%S+") do
            table.insert(args, word)
        end

        local sub = args[1] and args[1]:lower() or "open"

        -- /zl open or /zl menu
        if sub == "open" or sub == "menu" then
            ZoneLocked.ShowMainUI()
            return
        end

        -- /zl token [add|remove|show] [amount]
        if sub == "token" then
            local action = args[2] and args[2]:lower()
            local count = tonumber(args[3]) or 1

            if action == "add" then
                ZoneLocked.AddToken(count)
                ZoneLocked.Print(count .. " token(s) added.")
                if ZoneLockedData.randomUnlock then
                    ZoneLocked.Print("|cffffff00Random mode is enabled.|r Use |cff00ccff/zl redeem [n]|r to unlock zones.")
                end

            elseif action == "remove" then
                ZoneLocked.RemoveToken(count)
                ZoneLocked.Print(count .. " token(s) removed.")

            elseif action == "show" then
                ZoneLocked.Print("You have |cff00ff00" .. (ZoneLockedData.tokens or 0) .. "|r unlock tokens.")

            else
                ZoneLocked.Print("Usage: /zl token [add|remove|show] [amount]")
            end
            return
        end

        -- /zl redeem [n]
        if sub == "redeem" then
            local n = tonumber(args[2]) or 1
            for i = 1, n do
                C_Timer.After((i - 1) * 1.2, ZoneLocked.RedeemToken)
            end
            return
        end

        -- /zl bank [name]
        if sub == "bank" then
            if args[2] then
                ZoneLockedData.bankAlt = args[2]
                ZoneLocked.Print("Bank alt set to: " .. args[2])
            else
                ZoneLocked.Print("Current bank alt: " .. (ZoneLockedData.bankAlt or "none"))
            end
            return
        end

        -- /zl reset
        if sub == "reset" then
            StaticPopup_Show("ZONELOCKED_CONFIRM_RESET")
            return
        end

        -- /zl mode
        if sub == "mode" then
            ZoneLocked.ShowModeSelection()
            return
        end

        -- /zl random [on|off]
        if sub == "random" then
            local toggle = args[2] and args[2]:lower()
            if toggle == "on" then
                ZoneLockedData.randomUnlock = true
                ZoneLocked.Print("Random zone unlock is now |cff00ff00ENABLED|r.")
            elseif toggle == "off" then
                ZoneLockedData.randomUnlock = false
                ZoneLocked.Print("Random zone unlock is now |cffff0000DISABLED|r.")
            else
                local status = ZoneLockedData.randomUnlock and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"
                ZoneLocked.Print("Random zone unlock is currently: " .. status)
            end
            return
        end

         -- /zl debug
        if sub == "debug" then
            ZoneLockedData.debug = not ZoneLockedData.debug
            ZoneLocked.debug = ZoneLockedData.debug
            local state = ZoneLocked.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"
            ZoneLocked.Print("Debug mode is now " .. state)
            return
        end

        -- /zl help
        if sub == "help" then
            ZoneLocked.Print("|cffffff00ZoneLocked Help|r")
            print("/zl open – Open the UI")
            print("/zl menu – Open the tabbed interface")
            print("/zl token [add|remove|show] [amount] – Manage your unlock tokens")
            print("/zl redeem [n] – Use tokens to unlock zones")
            print("/zl bank [name] – Set or show your bank alt for gold mode")
            print("/zl reset – Reset all unlocked zones (confirmation required)")
            print("/zl mode – Show difficulty selection window")
            print("/zl random [on|off] – Toggle random zone unlock")
            print("/zl help – Show this help text")
            return
        end

        -- Unknown fallback
        ZoneLocked.Print("Unknown command. Try |cffffff00/zl help|r.")
    end
end
