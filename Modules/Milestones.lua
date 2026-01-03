-- ==============================================================
-- MODUL: Milestones - Charakter-Meilensteine für Hardcore
-- Ersetzt das alte Achievement-System
-- 100% Character-basiert, synchronisiert mit Gilde
-- ==============================================================

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Milestones = {}

-- Addon-Kommunikation für Sync
local MILESTONE_PREFIX = "GDLMile"
local COMM_DELIM = "|"

-- ==============================================================
-- MEILENSTEIN-DEFINITIONEN
-- Nur echte, bedeutungsvolle Meilensteine!
-- ==============================================================

local MILESTONE_DEFS = {
    -- ===========================================================
    -- LEVEL-MEILENSTEINE (Die wichtigsten im Hardcore!)
    -- ===========================================================
    {id = "level_10", name = "Level 10", desc = "Hat Level 10 erreicht", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", type = "level", threshold = 10, category = "level"},
    {id = "level_20", name = "Level 20", desc = "Hat Level 20 erreicht", icon = "Interface\\Icons\\Spell_Holy_GreaterHeal", type = "level", threshold = 20, category = "level"},
    {id = "level_30", name = "Level 30", desc = "Hat Level 30 erreicht", icon = "Interface\\Icons\\INV_Shield_06", type = "level", threshold = 30, category = "level"},
    {id = "level_40", name = "Level 40", desc = "Hat Level 40 erreicht (erstes Mount!)", icon = "Interface\\Icons\\Ability_Mount_RidingHorse", type = "level", threshold = 40, category = "level"},
    {id = "level_50", name = "Level 50", desc = "Hat Level 50 erreicht", icon = "Interface\\Icons\\INV_Shield_07", type = "level", threshold = 50, category = "level"},
    {id = "level_60", name = "Level 60 - UNSTERBLICH!", desc = "Hat Level 60 erreicht!", icon = "Interface\\Icons\\INV_Crown_01", type = "level", threshold = 60, category = "level"},
    
    -- ===========================================================
    -- DUNGEON-BOSSE (Endboss jedes Dungeons)
    -- ===========================================================
    -- Lowlevel Dungeons (10-25)
    {id = "boss_rfc", name = "Ragefire Chasm", desc = "Taragaman der Hungrige besiegt", icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard", type = "boss", bossId = 11520, category = "dungeon"},
    {id = "boss_wc", name = "Wailing Caverns", desc = "Mutanus der Verschlinger besiegt", icon = "Interface\\Icons\\INV_Misc_MonsterHead_01", type = "boss", bossId = 3654, category = "dungeon"},
    {id = "boss_dm", name = "Deadmines", desc = "Edwin VanCleef besiegt", icon = "Interface\\Icons\\INV_Helmet_25", type = "boss", bossId = 639, category = "dungeon"},
    {id = "boss_sfk", name = "Shadowfang Keep", desc = "Erzmagier Arugal besiegt", icon = "Interface\\Icons\\Spell_Shadow_Charm", type = "boss", bossId = 4275, category = "dungeon"},
    {id = "boss_bfd", name = "Blackfathom Deeps", desc = "Aku'mai besiegt", icon = "Interface\\Icons\\Spell_Shadow_DeathScream", type = "boss", bossId = 4829, category = "dungeon"},
    {id = "boss_stocks", name = "The Stockade", desc = "Bazil Thredd besiegt", icon = "Interface\\Icons\\INV_Misc_Key_13", type = "boss", bossId = 1716, category = "dungeon"},
    
    -- Midlevel Dungeons (25-45)
    {id = "boss_gnomer", name = "Gnomeregan", desc = "Mekgineer Thermaplugg besiegt", icon = "Interface\\Icons\\INV_Gizmo_02", type = "boss", bossId = 7800, category = "dungeon"},
    {id = "boss_sm_lib", name = "SM: Bibliothek", desc = "Arkanist Doan besiegt", icon = "Interface\\Icons\\INV_Misc_Book_07", type = "boss", bossId = 6487, category = "dungeon"},
    {id = "boss_sm_arm", name = "SM: Waffenkammer", desc = "Herod besiegt", icon = "Interface\\Icons\\INV_Axe_12", type = "boss", bossId = 3975, category = "dungeon"},
    {id = "boss_sm_cath", name = "SM: Kathedrale", desc = "Hochinquisitor Mograine besiegt", icon = "Interface\\Icons\\INV_Sword_27", type = "boss", bossId = 3976, category = "dungeon"},
    {id = "boss_sm_gy", name = "SM: Friedhof", desc = "Blutmagier Thalnos besiegt", icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", type = "boss", bossId = 4543, category = "dungeon"},
    {id = "boss_rfk", name = "Razorfen Kraul", desc = "Charlga Razorflank besiegt", icon = "Interface\\Icons\\INV_Misc_Head_Gnoll_01", type = "boss", bossId = 4421, category = "dungeon"},
    {id = "boss_rfd", name = "Razorfen Downs", desc = "Amnennar der Kältebringer besiegt", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", type = "boss", bossId = 7358, category = "dungeon"},
    {id = "boss_ulda", name = "Uldaman", desc = "Archaedas besiegt", icon = "Interface\\Icons\\INV_Misc_Gem_Stone_01", type = "boss", bossId = 2748, category = "dungeon"},
    {id = "boss_zf", name = "Zul'Farrak", desc = "Chief Ukorz Sandscalp besiegt", icon = "Interface\\Icons\\INV_Helmet_53", type = "boss", bossId = 7267, category = "dungeon"},
    {id = "boss_mara", name = "Maraudon", desc = "Prinzessin Theradras besiegt", icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem", type = "boss", bossId = 12201, category = "dungeon"},
    
    -- Highlevel Dungeons (45-60)
    {id = "boss_st", name = "Sunken Temple", desc = "Eranikus' Schatten besiegt", icon = "Interface\\Icons\\Spell_Shadow_GatherShadows", type = "boss", bossId = 5709, category = "dungeon"},
    {id = "boss_brd_emp", name = "BRD: Imperator", desc = "Imperator Dagran Thaurissan besiegt", icon = "Interface\\Icons\\INV_Hammer_Unique_Sulfuron", type = "boss", bossId = 9019, category = "dungeon"},
    {id = "boss_dm_north", name = "DM: Nord", desc = "König Gordok besiegt", icon = "Interface\\Icons\\INV_Misc_MonsterHead_02", type = "boss", bossId = 11501, category = "dungeon"},
    {id = "boss_dm_east", name = "DM: Ost", desc = "Alzzin der Wildformer besiegt", icon = "Interface\\Icons\\Spell_Nature_Regeneration", type = "boss", bossId = 11492, category = "dungeon"},
    {id = "boss_dm_west", name = "DM: West", desc = "Prinz Tortheldrin besiegt", icon = "Interface\\Icons\\INV_Sword_26", type = "boss", bossId = 11486, category = "dungeon"},
    {id = "boss_lbrs", name = "LBRS", desc = "Kriegsherr Voone besiegt", icon = "Interface\\Icons\\INV_Misc_MonsterHead_03", type = "boss", bossId = 9237, category = "dungeon"},
    {id = "boss_ubrs", name = "UBRS", desc = "General Drakkisath besiegt", icon = "Interface\\Icons\\Spell_Fire_Lavaspawn", type = "boss", bossId = 10363, category = "dungeon"},
    {id = "boss_scholo", name = "Scholomance", desc = "Dunkelmeister Gandling besiegt", icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "boss", bossId = 1853, category = "dungeon"},
    {id = "boss_strat_ud", name = "Strat: Untot", desc = "Baron Rivendare besiegt", icon = "Interface\\Icons\\INV_Sword_25", type = "boss", bossId = 10440, category = "dungeon"},
    {id = "boss_strat_live", name = "Strat: Lebend", desc = "Balnazzar besiegt", icon = "Interface\\Icons\\Spell_Shadow_PainSpike", type = "boss", bossId = 10813, category = "dungeon"},
    
    -- ===========================================================
    -- RAID-BOSSE
    -- ===========================================================
    {id = "boss_ony", name = "Onyxia", desc = "Onyxia besiegt!", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", type = "boss", bossId = 10184, category = "raid"},
    {id = "boss_mc_rag", name = "Molten Core: Ragnaros", desc = "Ragnaros besiegt!", icon = "Interface\\Icons\\Spell_Fire_Ragnaros_Lavabolt", type = "boss", bossId = 11502, category = "raid"},
    {id = "boss_bwl_nef", name = "BWL: Nefarian", desc = "Nefarian besiegt!", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "boss", bossId = 11583, category = "raid"},
    {id = "boss_zg_hakkar", name = "Zul'Gurub: Hakkar", desc = "Hakkar besiegt!", icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "boss", bossId = 14834, category = "raid"},
    {id = "boss_aq20_ossirian", name = "AQ20: Ossirian", desc = "Ossirian besiegt!", icon = "Interface\\Icons\\INV_Jewelry_Ring_40", type = "boss", bossId = 15339, category = "raid"},
    {id = "boss_aq40_cthun", name = "AQ40: C'Thun", desc = "C'Thun besiegt!", icon = "Interface\\Icons\\Spell_Nature_WispHeal", type = "boss", bossId = 15727, category = "raid"},
    {id = "boss_naxx_kt", name = "Naxxramas: Kel'Thuzad", desc = "Kel'Thuzad besiegt!", icon = "Interface\\Icons\\INV_Trinket_Naxxramas06", type = "boss", bossId = 15990, category = "raid"},
    
    -- ===========================================================
    -- BERUFE-MEILENSTEINE
    -- ===========================================================
    {id = "prof_150", name = "Geselle", desc = "Einen Beruf auf 150 gebracht", icon = "Interface\\Icons\\Trade_BlackSmithing", type = "profession", threshold = 150, category = "profession"},
    {id = "prof_225", name = "Experte", desc = "Einen Beruf auf 225 gebracht", icon = "Interface\\Icons\\Trade_LeatherWorking", type = "profession", threshold = 225, category = "profession"},
    {id = "prof_300", name = "Meister", desc = "Einen Beruf auf 300 gebracht!", icon = "Interface\\Icons\\Trade_Engineering", type = "profession", threshold = 300, category = "profession"},
    
    -- Sekundäre Berufe
    {id = "fish_300", name = "Meisterangler", desc = "Angeln auf 300", icon = "Interface\\Icons\\Trade_Fishing", type = "fishing", threshold = 300, category = "profession"},
    {id = "cook_300", name = "Meisterkoch", desc = "Kochen auf 300", icon = "Interface\\Icons\\INV_Misc_Food_15", type = "cooking", threshold = 300, category = "profession"},
    {id = "firstaid_300", name = "Meister-Ersthelfer", desc = "Erste Hilfe auf 300", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", type = "firstaid", threshold = 300, category = "profession"},
    
    -- ===========================================================
    -- KILL-MEILENSTEINE - Kreaturtypen
    -- ===========================================================
    -- Humanoide (überall - sehr häufig, daher frühe Meilensteine)
    {id = "kill_humanoid_25", name = "Wegelagerer", desc = "25 Humanoide getötet", icon = "Interface\\Icons\\Ability_Rogue_Ambush", type = "kills", creatureType = "humanoid", threshold = 25, category = "kills"},
    {id = "kill_humanoid_100", name = "Banditenjaeger", desc = "100 Humanoide getötet", icon = "Interface\\Icons\\Ability_Rogue_Disguise", type = "kills", creatureType = "humanoid", threshold = 100, category = "kills"},
    {id = "kill_humanoid_500", name = "Kopfgeldjaeger", desc = "500 Humanoide getötet", icon = "Interface\\Icons\\INV_Misc_Coin_02", type = "kills", creatureType = "humanoid", threshold = 500, category = "kills"},
    {id = "kill_humanoid_2000", name = "Schlaechter", desc = "2.000 Humanoide getötet!", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", type = "kills", creatureType = "humanoid", threshold = 2000, category = "kills"},
    
    -- Wildtiere (überall - sehr häufig)
    {id = "kill_beast_25", name = "Jaeger", desc = "25 Wildtiere getötet", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", type = "kills", creatureType = "beast", threshold = 25, category = "kills"},
    {id = "kill_beast_100", name = "Wildnisjaeger", desc = "100 Wildtiere getötet", icon = "Interface\\Icons\\Ability_Hunter_BeastCall", type = "kills", creatureType = "beast", threshold = 100, category = "kills"},
    {id = "kill_beast_500", name = "Grosswildjaeger", desc = "500 Wildtiere getötet", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", type = "kills", creatureType = "beast", threshold = 500, category = "kills"},
    {id = "kill_beast_2000", name = "Bestienmeister", desc = "2.000 Wildtiere getötet!", icon = "Interface\\Icons\\Ability_Hunter_BeastMastery", type = "kills", creatureType = "beast", threshold = 2000, category = "kills"},
    
    -- Untote (Plaguelands, Scholo, Strat)
    {id = "kill_undead_25", name = "Grabschaender", desc = "25 Untote getötet", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", type = "kills", creatureType = "undead", threshold = 25, category = "kills"},
    {id = "kill_undead_100", name = "Untotenjaeger", desc = "100 Untote getötet", icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", type = "kills", creatureType = "undead", threshold = 100, category = "kills"},
    {id = "kill_undead_500", name = "Untotenschlaechter", desc = "500 Untote getötet", icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", type = "kills", creatureType = "undead", threshold = 500, category = "kills"},
    {id = "kill_undead_1000", name = "Lichbane", desc = "1.000 Untote getötet", icon = "Interface\\Icons\\Spell_Holy_SenseUndead", type = "kills", creatureType = "undead", threshold = 1000, category = "kills"},
    {id = "kill_undead_5000", name = "Seuchenreiniger", desc = "5.000 Untote getötet!", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing", type = "kills", creatureType = "undead", threshold = 5000, category = "kills"},
    
    -- Dämonen (Felwood, DM, Winterspring)
    {id = "kill_demon_25", name = "Daemonentoeter", desc = "25 Dämonen getötet", icon = "Interface\\Icons\\Spell_Shadow_SummonImp", type = "kills", creatureType = "demon", threshold = 25, category = "kills"},
    {id = "kill_demon_100", name = "Daemonenbekaempfer", desc = "100 Dämonen getötet", icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard", type = "kills", creatureType = "demon", threshold = 100, category = "kills"},
    {id = "kill_demon_500", name = "Daemonenschlaechter", desc = "500 Dämonen getötet", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", type = "kills", creatureType = "demon", threshold = 500, category = "kills"},
    {id = "kill_demon_1000", name = "Eredarbane", desc = "1.000 Dämonen getötet!", icon = "Interface\\Icons\\Spell_Shadow_DemonicTactics", type = "kills", creatureType = "demon", threshold = 1000, category = "kills"},
    
    -- Elementare (Silithus, BRD, MC)
    {id = "kill_elemental_25", name = "Elementarjaeger", desc = "25 Elementare getötet", icon = "Interface\\Icons\\Spell_Fire_Fire", type = "kills", creatureType = "elemental", threshold = 25, category = "kills"},
    {id = "kill_elemental_100", name = "Funkensammler", desc = "100 Elementare getötet", icon = "Interface\\Icons\\Spell_Fire_FireBolt", type = "kills", creatureType = "elemental", threshold = 100, category = "kills"},
    {id = "kill_elemental_500", name = "Elementarbrecher", desc = "500 Elementare getötet!", icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem", type = "kills", creatureType = "elemental", threshold = 500, category = "kills"},
    
    -- Drachkin (UBRS, BWL, Burning Steppes)
    {id = "kill_dragonkin_10", name = "Welpentoeter", desc = "10 Drachkin getötet", icon = "Interface\\Icons\\INV_Misc_MonsterScales_02", type = "kills", creatureType = "dragonkin", threshold = 10, category = "kills"},
    {id = "kill_dragonkin_50", name = "Schuppensammler", desc = "50 Drachkin getötet", icon = "Interface\\Icons\\INV_Misc_MonsterScales_05", type = "kills", creatureType = "dragonkin", threshold = 50, category = "kills"},
    {id = "kill_dragonkin_250", name = "Drachenjaeger", desc = "250 Drachkin getötet", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "kills", creatureType = "dragonkin", threshold = 250, category = "kills"},
    {id = "kill_dragonkin_1000", name = "Drachenbane", desc = "1.000 Drachkin getötet!", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", type = "kills", creatureType = "dragonkin", threshold = 1000, category = "kills"},
    
    -- Riesen (Azshara, Feralas)
    {id = "kill_giant_10", name = "Riesentoeter", desc = "10 Riesen getötet", icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", type = "kills", creatureType = "giant", threshold = 10, category = "kills"},
    {id = "kill_giant_50", name = "Riesen-Bezwinger", desc = "50 Riesen getötet", icon = "Interface\\Icons\\INV_Misc_Foot_Centaur", type = "kills", creatureType = "giant", threshold = 50, category = "kills"},
    {id = "kill_giant_250", name = "Titanentoeter", desc = "250 Riesen getötet!", icon = "Interface\\Icons\\INV_Stone_15", type = "kills", creatureType = "giant", threshold = 250, category = "kills"},
}

-- Boss-ID zu Milestone-ID Mapping für schnellen Lookup
local BOSS_TO_MILESTONE = {}
for _, m in ipairs(MILESTONE_DEFS) do
    if m.type == "boss" and m.bossId then
        BOSS_TO_MILESTONE[m.bossId] = m.id
    end
end

-- ==============================================================
-- INITIALISIERUNG
-- ==============================================================

function Milestones:Initialize()
    -- Verhindere doppelte Initialisierung
    if self.initialized then return end
    self.initialized = true
    
    -- Registriere Addon-Prefix für Sync
    C_ChatInfo.RegisterAddonMessagePrefix(MILESTONE_PREFIX)
    
    -- Datenstruktur initialisieren
    -- WICHTIG: Pro Charakter speichern, nicht Account-weit!
    GuildDeathLogDB.milestones = GuildDeathLogDB.milestones or {}
    GuildDeathLogDB.guildMilestones = GuildDeathLogDB.guildMilestones or {}
    
    -- Aktuellen Charakter initialisieren
    local charKey = self:GetCharacterKey()
    GuildDeathLogDB.milestones[charKey] = GuildDeathLogDB.milestones[charKey] or {
        unlocked = {},
        stats = {
            maxProfession = 0,
            fishingSkill = 0,
            cookingSkill = 0,
            firstaidSkill = 0,
        }
    }
    
    self:RegisterEvents()
    
    -- Stats regelmäßig aktualisieren
    C_Timer.NewTicker(60, function() self:TrackPlayerStats() end)
    
    -- Bei Initialize sofort Level prüfen (still, ohne Chat-Meldung)
    C_Timer.After(2, function() 
        self:CheckCurrentLevel() 
        self:TrackPlayerStats()
    end)
    
    GDL:Debug("Milestones: Initialisiert für " .. charKey)
end

-- ==============================================================
-- CHARACTER KEY - WICHTIG für korrekte Zuordnung!
-- ==============================================================

function Milestones:GetCharacterKey(name, realm)
    -- Wenn keine Parameter, nutze aktuellen Spieler
    if not name then
        name = UnitName("player")
        realm = GetRealmName()
    end
    -- Entferne Realm-Suffix falls vorhanden
    name = strsplit("-", name)
    realm = realm or GetRealmName()
    return name .. "-" .. realm
end

function Milestones:GetCharacterData(charKey)
    charKey = charKey or self:GetCharacterKey()
    GuildDeathLogDB.milestones[charKey] = GuildDeathLogDB.milestones[charKey] or {
        unlocked = {},
        stats = {}
    }
    return GuildDeathLogDB.milestones[charKey]
end

-- ==============================================================
-- EVENT REGISTRATION - WIE WoW_Hardcore ES MACHT!
-- ==============================================================

function Milestones:RegisterEvents()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame")
    
    -- Event-Handler wie WoW_Hardcore: self[event](self, ...)
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if self[event] then
            self[event](self, ...)
        end
    end)
    
    -- Events registrieren
    self.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    
    GDL:Debug("Milestones: Events registriert")
end

-- ==============================================================
-- PLAYER_LEVEL_UP - Direkt vom Event, wie WoW_Hardcore!
-- Das erste Argument ist das NEUE LEVEL!
-- ==============================================================

function Milestones:PLAYER_LEVEL_UP(newLevel, ...)
    -- newLevel ist das NEUE Level nach dem Level-Up!
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    
    GDL:Debug("Milestones: PLAYER_LEVEL_UP Event! Neues Level: " .. tostring(newLevel))
    GDL:Print("|cff00FF00Level Up!|r " .. charName .. " ist jetzt Level " .. tostring(newLevel))
    
    -- Prüfe Level-Meilensteine
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" and m.threshold == newLevel then
            GDL:Debug("Milestones: Level-Meilenstein erreicht: " .. m.id)
            self:UnlockMilestone(m.id, charKey, charName, newLevel)
        end
    end
end

-- ==============================================================
-- PLAYER_LOGIN - Beim Einloggen alle Meilensteine prüfen
-- ==============================================================

function Milestones:PLAYER_LOGIN()
    GDL:Debug("Milestones: PLAYER_LOGIN Event")
    -- Kurz warten bis alle Daten geladen sind
    C_Timer.After(2, function()
        self:CheckCurrentLevel()
        self:TrackPlayerStats()
    end)
end

-- ==============================================================
-- PLAYER_ENTERING_WORLD - Bei jedem Zonenwechsel/Login
-- ==============================================================

function Milestones:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    GDL:Debug("Milestones: PLAYER_ENTERING_WORLD (initial: " .. tostring(isInitialLogin) .. ", reload: " .. tostring(isReloadingUi) .. ")")
    
    if isInitialLogin or isReloadingUi then
        -- Bei Login/Reload: Alle Level-Meilensteine prüfen
        C_Timer.After(3, function()
            self:CheckCurrentLevel()
            self:RequestMilestoneSync()
        end)
    end
end

-- ==============================================================
-- COMBAT_LOG_EVENT_UNFILTERED - Boss-Kills tracken
-- ==============================================================

function Milestones:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subEvent, _, sourceGUID, sourceName, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
    
    -- Nur UNIT_DIED Events
    if subEvent ~= "UNIT_DIED" then return end
    
    -- NPC ID aus GUID extrahieren
    local npcId = self:GetNPCIdFromGUID(destGUID)
    if not npcId then return end
    
    -- Ist das ein Boss aus unserer Liste?
    local milestoneId = BOSS_TO_MILESTONE[npcId]
    if not milestoneId then return end
    
    -- Wir müssen in einer Gruppe sein oder den Kill selbst gemacht haben
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    GDL:Debug("Milestones: Boss Kill erkannt! " .. (destName or "?") .. " (ID: " .. npcId .. ")")
    
    self:UnlockMilestone(milestoneId, charKey, charName, charLevel)
end

-- ==============================================================
-- CHAT_MSG_ADDON - Gilden-Sync
-- ==============================================================

function Milestones:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == MILESTONE_PREFIX and channel == "GUILD" then
        self:HandleMilestoneSync(message, sender)
    end
end

-- ==============================================================
-- CHECK CURRENT LEVEL - Prüft das aktuelle Level beim Login
-- ==============================================================

function Milestones:CheckCurrentLevel()
    local currentLevel = UnitLevel("player")
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    
    GDL:Debug("Milestones: CheckCurrentLevel - " .. charName .. " ist Level " .. currentLevel)
    
    local count = 0
    -- Alle Level-Meilensteine bis zum aktuellen Level freischalten
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" and currentLevel >= m.threshold then
            local charData = self:GetCharacterData(charKey)
            if not charData.unlocked[m.id] then
                GDL:Debug("Milestones: Nachholen Level-Meilenstein: " .. m.id .. " (aktuelles Level: " .. currentLevel .. ")")
                -- Still nachholen ohne Popup beim Login
                self:UnlockMilestone(m.id, charKey, charName, currentLevel, true)
                count = count + 1
            else
                GDL:Debug("Milestones: " .. m.id .. " bereits freigeschaltet")
            end
        end
    end
    
    if count > 0 then
        GDL:Debug("Milestones: " .. count .. " Level-Meilensteine nachgeholt")
    end
end

-- ==============================================================
-- TEST & DEBUG FUNKTIONEN
-- ==============================================================

function Milestones:TestLevelMilestones()
    local currentLevel = UnitLevel("player")
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    local charData = self:GetCharacterData(charKey)
    
    GDL:Print("=== Meilenstein-Debug ===")
    GDL:Print("Charakter: " .. charName .. " (" .. charKey .. ")")
    GDL:Print("Aktuelles Level: " .. currentLevel)
    GDL:Print("Gespeicherte Daten: " .. (charData and "JA" or "NEIN"))
    
    if charData then
        GDL:Print("Freigeschaltete Meilensteine:")
        local hasAny = false
        for id, data in pairs(charData.unlocked or {}) do
            GDL:Print("  - " .. id .. " (Level " .. (data.level or "?") .. ")")
            hasAny = true
        end
        if not hasAny then
            GDL:Print("  (keine)")
        end
    end
    
    GDL:Print("Level-Meilensteine in MILESTONE_DEFS:")
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" then
            local status = "|cffFF0000[-]|r"
            if currentLevel >= m.threshold then
                if charData and charData.unlocked and charData.unlocked[m.id] then
                    status = "|cff00FF00[OK]|r"
                else
                    status = "|cffFFFF00[!] FEHLT!|r"
                end
            end
            GDL:Print("  " .. status .. " " .. m.id .. " (Level " .. m.threshold .. ")")
        end
    end
    
    GDL:Print("=======================")
end

function Milestones:ForceUnlockCurrentLevel()
    local currentLevel = UnitLevel("player")
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    
    GDL:Print("|cffFFFF00[Force]|r Schalte alle Level-Meilensteine bis Level " .. currentLevel .. " frei...")
    
    local count = 0
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" and currentLevel >= m.threshold then
            -- Force unlock - ignoriere ob bereits freigeschaltet
            local charData = self:GetCharacterData(charKey)
            charData.unlocked[m.id] = {
                timestamp = time(),
                level = currentLevel,
            }
            count = count + 1
            GDL:Print("|cff00FF00[+]|r " .. m.name .. " freigeschaltet!")
        end
    end
    
    GDL:Print("|cff00FF00" .. count .. " Meilensteine freigeschaltet!|r")
end

function Milestones:GetNPCIdFromGUID(guid)
    if not guid then return nil end
    -- GUID Format: Creature-0-XXXX-XXXX-XXXX-NPCID-XXXX
    local npcId = select(6, strsplit("-", guid))
    return tonumber(npcId)
end

-- ==============================================================
-- BERUFE TRACKING
-- ==============================================================

function Milestones:TrackPlayerStats()
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    local charData = self:GetCharacterData(charKey)
    
    -- Berufe tracken (Classic Era API)
    local maxProf = 0
    local fishing = 0
    local cooking = 0
    local firstaid = 0
    
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, skillRank = GetSkillLineInfo(i)
        if not isHeader and skillRank then
            -- Hauptberufe
            if name == "Blacksmithing" or name == "Schmiedekunst" or
               name == "Leatherworking" or name == "Lederverarbeitung" or
               name == "Tailoring" or name == "Schneiderei" or
               name == "Engineering" or name == "Ingenieurskunst" or
               name == "Enchanting" or name == "Verzauberkunst" or
               name == "Alchemy" or name == "Alchimie" or
               name == "Herbalism" or name == "Kraeuterkunde" or
               name == "Mining" or name == "Bergbau" or
               name == "Skinning" or name == "Kuerschnerei" then
                if skillRank > maxProf then
                    maxProf = skillRank
                end
            -- Sekundäre Berufe
            elseif name == "Fishing" or name == "Angeln" then
                fishing = skillRank
            elseif name == "Cooking" or name == "Kochen" then
                cooking = skillRank
            elseif name == "First Aid" or name == "Erste Hilfe" then
                firstaid = skillRank
            end
        end
    end
    
    -- Stats speichern
    charData.stats.maxProfession = maxProf
    charData.stats.fishingSkill = fishing
    charData.stats.cookingSkill = cooking
    charData.stats.firstaidSkill = firstaid
    
    -- Meilensteine prüfen
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "profession" and maxProf >= m.threshold then
            self:UnlockMilestone(m.id, charKey, charName, charLevel)
        elseif m.type == "fishing" and fishing >= m.threshold then
            self:UnlockMilestone(m.id, charKey, charName, charLevel)
        elseif m.type == "cooking" and cooking >= m.threshold then
            self:UnlockMilestone(m.id, charKey, charName, charLevel)
        elseif m.type == "firstaid" and firstaid >= m.threshold then
            self:UnlockMilestone(m.id, charKey, charName, charLevel)
        end
    end
end

function Milestones:CheckAllMilestones()
    -- Alias für CheckCurrentLevel + TrackPlayerStats
    self:CheckCurrentLevel()
    self:TrackPlayerStats()
end

-- ==============================================================
-- MEILENSTEIN FREISCHALTEN
-- ==============================================================

function Milestones:UnlockMilestone(milestoneId, charKey, charName, charLevel, silent)
    local charData = self:GetCharacterData(charKey)
    
    -- Bereits freigeschaltet?
    if charData.unlocked[milestoneId] then
        return false
    end
    
    -- Meilenstein finden
    local milestone = nil
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.id == milestoneId then
            milestone = m
            break
        end
    end
    
    if not milestone then
        GDL:Debug("Milestones: Unbekannter Meilenstein: " .. milestoneId)
        return false
    end
    
    -- Freischalten!
    charData.unlocked[milestoneId] = {
        timestamp = time(),
        level = charLevel,
    }
    
    GDL:Debug("Milestones: FREIGESCHALTET! " .. charName .. " -> " .. milestone.name)
    
    -- Benachrichtigung (nur wenn nicht silent)
    if not silent then
        self:ShowUnlockPopup(milestone, charName)
        
        -- An Gilde senden
        self:BroadcastMilestone(milestoneId, charKey, charName, charLevel)
        
        -- Titles-Modul benachrichtigen (für neue Titel)
        local Titles = GDL:GetModule("Titles")
        if Titles and Titles.OnMilestoneUnlocked then
            Titles:OnMilestoneUnlocked(milestoneId)
        end
    end
    
    return true
end

-- ==============================================================
-- GILDEN-SYNC
-- ==============================================================

function Milestones:BroadcastMilestone(milestoneId, charKey, charName, charLevel)
    if not IsInGuild() then return end
    
    -- Format: UNLOCK|milestoneId|charKey|charName|charLevel|timestamp
    local msg = table.concat({
        "UNLOCK",
        milestoneId,
        charKey,
        charName,
        charLevel or UnitLevel("player"),
        time()
    }, COMM_DELIM)
    
    C_ChatInfo.SendAddonMessage(MILESTONE_PREFIX, msg, "GUILD")
    GDL:Debug("Milestones: Broadcast gesendet: " .. milestoneId .. " für " .. charName)
end

function Milestones:RequestMilestoneSync()
    if not IsInGuild() then return end
    
    C_ChatInfo.SendAddonMessage(MILESTONE_PREFIX, "SYNCREQ", "GUILD")
    GDL:Debug("Milestones: Sync angefordert")
end

function Milestones:HandleMilestoneSync(message, sender)
    -- Eigene Nachrichten ignorieren
    local senderName = strsplit("-", sender)
    if senderName == UnitName("player") then return end
    
    local parts = {strsplit(COMM_DELIM, message)}
    local cmd = parts[1]
    
    if cmd == "UNLOCK" then
        -- Empfangene Meilenstein-Freischaltung
        local milestoneId = parts[2]
        local charKey = parts[3]
        local charName = parts[4]
        local charLevel = tonumber(parts[5]) or 0
        local timestamp = tonumber(parts[6]) or time()
        
        self:OnGuildMilestone(milestoneId, charKey, charName, charLevel, timestamp, senderName)
        
    elseif cmd == "SYNCREQ" then
        -- Jemand fordert Sync an - sende unsere Daten
        self:SendMilestoneData(senderName)
        
    elseif cmd == "SYNCDATA" then
        -- Empfangene Sync-Daten
        local milestoneId = parts[2]
        local charKey = parts[3]
        local charName = parts[4]
        local charLevel = tonumber(parts[5]) or 0
        local timestamp = tonumber(parts[6]) or time()
        
        self:OnGuildMilestone(milestoneId, charKey, charName, charLevel, timestamp, senderName, true)
    end
end

function Milestones:SendMilestoneData(requester)
    if not IsInGuild() then return end
    
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local charName = UnitName("player")
    
    -- Sende alle freigeschalteten Meilensteine
    for milestoneId, data in pairs(charData.unlocked) do
        local msg = table.concat({
            "SYNCDATA",
            milestoneId,
            charKey,
            charName,
            data.level or 0,
            data.timestamp or time()
        }, COMM_DELIM)
        
        C_ChatInfo.SendAddonMessage(MILESTONE_PREFIX, msg, "GUILD")
    end
end

function Milestones:OnGuildMilestone(milestoneId, charKey, charName, charLevel, timestamp, fromPlayer, isSync)
    -- Gildenmitglied hat Meilenstein erreicht
    
    -- In Gilden-Daten speichern
    GuildDeathLogDB.guildMilestones = GuildDeathLogDB.guildMilestones or {}
    GuildDeathLogDB.guildMilestones[charKey] = GuildDeathLogDB.guildMilestones[charKey] or {}
    
    -- Bereits bekannt?
    if GuildDeathLogDB.guildMilestones[charKey][milestoneId] then
        return
    end
    
    GuildDeathLogDB.guildMilestones[charKey][milestoneId] = {
        timestamp = timestamp,
        level = charLevel,
        reportedBy = fromPlayer,
    }
    
    -- Meilenstein finden
    local milestone = nil
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.id == milestoneId then
            milestone = m
            break
        end
    end
    
    if milestone and not isSync then
        -- Nur bei neuen Meilensteinen (nicht bei Sync) anzeigen
        GDL:Print("|cff00FF00" .. charName .. "|r hat erreicht: |cffFFD100" .. milestone.name .. "|r")
        
        if GuildDeathLogDB.settings.sound then
            PlaySound(8959, "Master")
        end
    end
    
    GDL:Debug("Milestones: Gilden-Meilenstein: " .. charName .. " -> " .. milestoneId)
end

-- ==============================================================
-- UI: POPUP
-- ==============================================================

function Milestones:ShowUnlockPopup(milestone, charName)
    if not self.popup then
        local p = CreateFrame("Frame", "GDLMilestonePopup", UIParent, BackdropTemplateMixin and "BackdropTemplate")
        p:SetSize(320, 80)
        p:SetPoint("TOP", UIParent, "TOP", 0, -100)
        p:SetFrameStrata("HIGH")
        
        -- Hintergrund
        if p.SetBackdrop then
            p:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = {left = 8, right = 8, top = 8, bottom = 8}
            })
        end
        
        -- Icon
        p.icon = p:CreateTexture(nil, "ARTWORK")
        p.icon:SetSize(50, 50)
        p.icon:SetPoint("LEFT", 15, 0)
        
        -- Titel
        p.title = p:CreateFontString(nil, "OVERLAY")
        p.title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        p.title:SetPoint("TOPLEFT", p.icon, "TOPRIGHT", 10, -5)
        p.title:SetTextColor(1, 0.84, 0)
        
        -- Name
        p.name = p:CreateFontString(nil, "OVERLAY")
        p.name:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        p.name:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -3)
        p.name:SetTextColor(1, 1, 1)
        
        -- Beschreibung
        p.desc = p:CreateFontString(nil, "OVERLAY")
        p.desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        p.desc:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -3)
        p.desc:SetTextColor(0.7, 0.7, 0.7)
        
        p:Hide()
        self.popup = p
    end
    
    local p = self.popup
    p.icon:SetTexture(milestone.icon)
    p.title:SetText("|cffFFD100" .. charName .. "|r - Meilenstein erreicht!")
    p.name:SetText(milestone.name)
    p.desc:SetText(milestone.desc)
    
    p:SetAlpha(1)
    p:Show()
    
    -- Sound
    PlaySound(8959, "Master")
    
    -- Nach 5 Sekunden ausblenden
    C_Timer.After(5, function()
        if p:IsShown() then
            p:Hide()
        end
    end)
end

-- ==============================================================
-- API FUNKTIONEN
-- ==============================================================

function Milestones:GetAllMilestones()
    return MILESTONE_DEFS
end

function Milestones:GetMilestonesByCategory(category)
    local result = {}
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.category == category then
            table.insert(result, m)
        end
    end
    return result
end

function Milestones:GetCharacterMilestones(charKey)
    charKey = charKey or self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    return charData.unlocked or {}
end

function Milestones:GetGuildMilestones()
    return GuildDeathLogDB.guildMilestones or {}
end

function Milestones:IsMilestoneUnlocked(milestoneId, charKey)
    charKey = charKey or self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    return charData.unlocked[milestoneId] ~= nil
end

function Milestones:GetMilestoneProgress(charKey)
    charKey = charKey or self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local unlocked = 0
    local total = #MILESTONE_DEFS
    
    for _ in pairs(charData.unlocked) do
        unlocked = unlocked + 1
    end
    
    return unlocked, total
end

function Milestones:GetCategoryProgress(category, charKey)
    charKey = charKey or self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local unlocked = 0
    local total = 0
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.category == category then
            total = total + 1
            if charData.unlocked[m.id] then
                unlocked = unlocked + 1
            end
        end
    end
    
    return unlocked, total
end

-- Für Achievements.lua Kompatibilität (falls andere Module es aufrufen)
function Milestones:OnDeathWitnessed()
    -- Tode werden nicht mehr als Achievement getrackt
end

function Milestones:OnGuildDeath()
    -- Tode werden nicht mehr als Achievement getrackt
end

function Milestones:CheckAchievements()
    -- Redirect zu CheckAllMilestones
    self:CheckAllMilestones()
end

-- Modul registrieren
GDL:RegisterModule("Milestones", Milestones)

-- Auch als "Achievements" registrieren für Abwärtskompatibilität
GDL:RegisterModule("Achievements", Milestones)

-- ======================================================================
-- MODULE INITIALIZATION
-- ======================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            Milestones:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
