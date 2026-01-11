-- ══════════════════════════════════════════════════════════════
-- MODUL: Deathlog - Integration mit Deathlog Addon
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Deathlog = {}

local deathlogAvailable = false
local deathlogEntryCount = 0
local deathlogGuildDeaths = 0
local lastScan = 0
local deathlogAddonName = nil  -- Name des erkannten Deathlog-Addons

function Deathlog:Initialize()
    -- Mehrere Versuche mit Verzögerung (Deathlog lädt evtl. später)
    C_Timer.After(2, function() self:DetectDeathlog() end)
    C_Timer.After(5, function() self:DetectDeathlog() end)
    C_Timer.After(10, function() self:DetectDeathlog() end)
end

function Deathlog:DetectDeathlog()
    -- Bereits erkannt? Dann nur Daten scannen
    if deathlogAvailable then
        self:ScanData()
        return
    end
    
    GDL:Debug("Deathlog: Suche nach Deathlog-Addon...")
    
    -- ═══════════════════════════════════════════════════════════════
    -- METHODE 1: DeathNotificationLib Hook (bevorzugt)
    -- ═══════════════════════════════════════════════════════════════
    if _G["DeathNotificationLib_HookOnNewEntry"] then
        GDL:Debug("Deathlog: DeathNotificationLib gefunden!")
        DeathNotificationLib_HookOnNewEntry(function(playerData, checksum, peerReport, inGuild)
            self:OnDeathNotification(playerData, inGuild)
        end)
        deathlogAvailable = true
        deathlogAddonName = "DeathNotificationLib"
        self:ScanData()
        return
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- METHODE 2: Verschiedene Deathlog SavedVariables prüfen
    -- ═══════════════════════════════════════════════════════════════
    local possibleDataTables = {
        "deathlog_data",        -- Standard
        "DeathlogData",         -- Alternative Schreibweise
        "DEATHLOG_DATA",        -- Großbuchstaben
        "Deathlog_Data",        -- Mixed
        "deathlogData",         -- camelCase
        "DeathlogDB",           -- DB Variante
        "deathlogDB",           -- DB camelCase
        "hardcore_character_data",  -- Hardcore Addon
        "HardcoreDeathlogData",     -- Hardcore Deathlog
        "HardcoreDeaths",           -- Weitere Variante
        "deathlog_settings",        -- Settings könnten auch existieren
    }
    
    for _, varName in ipairs(possibleDataTables) do
        if _G[varName] and type(_G[varName]) == "table" then
            GDL:Debug("Deathlog: SavedVariable '" .. varName .. "' gefunden!")
            deathlogAvailable = true
            deathlogAddonName = varName
            self:ScanData()
            return
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- METHODE 3: Deathlog Addon-Tabelle selbst prüfen
    -- ═══════════════════════════════════════════════════════════════
    local possibleAddonTables = {
        "Deathlog",
        "DeathLog", 
        "DEATHLOG",
        "deathlog",
        "HardcoreDeathLog",
        "HardcoreDeathlog",
        "Hardcore",
        "HCDeathlog",
    }
    
    for _, varName in ipairs(possibleAddonTables) do
        local addonTable = _G[varName]
        if addonTable and type(addonTable) == "table" then
            -- Prüfe ob es wirklich das Deathlog-Addon ist (hat Daten oder Funktionen)
            if addonTable.data or addonTable.deaths or addonTable.entries or addonTable.db or 
               addonTable.GetDeaths or addonTable.OnDeath or addonTable.character_data then
                GDL:Debug("Deathlog: Addon-Tabelle '" .. varName .. "' gefunden!")
                deathlogAvailable = true
                deathlogAddonName = varName
                self:ScanData()
                return
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════════
    -- METHODE 4: Prüfe ob Addon geladen ist (über GetAddOnInfo)
    -- ═══════════════════════════════════════════════════════════════
    local deathlogAddons = {
        "Deathlog", "DeathLog", "deathlog", 
        "Hardcore_Deathlog", "HardcoreDeathlog",
        "Hardcore", "HardcoreAddon",
        "ClassicHardcore", "Classic_Hardcore",
    }
    for _, name in ipairs(deathlogAddons) do
        local loaded = false
        if C_AddOns and C_AddOns.IsAddOnLoaded then
            loaded = C_AddOns.IsAddOnLoaded(name)
        elseif IsAddOnLoaded then
            loaded = IsAddOnLoaded(name)
        end
        if loaded then
            GDL:Debug("Deathlog: Addon '" .. name .. "' ist geladen (Daten noch nicht verfuegbar)")
            deathlogAddonName = name .. " (geladen, warte auf Daten)"
            -- Nochmal später prüfen
            C_Timer.After(5, function() self:DetectDeathlog() end)
            return
        end
    end
    
    GDL:Debug("Deathlog: Kein Deathlog-Addon gefunden")
end

function Deathlog:OnEvent(event)
    if event == "PLAYER_READY" then
        C_Timer.After(5, function() self:DetectDeathlog() end)
    end
end

function Deathlog:SetupHooks()
    -- Legacy-Funktion - wird jetzt in DetectDeathlog() gemacht
    self:DetectDeathlog()
end

function Deathlog:OnDeathNotification(playerData, inGuild)
    GDL:Debug("DeathNotification erhalten: " .. (playerData and playerData.name or "nil"))
    
    if not playerData or not playerData.name or not GDL.currentGuildName then 
        GDL:Debug("DeathNotification: Daten unvollstaendig")
        return 
    end
    
    local isGuildDeath = inGuild or (playerData.guild and playerData.guild == GDL.currentGuildName)
    if not isGuildDeath then 
        GDL:Debug("DeathNotification: " .. playerData.name .. " nicht in unserer Gilde")
        return 
    end
    
    GDL:Debug("DeathNotification: " .. playerData.name .. " ist Gildenmitglied!")
    
    -- Koordinaten extrahieren (Vector2D hat .x und .y ODER [1] und [2])
    local posX, posY = 0, 0
    if playerData.map_pos then
        if playerData.map_pos.x then
            posX = playerData.map_pos.x
            posY = playerData.map_pos.y
        elseif playerData.map_pos[1] then
            posX = playerData.map_pos[1]
            posY = playerData.map_pos[2]
        end
    end
    
    local death = {
        name = playerData.name,
        level = playerData.level or 0,
        classId = playerData.class_id or 0,
        zone = self:GetZoneName(playerData.map_id),
        mapId = playerData.map_id or 0,
        posX = posX,
        posY = posY,
        lastWords = playerData.last_words or "",
        timestamp = playerData.date or time(),
    }
    
    local Sync = GDL:GetModule("Sync")
    if Sync then Sync:RecordLocalDeath(death) end
end

function Deathlog:OnHardcoreDeathEvent(name, level, classId, zoneName)
    if not name then return end
    
    local Guild = GDL:GetModule("Guild")
    if not Guild or not Guild:IsMember(name) then return end
    
    local death = {name = name, level = level or 0, classId = classId or 0, zone = zoneName or GDL:L("UNKNOWN"), timestamp = time()}
    
    local Sync = GDL:GetModule("Sync")
    if Sync then Sync:RecordLocalDeath(death) end
end

function Deathlog:ScanData()
    if time() - lastScan < 30 then return end
    lastScan = time()
    
    deathlogEntryCount = 0
    deathlogGuildDeaths = 0
    
    -- ═══════════════════════════════════════════════════════════════
    -- Finde die Deathlog-Daten in verschiedenen möglichen Strukturen
    -- ═══════════════════════════════════════════════════════════════
    local dataSource = nil
    
    -- Mögliche SavedVariable-Namen
    local possibleSources = {
        _G["deathlog_data"],
        _G["DeathlogData"],
        _G["DEATHLOG_DATA"],
        _G["Deathlog_Data"],
        _G["deathlogData"],
    }
    
    for _, source in ipairs(possibleSources) do
        if source and type(source) == "table" then
            dataSource = source
            break
        end
    end
    
    -- Falls nicht gefunden, prüfe Addon-Tabellen
    if not dataSource then
        local addonTables = {"Deathlog", "DeathLog", "DEATHLOG", "deathlog"}
        for _, name in ipairs(addonTables) do
            local t = _G[name]
            if t and type(t) == "table" then
                -- Verschiedene mögliche Daten-Keys
                dataSource = t.data or t.deaths or t.entries or t.db or t.saved or t
                if dataSource and type(dataSource) == "table" and next(dataSource) then
                    break
                end
            end
        end
    end
    
    if not dataSource or type(dataSource) ~= "table" then
        -- Kein Fehler wenn bereits als verfügbar markiert (Hook aktiv)
        if not deathlogAvailable then
            GDL:Debug("Deathlog: Keine Datenquelle gefunden")
        end
        return
    end
    
    deathlogAvailable = true
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    local Sync = GDL:GetModule("Sync")
    local importedCount = 0
    
    -- ═══════════════════════════════════════════════════════════════
    -- Durchsuche die Daten (verschiedene Strukturen unterstützt)
    -- ═══════════════════════════════════════════════════════════════
    
    -- Struktur 1: {realmName = {playerKey = entry}}
    for key1, value1 in pairs(dataSource) do
        if type(value1) == "table" then
            -- Ist es eine Realm-Tabelle oder direkt ein Entry?
            if value1.name or value1.level or value1.class_id then
                -- Direkt ein Entry
                deathlogEntryCount = deathlogEntryCount + 1
                local imported = self:TryImportEntry(value1, key1, guildData, Sync)
                if imported then importedCount = importedCount + 1 end
            else
                -- Eine Realm/Kategorie-Tabelle
                for key2, entry in pairs(value1) do
                    if type(entry) == "table" then
                        deathlogEntryCount = deathlogEntryCount + 1
                        local imported = self:TryImportEntry(entry, key2, guildData, Sync)
                        if imported then importedCount = importedCount + 1 end
                    end
                end
            end
        end
    end
    
    if importedCount > 0 then
        GDL:Debug("Deathlog: " .. importedCount .. " neue Gildentode importiert")
    end
    
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
end

-- Hilfsfunktion: Versuche einen Eintrag zu importieren
function Deathlog:TryImportEntry(entry, playerKey, guildData, Sync)
    if not entry or type(entry) ~= "table" then return false end
    
    -- Prüfe ob es ein Gildenmitglied ist
    local entryGuild = entry.guild or entry.guildName or entry.guild_name
    if not GDL.currentGuildName then return false end
    if not entryGuild or entryGuild ~= GDL.currentGuildName then return false end
    
    deathlogGuildDeaths = deathlogGuildDeaths + 1
    
    -- Koordinaten extrahieren
    local posX, posY = 0, 0
    local mapPos = entry.map_pos or entry.mapPos or entry.position
    if mapPos then
        if mapPos.x then
            posX = mapPos.x
            posY = mapPos.y
        elseif mapPos[1] then
            posX = mapPos[1]
            posY = mapPos[2]
        end
    end
    
    -- Name extrahieren
    local name = entry.name or entry.playerName or entry.player_name
    if not name and playerKey then
        name = playerKey:match("^([^%-]+)") or playerKey
    end
    
    local death = {
        name = name,
        level = entry.level or entry.playerLevel or 0,
        classId = entry.class_id or entry.classId or entry.class or 0,
        zone = self:GetZoneName(entry.map_id or entry.mapId or entry.mapID),
        mapId = entry.map_id or entry.mapId or entry.mapID or 0,
        posX = posX,
        posY = posY,
        timestamp = entry.date or entry.timestamp or entry.time or 0,
        lastWords = entry.last_words or entry.lastWords or "",
        fromDeathlog = true,
    }
    
    if Sync and not Sync:IsDuplicate(death) then
        table.insert(guildData.deaths, death)
        return true
    end
    
    return false
end

function Deathlog:GetZoneName(mapId)
    if not mapId or mapId == 0 then return GDL:L("UNKNOWN") end
    local mapInfo = C_Map.GetMapInfo(mapId)
    return mapInfo and mapInfo.name or GDL:L("UNKNOWN")
end

function Deathlog:IsAvailable() return deathlogAvailable end

function Deathlog:GetStats()
    return {
        available = deathlogAvailable, 
        totalEntries = deathlogEntryCount, 
        guildDeaths = deathlogGuildDeaths,
        addonName = deathlogAddonName or "Nicht erkannt"
    }
end

-- Debug-Befehl: Zeige alle globalen Variablen die "death" enthalten
function Deathlog:DebugGlobals()
    GDL:Print("=== Deathlog Debug ===")
    GDL:Print("Status: " .. (deathlogAvailable and "|cff00FF00JA|r" or "|cffFF0000NEIN|r"))
    GDL:Print("Erkannt als: " .. (deathlogAddonName or "nichts"))
    GDL:Print("Eintraege: " .. deathlogEntryCount)
    GDL:Print("Gildentode: " .. deathlogGuildDeaths)
    
    -- Spezifische Checks
    GDL:Print("--- Spezifische Checks ---")
    GDL:Print("DeathNotificationLib_HookOnNewEntry: " .. ((_G["DeathNotificationLib_HookOnNewEntry"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    GDL:Print("deathlog_data: " .. ((_G["deathlog_data"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    GDL:Print("Deathlog: " .. ((_G["Deathlog"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    GDL:Print("DeathlogDB: " .. ((_G["DeathlogDB"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    GDL:Print("HardcoreDeathLog: " .. ((_G["HardcoreDeathLog"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    GDL:Print("hardcore_character_data: " .. ((_G["hardcore_character_data"] and "|cff00FF00JA|r") or "|cffFF0000NEIN|r"))
    
    -- Suche nach globalen Variablen die relevant sein könnten
    GDL:Print("--- Alle 'death/hardcore' Variablen ---")
    local found = 0
    for k, v in pairs(_G) do
        local kLower = k:lower()
        -- Spezifischer suchen: death, hardcore, deathlog
        if kLower:find("death") or kLower:find("hardcore") or kLower:find("fallen") then
            -- Aber NICHT unser eigenes Addon
            if not k:find("GuildDeathLog") then
                if type(v) == "table" then
                    local count = 0
                    for _ in pairs(v) do count = count + 1 end
                    GDL:Print("  |cff00FF00" .. k .. "|r (table, " .. count .. " entries)")
                    found = found + 1
                elseif type(v) == "function" then
                    GDL:Print("  |cffFFFF00" .. k .. "|r (function)")
                    found = found + 1
                end
            end
        end
    end
    
    if found == 0 then
        GDL:Print("  |cffFF0000Keine relevanten Variablen gefunden!|r")
        GDL:Print("  ")
        GDL:Print("|cffFFAAAAIst Deathlog wirklich installiert?|r")
        GDL:Print("Pruefe: AddOns-Ordner und ob es aktiviert ist!")
    end
    
    -- Prüfe geladene Addons
    GDL:Print("--- Geladene Addons mit 'death/hardcore' ---")
    local addonCount = C_AddOns and C_AddOns.GetNumAddOns and C_AddOns.GetNumAddOns() or GetNumAddOns()
    local foundAddons = 0
    for i = 1, addonCount do
        local name, title, notes, loadable, reason, security
        if C_AddOns and C_AddOns.GetAddOnInfo then
            name, title, notes, loadable, reason, security = C_AddOns.GetAddOnInfo(i)
        else
            name, title, notes, loadable, reason, security = GetAddOnInfo(i)
        end
        local nameLower = (name or ""):lower()
        if nameLower:find("death") or nameLower:find("hardcore") then
            local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(i) or IsAddOnLoaded(i)
            local status = loaded and "|cff00FF00GELADEN|r" or "|cffFF0000NICHT GELADEN|r"
            GDL:Print("  " .. (name or "?") .. " - " .. status)
            foundAddons = foundAddons + 1
        end
    end
    if foundAddons == 0 then
        GDL:Print("  |cffFF0000Kein Deathlog/Hardcore Addon gefunden!|r")
    end
end

GDL:RegisterModule("Deathlog", Deathlog)
