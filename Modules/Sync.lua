-- ══════════════════════════════════════════════════════════════
-- MODUL: Sync - Gilden-Synchronisation
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Sync = {}

local ADDON_PREFIX = "GDLSync"
local COMM_DELIM = "|"
local COMM = {PING="PING", PONG="PONG", DEATH="DEATH", SYNC_REQ="SYNCREQ", SYNC_DATA="SYNCDAT"}

local syncedUsers = {}
local lastSyncRequest = 0
local recentDeaths = {}

-- WICHTIG: Prefix SOFORT registrieren beim Laden!
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

function Sync:Initialize()
    -- Prefix wurde bereits oben registriert
    GDL:Debug("Sync Initialize gestartet")
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:HandleEvent(event, ...) end)
    
    syncedUsers = GuildDeathLogDB.syncUsers or {}
    GDL:Debug("Sync: " .. self:CountTable(syncedUsers) .. " gespeicherte User geladen")
    
    -- Ping alle 5 Minuten
    C_Timer.NewTicker(300, function() self:SendPing() end)
    
    GDL:Print("|cff00AAFF[Sync]|r Gilden-Sync aktiv!")
end

function Sync:CountTable(t)
    local count = 0
    for _ in pairs(t or {}) do count = count + 1 end
    return count
end

function Sync:HandleEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Bei Login: PING senden und Sync anfordern
        C_Timer.After(3, function() 
            if IsInGuild() then
                self:SendPing()
                GDL:Debug("PING nach Login gesendet")
            end
        end)
        C_Timer.After(8, function() 
            if IsInGuild() then
                self:RequestFullSync()
            end
        end)
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        -- WICHTIG: Immer loggen was reinkommt!
        if prefix == ADDON_PREFIX then
            GDL:Debug("ADDON_MSG empfangen: " .. (message or "?"):sub(1,50) .. " von " .. (sender or "?") .. " (" .. (channel or "?") .. ")")
        end
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
    local msg = COMM.PING .. COMM_DELIM .. GDL.version
    local success = C_ChatInfo.SendAddonMessage(ADDON_PREFIX, msg, "GUILD")
    GDL:Debug("PING gesendet: " .. tostring(success) .. " (Prefix: " .. ADDON_PREFIX .. ")")
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
    
    GDL:Debug("Sync empfangen: " .. (cmd or "?") .. " von " .. (sender or "?"))
    
    -- JEDE Nachricht registriert den User (v1.2 Kompatibilitaet!)
    syncedUsers[sender] = syncedUsers[sender] or {}
    syncedUsers[sender].lastSeen = time()
    syncedUsers[sender].version = syncedUsers[sender].version or "1.x"
    GuildDeathLogDB.syncUsers = syncedUsers
    
    if cmd == COMM.PING or cmd == "PING" then
        syncedUsers[sender].version = data or "?"
        C_ChatInfo.SendAddonMessage(ADDON_PREFIX, COMM.PONG .. COMM_DELIM .. GDL.version, "GUILD")
        GDL:Debug("PONG gesendet an " .. sender)
    elseif cmd == COMM.PONG or cmd == "PONG" then
        syncedUsers[sender].version = data or "?"
        GDL:Debug("User registriert: " .. sender .. " v" .. (data or "?"))
    elseif cmd == COMM.DEATH or cmd == "DEATH" then
        self:HandleDeath(sender, data)
    elseif cmd == COMM.SYNC_REQ or cmd == "SYNCREQ" then
        self:HandleSyncRequest(sender, data)
    elseif cmd == COMM.SYNC_DATA or cmd == "SYNCDAT" then
        self:HandleSyncData(sender, data)
    end
end

function Sync:HandleBlizzardDeath(message, sender)
    if not GuildDeathLogDB.settings.useBlizzardChannel then return end
    local name = message:match("%[(.-)%]")
    local level = message:match("level (%d+)")
    if not name then return end
    
    local Guild = GDL:GetModule("Guild")
    if not Guild or not Guild:IsMember(name) then return end
    
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
    local v12Success = C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "DEATH:" .. v12Data, "GUILD")
    GDL:Debug("v1.2 Format gesendet: " .. tostring(v12Success) .. " - DEATH:" .. v12Data:sub(1,50))
    
    -- DANN das neue v4.0 Format senden
    local v40Success = C_ChatInfo.SendAddonMessage(ADDON_PREFIX, COMM.DEATH .. COMM_DELIM .. self:SerializeDeath(death), "GUILD")
    GDL:Debug("v4.0 Format gesendet: " .. tostring(v40Success))
    
    GDL:Print("|cff00FF00[Sync]|r Tod von " .. (death.name or "?") .. " an Gilde gesendet!")
end

function Sync:HandleDeath(sender, data)
    local death = self:DeserializeDeath(data)
    if death then self:ProcessIncomingDeath(death, sender) end
end

function Sync:ProcessIncomingDeath(death, source)
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
    
    -- IMMER im Chat anzeigen!
    GDL:Print("|cffFF6666" .. (death.name or "?") .. "|r ist gefallen! (Lvl " .. (death.level or "?") .. " - via " .. (source or "Sync") .. ")")
    
    if GuildDeathLogDB.settings.sound then 
        PlaySound(8959, "Master") 
        GDL:Debug("Sound abgespielt")
    end
    if GuildDeathLogDB.settings.overlay then
        local UI = GDL:GetModule("UI")
        if UI then 
            UI:ShowOverlay(death, true) 
            GDL:Debug("Overlay angezeigt")
        end
    end
    
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
    
    -- Achievements triggern
    local Achievements = GDL:GetModule("Achievements")
    if Achievements then
        Achievements:OnDeathWitnessed()
    end
end

function Sync:RequestFullSync()
    if not IsInGuild() then 
        GDL:Debug("Sync: Nicht in Gilde")
        return 
    end
    if time() - lastSyncRequest < 30 then 
        GDL:Debug("Sync: Cooldown aktiv")
        return 
    end
    lastSyncRequest = time()
    
    local guildData = GDL:GetGuildData()
    local lastTimestamp = 0
    for _, death in ipairs(guildData and guildData.deaths or {}) do
        if (death.timestamp or 0) > lastTimestamp then lastTimestamp = death.timestamp end
    end
    
    self:SendPing()
    
    -- Sende in BEIDEN Formaten fuer Kompatibilitaet!
    -- Neues Format (v4.0)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, COMM.SYNC_REQ .. COMM_DELIM .. lastTimestamp, "GUILD")
    -- Altes Format (v1.2)
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "SYNC_REQ:" .. lastTimestamp, "GUILD")
    
    GDL:Print(GDL:L("SYNC_REQUESTED"))
    GDL:Debug("Sync angefordert (beide Formate)")
end

function Sync:HandleSyncRequest(sender, data)
    local theirTimestamp = tonumber(data) or 0
    syncedUsers[sender] = syncedUsers[sender] or {}
    syncedUsers[sender].lastSeen = time()
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    local count = 0
    for _, death in ipairs(guildData.deaths or {}) do
        if (death.timestamp or 0) > theirTimestamp and count < 20 then
            C_ChatInfo.SendAddonMessage(ADDON_PREFIX, COMM.SYNC_DATA .. COMM_DELIM .. self:SerializeDeath(death), "GUILD")
            count = count + 1
        end
    end
end

function Sync:HandleSyncData(sender, data)
    local death = self:DeserializeDeath(data)
    if death then self:ProcessIncomingDeath(death, sender .. " (sync)") end
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
    
    -- Koordinaten ergänzen falls nicht vorhanden (vom MapMarkers Modul)
    if (not deathData.posX or deathData.posX == 0) and (not deathData.posY or deathData.posY == 0) then
        local MapMarkers = GDL:GetModule("MapMarkers")
        if MapMarkers then
            local lastLoc = MapMarkers:GetLastDeathLocation()
            if lastLoc and (time() - (lastLoc.timestamp or 0)) < 10 then
                deathData.mapId = lastLoc.mapId or deathData.mapId
                deathData.posX = lastLoc.posX or 0
                deathData.posY = lastLoc.posY or 0
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
    
    -- Achievements triggern (v4.0)
    local Achievements = GDL:GetModule("Achievements")
    if Achievements then
        Achievements:OnGuildDeath()
        Achievements:OnDeathWitnessed()
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
    
    -- Gildenchat Ankündigung mit Condolences (v4.0)
    if GuildDeathLogDB.settings.announce and IsInGuild() then
        local Condolences = GDL:GetModule("Condolences")
        if Condolences then
            local msg = Condolences:GetDeathAnnouncement(deathData.name, deathData.level or 0, GDL:GetClassName(deathData.classId))
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

GDL:RegisterModule("Sync", Sync)
