function ZoneLocked.AddToken(n)
    local newAmount = (ZoneLockedData.tokens or 0) + n
    ZoneLockedData.tokens = newAmount
    ZoneLocked.UpdateFloatingTokenButton()
    ZoneLocked.DebugPrint("Added X tokens", n)
    local mode = ZoneLockedData.mode or "none"
end

function ZoneLocked.FullUIRefresh()
    if ZoneLockedData.mode == "manual" then
        ZoneLocked.RefreshManualTab()
    end
    ZoneLocked.UpdateFloatingTokenButton()
end

function ZoneLocked.RemoveToken(n)
    n = n or 1
    local newAmount = math.max((ZoneLockedData.tokens or 0) - n, 0)
    ZoneLockedData.tokens = newAmount
    ZoneLocked.UpdateFloatingTokenButton()
    ZoneLocked.DebugPrint("Removed X tokens", n)
end

function ZoneLocked.RedeemToken()
  if not ZoneLockedData.randomUnlock then
    ZoneLocked.Print("Random Unlock is not enabled. Use the map to choose a zone manually.")
    return
  end

  if (ZoneLockedData.tokens or 0) < 1 then
    ZoneLocked.Print("You don't have any unlock tokens.")
    return
  end

  ZoneLocked.RemoveToken()
  ZoneLocked.Print("Redeemed 1 token. Unlocking a random zone...")

  ZoneLocked.UpdateFloatingTokenButton()

  ZoneLocked.UnlockRandomZone()
end

function ZoneLocked.Print(msg, r, g, b)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffZoneLocked:|r " .. msg, r or 1, g or 1, b or 1)
    end
end

function ZoneLocked.UnlockZoneWithLinked(mapID)
    ZoneLocked.DebugPrint("Unlocking zone:", mapID)
    ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
    ZoneLockedData.unlocked[mapID] = true

    local linked = ZoneLocked.unlockLinked[mapID]
    if linked then
        for _, id in ipairs(linked) do
            ZoneLocked.DebugPrint("Also unlocking linked zone:", id)
            ZoneLockedData.unlocked[id] = true
        end
    end
end

function ZoneLocked.RemoveToken(n)
    n = n or 1
    local newAmount = math.max((ZoneLockedData.tokens or 0) - n, 0)
    ZoneLockedData.tokens = newAmount
    ZoneLocked.UpdateFloatingTokenButton()
    ZoneLocked.DebugPrint("Removed X tokens", n)
end


function ZoneLocked.IsExpansionEnabledForZone(mapID)
    for _, entry in ipairs(ZoneLocked.ExpansionOrder) do
        local expansion = entry.key
        local zoneIDs = ZoneLocked.ExpansionZones[expansion]
        if zoneIDs and tContains(zoneIDs, mapID) then
            return ZoneLockedData.expansions and ZoneLockedData.expansions[expansion] == true
        end
    end
    return true
end

function ZoneLocked.GetAllZoneIDs()
    local ids = {}
    for _, zoneTable in pairs(ZoneLocked.ZonePositions or {}) do
        for zoneID, _ in pairs(zoneTable) do
            table.insert(ids, zoneID)
        end
    end
    return ids
end

function ZoneLocked.CanUnlockZone(zoneID)
    if not zoneID or not ZoneLocked.ZonePositions then return 4 end
    if ZoneLockedData.unlocked and ZoneLockedData.unlocked[zoneID] then return 4 end

    -- Finn kontinent
    local continent = ZoneLocked.GetContinentForZone(zoneID)
    local required = ZoneLocked.UnlockRequirements[continent] or ZoneLocked.UnlockRequirements.default

    -- Tell antall unlockede
    local unlockedCount = 0
    for _, zoneList in pairs(ZoneLocked.ZonePositions) do
        for id, _ in pairs(zoneList) do
            if ZoneLockedData.unlocked and ZoneLockedData.unlocked[id] then
                unlockedCount = unlockedCount + 1
            end
        end
    end

    if unlockedCount < required then
        return 3 -- Ikke nok soner unlocket
    end

    -- Bruk ZoneConnections i stedet for zoneList
    for knownZoneID, connectedIDs in pairs(ZoneLocked.ZoneConnections or {}) do
        if ZoneLockedData.unlocked and ZoneLockedData.unlocked[knownZoneID] and tContains(connectedIDs, zoneID) then
            return 1 -- Klar for opplåsing
        end
    end

    return 2 -- Ikke nabo til noen unlockede soner
end

function ZoneLocked.IsZoneUnlocked(zoneID)
    return ZoneLockedData and ZoneLockedData.unlocked and ZoneLockedData.unlocked[zoneID]
end

function ZoneLocked.IsZoneCompleted(zoneID)
    return ZoneLockedData.completedZones and ZoneLockedData.completedZones[zoneID]
end

function ZoneLocked.MarkZoneCompleted(zoneID)
    ZoneLockedData.completedZones = ZoneLockedData.completedZones or {}

    if not ZoneLockedData.completedZones[zoneID] then
        ZoneLockedData.completedZones[zoneID] = true
        ZoneLocked.AddToken(1)

        if ZoneLockedData.randomUnlock and ZoneLockedData.mode == "manual" then
            -- Bruk tokenen direkte (uten å legge til først)
            ZoneLocked.RedeemToken()
        else
            -- Gi spiller en token
            ZoneLocked.Print((C_Map.GetMapInfo(zoneID).name or "Zone") .. " marked complete. +1 Unlock Token")
        end
    end
end

function ZoneLocked.UnlockZone(zoneID)
    ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
    ZoneLockedData.unlocked[zoneID] = true
    ZoneLocked.Print("Zone unlocked: " .. (C_Map.GetMapInfo(zoneID) and C_Map.GetMapInfo(zoneID).name or tostring(zoneID)))
end

function ZoneLocked.GetSortedZoneIDs(zonesTable)
    local ids = {}

    for id in pairs(zonesTable) do
        table.insert(ids, id)
    end

    table.sort(ids, function(a, b)
        local nameA = C_Map.GetMapInfo(a) and C_Map.GetMapInfo(a).name or ""
        local nameB = C_Map.GetMapInfo(b) and C_Map.GetMapInfo(b).name or ""
        return nameA < nameB
    end)

    return ids
end

function ZoneLocked.ConsumeItems(itemID, amount)
    local remaining = amount
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if remaining <= 0 then return end
            local id = C_Container.GetContainerItemID(bag, slot)
            if id == itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                local toRemove = math.min(info.stackCount, remaining)
                C_Container.UseContainerItem(bag, slot, nil, true)
                remaining = remaining - toRemove
            end
        end
    end
end

function ZoneLocked.HasMinimumUnlocked(required)
    local unlocked = 0
    for _, isUnlocked in pairs(ZoneLockedData.unlocked or {}) do
        if isUnlocked then unlocked = unlocked + 1 end
    end
    return unlocked >= required, unlocked
end

function ZoneLocked.ShowLoadingThen(fn)
    if not ZoneLocked_LoadingFrame then
        local f = CreateFrame("Frame", "ZoneLocked_LoadingFrame", UIParent, "BasicFrameTemplate")
        f:SetSize(300, 100)
        f:SetPoint("CENTER")
        f.text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        f.text:SetPoint("CENTER")
        f.text:SetText("Loading item data...")
        f:Hide()
    end

    ZoneLocked_LoadingFrame:Show()

    ZoneLocked.PreloadItemData(function()
        ZoneLocked_LoadingFrame:Hide()
        if fn then
            fn()
        end
    end)
end

function ZoneLocked.GetContinentForZone(mapID)
    if not mapID then
        ZoneLocked.DebugPrint("⚠️ mapID is nil in GetContinentForZone")
        return nil
    end
    ZoneLocked.DebugPrint("→ Finding continent for:", mapID)

    local continentMapIDs = {}
    for continentID in pairs(ZoneLocked.ZonePositions) do
        continentMapIDs[continentID] = true
    end

    local mapInfo = C_Map.GetMapInfo(mapID)
    while mapInfo and not continentMapIDs[mapInfo.mapID] do
        mapInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
    end

    ZoneLocked.DebugPrint("→ Final continent for", mapID, "=", mapInfo and mapInfo.mapID or "nil")
    return mapInfo and mapInfo.mapID
end

function ZoneLocked.GetUnlocked()
    return ZoneLockedData.unlocked or {}
end

function ZoneLocked.CountItemInBags(itemID)
    local count = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = C_Container.GetContainerItemID(bag, slot)
            if item == itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                count = count + (info.stackCount or 1)
            end
        end
    end
    return count
end

function ZoneLocked.CheckATTZoneCompletion()
    if not ATT or not ATT.Search then return end

    local currentMapID = C_Map.GetBestMapForUnit("player")
    if not currentMapID then return end

    local function GetTopLevelMap(mapID)
        local info = C_Map.GetMapInfo(mapID)
        if info and info.parentMapID and info.parentMapID ~= 946 then
            return GetTopLevelMap(info.parentMapID)
        end
        return mapID
    end

    local topLevelID = GetTopLevelMap(currentMapID)

    -- Ikke sjekk hvis sonen allerede er registrert som "ferdig"
    ZoneLockedData.completedATT = ZoneLockedData.completedATT or {}
    if ZoneLockedData.completedATT[topLevelID] then return end

    local results = ATT.Search("mapID", topLevelID)
    for _, entry in ipairs(results or {}) do
        if entry.progress and entry.total and entry.progress >= entry.total then
            -- ✅ Ferdig!
            ZoneLockedData.completedATT[topLevelID] = true
            ZoneLocked.AddToken(1)
            ZoneLocked.Print("Completed |cff00ff00" .. (C_Map.GetMapInfo(topLevelID).name or "Unknown Zone") .. "|r via ATT! +1 Token")
            break
        end
    end
end


function ZoneLocked.GetAvailableConnectedZones()
    local available = {}

    for mapID, neighbors in pairs(ZoneLocked.ZoneConnections or {}) do
        if not ZoneLockedData.unlocked[mapID] then
            for _, neighborID in ipairs(neighbors) do
                ZoneLocked.DebugPrint("Checking neighbor:", neighborID, "→", ZoneLockedData.unlocked[neighborID])
                if ZoneLockedData.unlocked[neighborID] then
                    if not ZoneLocked.IsExpansionEnabledForZone(mapID) then
                        ZoneLocked.DebugPrint("❌ Skipping (disabled expansion)")
                        break
                    end

                    table.insert(available, mapID)
                    ZoneLocked.DebugPrint("✅ Added to available")
                    break
                end
            end
        end
    end

    ZoneLocked.DebugPrint("Total available connected zones:", #available)
    return available
end
