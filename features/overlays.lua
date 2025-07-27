local overlays = ZoneLocked.overlays or {}
ZoneLocked.overlays = overlays

local function GetOverlay(index)
    if not overlays[index] then
        local frame = CreateFrame("Frame", nil, WorldMapFrame.ScrollContainer.Child)
        frame:SetFrameLevel(5000)
        frame:SetSize(40, 40)

        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetPoint("TOPLEFT", -4, 4)
        bg:SetPoint("BOTTOMRIGHT", 4, -4)
        bg:SetTexture("Interface\\AddOns\\ZoneLocked\\lock-icon.tga")
        bg:SetVertexColor(0, 0, 0, 1) -- solid black
        frame.bg = bg

        local tex = frame:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\AddOns\\ZoneLocked\\lock-icon.tga")
        tex:SetVertexColor(1, 1, 1, 1)
        frame.texture = tex

        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")

            local mapID = self.mapID
            local zoneName = C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or ("Zone " .. mapID)
            local continentMapID = ZoneLocked.GetContinentForZone(mapID)
            local isRandom = ZoneLockedData and ZoneLockedData.randomUnlock

            local function GetExpansionForZone(id)
                for expansion, zones in pairs(ZoneLocked.ExpansionZones or {}) do
                    if tContains(zones, id) then
                        return expansion
                    end
                end
                return nil
            end

            function ZoneLocked:GetExpansionName(key)
                for _, entry in ipairs(ZoneLocked.ExpansionOrder) do
                    if entry.key == key then
                        return entry.name
                    end
                end
                return key
            end

            local expansion = GetExpansionForZone(mapID)
            local isDisabled = expansion and ZoneLockedData.expansions and not ZoneLockedData.expansions[expansion]

            if isDisabled then
                GameTooltip:SetText(string.format("|cffff2020%s|r is locked.", zoneName))
                GameTooltip:AddLine(ZoneLocked:GetExpansionName(expansion) .. " is currently disabled.", 1, 1, 0.5, true)
                GameTooltip:AddLine("You can enable it in settings.", 0.8, 0.8, 0.8, true)
            elseif isRandom then
                GameTooltip:SetText(string.format("%s is sealed.\nFate decides when it will open...", zoneName))
            else
                local status = ZoneLocked.CanUnlockZone(mapID)
                if status == 1 then
                    GameTooltip:SetText(string.format("This zone is locked.\nClick to unlock |cff00ff00%s|r.", zoneName))
                elseif status == 2 then
                    GameTooltip:SetText(string.format("|cffff2020%s|r is locked.\nYou haven’t discovered any neighboring zones.", zoneName))
                elseif status == 3 then
                    GameTooltip:SetText(string.format("|cffff2020%s|r is locked.\nYou haven’t unlocked enough zones to enter this area.", zoneName))
                elseif status == 4 then
                    GameTooltip:SetText(string.format("|cffff2020%s|r is locked.", zoneName))
                    GameTooltip:AddLine("You need to unlock more zones and discover a neighboring area first.", 1, 1, 0.5, true)
                end

                local required = ZoneLocked.UnlockRequirements[continentMapID] or ZoneLocked.UnlockRequirements.default
                local ok, current = ZoneLocked.HasMinimumUnlocked(required)
                if not ok then
                    GameTooltip:AddLine(string.format("|cffffff00You must unlock at least %d zones (you have %d).|r", required, current))
                end
            end

            GameTooltip:Show()
        end)

        frame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame:SetScript("OnMouseDown", function(self)
            local mapID = self.mapID
            if not mapID then return end

            local mode = (ZoneLockedData and ZoneLockedData.mode) or "easy"
            local isRandom = ZoneLockedData and ZoneLockedData.randomUnlock

            if isRandom then
                ZoneLocked.Print("With Random Unlocks you can't manually unlock zones.")
                return
            end

            local status = ZoneLocked.CanUnlockZone(mapID)
            if status == 2 then
                ZoneLocked.Print("You can't unlock this zone yet.")
                return
            elseif status == 3 or status == 4 then
                ZoneLocked.Print("This zone is not yet available.")
            end

            if not ZoneLocked.IsZoneLocked(mapID) then return end

            if not ZoneLocked.CanUnlockZone(mapID) then
                ZoneLocked.Print("You must discover a neighboring zone before unlocking this one.")
                return
            end

            ZoneLocked.CreateUnlockConfirmFrame()

            local zoneName = C_Map.GetMapInfo(mapID) and C_Map.GetMapInfo(mapID).name or ("Zone " .. mapID)
            local tokens = ZoneLockedData.tokens or 0
            local f = ZoneLocked_ConfirmFrame
            local tokenColor = (tokens <= 0) and "|cffff2020" or "|cff00ff00"

            f.text:SetText(string.format(
                "Are you sure you want to unlock |cff00ff00%s|r?\nYou have %s%d|r unlock tokens remaining.",
                zoneName,
                tokenColor, tokens
            ))

            -- Disable or enable confirm button based on token count
            if tokens <= 0 then
                f.confirm:Disable()
                f.confirm:SetAlpha(0.5)
            else
                f.confirm:Enable()
                f.confirm:SetAlpha(1)
            end

            f:Show()

            f.confirm:SetScript("OnClick", function()
                local tokens = ZoneLockedData.tokens or 0
                if tokens <= 0 then
                    ZoneLocked.Print("You don't have any unlock tokens left!")
                    f:Hide()
                    return
                end

                ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
                ZoneLockedData.unlocked[mapID] = true
                ZoneLocked.Print("|cff00ff00" .. zoneName .. " unlocked!|r")

                local linked = ZoneLocked.unlockLinked[mapID]
                if linked then
                    for _, id in ipairs(linked) do
                        if not ZoneLockedData.unlocked[id] then
                            ZoneLockedData.unlocked[id] = true
                            local linkedName = C_Map.GetMapInfo(id) and C_Map.GetMapInfo(id).name or ("Zone " .. id)
                            ZoneLocked.Print("|cff00ff00" .. linkedName .. " unlocked!|r")
                        end
                    end
                end

                ZoneLocked.RemoveToken()

                ZoneLocked.RefreshMode()
                DrawLockedOverlays(WorldMapFrame:GetMapID())
                f:Hide()
            end)
        end)

        overlays[index] = frame
    end
    return overlays[index]
end


function DrawLockedOverlays(mapID)
    for _, overlay in ipairs(overlays) do overlay:Hide() end

    local mapW = WorldMapFrame.ScrollContainer.Child:GetWidth()
    local mapH = WorldMapFrame.ScrollContainer.Child:GetHeight()

    local zones = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone)
    if not zones then return end

    local zonePositions = ZoneLocked.ZonePositions[mapID]
    if not zonePositions then return end

    local i = 1
    for _, zone in ipairs(zones) do
        if ZoneLocked.IsZoneLocked(zone.mapID) then
            local pos = zonePositions[zone.mapID]
            if pos then
                local overlay = GetOverlay(i)
                overlay.mapID = zone.mapID

                local x = pos.x * mapW
                local y = pos.y * mapH

                overlay:SetPoint("CENTER", WorldMapFrame.ScrollContainer.Child, "TOPLEFT", x, -y)

                local status = ZoneLocked.CanUnlockZone(zone.mapID)
                if ZoneLockedData.randomUnlock then
                    if status == 1 then
                        -- Kan bli valgt neste gang: mørk gul
                        overlay.texture:SetDesaturated(false)
                        overlay.texture:SetVertexColor(1, 0.8, 0.2, 1)
                    else
                        -- Kan ikke bli valgt: rød
                        overlay.texture:SetDesaturated(true)
                        overlay.texture:SetVertexColor(1, 0, 0, 0.8)
                    end
                else
                    if status == 1 then
                        -- Klar for manuell opplåsing
                        overlay.texture:SetDesaturated(false)
                        overlay.texture:SetVertexColor(1, 0.8, 0.2, 1)
                    elseif status == 2 or status == 3 then
                        -- Ikke mulig å låse opp
                        overlay.texture:SetDesaturated(true)
                        overlay.texture:SetVertexColor(1, 0, 0, 0.8)
                    else
                        -- Fallback
                        overlay.texture:SetDesaturated(true)
                        overlay.texture:SetVertexColor(1, 1, 1, 0.5)
                    end
                end

                overlay:Show()
                i = i + 1
            end
        end
    end
end