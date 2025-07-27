ZoneLocked = ZoneLocked or {}
ZoneLockedData = ZoneLockedData or {}


ZoneLockedData.tokens = ZoneLockedData.tokens or 0
ZoneLocked.overlays = ZoneLocked.overlays or {}
ZoneLocked.RaceDefaults = ZoneLocked.RaceDefaults or {}
ZoneLocked.ConnectedZones = ZoneLocked.ConnectedZones or {}
ZoneLockedData.unlocked = ZoneLockedData.unlocked or {}
ZoneLockedData.skillPoints = ZoneLockedData.skillPoints or 0
ZoneLockedData.tokensFromSkill = ZoneLockedData.tokensFromSkill or 0
ZoneLockedData.professionProgress = ZoneLockedData.professionProgress or {}
ZoneLocked.lastCompletedZones = {}
ZoneLockedData.tokensFromToken = ZoneLockedData.tokensFromToken or 0
ZoneLocked.TimeOutofBounds = ZoneLockedData.TimeOutofBounds or 0
ZoneLockedData.attClaimedZones = ZoneLockedData.attClaimedZones or {}
ZoneLockedData.completedZones = ZoneLockedData.completedZones or {}

ZoneLocked.debug = ZoneLockedData.debug or false
ZoneLockedData.expansions = ZoneLockedData.expansions or {
    Outland = false,
    Northrend = false,
    Cataclysm = false,
    Pandaria = false,
    Draenor = false,
    BrokenIsles = false,
    Shadowlands = false,
}

local addonName, addon = ...
if _G.AllTheThings then
    ZoneLocked.ATT = _G.AllTheThings
elseif addon and addon.AllTheThings then
    ZoneLocked.ATT = addon.AllTheThings
elseif type(select(2, ...)) == "table" and select(2, ...).GetProgressForMap then
    ZoneLocked.ATT = select(2, ...)
end
