-- ══════════════════════════════════════════════════════════════
-- KILL STATS MODULE - Tracks kills by creature type
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local KillStats = {}

-- Cache für Kreaturtypen (GUID -> Type)
local creatureTypeCache = {}
local CACHE_CLEANUP_INTERVAL = 60  -- Sekunden
local CACHE_MAX_AGE = 300  -- 5 Minuten

-- Kreaturtyp-Mapping (EN -> DE für Anzeige)
local CREATURE_TYPE_NAMES = {
    ["Undead"] = "Untoter",
    ["Dragonkin"] = "Drachkin",
    ["Demon"] = "Dämon",
    ["Elemental"] = "Elementar",
    ["Beast"] = "Wildtier",
    ["Humanoid"] = "Humanoid",
    ["Giant"] = "Riese",
    ["Mechanical"] = "Mechanisch",
    ["Critter"] = "Kleintier",
    -- Deutsche Rückgaben (falls Client auf Deutsch)
    ["Untoter"] = "Untoter",
    ["Drachkin"] = "Drachkin",
    ["Dämon"] = "Dämon",
    ["Elementar"] = "Elementar",
    ["Wildtier"] = "Wildtier",
    ["Humanoid"] = "Humanoid",
    ["Riese"] = "Riese",
    ["Mechanisch"] = "Mechanisch",
    ["Kleintier"] = "Kleintier",
}

-- Normalisiere Kreaturtyp zu englischem Key
local TYPE_TO_KEY = {
    ["Undead"] = "undead",
    ["Untoter"] = "undead",
    ["Dragonkin"] = "dragonkin",
    ["Drachkin"] = "dragonkin",
    ["Demon"] = "demon",
    ["Dämon"] = "demon",
    ["Elemental"] = "elemental",
    ["Elementar"] = "elemental",
    ["Beast"] = "beast",
    ["Wildtier"] = "beast",
    ["Humanoid"] = "humanoid",
    ["Giant"] = "giant",
    ["Riese"] = "giant",
    ["Mechanical"] = "mechanical",
    ["Mechanisch"] = "mechanical",
    ["Critter"] = "critter",
    ["Kleintier"] = "critter",
}

-- ══════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════════════════════════

function KillStats:OnInitialize()
    -- Sicherstellen dass SavedVariables existiert
    if not GuildDeathLogDB then GuildDeathLogDB = {} end
    if not GuildDeathLogDB.killStats then
        GuildDeathLogDB.killStats = {}
    end
    
    self:RegisterEvents()
    
    -- Cache-Cleanup Timer
    C_Timer.NewTicker(CACHE_CLEANUP_INTERVAL, function()
        self:CleanupCache()
    end)
    
    -- Beim Login: Prüfe alle existierenden Kills auf verpasste Meilensteine
    C_Timer.After(6, function()
        self:CheckAllMilestones()
    end)
    
    GDL:Debug("KillStats: Modul initialisiert")
end

-- Prüft alle Kill-Stats und schaltet verpasste Meilensteine frei
function KillStats:CheckAllMilestones()
    local charKey = self:GetCharacterKey()
    local stats = GuildDeathLogDB.killStats[charKey]
    if not stats then return end
    
    GDL:Debug("KillStats: Prüfe alle Meilensteine...")
    
    for typeKey, count in pairs(stats) do
        if count > 0 then
            self:CheckMilestones(typeKey, count)
        end
    end
end

-- Manuelle Prüfung mit Feedback
function KillStats:RecheckAllMilestones()
    local charKey = self:GetCharacterKey()
    local stats = GuildDeathLogDB.killStats[charKey]
    if not stats then 
        GDL:Print("|cffFF0000Keine Kill-Statistiken gefunden!|r")
        return 
    end
    
    GDL:Print("|cffFFD100Prüfe Kill-Meilensteine...|r")
    
    local unlocked = 0
    for typeKey, count in pairs(stats) do
        if count > 0 then
            local before = self:CountUnlockedMilestones(typeKey)
            self:CheckMilestones(typeKey, count)
            local after = self:CountUnlockedMilestones(typeKey)
            unlocked = unlocked + (after - before)
        end
    end
    
    if unlocked > 0 then
        GDL:Print("|cff00FF00" .. unlocked .. " Meilensteine nachträglich freigeschaltet!|r")
    else
        GDL:Print("|cff888888Alle Meilensteine sind bereits freigeschaltet.|r")
    end
end

function KillStats:CountUnlockedMilestones(typeKey)
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return 0 end
    
    local charKey = self:GetCharacterKey()
    local charData = Milestones:GetCharacterData(charKey)
    if not charData or not charData.unlocked then return 0 end
    
    local count = 0
    for id, _ in pairs(charData.unlocked) do
        if id:match("^kill_" .. typeKey) then
            count = count + 1
        end
    end
    return count
end

function KillStats:RegisterEvents()
    local frame = CreateFrame("Frame")
    self.eventFrame = frame
    
    frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_TARGET_CHANGED" then
            self:CacheCreatureType("target")
        elseif event == "UPDATE_MOUSEOVER_UNIT" then
            self:CacheCreatureType("mouseover")
        elseif event == "NAME_PLATE_UNIT_ADDED" then
            local unitToken = ...
            self:CacheCreatureType(unitToken)
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
            self:HandleCombatLog()
        end
    end)
end

-- ══════════════════════════════════════════════════════════════
-- CREATURE TYPE CACHING
-- ══════════════════════════════════════════════════════════════

function KillStats:CacheCreatureType(unitToken)
    if not unitToken then return end
    if not UnitExists(unitToken) then return end
    if UnitIsPlayer(unitToken) then return end  -- Keine Spieler
    
    local guid = UnitGUID(unitToken)
    if not guid then return end
    
    -- Nur Creatures cachen
    if not guid:match("^Creature") then return end
    
    -- Bereits gecached?
    if creatureTypeCache[guid] and creatureTypeCache[guid].type then
        creatureTypeCache[guid].time = time()  -- Refresh timestamp
        return
    end
    
    local creatureType = UnitCreatureType(unitToken)
    if creatureType and creatureType ~= "" then
        creatureTypeCache[guid] = {
            type = creatureType,
            name = UnitName(unitToken),
            time = time(),
            damagedByPlayer = false  -- NEU: Haben WIR Schaden gemacht?
        }
        GDL:Debug("KillStats: Cached " .. (UnitName(unitToken) or "?") .. " als " .. creatureType)
    end
end

function KillStats:CleanupCache()
    local now = time()
    local cleaned = 0
    for guid, data in pairs(creatureTypeCache) do
        if now - data.time > CACHE_MAX_AGE then
            creatureTypeCache[guid] = nil
            cleaned = cleaned + 1
        end
    end
    if cleaned > 0 then
        GDL:Debug("KillStats: " .. cleaned .. " alte Cache-Einträge entfernt")
    end
end

-- ══════════════════════════════════════════════════════════════
-- COMBAT LOG HANDLING
-- ══════════════════════════════════════════════════════════════

function KillStats:HandleCombatLog()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, 
          destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
    
    local playerGUID = UnitGUID("player")
    local petGUID = UnitGUID("pet")  -- Auch Pet-Kills zaehlen
    
    -- Bei Schaden: Markieren dass WIR diesen Mob angegriffen haben
    if subevent and subevent:match("_DAMAGE") then
        -- Schaden von uns oder unserem Pet
        if sourceGUID == playerGUID or sourceGUID == petGUID then
            -- Mob cachen falls noch nicht
            if destGUID and destGUID:match("^Creature") then
                -- Falls nicht im Cache, versuche zu cachen
                if not creatureTypeCache[destGUID] then
                    if destGUID == UnitGUID("target") then
                        self:CacheCreatureType("target")
                    end
                end
                -- Markiere dass WIR Schaden gemacht haben
                if creatureTypeCache[destGUID] then
                    creatureTypeCache[destGUID].damagedByPlayer = true
                    creatureTypeCache[destGUID].time = time()
                end
            end
        end
    end
    
    -- Bei Kill: Zählen (NUR wenn WIR Schaden gemacht haben!)
    if subevent == "PARTY_KILL" then
        -- PARTY_KILL: sourceGUID ist der Killer - nur wenn WIR oder unser PET
        if sourceGUID == playerGUID or sourceGUID == petGUID then
            self:ProcessKill(destGUID, destName)
        end
    elseif subevent == "UNIT_DIED" then
        -- UNIT_DIED: NUR zaehlen wenn wir den Mob SELBST angegriffen haben!
        local cacheData = creatureTypeCache[destGUID]
        if cacheData and cacheData.damagedByPlayer then
            self:ProcessKill(destGUID, destName)
        end
    end
end

function KillStats:ProcessKill(guid, name)
    if not guid then return end
    
    -- Nur Creatures
    if not guid:match("^Creature") then return end
    
    -- Kreaturtyp aus Cache holen
    local cacheData = creatureTypeCache[guid]
    if not cacheData or not cacheData.type then
        GDL:Debug("KillStats: Kein Typ für " .. (name or "?") .. " im Cache")
        return
    end
    
    local creatureType = cacheData.type
    local typeKey = TYPE_TO_KEY[creatureType]
    
    if not typeKey then
        GDL:Debug("KillStats: Unbekannter Typ: " .. creatureType)
        return
    end
    
    -- Kill zählen
    local charKey = self:GetCharacterKey()
    if not GuildDeathLogDB.killStats[charKey] then
        GuildDeathLogDB.killStats[charKey] = {}
    end
    
    local stats = GuildDeathLogDB.killStats[charKey]
    stats[typeKey] = (stats[typeKey] or 0) + 1
    
    GDL:Debug("KillStats: " .. (name or "?") .. " (" .. creatureType .. ") getötet! Gesamt: " .. stats[typeKey])
    
    -- Cache aufräumen
    creatureTypeCache[guid] = nil
    
    -- Meilensteine prüfen
    self:CheckMilestones(typeKey, stats[typeKey])
end

-- ══════════════════════════════════════════════════════════════
-- CHARACTER KEY
-- ══════════════════════════════════════════════════════════════

function KillStats:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- ══════════════════════════════════════════════════════════════
-- MILESTONE INTEGRATION
-- ══════════════════════════════════════════════════════════════

function KillStats:CheckMilestones(typeKey, count)
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then 
        GDL:Debug("KillStats: Milestones Modul nicht gefunden!")
        return 
    end
    
    -- Sicherstellen dass DB existiert
    if not GuildDeathLogDB or not GuildDeathLogDB.milestones then
        GDL:Debug("KillStats: GuildDeathLogDB.milestones nicht initialisiert!")
        return
    end
    
    -- Meilenstein-IDs basierend auf Typ und Anzahl (ALLE Stufen!)
    local milestoneThresholds = {
        humanoid = {25, 100, 500, 2000},
        beast = {25, 100, 500, 2000},
        undead = {25, 100, 500, 1000, 5000},
        demon = {25, 100, 500, 1000},
        elemental = {25, 100, 500},
        dragonkin = {10, 50, 250, 1000},
        giant = {10, 50, 250},
    }
    
    local thresholds = milestoneThresholds[typeKey]
    if not thresholds then return end
    
    for _, threshold in ipairs(thresholds) do
        if count >= threshold then
            local milestoneId = "kill_" .. typeKey .. "_" .. threshold
            local charKey = self:GetCharacterKey()
            local charName = UnitName("player")
            local level = UnitLevel("player")
            
            -- Prüfen ob bereits freigeschaltet
            local charData = Milestones:GetCharacterData(charKey)
            if charData and charData.unlocked and not charData.unlocked[milestoneId] then
                GDL:Debug("KillStats: Schalte frei: " .. milestoneId .. " (count=" .. count .. ", threshold=" .. threshold .. ")")
                Milestones:UnlockMilestone(milestoneId, charKey, charName, level, false)
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- STATS ABFRAGEN
-- ══════════════════════════════════════════════════════════════

function KillStats:GetStats(charKey)
    charKey = charKey or self:GetCharacterKey()
    return GuildDeathLogDB.killStats[charKey] or {}
end

function KillStats:GetKillCount(typeKey, charKey)
    local stats = self:GetStats(charKey)
    return stats[typeKey] or 0
end

function KillStats:GetTotalKills(charKey)
    local stats = self:GetStats(charKey)
    local total = 0
    for _, count in pairs(stats) do
        total = total + count
    end
    return total
end

-- Debug: Zeige alle Stats
function KillStats:PrintStats()
    local stats = self:GetStats()
    GDL:Print("=== Kill-Statistiken ===")
    GDL:Print("Gesamt: " .. self:GetTotalKills())
    for typeKey, count in pairs(stats) do
        GDL:Print("  " .. typeKey .. ": " .. count)
    end
end

-- Recheck: Prüfe ALLE bestehenden Kills auf Meilensteine
function KillStats:RecheckAllMilestones()
    local stats = self:GetStats()
    local unlockedCount = 0
    
    GDL:Print("|cffFFD100Pruefe alle Kill-Meilensteine...|r")
    
    for typeKey, count in pairs(stats) do
        if count > 0 then
            -- CheckMilestones für jeden Typ aufrufen
            local beforeCheck = self:CountUnlockedMilestones()
            self:CheckMilestones(typeKey, count)
            local afterCheck = self:CountUnlockedMilestones()
            unlockedCount = unlockedCount + (afterCheck - beforeCheck)
        end
    end
    
    if unlockedCount > 0 then
        GDL:Print("|cff00FF00" .. unlockedCount .. " neue Meilensteine freigeschaltet!|r")
    else
        GDL:Print("|cff888888Keine neuen Meilensteine.|r")
    end
end

-- Zähle freigeschaltete Kill-Meilensteine
function KillStats:CountUnlockedMilestones()
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return 0 end
    
    local charKey = self:GetCharacterKey()
    local charData = Milestones:GetCharacterData(charKey)
    if not charData or not charData.unlocked then return 0 end
    
    local count = 0
    for id, _ in pairs(charData.unlocked) do
        if id:match("^kill_") then
            count = count + 1
        end
    end
    return count
end

-- =============================================================
-- MODULE INITIALIZATION
-- =============================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function()
            KillStats:OnInitialize()
        end)
        -- Automatischer Recheck nach 5 Sekunden
        C_Timer.After(5, function()
            KillStats:RecheckAllMilestones()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

-- Modul registrieren
GDL:RegisterModule("KillStats", KillStats)
