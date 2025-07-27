function ZoneLocked.GetSkillTokenCost()
    local redeemed = ZoneLockedData.tokensFromSkill or 0
    return math.floor(100 * math.pow(1.1, redeemed))
end

function ZoneLocked.EnableSkillMode()
    ZoneLocked.DebugPrint("EnableSkillMode() called")
    if not ZoneLocked.SkillEventFrame then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_LEVEL_UP")
        f:RegisterEvent("CHAT_MSG_SKILL")
        f:SetScript("OnEvent", ZoneLocked.Skill_OnEvent)
        ZoneLocked.SkillEventFrame = f
    end
end

function ZoneLocked.UpdateSkillModeButton()
    if not ZoneLocked.SkillModeButton then return end

    local tokensEarned = ZoneLockedData.tokensFromSkill or 0
    local cost = ZoneLocked.GetSkillTokenCost()
    local points = ZoneLockedData.skillPoints or 0

    if points >= cost then
        ZoneLocked.SkillModeButton:SetText("Redeem for " .. cost)
        ZoneLocked.SkillModeButton:Enable()
    else
        ZoneLocked.SkillModeButton:SetText(points .. " / " .. cost)
        ZoneLocked.SkillModeButton:Disable()
    end
end

function ZoneLocked.AddSkillPoint()
    ZoneLockedData.skillPoints = (ZoneLockedData.skillPoints or 0) + 1
    ZoneLocked.DebugPrint("Skill Point added. Total now: " .. ZoneLockedData.skillPoints)
    ZoneLocked.UpdateSkillModeButton()
    

    --ZoneLocked.UpdateSkillBar()

    while ZoneLockedData.skillPoints >= ZoneLocked.GetSkillTokenCost() do
        local cost = ZoneLocked.GetSkillTokenCost()
        ZoneLocked.DebugPrint("Enough skill points to redeem a token. Cost: " .. cost)

        ZoneLockedData.skillPoints = ZoneLockedData.skillPoints - cost
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
        ZoneLockedData.tokensFromSkill = (ZoneLockedData.tokensFromSkill or 0) + 1

        ZoneLocked.DebugPrint("Token redeemed! Remaining Skill Points: " .. ZoneLockedData.skillPoints)
        ZoneLocked.DebugPrint("Total tokens from skill: " .. ZoneLockedData.tokensFromSkill)

        if ZoneLockedData.randomUnlock then
            ZoneLocked.DebugPrint("Random unlock enabled. Unlocking zone...")
            ZoneLocked.RedeemToken()
        else
            ZoneLocked.Print("You earned a Skill Token! You can now unlock a new zone on the map.")
        end
    end
    ZoneLocked.UpdateModeTab()
end

function ZoneLocked.Skill_OnEvent(self, event, ...)
    ZoneLocked.DebugPrint("Skill_OnEvent fired: " .. tostring(event))

    if event == "PLAYER_LEVEL_UP" then
        local newLevel = ...
        ZoneLocked.DebugPrint("Level up detected! New level: " .. tostring(newLevel))

        ZoneLocked.AddSkillPoint()
        ZoneLocked.Print("+1 Skill Point for leveling up!")

    elseif event == "CHAT_MSG_SKILL" then
        local msg = ...
        ZoneLocked.DebugPrint("CHAT_MSG_SKILL: " .. tostring(msg))

        local skillName, level = msg:match("Your skill in (.+) has increased to (%d+)")
        if skillName and level then
            level = tonumber(level)
            ZoneLockedData.professionProgress = ZoneLockedData.professionProgress or {}

            -- Finn hovedkategori
            local main = skillName:match("Cooking") and "Cooking"
                      or skillName:match("Fishing") and "Fishing"
                      or skillName:match("Herbalism") and "Herbalism"
                      or skillName:match("Skinning") and "Skinning"
                      or skillName:match("Mining") and "Mining"
                      or skillName:match("Blacksmithing") and "Blacksmithing"
                      or skillName:match("Alchemy") and "Alchemy"
                      or skillName:match("Engineering") and "Engineering"
                      or skillName:match("Tailoring") and "Tailoring"
                      or skillName:match("Enchanting") and "Enchanting"
                      or skillName:match("Inscription") and "Inscription"
                      or skillName:match("Jewelcrafting") and "Jewelcrafting"
                      or skillName:match("Leatherworking") and "Leatherworking"
                      or "Other"

            ZoneLockedData.professionProgress[main] = ZoneLockedData.professionProgress[main] or {}
            local prevBest = ZoneLockedData.professionProgress[main][skillName] or 0

            if level > prevBest then
                ZoneLockedData.professionProgress[main][skillName] = level
                ZoneLocked.AddSkillPoint()
                ZoneLocked.Print("+1 Skill Point for leveling " .. skillName .. " to " .. level .. "!")
            else
                ZoneLocked.DebugPrint("Level up ignored: " .. skillName .. " was previously at " .. prevBest)
            end
        else
            ZoneLocked.DebugPrint("Message did not match expected pattern.")
        end

    else
        ZoneLocked.DebugPrint("Unhandled event: " .. tostring(event))
    end
end


function ZoneLocked.CreateSkillModeButton()
    ZoneLocked.DebugPrint("CreateSkillModeButton() called")
    if ZoneLockedSkillButton then return end

    local btn = CreateFrame("Button", "ZoneLockedSkillButton", UIParent, "UIPanelButtonTemplate")
    btn:SetSize(180, 30)
    btn:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
    btn:SetText("Redeem Skill Points")

    btn:SetScript("OnClick", function()
        local tokensEarned = ZoneLockedData.tokensFromSkill or 0
        local cost = 1 + tokensEarned

        if (ZoneLockedData.skillPoints or 0) < cost then
            ZoneLocked.Print("Not enough skill points. Need " .. cost .. ".")
            return
        end

        ZoneLockedData.skillPoints = ZoneLockedData.skillPoints - cost
        ZoneLockedData.tokensFromSkill = tokensEarned + 1
        ZoneLockedData.tokens = (ZoneLockedData.tokens or 0) + 1
        ZoneLockedData.tokens = ZoneLockedData.tokens

        ZoneLocked.Print("+1 Unlock Token redeemed for " .. cost .. " Skill Points!")
        ZoneLocked.UpdateFloatingTokenButton()
        btn:SetText("Redeemed!")
        C_Timer.After(1.5, function()
            btn:SetText("Redeem Skill Points")
        end)
    end)

    btn:Hide()
    ZoneLocked.SkillModeButton = btn
end
