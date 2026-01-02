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

GDL.version = "4.2.1"
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

-- Prüft ob Spieler Gilden-Offizier ist (Rang 0-2)
function GDL:IsGuildOfficer()
    if not IsInGuild() then return false end
    local _, _, rankIndex = GetGuildInfo("player")
    return rankIndex and rankIndex <= 2  -- 0 = GM, 1 = Erster Offizier, 2 = Offizier
end

-- Passwort verifizieren
function GDL:VerifyPassword(inputPassword)
    if not GuildDeathLogDB.adminPassword then
        return false, "Kein Passwort gesetzt"
    end
    return inputPassword == GuildDeathLogDB.adminPassword, nil
end

-- Tod aus der Liste löschen
function GDL:DeleteDeath(deathIndex)
    local guildData = self:GetGuildData()
    if not guildData or not guildData.deaths then return false end
    
    if deathIndex < 1 or deathIndex > #guildData.deaths then
        return false
    end
    
    local death = guildData.deaths[deathIndex]
    local deathName = death and death.name or "Unbekannt"
    
    table.remove(guildData.deaths, deathIndex)
    self:Print("|cffFF6666" .. deathName .. "|r wurde aus der Liste entfernt.")
    
    -- UI aktualisieren
    local UI = self:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then
        UI:UpdateChronicle()
    end
    
    return true
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
    GuildDeathLogDB.adminPassword = GuildDeathLogDB.adminPassword or nil -- Gildenleiter-Passwort
    
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
    elseif msg == "ach" or msg == "achievements" or msg == "erfolge" or msg == "milestones" or msg == "meilensteine" then
        if UI then UI:ShowAchievements() end
    elseif msg == "export" then
        if Export then Export:ShowExportWindow() end
    elseif msg == "help" then
        GDL:Print("═══ Befehle / Commands v4.1 ═══")
        GDL:Print("/gdl - Buch öffnen / Open book")
        GDL:Print("/gdl hof - Ruhmeshalle / Hall of Fame")
        GDL:Print("/gdl stats - Statistiken / Statistics")
        GDL:Print("/gdl ach - Meilensteine / Milestones")
        GDL:Print("/gdl export - Export-Fenster")
        GDL:Print("/gdl sync - Synchronisieren")
        GDL:Print("/gdl test - |cffFFFF00Sync-Test senden|r")
        GDL:Print("/gdl debug - Debug-Fenster")
        GDL:Print("/gdl settings - Einstellungen")
        GDL:Print("--- Admin (Gildenleiter) ---")
        GDL:Print("/gdl setpw <pw> - Admin-Passwort setzen")
        GDL:Print("/gdl clearpw - Passwort entfernen")
        GDL:Print("/gdl haspw - Passwort-Status pruefen")
    elseif msg == "test" then
        if Sync then Sync:SendTestDeath() end
    elseif msg == "mtest" or msg == "milestonetest" then
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then 
            Milestones:TestLevelMilestones() 
        else
            GDL:Print("|cffFF0000Milestones-Modul nicht geladen!|r")
        end
    elseif msg == "mforce" or msg == "milestoneforce" then
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then 
            Milestones:ForceUnlockCurrentLevel() 
        else
            GDL:Print("|cffFF0000Milestones-Modul nicht geladen!|r")
        end
    elseif msg == "mcheck" or msg == "milestonecheck" then
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then 
            Milestones:CheckCurrentLevel() 
        else
            GDL:Print("|cffFF0000Milestones-Modul nicht geladen!|r")
        end
    elseif msg:match("^setpw%s+") then
        local password = msg:match("^setpw%s+(.+)$")
        if password and password ~= "" then
            -- Prüfen ob Gildenleiter
            if IsGuildLeader() or GDL:IsGuildOfficer() then
                GuildDeathLogDB.adminPassword = password
                GDL:Print("|cff00FF00Admin-Passwort gesetzt!|r")
                GDL:Print("|cffAAAAFFNur du und Offiziere können es ändern.|r")
            else
                GDL:Print("|cffFF0000Fehler:|r Nur der Gildenleiter oder Offiziere können das Passwort setzen!")
            end
        else
            GDL:Print("Verwendung: /gdl setpw <passwort>")
        end
    elseif msg == "clearpw" then
        if IsGuildLeader() or GDL:IsGuildOfficer() then
            GuildDeathLogDB.adminPassword = nil
            GDL:Print("|cffFFFF00Admin-Passwort entfernt.|r")
        else
            GDL:Print("|cffFF0000Fehler:|r Nur Gildenleiter oder Offiziere!")
        end
    elseif msg == "haspw" then
        if GuildDeathLogDB.adminPassword then
            GDL:Print("|cff00FF00Passwort ist gesetzt.|r Lösch-Buttons sind aktiv.")
        else
            GDL:Print("|cffFFFF00Kein Passwort gesetzt.|r Verwende /gdl setpw <passwort>")
        end
    else
        GDL:Print("Unbekannter Befehl. /gdl help für Hilfe")
    end
end
