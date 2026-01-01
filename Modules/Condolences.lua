-- ══════════════════════════════════════════════════════════════
-- MODUL: Condolences - Automatische Beileids-Nachrichten
-- Zufällige tröstende Nachrichten bei Toden
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Condolences = {}

-- Deutsche und Englische Beileids-Nachrichten
local CONDOLENCE_MESSAGES = {
    -- Deutsch - Respektvoll
    "Ruhe in Frieden, %s. Dein Opfer wird nicht vergessen.",
    "Möge %s in den Hallen der Tapferen ruhen.",
    "%s ist gefallen, aber niemals vergessen.",
    "Die Gilde trauert um %s. Ein wahrer Held.",
    "Ehre sei %s! Gefallen, aber unvergessen.",
    "%s hat tapfer gekämpft bis zum Ende.",
    "Wir gedenken %s. Ein Verlust für uns alle.",
    "%s - Dein Name lebt in unseren Herzen weiter.",
    
    -- Deutsch - Etwas lockerer
    "F für %s. o7",
    "RIP %s, du wirst uns fehlen!",
    "%s ist von uns gegangen... F",
    "Press F für unseren gefallenen Kameraden %s",
    "%s... wir sehen uns in Azeroth 2.0",
    
    -- Englisch - Respectful
    "Rest in peace, %s. Your sacrifice won't be forgotten.",
    "May %s rest in the halls of the brave.",
    "%s has fallen, but will never be forgotten.",
    "The guild mourns %s. A true hero.",
    "Honor to %s! Fallen, but never forgotten.",
    "%s fought bravely until the end.",
    "We remember %s. A loss for us all.",
    "%s - Your name lives on in our hearts.",
    
    -- Englisch - Casual
    "F for %s. o7",
    "RIP %s, you will be missed!",
    "%s has left us... F",
    "Press F for our fallen comrade %s",
    "%s... see you in Azeroth 2.0",
    
    -- Humor (optional)
    "%s dachte, das Wasser wäre flacher...",
    "%s wollte nur kurz AFK...",
    "Der Geistheiler kennt %s jetzt beim Namen.",
    "%s hat die Aggro-Range unterschätzt.",
    "%s thought the water was shallower...",
    "%s just wanted to go AFK for a sec...",
    "The spirit healer knows %s by name now.",
    "%s underestimated the aggro range.",
}

-- Ernste Nachrichten (für Auto-Announce)
local SERIOUS_MESSAGES = {
    "R.I.P. %s (Level %d %s) ist gefallen. Ruhe in Frieden.",
    "R.I.P. Die Gilde trauert um %s - Level %d %s",
    "R.I.P. %s, Level %d %s - Niemals vergessen.",
    "R.I.P. R.I.P. %s (Level %d %s)",
    "R.I.P. %s (Lvl %d %s) has fallen. Rest in peace.",
    "R.I.P. The guild mourns %s - Level %d %s",
    "R.I.P. %s, Level %d %s - Never forgotten.",
    "R.I.P. R.I.P. %s (Lvl %d %s)",
}

function Condolences:Initialize()
    GuildDeathLogDB.condolences = GuildDeathLogDB.condolences or {
        enabled = true,
        useHumor = false,
        lastMessage = 0,
        cooldown = 30, -- Sekunden zwischen Nachrichten
    }
end

function Condolences:GetRandomCondolence(name, includeHumor)
    local messages = {}
    
    -- Basis-Nachrichten (immer)
    for i = 1, 26 do -- Erste 26 sind respektvoll
        table.insert(messages, CONDOLENCE_MESSAGES[i])
    end
    
    -- Humor optional
    if includeHumor then
        for i = 27, #CONDOLENCE_MESSAGES do
            table.insert(messages, CONDOLENCE_MESSAGES[i])
        end
    end
    
    local msg = messages[math.random(#messages)]
    return string.format(msg, name)
end

function Condolences:GetDeathAnnouncement(name, level, className)
    local msg = SERIOUS_MESSAGES[math.random(#SERIOUS_MESSAGES)]
    return string.format(msg, name, level or 0, className or "?")
end

function Condolences:SendCondolence(name, channel)
    local settings = GuildDeathLogDB.condolences
    if not settings.enabled then return false end
    
    -- Cooldown prüfen
    if time() - (settings.lastMessage or 0) < settings.cooldown then
        return false
    end
    
    local message = self:GetRandomCondolence(name, settings.useHumor)
    
    channel = channel or "GUILD"
    if channel == "GUILD" and IsInGuild() then
        SendChatMessage(message, "GUILD")
        settings.lastMessage = time()
        return true
    end
    
    return false
end

function Condolences:SendToChannel(name, level, className, channelName)
    if not channelName or channelName == "" then return false end
    
    local channelId = GetChannelName(channelName)
    if not channelId or channelId == 0 then return false end
    
    local message = self:GetDeathAnnouncement(name, level, className)
    SendChatMessage(message, "CHANNEL", nil, channelId)
    return true
end

-- Einstellungen
function Condolences:SetEnabled(enabled)
    GuildDeathLogDB.condolences.enabled = enabled
end

function Condolences:SetUseHumor(useHumor)
    GuildDeathLogDB.condolences.useHumor = useHumor
end

function Condolences:SetCooldown(seconds)
    GuildDeathLogDB.condolences.cooldown = seconds
end

function Condolences:GetSettings()
    return GuildDeathLogDB.condolences
end

GDL:RegisterModule("Condolences", Condolences)
