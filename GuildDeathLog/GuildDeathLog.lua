-- ╔============================================================══╗
-- ║     DAS BUCH DER GEFALLENEN v5.3.3                          ║
-- ║     The Book of the Fallen                                   ║
-- ║     Epic Edition - LastWords, Killer, Achievements          ║
-- ║     Autor: PsYke86                                           ║
-- ╚============================================================══╝

local addonName, addon = ...

-- Globale Addon-Tabelle initialisieren
local GDL = {}
addon.GDL = GDL
_G["GuildDeathLog"] = GDL
_G["GuildDeathLogDB"] = _G["GuildDeathLogDB"] or {}

GDL.version = "5.9.7"
GDL.addonName = addonName
GDL.modules = {}
GDL.currentGuildName = nil
GDL.playerName = nil
GDL.playerRealm = nil

-- ============================================================══
-- CORE FUNKTIONEN
-- ============================================================══

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
    local deathTimestamp = death and death.timestamp or 0
    
    table.remove(guildData.deaths, deathIndex)
    self:Print("|cffFF6666" .. deathName .. "|r wurde aus der Liste entfernt.")
    
    -- DELETE an andere Gildenmitglieder syncen!
    local Sync = self:GetModule("Sync")
    if Sync and Sync.BroadcastDelete then
        Sync:BroadcastDelete(deathName, deathTimestamp)
        self:Print("|cff888888Loeschung wird an Gildenmitglieder gesendet...|r")
    end
    
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

-- ============================================================══
-- DATENBANK
-- ============================================================══

function GDL:InitDB()
    GuildDeathLogDB.guilds = GuildDeathLogDB.guilds or {}
    GuildDeathLogDB.settings = GuildDeathLogDB.settings or {}
    GuildDeathLogDB.adminPassword = GuildDeathLogDB.adminPassword or nil -- Gildenleiter-Passwort
    
    -- Version Check fuer Migration
    local currentVersion = "5.9.7"
    local savedVersion = GuildDeathLogDB.addonVersion or "0"
    
    -- BUG FIX: Settings NICHT mehr ueberschreiben bei Update!
    -- Nur bei komplett neuer Installation (Version "0") Defaults setzen
    if savedVersion == "0" then
        -- Erste Installation - Defaults setzen
        GuildDeathLogDB.settings.announce = true
        GuildDeathLogDB.settings.sound = true
        GuildDeathLogDB.settings.overlay = true
        GuildDeathLogDB.settings.mapMarkers = true
        GuildDeathLogDB.settings.guildTracker = true
        GuildDeathLogDB.settings.useBlizzardChannel = true
        GuildDeathLogDB.settings.useAddonChannel = true
        GuildDeathLogDB.settings.debugPrint = false
        GuildDeathLogDB.settings.milestoneAnnounce = true  -- NEU: Meilenstein-Chat
        GuildDeathLogDB.settings.milestonePopup = true     -- NEU: Meilenstein-Popup
    end
    
    if savedVersion ~= currentVersion then
        GuildDeathLogDB.addonVersion = currentVersion
        print("|cffFFD100[Buch der Gefallenen]|r v5.9.5 - |cff00FF00NEUES BUCH-UI!|r Tippe /gdl")
    end
    
    -- Sicherstellen dass alle Keys existieren (OHNE bestehende zu ueberschreiben!)
    local defaults = {
        announce = true,
        sound = true,
        overlay = true,
        mapMarkers = true,
        guildTracker = true,
        nameplateTitles = true,
        useBlizzardChannel = true,
        useAddonChannel = true,
        debugPrint = false,
        overlayScale = 1.0,
        milestoneAnnounce = true,  -- NEU: Meilenstein-Chat-Nachrichten
        milestonePopup = true,     -- NEU: Meilenstein-Popup
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
    -- WICHTIG: Wenn nicht in Gilde, NIL zurückgeben!
    if not IsInGuild() then 
        return nil 
    end
    
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

-- ============================================================══
-- HAUPT-EVENT-HANDLER
-- ============================================================══

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
        
        -- Eine einzige schöne Startup-Meldung
        GDL:Print("|cffFFD100Buch der Gefallenen:|r |cff00FF00Aktiv|r |cff888888(v" .. GDL.version .. ")|r")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            GDL:FireModuleEvent("PLAYER_READY")
        end)
        
    elseif event == "PLAYER_LOGOUT" then
        GDL:FireModuleEvent("PLAYER_LOGOUT")
    end
    
    GDL:FireModuleEvent(event, arg1)
end)

-- ============================================================══
-- SLASH COMMANDS
-- ============================================================══

SLASH_GDL1, SLASH_GDL2, SLASH_GDL3 = "/gdl", "/buch", "/book"

SlashCmdList["GDL"] = function(msg)
    msg = (msg or ""):lower():trim()
    
    local BookUI = _G["GDLBookUI"]
    local UI = GDL:GetModule("UI")
    local Sync = GDL:GetModule("Sync")
    local Debug = GDL:GetModule("Debug")
    local Export = GDL:GetModule("Export")
    
    if msg == "" or msg == "show" then
        if BookUI then BookUI:Toggle() end
    elseif msg == "hide" then
        if BookUI then BookUI:Hide() end
    elseif msg == "settings" or msg == "config" then
        -- Öffne Buch auf Settings-Kapitel
        if BookUI then 
            BookUI:Show()
            BookUI:LoadChapter(9)  -- Settings ist Kapitel 9
        end
    elseif msg == "sync" then
        if Sync then Sync:RequestFullSync() end
    elseif msg == "syncstatus" or msg == "ss" then
        if Sync then Sync:PrintSyncStatus() end
    elseif msg == "clearqueue" or msg == "cq" then
        if Sync then Sync:ClearQueue() end
    elseif msg == "debug" then
        if Debug then Debug:ShowWindow() end
    elseif msg == "scan" then
        local Deathlog = GDL:GetModule("Deathlog")
        if Deathlog then 
            Deathlog:DetectDeathlog()
            Deathlog:ScanData() 
            GDL:Print("Deathlog-Scan durchgefuehrt!")
        end
    elseif msg == "dlcheck" or msg == "deathlogcheck" or msg == "dlstatus" then
        -- NEU: Deathlog Debug-Befehl
        local Deathlog = GDL:GetModule("Deathlog")
        if Deathlog then 
            Deathlog:DebugGlobals()
        else
            GDL:Print("|cffFF0000Deathlog-Modul nicht geladen!|r")
        end
    elseif msg == "hof" or msg == "halloffame" or msg == "ruhmeshalle" then
        if BookUI then BookUI:Show() BookUI:LoadChapter(2) end
    elseif msg == "stats" or msg == "statistics" or msg == "statistiken" then
        if BookUI then BookUI:Show() BookUI:LoadChapter(3) end
    elseif msg == "ach" or msg == "achievements" or msg == "erfolge" or msg == "milestones" or msg == "meilensteine" then
        if BookUI then BookUI:Show() BookUI:LoadChapter(4) end
    elseif msg == "titles" or msg == "titel" then
        if BookUI then BookUI:Show() BookUI:LoadChapter(5) end
    elseif msg == "export" then
        if Export then Export:ShowExportWindow() end
    elseif msg == "help" then
        GDL:Print("=== Befehle / Commands v5.9.5 ===")
        GDL:Print("/gdl - |cffFFD100Buch oeffnen|r")
        GDL:Print("/gdl hof - Ruhmeshalle")
        GDL:Print("/gdl stats - Statistiken")
        GDL:Print("/gdl ach - Meilensteine")
        GDL:Print("/gdl titles - Titel")
        GDL:Print("/gdl prof - Gilden-Berufe")
        GDL:Print("/gdl rules - Gildenregeln")
        GDL:Print("/gdl cal - Gilden-Kalender")
        GDL:Print("/gdl settings - Einstellungen")
        GDL:Print("/gdl sync - Sync anfordern")
        GDL:Print("/gdl debug - Debug-Fenster")
    elseif msg == "cal" or msg == "calendar" or msg == "kalender" then
        if BookUI then BookUI:Show() BookUI:LoadChapter(8) end
    elseif msg == "leader" or msg == "leitung" or msg == "gl" then
        -- GEHEIMER COMMAND - nicht in Help aufgelistet!
        local GL = GDL:GetModule("GuildLeader")
        if GL then
            GL:Toggle()
        end
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
    elseif msg == "dueltest" or msg == "duelltest" then
        -- ⚔️ Simuliere Duell-Sieg für Tests
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then
            local charKey = Milestones:GetCharacterKey()
            local charData = Milestones:GetCharacterData(charKey)
            charData.stats.duelWins = (charData.stats.duelWins or 0) + 1
            local wins = charData.stats.duelWins
            GDL:Print("|cffFF4500⚔️ DUELL-TEST:|r Siege jetzt: " .. wins)
            Milestones:CheckDuelMilestones(wins)
        end
    elseif msg == "duelreset" or msg == "duellreset" then
        -- Reset Duell-Counter
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then
            local charKey = Milestones:GetCharacterKey()
            local charData = Milestones:GetCharacterData(charKey)
            charData.stats.duelWins = 0
            GDL:Print("|cffFFFF00Duell-Siege zurueckgesetzt auf 0|r")
        end
    elseif msg == "duelstats" or msg == "duellstats" then
        -- Zeige Duell-Stats
        local Milestones = GDL:GetModule("Milestones")
        if Milestones then
            local charKey = Milestones:GetCharacterKey()
            local charData = Milestones:GetCharacterData(charKey)
            local wins = charData.stats.duelWins or 0
            GDL:Print("|cffFF4500⚔️ Deine Duell-Siege:|r " .. wins)
        end
    elseif msg:match("^setpw%s+") then
        local password = msg:match("^setpw%s+(.+)$")
        if password and password ~= "" then
            -- Prüfen ob Gildenleiter
            if IsGuildLeader() or GDL:IsGuildOfficer() then
                GuildDeathLogDB.adminPassword = password
                GDL:Print("|cff00FF00Admin-Passwort gesetzt:|r '" .. password .. "'")
                GDL:Print("|cffAAAAFFNur du und Offiziere können es ändern.|r")
                -- UI aktualisieren damit X-Buttons erscheinen
                local UI = GDL:GetModule("UI")
                if UI and UI.mainFrame and UI.mainFrame:IsShown() then
                    UI:UpdateChronicle()
                end
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
            GDL:Print("|cff00FF00Passwort ist gesetzt:|r '" .. GuildDeathLogDB.adminPassword .. "'")
            GDL:Print("Lösch-Buttons sollten sichtbar sein (X rechts neben Einträgen)")
        else
            GDL:Print("|cffFFFF00Kein Passwort gesetzt.|r Verwende /gdl setpw <passwort>")
        end
    elseif msg == "blacklist" then
        -- Zeige Blacklist
        local bl = GuildDeathLogDB.deletedDeaths or {}
        local count = 0
        GDL:Print("|cffFFCC00=== Permanent geloeschte Eintraege ===|r")
        for key, timestamp in pairs(bl) do
            count = count + 1
            local name = key:match("^([^:]+)")
            GDL:Print(count .. ". |cffFF6666" .. name .. "|r")
        end
        if count == 0 then
            GDL:Print("|cff888888Keine geloeschten Eintraege.|r")
        else
            GDL:Print("|cffAAAAFFUm Blacklist zu leeren: /gdl clearblacklist|r")
        end
    elseif msg == "clearblacklist" then
        if IsGuildLeader() or GDL:IsGuildOfficer() then
            GuildDeathLogDB.deletedDeaths = {}
            GDL:Print("|cff00FF00Blacklist geleert!|r Geloeschte Eintraege koennen wieder gesynct werden.")
        else
            GDL:Print("|cffFF0000Fehler:|r Nur Gildenleiter oder Offiziere!")
        end
    elseif msg:match("^bltest%s+") then
        -- Test ob ein Name auf der Blacklist ist
        local testName = msg:match("^bltest%s+(.+)$")
        if testName then
            local Sync = GDL:GetModule("Sync")
            if Sync and Sync.IsDeleted then
                local isDeleted = Sync:IsDeleted(testName, 0)
                if isDeleted then
                    GDL:Print("|cffFF0000" .. testName .. "|r ist auf der Blacklist!")
                else
                    GDL:Print("|cff00FF00" .. testName .. "|r ist NICHT auf der Blacklist.")
                end
            end
        else
            GDL:Print("Verwendung: /gdl bltest <name>")
        end
    elseif msg == "coords" or msg == "markers" then
        local MapMarkers = GDL:GetModule("MapMarkers")
        if MapMarkers then
            MapMarkers:PrintCoordDebug()
        else
            GDL:Print("|cffFF0000MapMarkers-Modul nicht geladen!|r")
        end
    elseif msg == "kills" or msg == "killstats" then
        local KillStats = GDL:GetModule("KillStats")
        if KillStats then
            KillStats:PrintStats()
        else
            GDL:Print("|cffFF0000KillStats-Modul nicht geladen!|r")
        end
    elseif msg == "killcheck" or msg == "recheckills" then
        local KillStats = GDL:GetModule("KillStats")
        if KillStats then
            KillStats:RecheckAllMilestones()
        else
            GDL:Print("|cffFF0000KillStats-Modul nicht geladen!|r")
        end
    elseif msg == "titles" or msg == "titel" then
        local UI = GDL:GetModule("UI")
        if UI then
            UI:ToggleTitles()
        end
    elseif msg == "nptitles" or msg == "nptitel" or msg == "nameplatetitles" then
        local Titles = GDL:GetModule("Titles")
        if Titles then
            Titles:ToggleNameplateTitles()
        end
    elseif msg == "mytitles" or msg == "meinetitel" then
        local Titles = GDL:GetModule("Titles")
        if Titles then
            Titles:PrintTitles()
        else
            GDL:Print("|cffFF0000Titles-Modul nicht geladen!|r")
        end
    elseif msg == "titlecheck" or msg == "titelcheck" then
        local Titles = GDL:GetModule("Titles")
        if Titles then
            local selected = Titles:GetSelectedTitle()
            local isFemale = Titles:IsPlayerFemale()
            GDL:Print("=== Titel-Debug ===")
            GDL:Print("Geschlecht: " .. (isFemale and "Weiblich" or "Maennlich"))
            if selected then
                local titleText = Titles:GetTitleText(selected, isFemale)
                GDL:Print("Aktiver Titel: |cff00FF00" .. titleText .. "|r")
                GDL:Print("Titel-ID: " .. selected.id)
            else
                GDL:Print("Aktiver Titel: |cffFF0000KEINER|r")
                GDL:Print("Du musst erst Meilensteine erreichen!")
                GDL:Print("Nutze /gdl ach um Meilensteine zu sehen")
            end
        end
    elseif msg == "push" then
        local Sync = GDL:GetModule("Sync")
        if Sync then
            Sync:BroadcastRecentDeaths(50)
            GDL:Print("|cff00AAFF[Sync]|r Pushe Tode an alle Gildenmitglieder...")
        end
    elseif msg == "track" or msg == "tracker" or msg == "map" then
        local GuildTracker = GDL:GetModule("GuildTracker")
        if GuildTracker then
            local enabled = GuildTracker:Toggle()
        else
            GDL:Print("|cffFF0000GuildTracker-Modul nicht geladen!|r")
        end
    elseif msg == "trackstatus" or msg == "mapstatus" or msg == "trackerstatus" then
        local GuildTracker = GDL:GetModule("GuildTracker")
        if GuildTracker then
            GuildTracker:PrintStatus()
        else
            GDL:Print("|cffFF0000GuildTracker-Modul nicht geladen!|r")
        end
    elseif msg == "who" or msg == "online" then
        local GuildTracker = GDL:GetModule("GuildTracker")
        if GuildTracker then
            local players = GuildTracker:GetOnlinePlayers()
            if #players == 0 then
                GDL:Print("|cffAAAAFFKeine Gildenmitglieder mit Addon auf der Karte.|r")
            else
                GDL:Print("|cff00AAFF" .. #players .. " Gildenmitglieder mit Addon:|r")
                for _, p in ipairs(players) do
                    local lvl = p.level and p.level > 0 and (" Lv" .. p.level) or ""
                    local status = p.lastSeen < 5 and "|cff00FF00LIVE|r" or ("|cffFFFF00" .. p.lastSeen .. "s|r")
                    GDL:Print("  - " .. p.name .. lvl .. " (" .. status .. ")")
                end
            end
        end
    elseif msg == "users" or msg == "nutzer" or msg == "count" then
        -- Zeigt Status inkl. Server-User-Count
        local GuildTracker = GDL:GetModule("GuildTracker")
        if GuildTracker then
            GuildTracker:PrintStatus()
        else
            GDL:Print("|cffFF0000GuildTracker-Modul nicht geladen!|r")
        end
    elseif msg == "prof" or msg == "professions" or msg == "berufe" then
        -- Öffne Buch auf Berufe-Kapitel
        if BookUI then BookUI:Show() BookUI:LoadChapter(6) end
    elseif msg == "profscan" or msg == "scanprof" or msg == "scanguild" then
        -- Manueller Scan aller Gildenmitglieder in der Nähe
        local Professions = GDL:GetModule("Professions")
        if Professions then
            Professions:ManualScan()
        else
            GDL:Print("|cffFF0000Professions-Modul nicht geladen!|r")
        end
    elseif msg == "memorial" or msg == "gedenken" or msg == "rip" then
        local Memorial = GDL:GetModule("Memorial")
        if Memorial then
            Memorial:ShowMemorialWindow()
        else
            GDL:Print("|cffFF0000Memorial-Modul nicht geladen!|r")
        end
    elseif msg == "rules" or msg == "regeln" or msg == "gildenregeln" then
        -- Öffne Buch auf Regeln-Kapitel
        if BookUI then BookUI:Show() BookUI:LoadChapter(7) end
    elseif msg == "rulessync" or msg == "regelsync" then
        local GuildRules = GDL:GetModule("GuildRules")
        if GuildRules then
            GuildRules:RequestRules()
            GDL:Print("|cffFFD100Gildenregeln werden angefordert...|r")
        end
    elseif msg == "titlesync" or msg == "titelsync" then
        local Titles = GDL:GetModule("Titles")
        if Titles then
            Titles:RequestAllTitles()
            GDL:Print("|cffFFD100Titel werden angefordert...|r")
        end
    elseif msg == "guildstats" or msg == "gstats" or msg == "gildenstat" then
        local GuildStats = GDL:GetModule("GuildStats")
        if GuildStats then
            GuildStats:ShowStatsWindow()
        else
            GDL:Print("|cffFF0000GuildStats-Modul nicht geladen!|r")
        end
    elseif msg:match("^find%s+") or msg:match("^suche%s+") then
        local searchTerm = msg:match("^%S+%s+(.+)$")
        if searchTerm then
            local Professions = GDL:GetModule("Professions")
            if Professions then
                local results = Professions:FindByProfession(searchTerm)
                if #results == 0 then
                    GDL:Print("|cffFFAAAAKein Gildenmitglied mit '" .. searchTerm .. "' gefunden.|r")
                else
                    GDL:Print("|cff00AAFF" .. #results .. " Spieler mit '" .. searchTerm .. "':|r")
                    for _, r in ipairs(results) do
                        local p1 = r.data.prof1 and r.data.prof1.name or ""
                        local s1 = r.data.prof1 and r.data.prof1.skill or 0
                        local p2 = r.data.prof2 and r.data.prof2.name or ""
                        local s2 = r.data.prof2 and r.data.prof2.skill or 0
                        GDL:Print(string.format("  %s: %s (%d), %s (%d)", r.name, p1, s1, p2, s2))
                    end
                end
            end
        else
            GDL:Print("Verwendung: /gdl find <beruf>")
        end
    elseif msg == "msgtest" or msg == "condtest" then
        -- Test: Zeige 10 zufällige Todesnachrichten
        local Condolences = GDL:GetModule("Condolences")
        if Condolences then
            Condolences:TestMessages(10)
        else
            GDL:Print("|cffFF0000Condolences-Modul nicht geladen!|r")
        end
    elseif msg == "msgstats" or msg == "condstats" then
        -- Zeige Statistiken des Nachrichten-Systems
        local Condolences = GDL:GetModule("Condolences")
        if Condolences then
            Condolences:PrintStats()
        else
            GDL:Print("|cffFF0000Condolences-Modul nicht geladen!|r")
        end
    else
        GDL:Print("Unbekannter Befehl. /gdl help für Hilfe")
    end
end
