-- ══════════════════════════════════════════════════════════════
-- MODUL: LastWords - Letzte Worte vor dem Tod
-- Speichert die letzten Chat-Nachrichten jedes Spielers
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local LastWords = {}

-- Speichert letzte Nachrichten pro Spieler (max 3)
local playerMessages = {}
local MESSAGE_HISTORY = 3
local MESSAGE_TIMEOUT = 300 -- 5 Minuten

function LastWords:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SAY")
    frame:RegisterEvent("CHAT_MSG_YELL")
    frame:RegisterEvent("CHAT_MSG_GUILD")
    frame:RegisterEvent("CHAT_MSG_PARTY")
    frame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    frame:RegisterEvent("CHAT_MSG_RAID")
    frame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    frame:RegisterEvent("CHAT_MSG_EMOTE")
    frame:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
    
    frame:SetScript("OnEvent", function(_, event, message, sender, ...)
        self:OnChatMessage(event, message, sender)
    end)
    
    -- Cleanup Timer
    C_Timer.NewTicker(60, function() self:CleanupOldMessages() end)
end

function LastWords:OnChatMessage(event, message, sender)
    if not message or not sender then return end
    
    -- Nur Name ohne Server
    local name = strsplit("-", sender)
    
    -- Initialisieren wenn nötig
    if not playerMessages[name] then
        playerMessages[name] = {}
    end
    
    -- Nachricht speichern
    table.insert(playerMessages[name], 1, {
        text = message,
        channel = self:GetChannelName(event),
        timestamp = time()
    })
    
    -- Max Anzahl begrenzen
    while #playerMessages[name] > MESSAGE_HISTORY do
        table.remove(playerMessages[name])
    end
end

function LastWords:GetChannelName(event)
    local channels = {
        CHAT_MSG_SAY = "Sagen/Say",
        CHAT_MSG_YELL = "Schreien/Yell",
        CHAT_MSG_GUILD = "Gilde/Guild",
        CHAT_MSG_PARTY = "Gruppe/Party",
        CHAT_MSG_PARTY_LEADER = "Gruppe/Party",
        CHAT_MSG_RAID = "Schlachtzug/Raid",
        CHAT_MSG_RAID_LEADER = "Schlachtzug/Raid",
        CHAT_MSG_EMOTE = "Emote",
        CHAT_MSG_TEXT_EMOTE = "Emote",
    }
    return channels[event] or "Chat"
end

function LastWords:GetLastWords(playerName)
    local name = strsplit("-", playerName)
    local messages = playerMessages[name]
    
    if not messages or #messages == 0 then
        return nil
    end
    
    -- Nur Nachrichten der letzten 5 Minuten
    local recent = messages[1]
    if recent and (time() - recent.timestamp) < MESSAGE_TIMEOUT then
        return recent.text, recent.channel, recent.timestamp
    end
    
    return nil
end

function LastWords:GetAllLastWords(playerName)
    local name = strsplit("-", playerName)
    return playerMessages[name] or {}
end

function LastWords:CleanupOldMessages()
    local now = time()
    for name, messages in pairs(playerMessages) do
        -- Entferne alte Nachrichten
        for i = #messages, 1, -1 do
            if (now - messages[i].timestamp) > MESSAGE_TIMEOUT * 2 then
                table.remove(messages, i)
            end
        end
        -- Entferne leere Einträge
        if #messages == 0 then
            playerMessages[name] = nil
        end
    end
end

GDL:RegisterModule("LastWords", LastWords)
