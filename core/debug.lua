hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
    if ZoneLocked.debug then
        local mapID = WorldMapFrame:GetMapID()
        if mapID then
            print("|cff00ccffZoneLocked Debug:|r Viewing mapID =", mapID)
        end
    end
end)

function ZoneLocked.DebugPrint(...)
    if ZoneLocked.debug then
        print("|cff00ccff[ZoneLocked Debug]|r", ...)
    end
end
