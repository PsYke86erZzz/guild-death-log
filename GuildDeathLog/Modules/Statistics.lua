-- ══════════════════════════════════════════════════════════════
-- MODUL: Statistics - Erweiterte Statistiken
-- Tode nach Zone, Level-Verteilung, Klassen-Analyse
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Statistics = {}

local CLASS_NAMES_BY_ID = {
    [1] = "Krieger/Warrior", [2] = "Paladin", [3] = "Jäger/Hunter",
    [4] = "Schurke/Rogue", [5] = "Priester/Priest", [7] = "Schamane/Shaman",
    [8] = "Magier/Mage", [9] = "Hexenmeister/Warlock", [11] = "Druide/Druid"
}

function Statistics:Initialize()
    -- Nichts zu initialisieren
end

function Statistics:GetDeathsByZone()
    local guildData = GDL:GetGuildData()
    if not guildData then return {} end
    
    local zoneStats = {}
    
    for _, death in ipairs(guildData.deaths or {}) do
        local zone = death.zone or "Unbekannt/Unknown"
        if not zoneStats[zone] then
            zoneStats[zone] = {count = 0, avgLevel = 0, totalLevel = 0}
        end
        zoneStats[zone].count = zoneStats[zone].count + 1
        zoneStats[zone].totalLevel = zoneStats[zone].totalLevel + (death.level or 0)
    end
    
    -- Durchschnittslevel berechnen
    for zone, data in pairs(zoneStats) do
        if data.count > 0 then
            data.avgLevel = data.totalLevel / data.count
        end
    end
    
    -- In sortierte Liste umwandeln
    local sorted = {}
    for zone, data in pairs(zoneStats) do
        table.insert(sorted, {zone = zone, count = data.count, avgLevel = data.avgLevel})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    return sorted
end

function Statistics:GetDeathsByLevel()
    local guildData = GDL:GetGuildData()
    if not guildData then return {} end
    
    local levelStats = {}
    for i = 1, 60 do levelStats[i] = 0 end
    
    for _, death in ipairs(guildData.deaths or {}) do
        local level = death.level or 1
        if level >= 1 and level <= 60 then
            levelStats[level] = levelStats[level] + 1
        end
    end
    
    return levelStats
end

function Statistics:GetDeathsByClass()
    local guildData = GDL:GetGuildData()
    if not guildData then return {} end
    
    local classStats = {}
    
    for _, death in ipairs(guildData.deaths or {}) do
        local classId = death.classId or 0
        if not classStats[classId] then
            classStats[classId] = {count = 0, avgLevel = 0, totalLevel = 0, name = CLASS_NAMES_BY_ID[classId] or "Unknown"}
        end
        classStats[classId].count = classStats[classId].count + 1
        classStats[classId].totalLevel = classStats[classId].totalLevel + (death.level or 0)
    end
    
    -- Durchschnittslevel und sortieren
    local sorted = {}
    for classId, data in pairs(classStats) do
        if data.count > 0 then
            data.avgLevel = data.totalLevel / data.count
        end
        data.classId = classId
        table.insert(sorted, data)
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    return sorted
end

function Statistics:GetDeathsByTime()
    local guildData = GDL:GetGuildData()
    if not guildData then return {}, {} end
    
    local hourStats = {}
    local dayStats = {}
    for i = 0, 23 do hourStats[i] = 0 end
    for i = 1, 7 do dayStats[i] = 0 end
    
    for _, death in ipairs(guildData.deaths or {}) do
        if death.timestamp and death.timestamp > 0 then
            local hour = tonumber(date("%H", death.timestamp))
            local day = tonumber(date("%w", death.timestamp)) + 1 -- 1=Sunday
            if hour then hourStats[hour] = hourStats[hour] + 1 end
            if day then dayStats[day] = dayStats[day] + 1 end
        end
    end
    
    return hourStats, dayStats
end

function Statistics:GetDeathsByKiller()
    local guildData = GDL:GetGuildData()
    if not guildData then return {} end
    
    local killerStats = {}
    
    for _, death in ipairs(guildData.deaths or {}) do
        local killer = death.killerName or death.killer
        if killer and killer ~= "" and killer ~= "Unknown" then
            if not killerStats[killer] then
                killerStats[killer] = {count = 0, killerId = death.killerId or 0}
            end
            killerStats[killer].count = killerStats[killer].count + 1
        end
    end
    
    local sorted = {}
    for killer, data in pairs(killerStats) do
        table.insert(sorted, {name = killer, count = data.count, id = data.killerId})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    return sorted
end

function Statistics:GetDangerousZones(limit)
    limit = limit or 5
    local zones = self:GetDeathsByZone()
    local result = {}
    
    for i = 1, math.min(limit, #zones) do
        table.insert(result, zones[i])
    end
    
    return result
end

function Statistics:GetDeadliestKillers(limit)
    limit = limit or 5
    local killers = self:GetDeathsByKiller()
    local result = {}
    
    for i = 1, math.min(limit, #killers) do
        table.insert(result, killers[i])
    end
    
    return result
end

function Statistics:GetSummary()
    local guildData = GDL:GetGuildData()
    if not guildData then return {} end
    
    local deaths = guildData.deaths or {}
    local total = #deaths
    local now = time()
    local today = now - (now % 86400)
    local thisWeek = today - (7 * 86400)
    
    local todayCount, weekCount, levelSum, highestLevel, lowestLevel = 0, 0, 0, 0, 60
    
    for _, death in ipairs(deaths) do
        local ts = death.timestamp or 0
        local lvl = death.level or 0
        
        if ts >= today then todayCount = todayCount + 1 end
        if ts >= thisWeek then weekCount = weekCount + 1 end
        levelSum = levelSum + lvl
        if lvl > highestLevel then highestLevel = lvl end
        if lvl < lowestLevel and lvl > 0 then lowestLevel = lvl end
    end
    
    return {
        total = total,
        today = todayCount,
        thisWeek = weekCount,
        avgLevel = total > 0 and (levelSum / total) or 0,
        highestLevel = highestLevel,
        lowestLevel = total > 0 and lowestLevel or 0,
    }
end

GDL:RegisterModule("Statistics", Statistics)
