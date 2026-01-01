-- ╔══════════════════════════════════════════════════════════════╗
-- ║     DAS BUCH DER GEFALLENEN v4.0                            ║
-- ║     The Book of the Fallen                                   ║
-- ║     Epic Edition - LastWords, Killer, Achievements          ║
-- ║     Autor: PsYke86                                           ║
-- ╚══════════════════════════════════════════════════════════════╝

local addonName, addon = ...

-- Globale Addon-Tabelle initialisieren
local GDL = {}
addon.GDL = GDL
_G["GuildDeathLog"] = GDL
_G["GuildDeathLogDB"] = _G["GuildDeathLogDB"] or {}

GDL.version = "4.0.3"
GDL.addonName = addonName
GDL.modules = {}
GDL.currentGuildName = nil
GDL.playerName = nil
GDL.playerRealm = nil

-- ══════════════════════════════════════════════════════════════
-- CORE FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function GDL:Print(msg)
    print("|cffFFD100[Buch]|r " .. (msg or ""))
end

function GDL:Debug(msg)
    -- An Debug-Modul senden (fuer Debug-Fenster)
    local Debug = self.modules["Debug"]
    if Debug and Debug.Log then
        Debug:Log("DEBUG", msg, "AAAAAA")
    end
    
    -- Im Chat anzeigen wenn aktiviert
    if GuildDeathLogDB.settings and GuildDeathLogDB.settings.debugPrint then
        print("|cffAAAAAA[GDL-DEBUG]|r " .. (msg or ""))
    end
end

function GDL:RegisterModule(name, module)
    if not name or not module then return end
    if self.modules[name] then return end
    self.modules[name] = module
end

function GDL:GetModule(name)
    return self.modules[name]
end

-- Fallback L() Funktion bis Locale geladen ist
function GDL:L(key)
    local Locale = self.modules["Locale"]
    if Locale and Locale.L and Locale.L[key] then
        return Locale.L[key]
    end
    return key or ""
end

function GDL:GetClassName(classId)
    local Locale = self.modules["Locale"]
    if Locale and Locale.L and Locale.L.CLASSES then
        return Locale.L.CLASSES[classId] or "Unknown"
    end
    return "Unknown"
end

function GDL:FireModuleEvent(event, ...)
    for name, module in pairs(self.modules) do
        if module and module.OnEvent then
            pcall(module.OnEvent, module, event, ...)
        end
    end
end

function GDL:InitializeModules()
    for name, module in pairs(self.modules) do
        if module and module.Initialize then
            local ok, err = pcall(module.Initialize, module)
            if not ok then
                self:Print("|cffFF0000Fehler in " .. name .. ":|r " .. (err or "unknown"))
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- DATENBANK
-- ══════════════════════════════════════════════════════════════

function GDL:InitDB()
    GuildDeathLogDB.guilds = GuildDeathLogDB.guilds or {}
    GuildDeathLogDB.settings = GuildDeathLogDB.settings or {}
    
    -- Version Check fuer Migration
    local currentVersion = "4.0.2"
    local savedVersion = GuildDeathLogDB.addonVersion or "0"
    
    -- WICHTIG: Bei Update alle Settings auf AN setzen!
    if savedVersion ~= currentVersion then
        GuildDeathLogDB.settings.announce = true
        GuildDeathLogDB.settings.sound = true
        GuildDeathLogDB.settings.overlay = true
        GuildDeathLogDB.settings.mapMarkers = true
        GuildDeathLogDB.settings.useBlizzardChannel = true
        GuildDeathLogDB.settings.useAddonChannel = true
        GuildDeathLogDB.settings.debugPrint = false
        GuildDeathLogDB.addonVersion = currentVersion
        print("|cffFFD100[Buch]|r v4.0.1 - Alle Einstellungen aktiviert!")
    end
    
    -- Sicherstellen dass alle Keys existieren
    local defaults = {
        announce = true,
        sound = true,
        overlay = true,
        mapMarkers = true,
        useBlizzardChannel = true,
        useAddonChannel = true,
        debugPrint = false,
        overlayScale = 1.0,
    }
    
    for key, defaultValue in pairs(defaults) do
        if GuildDeathLogDB.settings[key] == nil then
            GuildDeathLogDB.settings[key] = defaultValue
        end
    end
    
    GuildDeathLogDB.syncUsers = GuildDeathLogDB.syncUsers or {}
    GuildDeathLogDB.lastSyncTimes = GuildDeathLogDB.lastSyncTimes or {}
end

function GDL:GetGuildData(guildName)
    guildName = guildName or self.currentGuildName
    if not guildName then return nil end
    
    if not GuildDeathLogDB.guilds[guildName] then
        GuildDeathLogDB.guilds[guildName] = {
            deaths = {},
            members = {},
            pendingSync = {},
        }
    end
    return GuildDeathLogDB.guilds[guildName]
end

-- ══════════════════════════════════════════════════════════════
-- HAUPT-EVENT-HANDLER
-- ══════════════════════════════════════════════════════════════

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LOGOUT")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        GDL:InitDB()
        GDL.playerName = UnitName("player")
        GDL.playerRealm = GetRealmName()
        
        C_Timer.After(0.5, function()
            GDL:InitializeModules()
        end)
        
        GDL:Print("|cffFFD100v" .. GDL.version .. "|r geladen")
        GDL:Print("|cffAAAAAA/gdl, /buch, /book|r")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            GDL:FireModuleEvent("PLAYER_READY")
        end)
        
    elseif event == "PLAYER_LOGOUT" then
        GDL:FireModuleEvent("PLAYER_LOGOUT")
    end
    
    GDL:FireModuleEvent(event, arg1)
end)

-- ══════════════════════════════════════════════════════════════
-- SLASH COMMANDS
-- ══════════════════════════════════════════════════════════════

SLASH_GDL1, SLASH_GDL2, SLASH_GDL3 = "/gdl", "/buch", "/book"

SlashCmdList["GDL"] = function(msg)
    msg = (msg or ""):lower():trim()
    
    local UI = GDL:GetModule("UI")
    local Sync = GDL:GetModule("Sync")
    local Debug = GDL:GetModule("Debug")
    local Export = GDL:GetModule("Export")
    
    if msg == "" or msg == "show" then
        if UI then UI:ShowBook() end
    elseif msg == "hide" then
        if UI then UI:HideBook() end
    elseif msg == "settings" or msg == "config" then
        if UI then UI:ShowSettings() end
    elseif msg == "sync" then
        if Sync then Sync:RequestFullSync() end
    elseif msg == "debug" then
        if Debug then Debug:ShowWindow() end
    elseif msg == "scan" then
        local Deathlog = GDL:GetModule("Deathlog")
        if Deathlog then Deathlog:ScanData() end
    elseif msg == "hof" or msg == "halloffame" or msg == "ruhmeshalle" then
        if UI then UI:ShowHallOfFame() end
    elseif msg == "stats" or msg == "statistics" or msg == "statistiken" then
        if UI then UI:ShowStatistics() end
    elseif msg == "ach" or msg == "achievements" or msg == "erfolge" then
        if UI then UI:ShowAchievements() end
    elseif msg == "export" then
        if Export then Export:ShowExportWindow() end
    elseif msg == "help" then
        GDL:Print("═══ Befehle / Commands v4.0 ═══")
        GDL:Print("/gdl - Buch öffnen / Open book")
        GDL:Print("/gdl hof - Ruhmeshalle / Hall of Fame")
        GDL:Print("/gdl stats - Statistiken / Statistics")
        GDL:Print("/gdl ach - Erfolge / Achievements")
        GDL:Print("/gdl export - Export-Fenster")
        GDL:Print("/gdl sync - Synchronisieren")
        GDL:Print("/gdl test - |cffFFFF00Sync-Test senden|r")
        GDL:Print("/gdl debug - Debug-Fenster")
        GDL:Print("/gdl settings - Einstellungen")
    elseif msg == "test" then
        if Sync then Sync:SendTestDeath() end
    else
        GDL:Print("Unbekannter Befehl. /gdl help für Hilfe")
    end
end
