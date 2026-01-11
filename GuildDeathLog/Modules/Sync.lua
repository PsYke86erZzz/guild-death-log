-- ══════════════════════════════════════════════════════════════
-- MODUL: Sync - Gilden-Synchronisation
-- ══════════════════════════════════════════════════════════════
-- Dieses Modul synct NUR zwischen GILDENMITGLIEDERN!
-- Nutzt GUILD Addon Messages (NICHT server-weit)
-- 
-- Alle Kommunikation ist GILDEN-INTERN:
-- - Todesfaelle
-- - PING/PONG fuer Online-Status
-- - Sync-Requests fuer historische Daten
--
-- v5.9.1: Throttling, Message Queue, Best Practices
-- - Max 255 Bytes pro Nachricht
-- - 13 B/s sustained für Guild Channel
-- - 6 Sekunden Delay nach Login
-- - Message Queue mit Rate Limiting
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Sync = {}

local ADDON_PREFIX = "GDLSync"
local COMM_DELIM = "|"
local COMM = {PING="PING", PONG="PONG", DEATH="DEATH", SYNC_REQ="SYNCREQ", SYNC_DATA="SYNCDAT", DELETE="DELETE"}

-- ══════════════════════════════════════════════════════════════
-- THROTTLING KONSTANTEN (basierend auf WoW Classic Limits)
-- ══════════════════════════════════════════════════════════════
local MAX_MESSAGE_SIZE = 250         -- 255 Byte Limit, 5 Reserve
local THROTTLE_RATE = 0.5            -- Sekunden zwischen Nachrichten (2/s = ~13 B/s average)
local LOGIN_DELAY = 6                -- Sekunden warten nach Login
local BURST_LIMIT = 5                -- Max Burst Messages
local BURST_RECOVERY = 10            -- Sekunden für Burst Recovery

local syncedUsers = {}
local lastSyncRequest = 0
local recentDeaths = {}
local deletedDeaths = nil

-- Message Queue für Throttling
local messageQueue = {}
local lastMessageTime = 0
local burstCount = 0
local lastBurstReset = 0
local isProcessingQueue = false
local loginComplete = false

-- WICHTIG: Prefix SOFORT registrieren beim Laden!
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- ══════════════════════════════════════════════════════════════
-- MESSAGE QUEUE & THROTTLING
-- ══════════════════════════════════════════════════════════════

-- Sichere SendAddonMessage mit Throttling
function Sync:QueueMessage(message, priority)
    if not message or message == "" then return false end
    
    -- Message Size Check (255 Byte Limit!)
    if #message > MAX_MESSAGE_SIZE then
        GDL:Debug("WARNUNG: Nachricht zu lang (" .. #message .. " bytes), wird gekürzt!")
        message = message:sub(1, MAX_MESSAGE_SIZE)
    end
    
    -- NULL-Bytes entfernen (brechen Parsing!)
    message = message:gsub("%z", "")
    
    -- In Queue einfügen (priority: 1=hoch, 2=normal, 3=niedrig)
    table.insert(messageQueue, {
        msg = message,
        priority = priority or 2,
        timestamp = time()
    })
    
    -- Queue nach Priorität sortieren
    table.sort(messageQueue, function(a, b) 
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return a.timestamp < b.timestamp
    end)
    
    -- Queue Processing starten
    self:ProcessQueue()
    return true
end

function Sync:ProcessQueue()
    if isProcessingQueue then return end
    if #messageQueue == 0 then return end
    if not IsInGuild() then 
        messageQueue = {}  -- Clear queue wenn nicht in Gilde
        return 
    end
    
    -- Login-Delay prüfen
    if not loginComplete then
        GDL:Debug("Sync: Warte auf Login-Delay...")
        return
    end
    
    isProcessingQueue = true
    
    local now = GetTime()
    
    -- Burst Reset
    if now - lastBurstReset > BURST_RECOVERY then
        burstCount = 0
        lastBurstReset = now
    end
    
    -- Throttle Check
    local timeSinceLastMsg = now - lastMessageTime
    if timeSinceLastMsg < THROTTLE_RATE and burstCount >= BURST_LIMIT then
        -- Zu schnell - warte
        C_Timer.After(THROTTLE_RATE - timeSinceLastMsg + 0.1, function()
            isProcessingQueue = false
            self:ProcessQueue()
        end)
        return
    end
    
    -- Nächste Nachricht senden
    local entry = table.remove(messageQueue, 1)
    if entry then
        local success = C_ChatInfo.SendAddonMessage(ADDON_PREFIX, entry.msg, "GUILD")
        if success then
            lastMessageTime = now
            burstCount = burstCount + 1
            GDL:Debug("-> MSG [" .. #entry.msg .. "B] Q:" .. #messageQueue)
        end
    end
    
    isProcessingQueue = false
    
    -- Weitere Messages in Queue?
    if #messageQueue > 0 then
        C_Timer.After(THROTTLE_RATE, function()
            self:ProcessQueue()
        end)
    end
end

-- Direkte Send-Funktion (für kritische Messages wie PING)
function Sync:SendDirect(message)
    if not IsInGuild() then return false end
    if not loginComplete then return false end
    if #message > MAX_MESSAGE_SIZE then
        message = message:sub(1, MAX_MESSAGE_SIZE)
    end
    return C_ChatInfo.SendAddonMessage(ADDON_PREFIX, message, "GUILD")
end

function Sync:Initialize()
    -- Verhindere doppelte Initialisierung
    if self.initialized then return end
    self.initialized = true
    
    GDL:Debug("Sync Initialize gestartet")
    
    -- ══════════════════════════════════════════════════════════
    -- SAVEDVARIABLES BACKUP & VALIDIERUNG
    -- ══════════════════════════════════════════════════════════
    
    -- Backup erstellen wenn Daten vorhanden
    if GuildDeathLogDB and GuildDeathLogDB.deaths then
        GuildDeathLogDB._backup = GuildDeathLogDB._backup or {}
        GuildDeathLogDB._backup.deaths = GuildDeathLogDB._backup.deaths or {}
        GuildDeathLogDB._backup.timestamp = time()
        -- Nur letzte 100 Tode sichern
        local deathCount = 0
        for guildName, data in pairs(GuildDeathLogDB.deaths or {}) do
            if data.deaths then
                deathCount = deathCount + #data.deaths
            end
        end
        if deathCount > 0 then
            GDL:Debug("Backup: " .. deathCount .. " Tode gesichert")
        end
    end
    
    -- ══════════════════════════════════════════════════════════
    -- EVENT FRAME
    -- ══════════════════════════════════════════════════════════
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:HandleEvent(event, ...) end)
    
    syncedUsers = GuildDeathLogDB.syncUsers or {}
    GDL:Debug("Sync: " .. self:CountTable(syncedUsers) .. " gespeicherte User geladen")
    
    -- BLACKLIST aus DB laden (persistent!)
    GuildDeathLogDB.deletedDeaths = GuildDeathLogDB.deletedDeaths or {}
    deletedDeaths = GuildDeathLogDB.deletedDeaths
    
    local blCount = 0
    for _ in pairs(deletedDeaths) do blCount = blCount + 1 end
    if blCount > 0 then
        GDL:Debug("Blacklist: " .. blCount .. " permanent geloeschte Eintraege geladen")
    end
    
    -- ════════════════════════════════════════════════════════
    -- SYNC-TIMER: Mit Login-Delay (6+ Sekunden!)
    -- Server ist "cranky" direkt nach Login
    -- ════════════════════════════════════════════════════════
    
    -- LOGIN DELAY: 6 Sekunden warten bevor Sync beginnt!
    C_Timer.After(LOGIN_DELAY, function()
        loginComplete = true
        GDL:Debug("Sync: Login-Delay abgeschlossen, Sync aktiv")
        
        if IsInGuild() then 
            self:SendPing()
            -- Erste Sync-Request nach weiteren 2 Sekunden
            C_Timer.After(2, function()
                self:RequestFullSync()
            end)
        end
    end)
    
    -- Ping alle 3 Minuten
    C_Timer.NewTicker(180, function() 
        if IsInGuild() and loginComplete then 
            self:SendPing() 
        end
    end)
    
    -- Automatischer Sync alle 5 Minuten
    C_Timer.NewTicker(300, function() 
        if IsInGuild() and loginComplete then
            self:RequestFullSync()
        end
    end)
    
    -- Proaktiver Push alle 10 Minuten
    C_Timer.NewTicker(600, function()
        if IsInGuild() and loginComplete then
            self:BroadcastRecentDeaths(30)
        end
    end)
    
    -- Zusaetzlicher Sync nach 30 Sekunden fuer Spieler die spaeter online kommen
    C_Timer.After(30, function()
        if IsInGuild() and loginComplete then
            self:RequestFullSync()
            self:BroadcastRecentDeaths(50)
        end
    end)
    
    GDL:Debug("Sync: Gilden-Sync initialisiert (wartet auf Login-Delay)")
end

function Sync:CountTable(t)
    local count = 0
    for _ in pairs(t or {}) do count = count + 1 end
    return count
end

function Sync:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Timer sind bereits in Initialize gesetzt
        GDL:Debug("PLAYER_ENTERING_WORLD - Sync wird gestartet")
    elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        -- Bei Gilden/Gruppenänderung: Nur Ping senden, KEIN Broadcast!
        C_Timer.After(5, function()
            if IsInGuild() then 
                self:SendPing() 
            end
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_PREFIX and channel == "GUILD" then
            self:HandleAddonMessage(message, sender)
        end
    elseif event == "CHAT_MSG_CHANNEL" then
        local message, sender, _, _, _, _, _, _, channelName = ...
        if channelName and channelName:lower():find("hardcoredeaths") then
            GDL:Debug("HC-Channel: " .. (message or "?"):sub(1,50))
            self:HandleBlizzardDeath(message, sender)
        end
    end
end

function Sync:SendPing()
    if not IsInGuild() then 
        GDL:Debug("SendPing: Nicht in Gilde")
        return 
    end
    if not loginComplete then
        GDL:Debug("SendPing: Login-Delay nicht abgeschlossen")
        return
    end
    local msg = COMM.PING .. COMM_DELIM .. GDL.version
    -- PING ist wichtig, direkt senden (Priorität 1)
    self:QueueMessage(msg, 1)
    GDL:Debug("-> PING (queued)")
end

function Sync:HandleAddonMessage(message, sender)
    sender = strsplit("-", sender)
    if sender == GDL.playerName then return end
    
    -- Unterstütze beide Protokoll-Formate (v1.2 und v4.0)
    local cmd, data
    
    -- Neues Format: COMMAND|data
    if message:find(COMM_DELIM) then
        cmd, data = strsplit(COMM_DELIM, message, 2)
    -- Altes v1.2 Format: COMMAND:data
    elseif message:find(":") then
        cmd, data = strsplit(":", message, 2)
        -- Konvertiere alte Kommandos zu neuen
        if cmd == "SYNC_REQ" then cmd = "SYNCREQ" end
        if cmd == "SYNC_DATA" then cmd = "SYNCDAT" end
    else
        cmd = message
    end
    
    -- DEBUG: Nur SYNCREQ loggen (PING/PONG/SYNCDAT werden separat behandelt)
    if cmd == COMM.SYNC_REQ or cmd == "SYNCREQ" then
        GDL:Debug("<- SYNCREQ " .. sender)
    end
    
    -- Ist dieser User neu? (noch nie gesehen oder lange offline)
    local isNewUser = not syncedUsers[sender] or 
                      not syncedUsers[sender].lastSeen or 
                      (time() - (syncedUsers[sender].lastSeen or 0)) > 3600  -- 1 Stunde offline
    
    -- JEDE Nachricht registriert den User (v1.2 Kompatibilitaet!)
    syncedUsers[sender] = syncedUsers[sender] or {}
    syncedUsers[sender].lastSeen = time()
    syncedUsers[sender].version = syncedUsers[sender].version or "1.x"
    GuildDeathLogDB.syncUsers = syncedUsers
    
    if cmd == COMM.PING or cmd == "PING" then
        syncedUsers[sender].version = data or "?"
        -- Sende PONG zurück (Priorität 1 für schnelle Antwort)
        self:QueueMessage(COMM.PONG .. COMM_DELIM .. GDL.version, 1)
        -- Debug: Kurz und knapp
        GDL:Debug("<- PING " .. sender .. " v" .. (data or "?"))
        
        -- ══════════════════════════════════════════════════════
        -- WICHTIG: Bei PING von neuem User - sende unsere Daten!
        -- ══════════════════════════════════════════════════════
        if isNewUser then
            GDL:Debug("Neuer User: " .. sender .. " - sende Daten")
            C_Timer.After(3, function()  -- Erhöht von 2 auf 3 Sekunden
                self:SendRecentDeaths(sender, 50)
            end)
        end
        
    elseif cmd == COMM.PONG or cmd == "PONG" then
        syncedUsers[sender].version = data or "?"
        GDL:Debug("<- PONG " .. sender .. " v" .. (data or "?"))
        
    elseif cmd == COMM.DEATH or cmd == "DEATH" then
        self:HandleDeath(sender, data)
        
    elseif cmd == COMM.SYNC_REQ or cmd == "SYNCREQ" then
        self:HandleSyncRequest(sender, data)
        
    elseif cmd == COMM.SYNC_DATA or cmd == "SYNCDAT" then
        self:HandleSyncData(sender, data)
        
    elseif cmd == COMM.DELETE or cmd == "DELETE" then
        self:HandleDeleteSync(sender, data)
    end
end

function Sync:HandleBlizzardDeath(message, sender)
    GDL:Debug("HC-Channel Nachricht: " .. (message or "nil"):sub(1, 80))
    
    if not GuildDeathLogDB.settings.useBlizzardChannel then 
        GDL:Debug("HC-Channel: useBlizzardChannel ist DEAKTIVIERT!")
        return 
    end
    
    local name = message:match("%[(.-)%]")
    local level = message:match("level (%d+)")
    
    if not name then 
        GDL:Debug("HC-Channel: Kein Name gefunden in Nachricht")
        return 
    end
    
    GDL:Debug("HC-Channel: Name=" .. name .. ", Level=" .. (level or "?"))
    
    local Guild = GDL:GetModule("Guild")
    if not Guild then
        GDL:Debug("HC-Channel: Guild-Modul nicht geladen!")
        return
    end
    
    if not Guild:IsMember(name) then 
        GDL:Debug("HC-Channel: " .. name .. " ist KEIN Gildenmitglied")
        return 
    end
    
    GDL:Debug("HC-Channel: " .. name .. " ist Gildenmitglied - verarbeite Tod!")
    self:ProcessIncomingDeath({name=name, level=tonumber(level) or 0, timestamp=time(), fromBlizzard=true}, "Blizzard")
end

function Sync:SerializeDeath(death)
    -- LastWords und Killer escapen (| durch / ersetzen)
    local lastWords = (death.lastWords or ""):gsub(COMM_DELIM, "/"):sub(1, 100) -- Max 100 chars
    local killerName = (death.killerName or ""):gsub(COMM_DELIM, "/")
    
    return table.concat({
        death.name or "?", death.level or 0, death.classId or 0,
        (death.zone or ""):gsub(COMM_DELIM, "/"), death.timestamp or 0,
        death.mapId or 0, math.floor((death.posX or 0) * 10000), math.floor((death.posY or 0) * 10000),
        lastWords, killerName, death.killerId or 0
    }, COMM_DELIM)
end

-- v1.2 Format: name|level|class_STRING|zone|timestamp|lastWords
-- v4.0 Format: name|level|classId|zone|timestamp|mapId|posX|posY|lastWords|killerName|killerId
function Sync:DeserializeDeath(data)
    local parts = {strsplit(COMM_DELIM, data)}
    if #parts < 5 then return nil end
    
    local death = {
        name = parts[1],
        level = tonumber(parts[2]) or 0,
        zone = parts[4],
        timestamp = tonumber(parts[5]) or 0,
    }
    
    -- Erkennung: ist parts[3] eine Zahl (v4.0) oder ein String (v1.2)?
    local classValue = tonumber(parts[3])
    if classValue then
        -- v4.0 Format
        death.classId = classValue
        death.mapId = tonumber(parts[6]) or 0
        death.posX = (tonumber(parts[7]) or 0) / 10000
        death.posY = (tonumber(parts[8]) or 0) / 10000
        death.lastWords = parts[9] or ""
        death.killerName = parts[10] or ""
        death.killerId = tonumber(parts[11]) or 0
    else
        -- v1.2 Format - class ist ein String wie "Krieger"
        death.classId = self:ClassNameToId(parts[3])
        death.lastWords = parts[6] or ""
    end
    
    return death
end

-- Konvertiert Klassen-Namen zu ID (fuer v1.2 Kompatibilitaet)
function Sync:ClassNameToId(className)
    local classMap = {
        ["Krieger"] = 1, ["Warrior"] = 1,
        ["Paladin"] = 2,
        ["Jaeger"] = 3, ["Jäger"] = 3, ["Hunter"] = 3,
        ["Schurke"] = 4, ["Rogue"] = 4,
        ["Priester"] = 5, ["Priest"] = 5,
        ["Schamane"] = 7, ["Shaman"] = 7,
        ["Magier"] = 8, ["Mage"] = 8,
        ["Hexenmeister"] = 9, ["Warlock"] = 9,
        ["Druide"] = 11, ["Druid"] = 11,
    }
    return classMap[className] or 0
end

function Sync:GetDeathKey(name, timestamp)
    -- Alte Methode für Kompatibilität - 1 Minute Fenster
    return (name or ""):lower() .. "-" .. math.floor((timestamp or 0) / 60)
end

-- NEUE Methode: Prüft ob gleicher Name innerhalb von 5 Minuten
function Sync:IsDuplicateByName(name, timestamp, windowSeconds)
    windowSeconds = windowSeconds or 300 -- Standard: 5 Minuten
    local checkName = (name or ""):lower()
    local checkTime = timestamp or time()
    
    local guildData = GDL:GetGuildData()
    if guildData then
        for _, d in ipairs(guildData.deaths or {}) do
            local deathName = (d.name or ""):lower()
            local deathTime = d.timestamp or 0
            
            -- Gleicher Name UND innerhalb des Zeitfensters?
            if deathName == checkName then
                local timeDiff = math.abs(checkTime - deathTime)
                if timeDiff < windowSeconds then
                    GDL:Debug("Duplikat erkannt: " .. name .. " (Zeitdiff: " .. timeDiff .. "s)")
                    return true
                end
            end
        end
    end
    return false
end

function Sync:IsDuplicate(death)
    -- Erst die neue 5-Minuten-Prüfung
    if self:IsDuplicateByName(death.name, death.timestamp, 300) then
        return true
    end
    
    -- Dann die alte Key-basierte Prüfung
    local key = self:GetDeathKey(death.name, death.timestamp)
    if recentDeaths[key] then return true end
    
    local guildData = GDL:GetGuildData()
    if guildData then
        for _, d in ipairs(guildData.deaths or {}) do
            if self:GetDeathKey(d.name, d.timestamp) == key then return true end
        end
    end
    return false
end

function Sync:BroadcastDeath(death)
    if not IsInGuild() then 
        GDL:Debug("BroadcastDeath: Nicht in Gilde!")
        return 
    end
    if not loginComplete then
        GDL:Debug("BroadcastDeath: Login-Delay nicht abgeschlossen - wird verzögert")
        C_Timer.After(LOGIN_DELAY + 1, function()
            self:BroadcastDeath(death)
        end)
        return
    end
    
    -- ZUERST das alte v1.2 Format senden (wichtig für Kompatibilität!)
    local className = GDL:GetClassName(death.classId) or "Unknown"
    local v12Data = string.format("%s|%d|%s|%s|%d|%s",
        death.name or "?", 
        death.level or 0, 
        className,
        (death.zone or "Unknown"):gsub("|", "/"), 
        death.timestamp or 0, 
        (death.lastWords or ""):gsub("|", "/"):sub(1, 100)
    )
    -- Death ist Priorität 1 (wichtig!)
    self:QueueMessage("DEATH:" .. v12Data, 1)
    GDL:Debug("v1.2 Format gequeued: DEATH:" .. v12Data:sub(1,50))
    
    -- DANN das neue v4.0 Format senden
    local serialized = self:SerializeDeath(death)
    if serialized and #serialized < MAX_MESSAGE_SIZE - 10 then
        self:QueueMessage(COMM.DEATH .. COMM_DELIM .. serialized, 1)
        GDL:Debug("v4.0 Format gequeued")
    end
    GDL:Debug("Sync: Tod von " .. (death.name or "?") .. " an Gilde gequeued")
end

function Sync:HandleDeath(sender, data)
    local death = self:DeserializeDeath(data)
    if death then 
        -- Nur anzeigen wenn der Tod weniger als 30 SEKUNDEN alt ist = wirklich LIVE!
        local isHistorical = death.timestamp and (time() - death.timestamp) > 30
        self:ProcessIncomingDeath(death, sender, isHistorical) 
    end
end

function Sync:ProcessIncomingDeath(death, source, isSilent)
    -- Blacklist-Check: Wurde dieser Eintrag gelöscht?
    if self:IsDeleted(death.name, death.timestamp) then
        GDL:Debug("Geloeschter Eintrag ignoriert: " .. (death.name or "?"))
        return
    end
    
    if self:IsDuplicate(death) then 
        GDL:Debug("Duplikat ignoriert: " .. (death.name or "?"))
        return 
    end
    
    local key = self:GetDeathKey(death.name, death.timestamp)
    recentDeaths[key] = time()
    C_Timer.After(300, function() recentDeaths[key] = nil end)
    
    local guildData = GDL:GetGuildData()
    if guildData then
        death.syncedFrom = source
        death.syncedAt = time()
        table.insert(guildData.deaths, death)
        GDL:Debug("Tod gespeichert: " .. (death.name or "?") .. " von " .. (source or "?"))
    end
    
    -- Memorial: Verstorbene aus Berufe-Liste entfernen
    local Memorial = GDL:GetModule("Memorial")
    if Memorial then
        Memorial:OnDeath(death)
        -- Gedenkhalle aktualisieren wenn offen
        if Memorial.frame and Memorial.frame:IsShown() then
            Memorial:UpdateMemorialList()
        end
    end
    
    -- GuildStats aktualisieren wenn offen
    local GuildStats = GDL:GetModule("GuildStats")
    if GuildStats and GuildStats.frame and GuildStats.frame:IsShown() then
        GuildStats:UpdateDeathsList()
    end
    
    -- Professions aktualisieren wenn offen (Verstorbene entfernen)
    local Professions = GDL:GetModule("Professions")
    if Professions and Professions.frame and Professions.frame:IsShown() then
        Professions:UpdateWindow()
    end
    
    -- Nur bei NEUEN Toden anzeigen, NICHT bei historischem Resync!
    if not isSilent then
        GDL:Print("|cffFF6666" .. (death.name or "?") .. "|r ist gefallen! (Lvl " .. (death.level or "?") .. ")")
        
        if GuildDeathLogDB.settings.sound then 
            PlaySound(8959, "Master") 
        end
        if GuildDeathLogDB.settings.overlay then
            local UI = GDL:GetModule("UI")
            if UI then 
                UI:ShowOverlay(death, true) 
            end
        end
    end
    
    -- UI Update immer (auch silent)
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
end

function Sync:RequestFullSync()
    if not IsInGuild() then 
        GDL:Debug("Sync: Nicht in Gilde")
        return 
    end
    -- Cooldown von 30 auf 15 Sekunden reduziert
    if time() - lastSyncRequest < 15 then 
        GDL:Debug("Sync: Cooldown aktiv (" .. (15 - (time() - lastSyncRequest)) .. "s)")
        return 
    end
    lastSyncRequest = time()
    
    local guildData = GDL:GetGuildData()
    local lastTimestamp = 0
    for _, death in ipairs(guildData and guildData.deaths or {}) do
        if (death.timestamp or 0) > lastTimestamp then lastTimestamp = death.timestamp end
    end
    
    self:SendPing()
    
    -- Sende in BEIDEN Formaten fuer Kompatibilitaet! (Priorität 2 = normal)
    -- Neues Format (v4.0)
    self:QueueMessage(COMM.SYNC_REQ .. COMM_DELIM .. lastTimestamp, 2)
    -- Altes Format (v1.2)
    self:QueueMessage("SYNC_REQ:" .. lastTimestamp, 2)
    
    GDL:Debug("-> SYNCREQ queued (seit " .. lastTimestamp .. ")")
end

function Sync:HandleSyncRequest(sender, data)
    local theirTimestamp = tonumber(data) or 0
    syncedUsers[sender] = syncedUsers[sender] or {}
    syncedUsers[sender].lastSeen = time()
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    -- Sammle alle Tode die neuer sind als deren Timestamp
    local toSend = {}
    for _, death in ipairs(guildData.deaths or {}) do
        if (death.timestamp or 0) > theirTimestamp then
            table.insert(toSend, death)
        end
    end
    
    -- Sortiere nach Zeit (neueste zuerst)
    table.sort(toSend, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    -- Sende bis zu 50 Tode, mit Queue (Priorität 3 = niedrig, bulk data)
    local maxToSend = math.min(#toSend, 50)
    
    GDL:Debug("-> " .. maxToSend .. " Tode an " .. sender .. " (queued)")
    
    for i = 1, maxToSend do
        local death = toSend[i]
        local serialized = self:SerializeDeath(death)
        if serialized and #serialized < MAX_MESSAGE_SIZE - 15 then
            -- Gestaffelt in Queue einfügen (Priorität 3 = bulk)
            C_Timer.After((i-1) * 0.3, function()
                self:QueueMessage(COMM.SYNC_DATA .. COMM_DELIM .. serialized, 3)
            end)
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- NEUE FUNKTION: Sende die letzten X Tode an die Gilde
-- ══════════════════════════════════════════════════════════════
function Sync:SendRecentDeaths(targetUser, maxCount)
    maxCount = maxCount or 30
    if not loginComplete then return end
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    -- Sammle alle Tode
    local allDeaths = {}
    for _, death in ipairs(guildData.deaths or {}) do
        table.insert(allDeaths, death)
    end
    
    -- Sortiere nach Zeit (neueste zuerst)
    table.sort(allDeaths, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    -- Sende die neuesten X Tode mit Queue (Priorität 3 = bulk)
    local count = 0
    for i, death in ipairs(allDeaths) do
        if count >= maxCount then break end
        
        local serialized = self:SerializeDeath(death)
        if serialized and #serialized < MAX_MESSAGE_SIZE - 15 then
            C_Timer.After(count * 0.4, function()
                self:QueueMessage(COMM.SYNC_DATA .. COMM_DELIM .. serialized, 3)
            end)
            count = count + 1
        end
    end
    
    if count > 0 then
        GDL:Debug("-> " .. count .. " Tode queued (Auto)")
    end
end

-- ══════════════════════════════════════════════════════════════
-- NEUE FUNKTION: Broadcast - Pusht Tode an ALLE in der Gilde
-- Wird regelmäßig aufgerufen um sicherzustellen dass alle synced sind
-- ══════════════════════════════════════════════════════════════
function Sync:BroadcastRecentDeaths(maxCount)
    if not IsInGuild() then return end
    if not loginComplete then return end
    maxCount = maxCount or 20
    
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.deaths then return end
    
    -- Nur Tode der letzten 7 Tage pushen
    local sevenDaysAgo = time() - (7 * 24 * 60 * 60)
    
    -- Sammle relevante Tode
    local recentDeathsList = {}
    for _, death in ipairs(guildData.deaths) do
        if (death.timestamp or 0) > sevenDaysAgo then
            table.insert(recentDeathsList, death)
        end
    end
    
    -- Sortiere nach Zeit (neueste zuerst)
    table.sort(recentDeathsList, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    -- Sende mit Queue (Priorität 3 = bulk)
    local count = 0
    for i, death in ipairs(recentDeathsList) do
        if count >= maxCount then break end
        
        local serialized = self:SerializeDeath(death)
        if serialized and #serialized < MAX_MESSAGE_SIZE - 15 then
            C_Timer.After(count * 0.35, function()
                self:QueueMessage(COMM.SYNC_DATA .. COMM_DELIM .. serialized, 3)
            end)
            count = count + 1
        end
    end
    
    if count > 0 then
        GDL:Debug("-> " .. count .. " Tode queued (Broadcast)")
    end
end

-- Zähler für empfangene Sync-Daten (für Debug-Zusammenfassung)
local syncDataReceived = 0
local syncDataLastSender = nil
local syncDataTimer = nil

function Sync:HandleSyncData(sender, data)
    local death = self:DeserializeDeath(data)
    if death then 
        -- Prüfe ob der Tod älter als 30 SEKUNDEN ist = historischer Sync = SILENT
        local isHistorical = death.timestamp and (time() - death.timestamp) > 30
        self:ProcessIncomingDeath(death, sender .. " (sync)", isHistorical) 
        
        -- Zähle empfangene Daten für Debug-Zusammenfassung
        syncDataReceived = syncDataReceived + 1
        syncDataLastSender = sender
        
        -- Timer für Zusammenfassung (nach 2 Sekunden ohne neue Daten)
        if syncDataTimer then
            syncDataTimer:Cancel()
        end
        syncDataTimer = C_Timer.NewTimer(2, function()
            if syncDataReceived > 0 then
                GDL:Debug(syncDataLastSender .. " -> " .. syncDataReceived .. " Tode empfangen")
                syncDataReceived = 0
                syncDataLastSender = nil
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- DELETE SYNC - Löschungen an Gildenmitglieder senden
-- ══════════════════════════════════════════════════════════════

function Sync:BroadcastDelete(deathName, deathTimestamp)
    if not IsInGuild() then return end
    
    -- Zur persistenten Blacklist hinzufügen
    local deleteKey = (deathName or "") .. ":" .. (deathTimestamp or 0)
    deletedDeaths[deleteKey] = time()
    -- DB wird automatisch gespeichert
    
    -- Format: DELETE|name|timestamp (Priorität 1 = wichtig)
    local msg = COMM.DELETE .. COMM_DELIM .. (deathName or "") .. COMM_DELIM .. (deathTimestamp or 0)
    self:QueueMessage(msg, 1)
    GDL:Debug("-> DELETE queued: " .. deathName)
end

function Sync:HandleDeleteSync(sender, data)
    if not data then return end
    
    local name, timestamp = strsplit(COMM_DELIM, data)
    timestamp = tonumber(timestamp) or 0
    
    if not name or name == "" then return end
    
    GDL:Debug("<- DELETE von " .. sender .. ": " .. name)
    
    -- Zur persistenten Blacklist hinzufügen
    local deleteKey = name .. ":" .. timestamp
    deletedDeaths[deleteKey] = time()
    -- DB wird automatisch gespeichert
    
    -- Finde und lösche den Eintrag lokal
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.deaths then return end
    
    for i = #guildData.deaths, 1, -1 do
        local death = guildData.deaths[i]
        -- Match by name AND timestamp (falls vorhanden) oder nur name
        if death.name == name then
            if timestamp == 0 or (death.timestamp and math.abs(death.timestamp - timestamp) < 60) then
                table.remove(guildData.deaths, i)
                GDL:Print("|cff888888" .. name .. " wurde durch " .. sender .. " geloescht.|r")
                
                -- UI aktualisieren
                local UI = GDL:GetModule("UI")
                if UI and UI.mainFrame and UI.mainFrame:IsShown() then
                    UI:UpdateChronicle()
                end
                break
            end
        end
    end
end

-- Prüft ob ein Eintrag auf der Blacklist steht
function Sync:IsDeleted(name, timestamp)
    -- Blacklist aus DB holen (falls noch nicht initialisiert)
    local bl = deletedDeaths or GuildDeathLogDB.deletedDeaths
    if not bl then return false end
    if not name then return false end
    
    -- Nach NAME suchen (ignoriere Timestamp - Name reicht!)
    for key, _ in pairs(bl) do
        local keyName = key:match("^([^:]+)")
        if keyName and keyName:lower() == name:lower() then
            GDL:Debug("Blacklist Match: " .. name)
            return true
        end
    end
    
    return false
end

function Sync:SendPendingSync()
    if not IsInGuild() then return end
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.pendingSync then return end
    
    for _, death in ipairs(guildData.pendingSync) do
        self:BroadcastDeath(death)
    end
    guildData.pendingSync = {}
end

function Sync:GetOnlineUsers()
    local online = {}
    local now = time()
    for name, data in pairs(syncedUsers) do
        if (now - (data.lastSeen or 0)) < 600 then
            table.insert(online, {name = name, version = data.version, lastSeen = data.lastSeen})
        end
    end
    return online
end

function Sync:GetLastSyncTime()
    return lastSyncRequest
end

-- TEST-Funktion: Sendet einen Fake-Tod für Sync-Test
function Sync:SendTestDeath()
    if not IsInGuild() then 
        GDL:Print("|cffFF0000Fehler:|r Nicht in einer Gilde!")
        return 
    end
    
    local testDeath = {
        name = "TestChar-" .. math.random(1000, 9999),
        level = math.random(1, 60),
        classId = math.random(1, 11),
        zone = "Testzone",
        timestamp = time(),
        lastWords = "Dies ist ein Test!",
    }
    
    GDL:Print("|cffFFFF00[TEST]|r Sende Test-Tod...")
    self:BroadcastDeath(testDeath)
    GDL:Print("|cffFFFF00[TEST]|r Wenn andere Gildenmitglieder dies sehen, funktioniert der Sync!")
end

function Sync:RecordLocalDeath(deathData)
    if self:IsDuplicate(deathData) then return end
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    deathData.timestamp = deathData.timestamp or time()
    
    -- Koordinaten ergänzen falls nicht vorhanden
    if (not deathData.posX or deathData.posX == 0) and (not deathData.posY or deathData.posY == 0) then
        -- 1. Versuch: MapMarkers lastDeathLocation (eigener Tod)
        local MapMarkers = GDL:GetModule("MapMarkers")
        if MapMarkers then
            local lastLoc = MapMarkers:GetLastDeathLocation()
            -- Timeout erhöht auf 60 Sekunden
            if lastLoc and (time() - (lastLoc.timestamp or 0)) < 60 then
                deathData.mapId = lastLoc.mapId or deathData.mapId
                deathData.posX = lastLoc.posX or 0
                deathData.posY = lastLoc.posY or 0
                GDL:Debug("MapMarkers: Koordinaten aus lastDeathLocation übernommen")
            end
        end
        
        -- 2. Versuch: Wenn es der eigene Tod ist, aktuelle Position nutzen
        local playerName = UnitName("player")
        if deathData.name == playerName and (not deathData.posX or deathData.posX == 0) then
            local mapId = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
            if mapId then
                local position = C_Map.GetPlayerMapPosition(mapId, "player")
                if position then
                    local posX, posY = position:GetXY()
                    if posX and posX > 0 then
                        deathData.mapId = mapId
                        deathData.posX = posX
                        deathData.posY = posY
                        GDL:Debug("MapMarkers: Koordinaten direkt erfasst")
                    end
                end
            end
        end
    end
    
    -- LastWords hinzufügen (v4.0)
    if not deathData.lastWords or deathData.lastWords == "" then
        local LastWords = GDL:GetModule("LastWords")
        if LastWords then
            local words = LastWords:GetLastWords(deathData.name)
            if words then
                deathData.lastWords = words
            end
        end
    end
    
    -- Killer Info hinzufügen (v4.0)
    if not deathData.killerName then
        local KillerTracker = GDL:GetModule("KillerTracker")
        if KillerTracker then
            local killer = KillerTracker:GetKiller(deathData.name)
            if killer then
                deathData.killerName = killer.name
                deathData.killerId = killer.id
                deathData.killerSpell = killer.spell
            end
        end
    end
    
    table.insert(guildData.deaths, deathData)
    self:BroadcastDeath(deathData)
    
    -- Memorial: Verstorbene aus Berufe-Liste entfernen + Fenster aktualisieren
    local Memorial = GDL:GetModule("Memorial")
    if Memorial then
        Memorial:OnDeath(deathData)
        if Memorial.frame and Memorial.frame:IsShown() then
            Memorial:UpdateMemorialList()
        end
    end
    
    -- GuildStats aktualisieren wenn offen
    local GuildStats = GDL:GetModule("GuildStats")
    if GuildStats and GuildStats.frame and GuildStats.frame:IsShown() then
        GuildStats:UpdateDeathsList()
    end
    
    -- Professions aktualisieren wenn offen
    local Professions = GDL:GetModule("Professions")
    if Professions and Professions.frame and Professions.frame:IsShown() then
        Professions:UpdateWindow()
    end
    
    -- Sound & Overlay für lokale Tode
    if GuildDeathLogDB.settings.sound then PlaySound(8959, "Master") end
    if GuildDeathLogDB.settings.overlay then
        local UI = GDL:GetModule("UI")
        if UI then UI:ShowOverlay(deathData, false) end
    end
    
    -- Update UI wenn offen
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
    
    -- Gildenchat Ankündigung mit EPISCHEN Condolences (v4.8)
    if GuildDeathLogDB.settings.announce and IsInGuild() then
        local Condolences = GDL:GetModule("Condolences")
        if Condolences then
            -- Killer extrahieren (kann "Environment", Mob-Name, etc. sein)
            local killer = deathData.killer or deathData.source or nil
            local zone = deathData.zone or nil
            local className = GDL:GetClassName(deathData.classId)
            
            local msg = Condolences:GetDeathAnnouncement(
                deathData.name, 
                deathData.level or 0, 
                className,
                killer,
                zone
            )
            SendChatMessage(msg, "GUILD")
        else
            local L = GDL:GetModule("Locale").L
            local msg = L.DEATH_MESSAGES[math.random(#L.DEATH_MESSAGES)]
            SendChatMessage(string.format(msg, deathData.name, deathData.level or 0, GDL:GetClassName(deathData.classId)), "GUILD")
        end
    end
    
    -- Export zu Custom Channel (v4.0)
    local Export = GDL:GetModule("Export")
    if Export then
        Export:AnnounceToChannel(deathData)
    end
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG / STATUS FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function Sync:GetSyncStatus()
    local status = {
        initialized = self.initialized or false,
        loginComplete = loginComplete or false,
        queueSize = #messageQueue,
        burstCount = burstCount,
        onlineUsers = self:CountTable(syncedUsers),
        blacklistSize = self:CountTable(deletedDeaths),
    }
    return status
end

function Sync:PrintSyncStatus()
    local s = self:GetSyncStatus()
    GDL:Print("|cffFFD100=== SYNC STATUS ===|r")
    GDL:Print("Initialisiert: " .. (s.initialized and "|cff00FF00Ja|r" or "|cffFF0000Nein|r"))
    GDL:Print("Login-Delay: " .. (s.loginComplete and "|cff00FF00Abgeschlossen|r" or "|cffFF8800Wartet...|r"))
    GDL:Print("Queue: " .. s.queueSize .. " Nachrichten")
    GDL:Print("Burst: " .. s.burstCount .. "/" .. BURST_LIMIT)
    GDL:Print("Online Users: " .. s.onlineUsers)
    GDL:Print("Blacklist: " .. s.blacklistSize .. " Einträge")
    GDL:Print("|cffFFD100==================|r")
end

function Sync:ClearQueue()
    local count = #messageQueue
    messageQueue = {}
    GDL:Print("Queue geleert: " .. count .. " Nachrichten entfernt")
end

-- ======================================================================
-- MODULE INITIALIZATION
-- ======================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            Sync:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Sync", Sync)
