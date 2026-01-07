-- ══════════════════════════════════════════════════════════════
-- MODUL: Locale - Sprachdateien / Language Files
-- Supports: German (deDE) and English (default)
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Locale = {}

local L = {}
Locale.L = L

function Locale:Initialize()
    local clientLocale = GetLocale()
    
    if clientLocale == "deDE" then
        -- ═══ GERMAN / DEUTSCH ═══
        
        -- Classes
        L.CLASSES = {[1]="Krieger",[2]="Paladin",[3]="Jaeger",[4]="Schurke",[5]="Priester",[7]="Schamane",[8]="Magier",[9]="Hexenmeister",[11]="Druide"}
        
        -- Core
        L.ADDON_TITLE = "Das Buch der Gefallenen"
        L.ADDON_SHORT = "Buch"
        L.NO_GUILD = "Keine Gilde"
        L.NO_GUILD_INFO = "Du bist in keiner Gilde.\nTritt einer Gilde bei."
        L.UNKNOWN = "Unbekannt"
        L.LEVEL = "Level"
        L.OK = "OK"
        L.CANCEL = "Abbrechen"
        L.CLOSE = "Schliessen"
        L.SAVE = "Speichern"
        L.DELETE = "Loeschen"
        L.EDIT = "Bearbeiten"
        L.BACK = "Zurueck"
        L.VERSION = "Version"
        
        -- Statistics
        L.GUILD_DEATHS = "Gefallene Gildenmitglieder"
        L.TOTAL_DEATHS = "%d Gefallene"
        L.AVG_LEVEL = "Avg Level: %.1f"
        L.TODAY = "Heute: %d"
        L.THIS_WEEK = "Woche: %d"
        L.FALLEN = "Gefallene"
        L.FALLEN_TODAY = "Heute"
        L.FALLEN_WEEK = "Diese Woche"
        L.NO_LOSSES = "Keine Verluste!\nDie Gilde steht stark."
        
        -- Buttons (UI)
        L.BTN_REFRESH = "Aktualisieren"
        L.BTN_SETTINGS = "Einstellungen"
        L.BTN_SYNC = "Sync"
        L.BTN_EXPORT = "Export"
        L.BTN_DEBUG = "Debug"
        L.BTN_HALL_OF_FAME = "Ruhmeshalle"
        L.BTN_STATISTICS = "Statistiken"
        L.BTN_MILESTONES = "Meilensteine"
        L.BTN_PROFESSIONS = "Berufe"
        L.BTN_GUILD_MAP = "Gilden-Karte"
        L.BTN_TITLES = "Titel"
        L.BTN_MEMORIAL = "Gedenkhalle"
        L.BTN_GUILD_STATS = "Gilden-Stats"
        L.BTN_RULES = "Regeln"
        L.BTN_CALENDAR = "Kalender"
        L.BTN_LEADER = "Leitung"
        L.BTN_BOOK = "Buch"
        
        -- Guild Rules
        L.RULES_TITLE = "Gildenregeln"
        L.RULES_CAN_EDIT = "Du kannst die Regeln bearbeiten"
        L.RULES_CANNOT_EDIT = "Nur Offiziere koennen Regeln bearbeiten"
        L.RULES_UPDATED = "Gildenregeln wurden aktualisiert! Bitte nachlesen."
        L.RULES_SAVED = "Gildenregeln gespeichert und verteilt!"
        L.RULES_REQUESTING = "Regeln werden von Gildenmitgliedern angefragt..."
        L.RULES_ONLY_OFFICERS = "Nur Offiziere koennen die Regeln bearbeiten!"
        L.RULES_CHAT_UPDATED = "[Gildenregeln] Aktualisiert, bitte nachlesen! (/gdl rules)"
        
        -- Settings
        L.SETTING_ANNOUNCE = "Gildenchat-Ankuendigung"
        L.SETTING_SOUND = "Sound abspielen"
        L.SETTING_OVERLAY = "Popup anzeigen"
        L.SETTING_MAP_MARKERS = "Karten-Marker"
        L.SETTING_DEBUG = "Debug-Ausgabe"
        L.SETTING_BLIZZARD_CHANNEL = "Blizzard HC-Channel"
        L.SETTING_ADDON_CHANNEL = "Addon-Sync"
        L.SETTING_GUILD_TRACKER = "Gilden-Tracker"
        
        -- Sync & Status
        L.LIVE = "LIVE"
        L.SYNCED = "SYNC"
        L.SYNC_REQUESTED = "Sync angefordert..."
        L.SYNC_RECEIVED = "Sync: %s (Lvl %d)"
        L.GUILD_CHANGED = "Gilde gewechselt zu: %s"
        L.GUILD_LEFT = "Du hast die Gilde verlassen."
        
        -- Deaths
        L.DEATH_RECEIVED = "%s ist gefallen!"
        L.MAP_DIED = "Gestorben: %s"
        L.KILLED_BY = "Getoetet von"
        L.LAST_WORDS = "Letzte Worte"
        L.ZONE = "Zone"
        L.DATE = "Datum"
        L.TIME = "Zeit"
        
        -- Debug
        L.DEBUG_TITLE = "Debug & Sync Info"
        L.DEBUG_SYNC_STATUS = "Sync Status"
        L.DEBUG_USERS = "Addon-User: %d"
        L.DEBUG_LAST_SYNC = "Letzter Sync: %s"
        L.DEBUG_DEATHLOG = "Deathlog Status"
        L.DEBUG_FOUND = "Gefunden: %s"
        L.DEBUG_ENTRIES = "Eintraege: %d"
        L.DEBUG_GUILD_DEATHS = "Gildentode: %d"
        L.DEBUG_LOG = "Aktivitaets-Log"
        L.DEBUG_CLEAR = "Leeren"
        L.DEBUG_NEVER = "Nie"
        
        -- Hall of Fame
        L.HOF_TITLE = "Ruhmeshalle"
        L.HOF_SUBTITLE = "Die Unsterblichen"
        L.HOF_EMPTY = "Noch keine Level 60 Ueberlebenden"
        L.HOF_REACHED = "erreichte Level 60"
        
        -- Memorial
        L.MEMORIAL_TITLE = "Gedenkhalle"
        L.MEMORIAL_SUBTITLE = "Wir gedenken der Gefallenen"
        L.MEMORIAL_EMPTY = "Keine Gefallenen zum Gedenken"
        L.MEMORIAL_RIP = "Ruhe in Frieden"
        
        -- Milestones
        L.MILESTONES_TITLE = "Meilensteine"
        L.MILESTONES_SUBTITLE = "Ueberlebens-Erfolge"
        L.MILESTONE_UNLOCKED = "Meilenstein erreicht!"
        L.MILESTONE_LEVEL = "Level %d erreicht"
        L.MILESTONE_BOSS = "%s besiegt"
        L.MILESTONE_PROFESSION = "%s Skill %d"
        
        -- Professions
        L.PROFESSIONS_TITLE = "Gilden-Berufe"
        L.PROFESSIONS_SUBTITLE = "Wer kann was?"
        L.PROFESSIONS_EMPTY = "Keine Berufsdaten verfuegbar"
        L.PROFESSIONS_SEARCH = "Suchen..."
        
        -- Titles
        L.TITLES_TITLE = "Titel"
        L.TITLES_CURRENT = "Aktueller Titel:"
        L.TITLES_UNLOCKED = "Titel freigeschaltet"
        L.TITLES_CLICK_SELECT = "Klicken zum Auswaehlen"
        L.TITLES_ACTIVE = "AKTIV"
        L.TITLES_REQUIRED = "Benoetigt:"
        L.TITLES_PRIORITY = "Prioritaet:"
        
        -- Guild Stats
        L.GSTATS_TITLE = "Gilden-Statistiken"
        L.GSTATS_MEMBERS = "Mitglieder"
        L.GSTATS_ONLINE = "Online"
        L.GSTATS_AVG_LEVEL = "Durchschnittslevel"
        L.GSTATS_DEATHS_TODAY = "Tode heute"
        L.GSTATS_DEATHS_WEEK = "Tode diese Woche"
        L.GSTATS_DEATHS_TOTAL = "Tode gesamt"
        
        -- Export
        L.EXPORT_TITLE = "Export"
        L.EXPORT_DISCORD = "Discord Format"
        L.EXPORT_TEXT = "Text Format"
        L.EXPORT_CSV = "CSV Format"
        L.EXPORT_STATS = "Statistiken"
        L.EXPORT_COPY = "Text markieren und Strg+C"
        
        -- Chronicle (main list)
        L.CHRONICLE_HEADER = "- Chronik der Gefallenen -"
        L.CHRONICLE_EMPTY = "Noch keine Gefallenen verzeichnet"
        
        -- Quotes
        L.BOOK_QUOTES = {
            "Ihre Namen sind in Stein gemeisselt.",
            "Moegen ihre Seelen Frieden finden.",
            "In Ehren gefallen.",
            "Vergessen werden sie niemals.",
            "Helden sterben nicht, sie leben in unseren Herzen weiter.",
        }
        
        -- Death Messages (simple versions for chat)
        L.DEATH_MESSAGES = {
            "%s (Lvl %d %s) ist gefallen. R.I.P.",
            "Die Gilde trauert um %s - Level %d %s",
        }
        
    else
        -- ═══ ENGLISH (DEFAULT) ═══
        
        -- Classes
        L.CLASSES = {[1]="Warrior",[2]="Paladin",[3]="Hunter",[4]="Rogue",[5]="Priest",[7]="Shaman",[8]="Mage",[9]="Warlock",[11]="Druid"}
        
        -- Core
        L.ADDON_TITLE = "The Book of the Fallen"
        L.ADDON_SHORT = "Book"
        L.NO_GUILD = "No Guild"
        L.NO_GUILD_INFO = "You are not in a guild.\nJoin a guild to track deaths."
        L.UNKNOWN = "Unknown"
        L.LEVEL = "Level"
        L.OK = "OK"
        L.CANCEL = "Cancel"
        L.CLOSE = "Close"
        L.SAVE = "Save"
        L.DELETE = "Delete"
        L.EDIT = "Edit"
        L.BACK = "Back"
        L.VERSION = "Version"
        
        -- Statistics
        L.GUILD_DEATHS = "Fallen Guild Members"
        L.TOTAL_DEATHS = "%d Fallen"
        L.AVG_LEVEL = "Avg Level: %.1f"
        L.TODAY = "Today: %d"
        L.THIS_WEEK = "Week: %d"
        L.FALLEN = "Fallen"
        L.FALLEN_TODAY = "Today"
        L.FALLEN_WEEK = "This Week"
        L.NO_LOSSES = "No losses!\nThe guild stands strong."
        
        -- Buttons (UI)
        L.BTN_REFRESH = "Refresh"
        L.BTN_SETTINGS = "Settings"
        L.BTN_SYNC = "Sync"
        L.BTN_EXPORT = "Export"
        L.BTN_DEBUG = "Debug"
        L.BTN_HALL_OF_FAME = "Hall of Fame"
        L.BTN_STATISTICS = "Statistics"
        L.BTN_MILESTONES = "Milestones"
        L.BTN_PROFESSIONS = "Professions"
        L.BTN_GUILD_MAP = "Guild Map"
        L.BTN_TITLES = "Titles"
        L.BTN_MEMORIAL = "Memorial"
        L.BTN_GUILD_STATS = "Guild Stats"
        L.BTN_RULES = "Rules"
        L.BTN_CALENDAR = "Calendar"
        L.BTN_LEADER = "Leadership"
        L.BTN_BOOK = "Book"
        
        -- Guild Rules
        L.RULES_TITLE = "Guild Rules"
        L.RULES_CAN_EDIT = "You can edit the rules"
        L.RULES_CANNOT_EDIT = "Only officers can edit rules"
        L.RULES_UPDATED = "Guild rules have been updated! Please read."
        L.RULES_SAVED = "Guild rules saved and distributed!"
        L.RULES_REQUESTING = "Requesting rules from guild members..."
        L.RULES_ONLY_OFFICERS = "Only officers can edit the rules!"
        L.RULES_CHAT_UPDATED = "[Guild Rules] Updated, please read! (/gdl rules)"
        
        -- Settings
        L.SETTING_ANNOUNCE = "Guild chat announcement"
        L.SETTING_SOUND = "Play sound"
        L.SETTING_OVERLAY = "Show popup"
        L.SETTING_MAP_MARKERS = "Map markers"
        L.SETTING_DEBUG = "Debug output"
        L.SETTING_BLIZZARD_CHANNEL = "Blizzard HC channel"
        L.SETTING_ADDON_CHANNEL = "Addon sync"
        L.SETTING_GUILD_TRACKER = "Guild tracker"
        
        -- Sync & Status
        L.LIVE = "LIVE"
        L.SYNCED = "SYNC"
        L.SYNC_REQUESTED = "Sync requested..."
        L.SYNC_RECEIVED = "Sync: %s (Lvl %d)"
        L.GUILD_CHANGED = "Guild changed to: %s"
        L.GUILD_LEFT = "You have left the guild."
        
        -- Deaths
        L.DEATH_RECEIVED = "%s has fallen!"
        L.MAP_DIED = "Died: %s"
        L.KILLED_BY = "Killed by"
        L.LAST_WORDS = "Last Words"
        L.ZONE = "Zone"
        L.DATE = "Date"
        L.TIME = "Time"
        
        -- Debug
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
        
        -- Hall of Fame
        L.HOF_TITLE = "Hall of Fame"
        L.HOF_SUBTITLE = "The Immortals"
        L.HOF_EMPTY = "No Level 60 survivors yet"
        L.HOF_REACHED = "reached Level 60"
        
        -- Memorial
        L.MEMORIAL_TITLE = "Memorial Hall"
        L.MEMORIAL_SUBTITLE = "We remember the fallen"
        L.MEMORIAL_EMPTY = "No fallen to remember"
        L.MEMORIAL_RIP = "Rest in Peace"
        
        -- Milestones
        L.MILESTONES_TITLE = "Milestones"
        L.MILESTONES_SUBTITLE = "Survival Achievements"
        L.MILESTONE_UNLOCKED = "Milestone achieved!"
        L.MILESTONE_LEVEL = "Reached Level %d"
        L.MILESTONE_BOSS = "Defeated %s"
        L.MILESTONE_PROFESSION = "%s Skill %d"
        
        -- Professions
        L.PROFESSIONS_TITLE = "Guild Professions"
        L.PROFESSIONS_SUBTITLE = "Who can do what?"
        L.PROFESSIONS_EMPTY = "No profession data available"
        L.PROFESSIONS_SEARCH = "Search..."
        
        -- Titles
        L.TITLES_TITLE = "Titles"
        L.TITLES_CURRENT = "Current Title:"
        L.TITLES_UNLOCKED = "titles unlocked"
        L.TITLES_CLICK_SELECT = "Click to select"
        L.TITLES_ACTIVE = "ACTIVE"
        L.TITLES_REQUIRED = "Requires:"
        L.TITLES_PRIORITY = "Priority:"
        
        -- Guild Stats
        L.GSTATS_TITLE = "Guild Statistics"
        L.GSTATS_MEMBERS = "Members"
        L.GSTATS_ONLINE = "Online"
        L.GSTATS_AVG_LEVEL = "Average Level"
        L.GSTATS_DEATHS_TODAY = "Deaths today"
        L.GSTATS_DEATHS_WEEK = "Deaths this week"
        L.GSTATS_DEATHS_TOTAL = "Total deaths"
        
        -- Export
        L.EXPORT_TITLE = "Export"
        L.EXPORT_DISCORD = "Discord Format"
        L.EXPORT_TEXT = "Text Format"
        L.EXPORT_CSV = "CSV Format"
        L.EXPORT_STATS = "Statistics"
        L.EXPORT_COPY = "Select text and Ctrl+C"
        
        -- Chronicle (main list)
        L.CHRONICLE_HEADER = "- Chronicle of the Fallen -"
        L.CHRONICLE_EMPTY = "No fallen recorded yet"
        
        -- Quotes
        L.BOOK_QUOTES = {
            "Their names are carved in stone.",
            "May their souls find peace.",
            "Fallen with honor.",
            "They will never be forgotten.",
            "Heroes don't die, they live on in our hearts.",
        }
        
        -- Death Messages (simple versions for chat)
        L.DEATH_MESSAGES = {
            "%s (Lvl %d %s) has fallen. R.I.P.",
            "The guild mourns %s - Level %d %s",
        }
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
