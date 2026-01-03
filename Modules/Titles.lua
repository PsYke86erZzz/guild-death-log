-- ==============================================================
-- MODUL: Titles - Custom Titel für Hardcore-Meilensteine
-- Sichtbar für alle Gildenmitglieder die das Addon haben!
-- ==============================================================

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Titles = {}

-- Addon-Kommunikation
local TITLE_PREFIX = "GDLTitle"
local BROADCAST_INTERVAL = 120  -- Alle 2 Minuten eigenen Titel senden
local SYNC_DELAY = 5  -- Sekunden nach Login bevor Sync startet

-- Speichert Titel aller Spieler
-- Format: {playerName = {title = "...", titleId = "...", timestamp = ...}}
local guildTitles = {}

-- Prefix registrieren
C_ChatInfo.RegisterAddonMessagePrefix(TITLE_PREFIX)

-- ==============================================================
-- TITEL-DEFINITIONEN
-- Verknüpft mit Meilensteinen
-- ==============================================================

local TITLE_DEFS = {
    -- ===========================================================
    -- LEVEL-TITEL
    -- ===========================================================
    {
        id = "immortal",
        name = "der Unsterbliche",
        nameFemale = "die Unsterbliche",
        desc = "Hat Level 60 im Hardcore-Modus erreicht",
        icon = "Interface\\Icons\\INV_Crown_01",
        color = {1, 0.84, 0},  -- Gold
        requirement = "level_60",
        priority = 100,  -- Höher = prestigeträchtiger
    },
    {
        id = "veteran",
        name = "der Veteran",
        nameFemale = "die Veteranin",
        desc = "Hat Level 50 erreicht",
        icon = "Interface\\Icons\\INV_Shield_07",
        color = {0.7, 0.7, 0.9},
        requirement = "level_50",
        priority = 50,
    },
    {
        id = "survivor",
        name = "der Überlebende",
        nameFemale = "die Überlebende",
        desc = "Hat Level 40 erreicht",
        icon = "Interface\\Icons\\Ability_Mount_RidingHorse",
        color = {0.5, 0.8, 0.5},
        requirement = "level_40",
        priority = 40,
    },
    
    -- ===========================================================
    -- RAID-TITEL (Höchstes Prestige)
    -- ===========================================================
    {
        id = "champion_naxx",
        name = "Champion von Naxxramas",
        nameFemale = "Champion von Naxxramas",
        desc = "Hat Kel'Thuzad in Naxxramas besiegt",
        icon = "Interface\\Icons\\INV_Trinket_Naxxramas06",
        color = {0.6, 0.2, 0.8},  -- Lila
        requirement = "boss_naxx_kt",
        priority = 200,
    },
    {
        id = "slayer_cthun",
        name = "Bezwinger von C'Thun",
        nameFemale = "Bezwingerin von C'Thun",
        desc = "Hat C'Thun in AQ40 besiegt",
        icon = "Interface\\Icons\\Spell_Nature_WispHeal",
        color = {0.8, 0.6, 0.2},
        requirement = "boss_aq40_cthun",
        priority = 180,
    },
    {
        id = "dragonslayer",
        name = "Drachentöter",
        nameFemale = "Drachentöterin",
        desc = "Hat Nefarian in BWL besiegt",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01",
        color = {0.9, 0.3, 0.1},
        requirement = "boss_bwl_nef",
        priority = 160,
    },
    {
        id = "firelord_slayer",
        name = "Bezwinger des Feuerlords",
        nameFemale = "Bezwingerin des Feuerlords",
        desc = "Hat Ragnaros in MC besiegt",
        icon = "Interface\\Icons\\Spell_Fire_Ragnaros_Lavabolt",
        color = {1, 0.4, 0.1},
        requirement = "boss_mc_rag",
        priority = 140,
    },
    {
        id = "onyxia_slayer",
        name = "Onyxiabezwinger",
        nameFemale = "Onyxiabezwingerin",
        desc = "Hat Onyxia besiegt",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
        color = {0.2, 0.2, 0.2},
        requirement = "boss_ony",
        priority = 120,
    },
    
    -- ===========================================================
    -- KILL-TITEL - Leichte Stufen (erreichbar ab Level 1-20)
    -- ===========================================================
    {
        id = "hunter_humanoid",
        name = "Wegelagerer",
        nameFemale = "Wegelagerin",
        desc = "Hat 25 Humanoide getötet",
        icon = "Interface\\Icons\\Ability_Rogue_Ambush",
        color = {0.6, 0.5, 0.4},
        requirement = "kill_humanoid_25",
        priority = 10,
    },
    {
        id = "hunter_beast",
        name = "Jaeger",
        nameFemale = "Jaegerin",
        desc = "Hat 25 Wildtiere getötet",
        icon = "Interface\\Icons\\Ability_Hunter_SniperShot",
        color = {0.5, 0.6, 0.3},
        requirement = "kill_beast_25",
        priority = 10,
    },
    {
        id = "hunter_undead",
        name = "Grabschaender",
        nameFemale = "Grabschaenderin",
        desc = "Hat 25 Untote getötet",
        icon = "Interface\\Icons\\Spell_Shadow_DeathCoil",
        color = {0.4, 0.5, 0.4},
        requirement = "kill_undead_25",
        priority = 12,
    },
    {
        id = "hunter_demon",
        name = "Daemonentoeter",
        nameFemale = "Daemonentoterin",
        desc = "Hat 25 Dämonen getötet",
        icon = "Interface\\Icons\\Spell_Shadow_SummonImp",
        color = {0.5, 0.3, 0.5},
        requirement = "kill_demon_25",
        priority = 12,
    },
    {
        id = "hunter_elemental",
        name = "Elementarjaeger",
        nameFemale = "Elementarjaegerin",
        desc = "Hat 25 Elementare getötet",
        icon = "Interface\\Icons\\Spell_Fire_Fire",
        color = {0.7, 0.4, 0.2},
        requirement = "kill_elemental_25",
        priority = 12,
    },
    {
        id = "hunter_dragonkin",
        name = "Welpentoeter",
        nameFemale = "Welpentoterin",
        desc = "Hat 10 Drachkin getötet",
        icon = "Interface\\Icons\\INV_Misc_MonsterScales_02",
        color = {0.6, 0.4, 0.3},
        requirement = "kill_dragonkin_10",
        priority = 15,
    },
    {
        id = "hunter_giant",
        name = "Riesentoeter",
        nameFemale = "Riesentoterin",
        desc = "Hat 10 Riesen getötet",
        icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01",
        color = {0.5, 0.5, 0.5},
        requirement = "kill_giant_10",
        priority = 15,
    },
    
    -- ===========================================================
    -- KILL-TITEL - Mittlere Stufen (100er)
    -- ===========================================================
    {
        id = "slayer_humanoid",
        name = "Banditenjaeger",
        nameFemale = "Banditenjaegerin",
        desc = "Hat 100 Humanoide getötet",
        icon = "Interface\\Icons\\Ability_Rogue_Disguise",
        color = {0.7, 0.5, 0.3},
        requirement = "kill_humanoid_100",
        priority = 25,
    },
    {
        id = "slayer_beast",
        name = "Wildnisjaeger",
        nameFemale = "Wildnisjaegerin",
        desc = "Hat 100 Wildtiere getötet",
        icon = "Interface\\Icons\\Ability_Hunter_BeastCall",
        color = {0.6, 0.7, 0.3},
        requirement = "kill_beast_100",
        priority = 25,
    },
    {
        id = "slayer_undead",
        name = "Untotenjaeger",
        nameFemale = "Untotenjaegerin",
        desc = "Hat 100 Untote getötet",
        icon = "Interface\\Icons\\Spell_Shadow_AnimateDead",
        color = {0.5, 0.6, 0.5},
        requirement = "kill_undead_100",
        priority = 30,
    },
    {
        id = "slayer_demon",
        name = "Daemonenbekaempfer",
        nameFemale = "Daemonenbekaempferin",
        desc = "Hat 100 Dämonen getötet",
        icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
        color = {0.6, 0.3, 0.6},
        requirement = "kill_demon_100",
        priority = 30,
    },
    {
        id = "slayer_elemental",
        name = "Funkensammler",
        nameFemale = "Funkensammlerin",
        desc = "Hat 100 Elementare getötet",
        icon = "Interface\\Icons\\Spell_Fire_FireBolt",
        color = {0.8, 0.5, 0.2},
        requirement = "kill_elemental_100",
        priority = 30,
    },
    
    -- ===========================================================
    -- KILL-TITEL - Hohe Stufen
    -- ===========================================================
    {
        id = "plague_cleanser",
        name = "Seuchenreiniger",
        nameFemale = "Seuchenreinigerin",
        desc = "Hat 5.000 Untote getötet",
        icon = "Interface\\Icons\\Spell_Holy_SenseUndead",
        color = {0.4, 0.8, 0.4},
        requirement = "kill_undead_5000",
        priority = 90,
    },
    {
        id = "lichbane",
        name = "Lichbane",
        nameFemale = "Lichbane",
        desc = "Hat 1.000 Untote getötet",
        icon = "Interface\\Icons\\Spell_Shadow_RaiseDead",
        color = {0.5, 0.7, 0.5},
        requirement = "kill_undead_1000",
        priority = 70,
    },
    {
        id = "dragonbane",
        name = "Drachenbane",
        nameFemale = "Drachenbane",
        desc = "Hat 1.000 Drachkin getötet",
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black",
        color = {0.8, 0.5, 0.2},
        requirement = "kill_dragonkin_1000",
        priority = 85,
    },
    {
        id = "eredarbane",
        name = "Eredarbane",
        nameFemale = "Eredarbane",
        desc = "Hat 1.000 Dämonen getötet",
        icon = "Interface\\Icons\\Spell_Shadow_DemonicTactics",
        color = {0.6, 0.2, 0.6},
        requirement = "kill_demon_1000",
        priority = 80,
    },
    {
        id = "beastmaster",
        name = "Bestienmeister",
        nameFemale = "Bestienmeisterin",
        desc = "Hat 2.000 Wildtiere getötet",
        icon = "Interface\\Icons\\Ability_Hunter_BeastMastery",
        color = {0.6, 0.4, 0.2},
        requirement = "kill_beast_2000",
        priority = 60,
    },
    {
        id = "titanslayer",
        name = "Titanentoeter",
        nameFemale = "Titanentoterin",
        desc = "Hat 250 Riesen getötet",
        icon = "Interface\\Icons\\INV_Stone_15",
        color = {0.5, 0.5, 0.6},
        requirement = "kill_giant_250",
        priority = 65,
    },
    
    -- ===========================================================
    -- BERUFE-TITEL
    -- ===========================================================
    {
        id = "grandmaster",
        name = "Großmeister",
        nameFemale = "Großmeisterin",
        desc = "Hat einen Beruf auf 300 gemeistert",
        icon = "Interface\\Icons\\Trade_Engineering",
        color = {0.8, 0.6, 0.2},
        requirement = "prof_300",
        priority = 55,
    },
    {
        id = "master_angler",
        name = "Meisterangler",
        nameFemale = "Meisteranglerin",
        desc = "Hat Angeln auf 300",
        icon = "Interface\\Icons\\Trade_Fishing",
        color = {0.3, 0.5, 0.8},
        requirement = "fish_300",
        priority = 45,
    },
    
    -- ===========================================================
    -- DUNGEON-TITEL
    -- ===========================================================
    {
        id = "baron_slayer",
        name = "Baronbezwinger",
        nameFemale = "Baronbezwingerin",
        desc = "Hat Baron Rivendare besiegt",
        icon = "Interface\\Icons\\INV_Sword_25",
        color = {0.4, 0.4, 0.5},
        requirement = "boss_strat_ud",
        priority = 75,
    },
    {
        id = "dark_master",
        name = "Dunkelmeister-Bezwinger",
        nameFemale = "Dunkelmeister-Bezwingerin",
        desc = "Hat Dunkelmeister Gandling besiegt",
        icon = "Interface\\Icons\\Spell_Shadow_Haunting",
        color = {0.3, 0.3, 0.4},
        requirement = "boss_scholo",
        priority = 72,
    },
    
    -- ===========================================================
    -- BASIS-TITEL (Jeder hat mindestens einen)
    -- ===========================================================
    {
        id = "adventurer",
        name = "der Abenteurer",
        nameFemale = "die Abenteurerin",
        desc = "Hat die Reise begonnen",
        icon = "Interface\\Icons\\INV_Misc_Map_01",
        color = {0.7, 0.7, 0.7},
        requirement = nil,  -- Immer verfügbar
        priority = 1,
    },
}

-- Lookup-Tabelle für schnellen Zugriff
local TITLE_BY_ID = {}
local TITLE_BY_REQUIREMENT = {}
for _, t in ipairs(TITLE_DEFS) do
    TITLE_BY_ID[t.id] = t
    if t.requirement then
        TITLE_BY_REQUIREMENT[t.requirement] = t
    end
end

-- ==============================================================
-- INITIALISIERUNG
-- ==============================================================

function Titles:Initialize()
    -- SavedVariables
    if not GuildDeathLogDB then GuildDeathLogDB = {} end
    if not GuildDeathLogDB.titles then
        GuildDeathLogDB.titles = {}
    end
    if not GuildDeathLogDB.selectedTitle then
        GuildDeathLogDB.selectedTitle = "adventurer"
    end
    
    self:RegisterEvents()
    self:SetupTooltipHook()
    self:SetupNameplateHook()
    
    -- Verzögerter Start für Sync
    C_Timer.After(SYNC_DELAY, function()
        self:BroadcastTitle()
        self:RequestGuildTitles()
    end)
    
    -- Periodischer Broadcast
    C_Timer.NewTicker(BROADCAST_INTERVAL, function()
        self:BroadcastTitle()
    end)
    
    GDL:Debug("Titles: Modul initialisiert")
end

function Titles:RegisterEvents()
    local frame = CreateFrame("Frame")
    self.eventFrame = frame
    
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("GUILD_ROSTER_UPDATE")
    
    frame:SetScript("OnEvent", function(_, event, ...)
        if event == "CHAT_MSG_ADDON" then
            self:OnAddonMessage(...)
        elseif event == "GUILD_ROSTER_UPDATE" then
            -- Bei Gilden-Update erneut broadcasten
            C_Timer.After(2, function()
                self:BroadcastTitle()
            end)
        end
    end)
end

-- ==============================================================
-- TITEL-VERWALTUNG
-- ==============================================================

function Titles:GetCharacterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function Titles:GetUnlockedTitles()
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return {TITLE_BY_ID["adventurer"]} end
    
    local charKey = self:GetCharacterKey()
    local charMilestones = Milestones:GetCharacterMilestones(charKey)
    
    local unlocked = {}
    
    for _, title in ipairs(TITLE_DEFS) do
        if not title.requirement then
            -- Basis-Titel immer verfügbar
            table.insert(unlocked, title)
        elseif charMilestones and charMilestones[title.requirement] then
            -- Meilenstein erreicht
            table.insert(unlocked, title)
        end
    end
    
    -- Nach Priorität sortieren
    table.sort(unlocked, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
    
    return unlocked
end

function Titles:GetSelectedTitle()
    local titleId = GuildDeathLogDB.selectedTitle or "adventurer"
    return TITLE_BY_ID[titleId]
end

function Titles:SetSelectedTitle(titleId)
    if not TITLE_BY_ID[titleId] then return false end
    
    -- Prüfen ob freigeschaltet
    local unlocked = self:GetUnlockedTitles()
    local found = false
    for _, t in ipairs(unlocked) do
        if t.id == titleId then
            found = true
            break
        end
    end
    
    if not found then
        GDL:Print("|cffFF0000Dieser Titel ist noch nicht freigeschaltet!|r")
        return false
    end
    
    GuildDeathLogDB.selectedTitle = titleId
    self:BroadcastTitle()
    
    local title = TITLE_BY_ID[titleId]
    GDL:Print("|cff00FF00Titel gewählt:|r " .. self:FormatTitle(title))
    
    return true
end

function Titles:FormatTitle(title, playerName)
    if not title then return "" end
    
    local name = title.name
    local color = title.color or {1, 1, 1}
    local hexColor = string.format("|cff%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
    
    if playerName then
        return hexColor .. "<" .. name .. "> " .. playerName .. "|r"
    else
        return hexColor .. "<" .. name .. ">|r"
    end
end

function Titles:GetFormattedPlayerTitle(playerName)
    local data = guildTitles[playerName]
    if not data or not data.titleId then return nil end
    
    local title = TITLE_BY_ID[data.titleId]
    if not title then return nil end
    
    return self:FormatTitle(title)
end

-- ==============================================================
-- ADDON-KOMMUNIKATION
-- ==============================================================

function Titles:BroadcastTitle()
    if not IsInGuild() then return end
    
    local title = self:GetSelectedTitle()
    if not title then return end
    
    local playerName = UnitName("player")
    local message = playerName .. "|" .. title.id
    
    C_ChatInfo.SendAddonMessage(TITLE_PREFIX, message, "GUILD")
    GDL:Debug("Titles: Broadcast -> " .. title.id)
end

function Titles:RequestGuildTitles()
    if not IsInGuild() then return end
    
    C_ChatInfo.SendAddonMessage(TITLE_PREFIX, "REQUEST", "GUILD")
    GDL:Debug("Titles: Request gesendet")
end

function Titles:OnAddonMessage(prefix, message, channel, sender)
    if prefix ~= TITLE_PREFIX then return end
    
    -- Eigene Nachrichten ignorieren
    local playerName = UnitName("player")
    local senderName = Ambiguate(sender, "short")
    if senderName == playerName then return end
    
    if message == "REQUEST" then
        -- Jemand fragt nach Titeln
        C_Timer.After(math.random() * 2, function()
            self:BroadcastTitle()
        end)
        return
    end
    
    -- Titel-Update: "PlayerName|titleId"
    local name, titleId = strsplit("|", message)
    if name and titleId then
        guildTitles[name] = {
            titleId = titleId,
            timestamp = time()
        }
        GDL:Debug("Titles: Empfangen " .. name .. " -> " .. titleId)
    end
end

-- =============================================================
-- TOOLTIP-INTEGRATION
-- =============================================================

function Titles:SetupTooltipHook()
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        -- Prüfen ob wir bereits einen Titel hinzugefügt haben
        if tooltip.gdlTitleAdded then return end
        
        local name, unit = tooltip:GetUnit()
        if not unit or not UnitIsPlayer(unit) then return end
        
        local playerName = UnitName(unit)
        local titleStr = nil
        
        -- Eigener Charakter?
        if UnitIsUnit(unit, "player") then
            local title = self:GetSelectedTitle()
            if title then
                titleStr = self:FormatTitle(title)
            end
        else
            -- Anderer Spieler - nur Gildenmitglieder
            local guildName = GetGuildInfo(unit)
            local myGuild = GetGuildInfo("player")
            if guildName and guildName == myGuild then
                titleStr = self:GetFormattedPlayerTitle(playerName)
            end
        end
        
        if titleStr then
            tooltip:AddLine(titleStr, 1, 1, 1)
            tooltip.gdlTitleAdded = true
            tooltip:Show()
        end
    end)
    
    -- Reset Flag wenn Tooltip versteckt wird
    GameTooltip:HookScript("OnHide", function(tooltip)
        tooltip.gdlTitleAdded = nil
    end)
end

-- =============================================================
-- NAMEPLATE-INTEGRATION
-- =============================================================

function Titles:SetupNameplateHook()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    
    frame:SetScript("OnEvent", function(_, event, unitToken)
        if event == "NAME_PLATE_UNIT_ADDED" then
            self:UpdateNameplate(unitToken)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            self:CleanupNameplate(unitToken)
        end
    end)
    
    -- Auch bei existierenden Nameplates
    C_Timer.After(1, function()
        for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
            local unitToken = plate.namePlateUnitToken
            if unitToken then
                self:UpdateNameplate(unitToken)
            end
        end
    end)
end

function Titles:UpdateNameplate(unitToken)
    if not UnitIsPlayer(unitToken) then return end
    
    local playerName = UnitName(unitToken)
    local title = nil
    
    -- Eigener Charakter?
    if UnitIsUnit(unitToken, "player") then
        title = self:GetSelectedTitle()
    else
        -- Anderer Spieler - nur Gildenmitglieder
        local guildName = GetGuildInfo(unitToken)
        local myGuild = GetGuildInfo("player")
        if not guildName or guildName ~= myGuild then return end
        
        local data = guildTitles[playerName]
        if not data or not data.titleId then return end
        
        title = TITLE_BY_ID[data.titleId]
    end
    
    if not title then return end
    
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if not nameplate then return end
    
    -- Titel-Text erstellen oder updaten
    if not nameplate.gdlTitle then
        local titleText = nameplate:CreateFontString(nil, "OVERLAY")
        titleText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        titleText:SetPoint("BOTTOM", nameplate, "TOP", 0, 2)
        nameplate.gdlTitle = titleText
    end
    
    local color = title.color or {1, 1, 1}
    nameplate.gdlTitle:SetTextColor(color[1], color[2], color[3])
    nameplate.gdlTitle:SetText("<" .. title.name .. ">")
    nameplate.gdlTitle:Show()
end

function Titles:CleanupNameplate(unitToken)
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if nameplate and nameplate.gdlTitle then
        nameplate.gdlTitle:Hide()
    end
end

-- ==============================================================
-- TITEL DURCH MEILENSTEIN FREISCHALTEN
-- ==============================================================

function Titles:OnMilestoneUnlocked(milestoneId)
    local title = TITLE_BY_REQUIREMENT[milestoneId]
    if not title then return end
    
    -- Benachrichtigung
    GDL:Print("=======================================")
    GDL:Print("|cffFFD100*** NEUER TITEL FREIGESCHALTET! ***|r")
    GDL:Print(self:FormatTitle(title))
    GDL:Print("|cffAAAAAA" .. title.desc .. "|r")
    GDL:Print("|cff888888Verwende /gdl titles zum Auswählen|r")
    GDL:Print("=======================================")
    
    -- Sound abspielen
    PlaySound(8959)  -- Level-Up Sound
end

-- ==============================================================
-- STATISTIKEN
-- ==============================================================

function Titles:GetStats()
    local unlocked = self:GetUnlockedTitles()
    local total = #TITLE_DEFS
    return #unlocked, total
end

function Titles:PrintTitles()
    local unlocked = self:GetUnlockedTitles()
    local unlockedCount, total = self:GetStats()
    local selected = self:GetSelectedTitle()
    
    GDL:Print("=== Deine Titel (" .. unlockedCount .. "/" .. total .. ") ===")
    
    for _, title in ipairs(unlocked) do
        local marker = ""
        if selected and selected.id == title.id then
            marker = " |cff00FF00◄ AKTIV|r"
        end
        GDL:Print("  " .. self:FormatTitle(title) .. marker)
    end
    
    GDL:Print("|cff888888Verwende /gdl titles für das Titel-Fenster|r")
end

-- ==============================================================
-- MODULE INITIALIZATION
-- ==============================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(4, function()
            Titles:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Titles", Titles)
