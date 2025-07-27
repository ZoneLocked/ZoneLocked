ZoneLocked.SkillBarMixin = {}

function ZoneLocked.SkillBarMixin:UpdateBar()
    local current = ZoneLockedData.skillPoints or 0
    local needed = ZoneLocked.GetSkillTokenCost()
    self.bar:SetMinMaxValues(0, needed)
    self.bar:SetValue(current)
    self.text:SetText(current .. " / " .. needed .. " Skill Points")
end

function ZoneLocked.CreateSkillBar()
    if not ZoneLockedData or ZoneLockedData.mode ~= "skill" then return end
    if ZoneLocked.SkillBarFrame then return end

    local frame = CreateFrame("Frame", "ZoneLockedSkillBar", UIParent, "BackdropTemplate")
    frame:SetSize(300, 24)

    local x = ZoneLockedData.skillBarX or 0
    local y = ZoneLockedData.skillBarY or -200
    frame:SetPoint("CENTER", UIParent, "CENTER", x, y)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    frame:RegisterForDrag("LeftButton")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)

    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local _, _, _, x, y = self:GetPoint()
        ZoneLockedData.skillBarX = x
        ZoneLockedData.skillBarY = y
    end)

    -- 🔵 Statusbar
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(280, 16)
    bar:SetPoint("CENTER")
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.2, 0.6, 1)

    -- 🏷️ Tekst
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", bar, "CENTER", 0, 0)
    label:SetText("0 / 0 Skill Points")

    -- 🔄 Oppdatering
    function ZoneLocked.UpdateSkillBar()
        if not ZoneLocked.SkillBarFrame then return end
        local points = ZoneLockedData.skillPoints or 0
        local cost = ZoneLocked.GetSkillTokenCost()

        bar:SetMinMaxValues(0, cost)
        bar:SetValue(points)
        label:SetText(points .. " / " .. cost .. " Skill Points")
    end

    ZoneLocked.UpdateSkillBar()
    frame.bar = bar
    frame.label = label
    ZoneLocked.SkillBarFrame = frame
end

