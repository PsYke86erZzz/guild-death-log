-- ══════════════════════════════════════════════════════════════
-- MODUL: Locale - Sprachdateien
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Locale = {}

local L = {}
Locale.L = L

function Locale:Initialize()
    local clientLocale = GetLocale()
    
    if clientLocale == "deDE" then
        L.CLASSES = {[1]="Krieger",[2]="Paladin",[3]="Jäger",[4]="Schurke",[5]="Priester",[7]="Schamane",[8]="Magier",[9]="Hexenmeister",[11]="Druide"}
        L.ADDON_TITLE = "Das Buch der Gefallenen"
        L.ADDON_SHORT = "Buch"
        L.NO_GUILD = "Keine Gilde"
        L.NO_GUILD_INFO = "Du bist in keiner Gilde.\nTritt einer Gilde bei."
        L.GUILD_DEATHS = "Gefallene Gildenmitglieder"
        L.TOTAL_DEATHS = "%d Gefallene"
        L.AVG_LEVEL = "Ø Level: %.1f"
        L.TODAY = "Heute: %d"
        L.THIS_WEEK = "Woche: %d"
        L.REFRESH = "Aktualisieren"
        L.SETTINGS = "Einstellungen"
        L.SYNC = "Sync"
        L.DEBUG = "Debug"
        L.LEVEL = "Level"
        L.UNKNOWN = "Unbekannt"
        L.LIVE = "LIVE"
        L.SYNCED = "SYNC"
        L.OK = "OK"
        L.NO_LOSSES = "Keine Verluste!\nDie Gilde steht stark."
        L.GUILD_CHANGED = "Gilde gewechselt zu: %s"
        L.GUILD_LEFT = "Du hast die Gilde verlassen."
        L.SYNC_REQUESTED = "Sync angefordert..."
        L.SYNC_RECEIVED = "Sync: %s (Lvl %d)"
        L.DEATH_RECEIVED = "%s ist gefallen!"
        L.MAP_DIED = "Gestorben: %s"
        L.SETTING_ANNOUNCE = "Gildenchat-Ankündigung"
        L.SETTING_SOUND = "Sound abspielen"
        L.SETTING_OVERLAY = "Popup anzeigen"
        L.SETTING_MAP_MARKERS = "Karten-Marker"
        L.SETTING_DEBUG = "Debug-Ausgabe"
        L.SETTING_BLIZZARD_CHANNEL = "Blizzard HC-Channel"
        L.SETTING_ADDON_CHANNEL = "Addon-Sync"
        L.DEBUG_TITLE = "Debug & Sync Info"
        L.DEBUG_SYNC_STATUS = "Sync Status"
        L.DEBUG_USERS = "Addon-User: %d"
        L.DEBUG_LAST_SYNC = "Letzter Sync: %s"
        L.DEBUG_DEATHLOG = "Deathlog Status"
        L.DEBUG_FOUND = "Gefunden: %s"
        L.DEBUG_ENTRIES = "Einträge: %d"
        L.DEBUG_GUILD_DEATHS = "Gildentode: %d"
        L.DEBUG_LOG = "Aktivitäts-Log"
        L.DEBUG_CLEAR = "Leeren"
        L.DEBUG_NEVER = "Nie"
        L.DEATH_MESSAGES = {"%s (Lvl %d %s) ist gefallen. R.I.P.", "Die Gilde trauert um %s - Level %d %s"}
        L.BOOK_QUOTES = {"Ihre Namen sind in Stein gemeißelt.", "Mögen ihre Seelen Frieden finden.", "In Ehren gefallen."}
    else
        L.CLASSES = {[1]="Warrior",[2]="Paladin",[3]="Hunter",[4]="Rogue",[5]="Priest",[7]="Shaman",[8]="Mage",[9]="Warlock",[11]="Druid"}
        L.ADDON_TITLE = "The Book of the Fallen"
        L.ADDON_SHORT = "Book"
        L.NO_GUILD = "No Guild"
        L.NO_GUILD_INFO = "You are not in a guild.\nJoin a guild to track deaths."
        L.GUILD_DEATHS = "Fallen Guild Members"
        L.TOTAL_DEATHS = "%d Fallen"
        L.AVG_LEVEL = "Avg Level: %.1f"
        L.TODAY = "Today: %d"
        L.THIS_WEEK = "Week: %d"
        L.REFRESH = "Refresh"
        L.SETTINGS = "Settings"
        L.SYNC = "Sync"
        L.DEBUG = "Debug"
        L.LEVEL = "Level"
        L.UNKNOWN = "Unknown"
        L.LIVE = "LIVE"
        L.SYNCED = "SYNC"
        L.OK = "OK"
        L.NO_LOSSES = "No losses!\nThe guild stands strong."
        L.GUILD_CHANGED = "Guild changed to: %s"
        L.GUILD_LEFT = "You have left the guild."
        L.SYNC_REQUESTED = "Sync requested..."
        L.SYNC_RECEIVED = "Sync: %s (Lvl %d)"
        L.DEATH_RECEIVED = "%s has fallen!"
        L.MAP_DIED = "Died: %s"
        L.SETTING_ANNOUNCE = "Guild chat announcement"
        L.SETTING_SOUND = "Play sound"
        L.SETTING_OVERLAY = "Show popup"
        L.SETTING_MAP_MARKERS = "Map markers"
        L.SETTING_DEBUG = "Debug output"
        L.SETTING_BLIZZARD_CHANNEL = "Blizzard HC channel"
        L.SETTING_ADDON_CHANNEL = "Addon sync"
        L.DEBUG_TITLE = "Debug & Sync Info"
        L.DEBUG_SYNC_STATUS = "Sync Status"
        L.DEBUG_USERS = "Addon users: %d"
        L.DEBUG_LAST_SYNC = "Last sync: %s"
        L.DEBUG_DEATHLOG = "Deathlog Status"
        L.DEBUG_FOUND = "Found: %s"
        L.DEBUG_ENTRIES = "Entries: %d"
        L.DEBUG_GUILD_DEATHS = "Guild deaths: %d"
        L.DEBUG_LOG = "Activity Log"
        L.DEBUG_CLEAR = "Clear"
        L.DEBUG_NEVER = "Never"
        L.DEATH_MESSAGES = {"%s (Lvl %d %s) has fallen. R.I.P.", "The guild mourns %s - Level %d %s"}
        L.BOOK_QUOTES = {"Their names are carved in stone.", "May their souls find peace.", "Fallen with honor."}
    end
end

function GDL:L(key)
    return L[key] or key
end

function GDL:GetClassName(classId)
    return L.CLASSES and L.CLASSES[classId] or L.UNKNOWN or "Unknown"
end

-- Register
GDL:RegisterModule("Locale", Locale)
