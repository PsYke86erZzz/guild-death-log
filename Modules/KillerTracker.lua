-- ══════════════════════════════════════════════════════════════
-- MODUL: KillerTracker - Todesursache verfolgen
-- Speichert welches Monster/welcher Spieler getötet hat
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local KillerTracker = {}

-- Speichert letzte Kampf-Infos pro Spieler
local combatInfo = {}
local COMBAT_TIMEOUT = 30 -- Sekunden

function KillerTracker:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    frame:SetScript("OnEvent", function()
        self:OnCombatLog()
    end)
    
    -- Cleanup Timer
    C_Timer.NewTicker(10, function() self:CleanupOldData() end)
end

function KillerTracker:OnCombatLog()
    local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags,
          destGUID, destName, destFlags, destRaidFlags, spellId, spellName = CombatLogGetCurrentEventInfo()
    
    if not destName or not destGUID then return end
    
    -- Nur Spieler tracken
    if not destGUID:match("^Player-") then return end
    
    local playerName = strsplit("-", destName)
    
    -- Damage Events speichern
    if subevent:match("_DAMAGE$") then
        self:RecordDamage(playerName, sourceGUID, sourceName, spellName)
    end
    
    -- Tod Event
    if subevent == "UNIT_DIED" then
        self:RecordDeath(playerName)
    end
end

function KillerTracker:RecordDamage(playerName, sourceGUID, sourceName, spellName)
    if not combatInfo[playerName] then
        combatInfo[playerName] = {}
    end
    
    combatInfo[playerName].lastDamage = {
        sourceGUID = sourceGUID,
        sourceName = sourceName or "Unknown",
        spellName = spellName,
        timestamp = time()
    }
    
    -- Source ID extrahieren (für NPCs)
    if sourceGUID then
        local sourceType, _, _, _, _, sourceId = strsplit("-", sourceGUID)
        if sourceType == "Creature" or sourceType == "Vehicle" then
            combatInfo[playerName].lastDamage.sourceId = tonumber(sourceId) or 0
        end
    end
end

function KillerTracker:RecordDeath(playerName)
    if combatInfo[playerName] and combatInfo[playerName].lastDamage then
        combatInfo[playerName].deathInfo = combatInfo[playerName].lastDamage
        combatInfo[playerName].deathInfo.deathTime = time()
    end
end

function KillerTracker:GetKiller(playerName)
    local name = strsplit("-", playerName)
    local info = combatInfo[name]
    
    if not info then return nil end
    
    -- Bevorzuge deathInfo, dann lastDamage
    local data = info.deathInfo or info.lastDamage
    
    if data and (time() - (data.timestamp or data.deathTime or 0)) < COMBAT_TIMEOUT then
        return {
            name = data.sourceName or "Unknown",
            id = data.sourceId or 0,
            spell = data.spellName,
            guid = data.sourceGUID
        }
    end
    
    return nil
end

function KillerTracker:GetKillerString(playerName)
    local killer = self:GetKiller(playerName)
    if not killer then return nil end
    
    local str = killer.name
    if killer.spell then
        str = str .. " (" .. killer.spell .. ")"
    end
    return str
end

function KillerTracker:CleanupOldData()
    local now = time()
    for name, info in pairs(combatInfo) do
        -- Alte Einträge entfernen (älter als 2 Minuten)
        if info.lastDamage and (now - (info.lastDamage.timestamp or 0)) > 120 then
            if not info.deathInfo then
                combatInfo[name] = nil
            else
                info.lastDamage = nil
            end
        end
        -- Sehr alte Tode entfernen (älter als 10 Minuten)
        if info.deathInfo and (now - (info.deathInfo.deathTime or 0)) > 600 then
            combatInfo[name] = nil
        end
    end
end

GDL:RegisterModule("KillerTracker", KillerTracker)
