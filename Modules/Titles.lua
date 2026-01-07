-- ==============================================================
-- MODUL: Titles - Custom Titel für Hardcore-Meilensteine
-- v5.3.3 - Chat minimal (★) + An/Aus + Geschlecht + DE/EN
-- ==============================================================

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Titles = {}

local TITLE_PREFIX = "GDLTitle"
local BROADCAST_INTERVAL = 120
local SYNC_DELAY = 5

local guildTitles = {}

C_ChatInfo.RegisterAddonMessagePrefix(TITLE_PREFIX)

-- ==============================================================
-- LOKALISIERUNG
-- ==============================================================

local L_TITLE = {}
local locale = GetLocale()

if locale == "deDE" then
    L_TITLE = {
        NEW_TITLE = "*** NEUER TITEL FREIGESCHALTET! ***",
        USE_TITLES = "Verwende /gdl titles zum Auswaehlen",
        YOUR_TITLES = "Deine Titel",
        ACTIVE = "AKTIV",
    }
else
    L_TITLE = {
        NEW_TITLE = "*** NEW TITLE UNLOCKED! ***",
        USE_TITLES = "Use /gdl titles to select",
        YOUR_TITLES = "Your Titles",
        ACTIVE = "ACTIVE",
    }
end

-- ==============================================================
-- TITEL-DEFINITIONEN - KOMPLETT!
-- ==============================================================

local TITLE_DEFS = {
    -- ===========================================================
    -- LEGENDÄRE TITEL (Höchste Priorität)
    -- ===========================================================
    {id = "true_immortal", name = locale == "deDE" and "der Wahre Unsterbliche" or "the True Immortal", nameFemale = locale == "deDE" and "die Wahre Unsterbliche" or "the True Immortal", desc = locale == "deDE" and "Level 60 + Alle Raids + 30 Tage /played" or "Level 60 + All Raids + 30 days /played", icon = "Interface\\Icons\\Spell_Holy_Resurrection", color = {1, 0.5, 1}, requirement = "meta_true_immortal", priority = 500},
    {id = "perfectionist", name = locale == "deDE" and "der Perfektionist" or "the Perfectionist", nameFemale = locale == "deDE" and "die Perfektionistin" or "the Perfectionist", desc = locale == "deDE" and "Level 60 + Alle Berufe 300 + Alle Dungeons" or "Level 60 + All Profs 300 + All Dungeons", icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend", color = {0.9, 0.8, 0.5}, requirement = "meta_perfectionist", priority = 480},
    {id = "godslayer", name = locale == "deDE" and "Goetterschlaechter" or "Godslayer", nameFemale = locale == "deDE" and "Goetterschlaechterin" or "Godslayer", desc = locale == "deDE" and "C'Thun UND Kel'Thuzad besiegt" or "Defeated C'Thun AND Kel'Thuzad", icon = "Interface\\Icons\\INV_Misc_Eye_01", color = {0.8, 0.2, 0.8}, requirement = "meta_godslayer", priority = 450},
    {id = "legend_azeroth", name = locale == "deDE" and "Legende von Azeroth" or "Legend of Azeroth", nameFemale = locale == "deDE" and "Legende von Azeroth" or "Legend of Azeroth", desc = locale == "deDE" and "Level 60 + Alle Dungeons + 5.000 Kills" or "Level 60 + All Dungeons + 5,000 Kills", icon = "Interface\\Icons\\INV_Misc_Map02", color = {1, 0.84, 0}, requirement = "meta_legend_azeroth", priority = 400},
    {id = "immortal_veteran", name = locale == "deDE" and "Unsterblicher Veteran" or "Immortal Veteran", nameFemale = locale == "deDE" and "Unsterbliche Veteranin" or "Immortal Veteran", desc = locale == "deDE" and "Level 60 + 7 Tage /played" or "Level 60 + 7 days /played", icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", color = {0.9, 0.7, 0.9}, requirement = "meta_immortal_veteran", priority = 380},
    {id = "dungeon_legend", name = locale == "deDE" and "Kerker-Legende" or "Dungeon Legend", nameFemale = locale == "deDE" and "Kerker-Legende" or "Dungeon Legend", desc = locale == "deDE" and "Alle Dungeons UND Raids gemeistert" or "All Dungeons AND Raids mastered", icon = "Interface\\Icons\\Spell_Holy_ChampionsBond", color = {0.7, 0.5, 1}, requirement = "meta_dungeon_legend", priority = 370},

    -- ===========================================================
    -- RAID-BOSSE
    -- ===========================================================
    {id = "kt_slayer", name = locale == "deDE" and "Bezwinger von Kel'Thuzad" or "Kel'Thuzad Slayer", nameFemale = locale == "deDE" and "Bezwingerin von Kel'Thuzad" or "Kel'Thuzad Slayer", desc = locale == "deDE" and "Kel'Thuzad besiegt" or "Defeated Kel'Thuzad", icon = "Interface\\Icons\\INV_Trinket_Naxxramas06", color = {0.6, 0.8, 1}, requirement = "boss_naxx_kt", priority = 360},
    {id = "cthun_slayer", name = locale == "deDE" and "Bezwinger von C'Thun" or "C'Thun Slayer", nameFemale = locale == "deDE" and "Bezwingerin von C'Thun" or "C'Thun Slayer", desc = locale == "deDE" and "C'Thun besiegt" or "Defeated C'Thun", icon = "Interface\\Icons\\INV_Misc_Eye_01", color = {0.5, 0.8, 0.5}, requirement = "boss_aq40_cthun", priority = 350},
    {id = "nef_slayer", name = locale == "deDE" and "Nefarian-Toeter" or "Nefarian Slayer", nameFemale = locale == "deDE" and "Nefarian-Toeterin" or "Nefarian Slayer", desc = locale == "deDE" and "Nefarian besiegt" or "Defeated Nefarian", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", color = {0.3, 0.3, 0.3}, requirement = "boss_bwl_nef", priority = 340},
    {id = "rag_slayer", name = locale == "deDE" and "Ragnaros-Toeter" or "Ragnaros Slayer", nameFemale = locale == "deDE" and "Ragnaros-Toeterin" or "Ragnaros Slayer", desc = locale == "deDE" and "Ragnaros besiegt" or "Defeated Ragnaros", icon = "Interface\\Icons\\Spell_Fire_Lavaspawn", color = {1, 0.5, 0.2}, requirement = "boss_mc_rag", priority = 330},
    {id = "ony_slayer", name = locale == "deDE" and "Drachenbezwinger" or "Dragon Slayer", nameFemale = locale == "deDE" and "Drachenbezwingerin" or "Dragon Slayer", desc = locale == "deDE" and "Onyxia besiegt" or "Defeated Onyxia", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", color = {0.5, 0.3, 0.5}, requirement = "boss_ony", priority = 320},
    {id = "hakkar_slayer", name = locale == "deDE" and "Haekkar-Toeter" or "Hakkar Slayer", nameFemale = locale == "deDE" and "Haekkar-Toeterin" or "Hakkar Slayer", desc = locale == "deDE" and "Hakkar besiegt" or "Defeated Hakkar", icon = "Interface\\Icons\\Ability_Creature_Poison_05", color = {0.2, 0.8, 0.4}, requirement = "boss_zg_hakkar", priority = 310},
    {id = "ossirian_slayer", name = locale == "deDE" and "Ossirian-Toeter" or "Ossirian Slayer", nameFemale = locale == "deDE" and "Ossirian-Toeterin" or "Ossirian Slayer", desc = locale == "deDE" and "Ossirian besiegt" or "Defeated Ossirian", icon = "Interface\\Icons\\INV_Jewelry_Ring_AhnQiraj_01", color = {0.8, 0.7, 0.4}, requirement = "boss_aq20_ossirian", priority = 300},

    -- ===========================================================
    -- META-ACHIEVEMENTS
    -- ===========================================================
    {id = "raid_master", name = locale == "deDE" and "Raidmeister" or "Raid Master", nameFemale = locale == "deDE" and "Raidmeisterin" or "Raid Master", desc = locale == "deDE" and "Alle Raid-Endbosse besiegt" or "All raid end bosses defeated", icon = "Interface\\Icons\\INV_Helmet_06", color = {0.8, 0.6, 0.2}, requirement = "meta_all_raids", priority = 295},
    {id = "dungeon_master", name = locale == "deDE" and "Kerkermeister" or "Dungeon Master", nameFemale = locale == "deDE" and "Kerkermeisterin" or "Dungeon Master", desc = locale == "deDE" and "Alle Dungeon-Endbosse besiegt" or "All dungeon end bosses defeated", icon = "Interface\\Icons\\INV_Jewelry_Talisman_08", color = {0.5, 0.5, 0.8}, requirement = "meta_all_dungeons", priority = 290},
    {id = "high_dungeon_master", name = locale == "deDE" and "Meister der Hoeheren Kerker" or "High Dungeon Master", nameFemale = locale == "deDE" and "Meisterin der Hoeheren Kerker" or "High Dungeon Master", desc = locale == "deDE" and "Alle High-Level Dungeons" or "All high-level dungeons", icon = "Interface\\Icons\\INV_Misc_Key_14", color = {0.6, 0.4, 0.8}, requirement = "meta_high_dungeons", priority = 280},
    {id = "mid_dungeon_master", name = locale == "deDE" and "Meister der Mittleren Kerker" or "Mid Dungeon Master", nameFemale = locale == "deDE" and "Meisterin der Mittleren Kerker" or "Mid Dungeon Master", desc = locale == "deDE" and "Alle Mid-Level Dungeons" or "All mid-level dungeons", icon = "Interface\\Icons\\INV_Misc_Key_10", color = {0.5, 0.5, 0.7}, requirement = "meta_mid_dungeons", priority = 200},
    {id = "low_dungeon_master", name = locale == "deDE" and "Meister der Niederen Kerker" or "Low Dungeon Master", nameFemale = locale == "deDE" and "Meisterin der Niederen Kerker" or "Low Dungeon Master", desc = locale == "deDE" and "Alle Low-Level Dungeons" or "All low-level dungeons", icon = "Interface\\Icons\\INV_Misc_Key_04", color = {0.4, 0.6, 0.5}, requirement = "meta_low_dungeons", priority = 120},
    {id = "complete_crafter", name = locale == "deDE" and "Meisterhandwerker" or "Master Crafter", nameFemale = locale == "deDE" and "Meisterhandwerkerin" or "Master Crafter", desc = locale == "deDE" and "Hauptberuf 300 + Alle Nebenberufe 300" or "Main prof 300 + All secondary 300", icon = "Interface\\Icons\\Achievement_Profession_Chefhat", color = {0.7, 0.5, 0.3}, requirement = "meta_complete_crafter", priority = 275},
    {id = "secondary_master", name = locale == "deDE" and "Nebenberuf-Meister" or "Secondary Master", nameFemale = locale == "deDE" and "Nebenberuf-Meisterin" or "Secondary Master", desc = locale == "deDE" and "Angeln, Kochen, Erste Hilfe auf 300" or "Fishing, Cooking, First Aid at 300", icon = "Interface\\Icons\\Spell_Nature_EnchantArmor", color = {0.5, 0.6, 0.5}, requirement = "meta_all_secondary", priority = 180},

    -- ===========================================================
    -- HIGH-LEVEL DUNGEON BOSSE
    -- ===========================================================
    {id = "baron_slayer", name = locale == "deDE" and "Barontoeter" or "Baron Slayer", nameFemale = locale == "deDE" and "Barontoeterin" or "Baron Slayer", desc = locale == "deDE" and "Baron Rivendare besiegt" or "Defeated Baron Rivendare", icon = "Interface\\Icons\\INV_Sword_49", color = {0.4, 0.4, 0.5}, requirement = "boss_strat_ud", priority = 270},
    {id = "strat_live", name = locale == "deDE" and "Scharlachroter Kreuzfahrer" or "Scarlet Crusader", nameFemale = locale == "deDE" and "Scharlachrote Kreuzfahrerin" or "Scarlet Crusader", desc = locale == "deDE" and "Balnazzar besiegt" or "Defeated Balnazzar", icon = "Interface\\Icons\\Spell_Holy_HolyBolt", color = {0.8, 0.2, 0.2}, requirement = "boss_strat_live", priority = 265},
    {id = "scholo_slayer", name = locale == "deDE" and "Scholomance-Bezwinger" or "Scholomance Conqueror", nameFemale = locale == "deDE" and "Scholomance-Bezwingerin" or "Scholomance Conqueror", desc = locale == "deDE" and "Darkmaster Gandling besiegt" or "Defeated Darkmaster Gandling", icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", color = {0.3, 0.5, 0.3}, requirement = "boss_scholo", priority = 260},
    {id = "ubrs_slayer", name = locale == "deDE" and "UBRS-Bezwinger" or "UBRS Conqueror", nameFemale = locale == "deDE" and "UBRS-Bezwingerin" or "UBRS Conqueror", desc = locale == "deDE" and "General Drakkisath besiegt" or "Defeated General Drakkisath", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", color = {0.6, 0.3, 0.2}, requirement = "boss_ubrs", priority = 255},
    {id = "lbrs_slayer", name = locale == "deDE" and "LBRS-Bezwinger" or "LBRS Conqueror", nameFemale = locale == "deDE" and "LBRS-Bezwingerin" or "LBRS Conqueror", desc = locale == "deDE" and "Ueberlord Wyrmthalak besiegt" or "Defeated Overlord Wyrmthalak", icon = "Interface\\Icons\\INV_Misc_MonsterScales_15", color = {0.5, 0.4, 0.3}, requirement = "boss_lbrs", priority = 250},
    {id = "dm_north", name = locale == "deDE" and "Koenigs-Bezwinger" or "King Slayer", nameFemale = locale == "deDE" and "Koenigs-Bezwingerin" or "King Slayer", desc = locale == "deDE" and "Koenig Gordok besiegt" or "Defeated King Gordok", icon = "Interface\\Icons\\INV_Misc_Head_Ogre_01", color = {0.6, 0.5, 0.3}, requirement = "boss_dm_north", priority = 245},
    {id = "dm_west", name = locale == "deDE" and "Prinzentoeter" or "Prince Slayer", nameFemale = locale == "deDE" and "Prinzentoeterin" or "Prince Slayer", desc = locale == "deDE" and "Prinz Tortheldrin besiegt" or "Defeated Prince Tortheldrin", icon = "Interface\\Icons\\INV_Sword_26", color = {0.4, 0.5, 0.6}, requirement = "boss_dm_west", priority = 240},
    {id = "dm_east", name = locale == "deDE" and "Satyr-Toeter" or "Satyr Slayer", nameFemale = locale == "deDE" and "Satyr-Toeterin" or "Satyr Slayer", desc = locale == "deDE" and "Alzzin besiegt" or "Defeated Alzzin", icon = "Interface\\Icons\\Spell_Nature_AbolishMagic", color = {0.3, 0.6, 0.3}, requirement = "boss_dm_east", priority = 235},
    {id = "brd_emperor", name = locale == "deDE" and "Imperatortoeter" or "Emperor Slayer", nameFemale = locale == "deDE" and "Imperatortoeterin" or "Emperor Slayer", desc = locale == "deDE" and "Imperator Thaurissan besiegt" or "Defeated Emperor Thaurissan", icon = "Interface\\Icons\\INV_Crown_01", color = {0.8, 0.6, 0.2}, requirement = "boss_brd_emp", priority = 230},
    {id = "sunken_temple", name = locale == "deDE" and "Tempelreiniger" or "Temple Cleanser", nameFemale = locale == "deDE" and "Tempelreinigerin" or "Temple Cleanser", desc = locale == "deDE" and "Eranikus' Schatten besiegt" or "Defeated Shade of Eranikus", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green", color = {0.3, 0.5, 0.4}, requirement = "boss_st", priority = 225},

    -- ===========================================================
    -- MID-LEVEL DUNGEON BOSSE
    -- ===========================================================
    {id = "mara_slayer", name = locale == "deDE" and "Prinzessinnentoeter" or "Princess Slayer", nameFemale = locale == "deDE" and "Prinzessinnentoeterin" or "Princess Slayer", desc = locale == "deDE" and "Prinzessin Theradras besiegt" or "Defeated Princess Theradras", icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem", color = {0.5, 0.4, 0.3}, requirement = "boss_mara", priority = 195},
    {id = "zf_slayer", name = locale == "deDE" and "Sandscalp-Toeter" or "Sandscalp Slayer", nameFemale = locale == "deDE" and "Sandscalp-Toeterin" or "Sandscalp Slayer", desc = locale == "deDE" and "Haeuptling Sandscalp besiegt" or "Defeated Chief Sandscalp", icon = "Interface\\Icons\\Ability_Warrior_Cleave", color = {0.8, 0.7, 0.4}, requirement = "boss_zf", priority = 190},
    {id = "ulda_slayer", name = locale == "deDE" and "Archaedas-Toeter" or "Archaedas Slayer", nameFemale = locale == "deDE" and "Archaedas-Toeterin" or "Archaedas Slayer", desc = locale == "deDE" and "Archaedas besiegt" or "Defeated Archaedas", icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem", color = {0.6, 0.5, 0.4}, requirement = "boss_ulda", priority = 185},
    {id = "rfd_slayer", name = locale == "deDE" and "Kaeltebringer-Toeter" or "Coldbringer Slayer", nameFemale = locale == "deDE" and "Kaeltebringer-Toeterin" or "Coldbringer Slayer", desc = locale == "deDE" and "Amnennar besiegt" or "Defeated Amnennar", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", color = {0.4, 0.5, 0.7}, requirement = "boss_rfd", priority = 170},
    {id = "rfk_slayer", name = locale == "deDE" and "Razorflank-Toeter" or "Razorflank Slayer", nameFemale = locale == "deDE" and "Razorflank-Toeterin" or "Razorflank Slayer", desc = locale == "deDE" and "Charlga Razorflank besiegt" or "Defeated Charlga Razorflank", icon = "Interface\\Icons\\Ability_Hunter_Pet_Boar", color = {0.5, 0.4, 0.3}, requirement = "boss_rfk", priority = 165},
    {id = "gnomer_slayer", name = locale == "deDE" and "Thermaplugg-Toeter" or "Thermaplugg Slayer", nameFemale = locale == "deDE" and "Thermaplugg-Toeterin" or "Thermaplugg Slayer", desc = locale == "deDE" and "Thermaplugg besiegt" or "Defeated Thermaplugg", icon = "Interface\\Icons\\INV_Gizmo_08", color = {0.4, 0.6, 0.4}, requirement = "boss_gnomer", priority = 160},
    {id = "sm_cath", name = locale == "deDE" and "Mograine-Toeter" or "Mograine Slayer", nameFemale = locale == "deDE" and "Mograine-Toeterin" or "Mograine Slayer", desc = locale == "deDE" and "Mograine besiegt" or "Defeated Mograine", icon = "Interface\\Icons\\INV_Sword_20", color = {0.8, 0.2, 0.2}, requirement = "boss_sm_cath", priority = 175},
    {id = "sm_arm", name = locale == "deDE" and "Herod-Toeter" or "Herod Slayer", nameFemale = locale == "deDE" and "Herod-Toeterin" or "Herod Slayer", desc = locale == "deDE" and "Herod besiegt" or "Defeated Herod", icon = "Interface\\Icons\\INV_Axe_40", color = {0.7, 0.3, 0.3}, requirement = "boss_sm_arm", priority = 155},
    {id = "sm_lib", name = locale == "deDE" and "Doan-Toeter" or "Doan Slayer", nameFemale = locale == "deDE" and "Doan-Toeterin" or "Doan Slayer", desc = locale == "deDE" and "Doan besiegt" or "Defeated Doan", icon = "Interface\\Icons\\INV_Staff_13", color = {0.5, 0.4, 0.6}, requirement = "boss_sm_lib", priority = 150},
    {id = "sm_gy", name = locale == "deDE" and "Blutmagier-Toeter" or "Bloodmage Slayer", nameFemale = locale == "deDE" and "Blutmagier-Toeterin" or "Bloodmage Slayer", desc = locale == "deDE" and "Thalnos besiegt" or "Defeated Thalnos", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", color = {0.6, 0.2, 0.2}, requirement = "boss_sm_gy", priority = 145},

    -- ===========================================================
    -- LOW-LEVEL DUNGEON BOSSE
    -- ===========================================================
    {id = "sfk_slayer", name = locale == "deDE" and "Arugal-Toeter" or "Arugal Slayer", nameFemale = locale == "deDE" and "Arugal-Toeterin" or "Arugal Slayer", desc = locale == "deDE" and "Arugal besiegt" or "Defeated Arugal", icon = "Interface\\Icons\\Spell_Shadow_SummonFelHunter", color = {0.4, 0.4, 0.6}, requirement = "boss_sfk", priority = 115},
    {id = "bfd_slayer", name = locale == "deDE" and "Aku'mai-Toeter" or "Aku'mai Slayer", nameFemale = locale == "deDE" and "Aku'mai-Toeterin" or "Aku'mai Slayer", desc = locale == "deDE" and "Aku'mai besiegt" or "Defeated Aku'mai", icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental", color = {0.3, 0.4, 0.6}, requirement = "boss_bfd", priority = 110},
    {id = "stocks_slayer", name = locale == "deDE" and "Gefaengniswaerter" or "Prison Warden", nameFemale = locale == "deDE" and "Gefaengniswaerterin" or "Prison Warden", desc = locale == "deDE" and "Bazil Thredd besiegt" or "Defeated Bazil Thredd", icon = "Interface\\Icons\\INV_Misc_Key_01", color = {0.5, 0.5, 0.5}, requirement = "boss_stocks", priority = 105},
    {id = "dm_slayer", name = locale == "deDE" and "VanCleef-Toeter" or "VanCleef Slayer", nameFemale = locale == "deDE" and "VanCleef-Toeterin" or "VanCleef Slayer", desc = locale == "deDE" and "VanCleef besiegt" or "Defeated VanCleef", icon = "Interface\\Icons\\INV_Helmet_25", color = {0.6, 0.4, 0.2}, requirement = "boss_dm", priority = 100},
    {id = "wc_slayer", name = locale == "deDE" and "Mutanus-Toeter" or "Mutanus Slayer", nameFemale = locale == "deDE" and "Mutanus-Toeterin" or "Mutanus Slayer", desc = locale == "deDE" and "Mutanus besiegt" or "Defeated Mutanus", icon = "Interface\\Icons\\Spell_Nature_MirrorImage", color = {0.3, 0.5, 0.3}, requirement = "boss_wc", priority = 95},
    {id = "rfc_slayer", name = locale == "deDE" and "Taragaman-Toeter" or "Taragaman Slayer", nameFemale = locale == "deDE" and "Taragaman-Toeterin" or "Taragaman Slayer", desc = locale == "deDE" and "Taragaman besiegt" or "Defeated Taragaman", icon = "Interface\\Icons\\Spell_Fire_Fire", color = {0.7, 0.3, 0.2}, requirement = "boss_rfc", priority = 90},

    -- ===========================================================
    -- SPIELZEIT-TITEL
    -- ===========================================================
    {id = "eternal", name = locale == "deDE" and "der Ewige" or "the Eternal", nameFemale = locale == "deDE" and "die Ewige" or "the Eternal", desc = locale == "deDE" and "30 Tage /played" or "30 days /played", icon = "Interface\\Icons\\Spell_Holy_Resurrection", color = {0.9, 0.8, 0.5}, requirement = "played_720h", priority = 285},
    {id = "two_weeks", name = locale == "deDE" and "Zwei Wochen Stark" or "Two Weeks Strong", nameFemale = locale == "deDE" and "Zwei Wochen Stark" or "Two Weeks Strong", desc = locale == "deDE" and "14 Tage /played" or "14 days /played", icon = "Interface\\Icons\\Spell_Holy_SealOfWrath", color = {0.6, 0.6, 0.8}, requirement = "played_336h", priority = 220},
    {id = "one_week", name = locale == "deDE" and "Eine Woche Stark" or "One Week Strong", nameFemale = locale == "deDE" and "Eine Woche Stark" or "One Week Strong", desc = locale == "deDE" and "7 Tage /played" or "7 days /played", icon = "Interface\\Icons\\Spell_Holy_SealOfValor", color = {0.5, 0.5, 0.7}, requirement = "played_168h", priority = 140},
    {id = "three_days", name = locale == "deDE" and "Drei Tage Ueberlebt" or "Three Days Survived", nameFemale = locale == "deDE" and "Drei Tage Ueberlebt" or "Three Days Survived", desc = locale == "deDE" and "72h /played" or "72h /played", icon = "Interface\\Icons\\Spell_Holy_SealOfSalvation", color = {0.5, 0.5, 0.6}, requirement = "played_72h", priority = 55},
    {id = "first_day", name = locale == "deDE" and "Erster Tag" or "First Day", nameFemale = locale == "deDE" and "Erster Tag" or "First Day", desc = locale == "deDE" and "24h /played" or "24h /played", icon = "Interface\\Icons\\Spell_Nature_TimeStop", color = {0.4, 0.6, 0.7}, requirement = "played_24h", priority = 30},

    -- ===========================================================
    -- LEVEL-TITEL
    -- ===========================================================
    {id = "immortal", name = locale == "deDE" and "der Unsterbliche" or "the Immortal", nameFemale = locale == "deDE" and "die Unsterbliche" or "the Immortal", desc = locale == "deDE" and "Level 60" or "Level 60", icon = "Interface\\Icons\\INV_Crown_01", color = {1, 0.84, 0}, requirement = "level_60", priority = 210},
    {id = "veteran", name = locale == "deDE" and "der Veteran" or "the Veteran", nameFemale = locale == "deDE" and "die Veteranin" or "the Veteran", desc = locale == "deDE" and "Level 50" or "Level 50", icon = "Interface\\Icons\\INV_Shield_07", color = {0.6, 0.5, 0.7}, requirement = "level_50", priority = 130},
    {id = "survivor", name = locale == "deDE" and "der Ueberlebende" or "the Survivor", nameFemale = locale == "deDE" and "die Ueberlebende" or "the Survivor", desc = locale == "deDE" and "Level 40" or "Level 40", icon = "Interface\\Icons\\Ability_Mount_RidingHorse", color = {0.5, 0.6, 0.5}, requirement = "level_40", priority = 80},
    {id = "traveler", name = locale == "deDE" and "der Reisende" or "the Traveler", nameFemale = locale == "deDE" and "die Reisende" or "the Traveler", desc = locale == "deDE" and "Level 30" or "Level 30", icon = "Interface\\Icons\\INV_Shield_06", color = {0.4, 0.5, 0.6}, requirement = "level_30", priority = 45},
    {id = "adventurer", name = locale == "deDE" and "der Abenteurer" or "the Adventurer", nameFemale = locale == "deDE" and "die Abenteurerin" or "the Adventurer", desc = locale == "deDE" and "Level 20" or "Level 20", icon = "Interface\\Icons\\Spell_Holy_GreaterHeal", color = {0.4, 0.6, 0.4}, requirement = "level_20", priority = 40},
    {id = "newcomer", name = locale == "deDE" and "der Neuling" or "the Newcomer", nameFemale = locale == "deDE" and "die Neulingin" or "the Newcomer", desc = locale == "deDE" and "Level 10" or "Level 10", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", color = {0.5, 0.7, 0.5}, requirement = "level_10", priority = 10},

    -- ===========================================================
    -- TOTAL KILL-TITEL
    -- ===========================================================
    {id = "massacre", name = locale == "deDE" and "Das Massaker" or "the Massacre", nameFemale = locale == "deDE" and "Das Massaker" or "the Massacre", desc = locale == "deDE" and "50.000 Kills" or "50,000 Kills", icon = "Interface\\Icons\\Spell_Shadow_DeathScream", color = {0.8, 0.1, 0.1}, requirement = "kills_total_50000", priority = 215},
    {id = "annihilator", name = locale == "deDE" and "Vernichter" or "Annihilator", nameFemale = locale == "deDE" and "Vernichterin" or "Annihilator", desc = locale == "deDE" and "25.000 Kills" or "25,000 Kills", icon = "Interface\\Icons\\Ability_Warrior_WarCry", color = {0.7, 0.2, 0.2}, requirement = "kills_total_25000", priority = 180},
    {id = "destroyer", name = locale == "deDE" and "Zerstoerer" or "Destroyer", nameFemale = locale == "deDE" and "Zerstoererin" or "Destroyer", desc = locale == "deDE" and "10.000 Kills" or "10,000 Kills", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", color = {0.6, 0.3, 0.3}, requirement = "kills_total_10000", priority = 135},
    {id = "executioner", name = locale == "deDE" and "Henker" or "Executioner", nameFemale = locale == "deDE" and "Henkerin" or "Executioner", desc = locale == "deDE" and "5.000 Kills" or "5,000 Kills", icon = "Interface\\Icons\\Ability_Warrior_Rampage", color = {0.5, 0.3, 0.3}, requirement = "kills_total_5000", priority = 85},
    {id = "slayer", name = locale == "deDE" and "Schlaechter" or "Slayer", nameFemale = locale == "deDE" and "Schlaechterin" or "Slayer", desc = locale == "deDE" and "1.000 Kills" or "1,000 Kills", icon = "Interface\\Icons\\Ability_DualWield", color = {0.4, 0.3, 0.3}, requirement = "kills_total_1000", priority = 50},

    -- ===========================================================
    -- HUMANOID-KILL TITEL
    -- ===========================================================
    {id = "warlord", name = locale == "deDE" and "Kriegsherr" or "Warlord", nameFemale = locale == "deDE" and "Kriegsherrin" or "Warlord", desc = locale == "deDE" and "2.000 Humanoide" or "2,000 Humanoids", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", color = {0.8, 0.3, 0.2}, requirement = "kill_humanoid_2000", priority = 92},
    {id = "bounty_hunter", name = locale == "deDE" and "Kopfgeldjaeger" or "Bounty Hunter", nameFemale = locale == "deDE" and "Kopfgeldjaegerin" or "Bounty Hunter", desc = locale == "deDE" and "500 Humanoide" or "500 Humanoids", icon = "Interface\\Icons\\INV_Misc_Coin_02", color = {0.7, 0.5, 0.2}, requirement = "kill_humanoid_500", priority = 70},
    {id = "bandit_slayer", name = locale == "deDE" and "Banditenjaeger" or "Bandit Slayer", nameFemale = locale == "deDE" and "Banditenjaegerin" or "Bandit Slayer", desc = locale == "deDE" and "100 Humanoide" or "100 Humanoids", icon = "Interface\\Icons\\Ability_Rogue_Disguise", color = {0.6, 0.4, 0.3}, requirement = "kill_humanoid_100", priority = 35},
    {id = "highwayman", name = locale == "deDE" and "Wegelagerer" or "Highwayman", nameFemale = locale == "deDE" and "Wegelagerin" or "Highwayman", desc = locale == "deDE" and "25 Humanoide" or "25 Humanoids", icon = "Interface\\Icons\\Ability_Rogue_Ambush", color = {0.5, 0.4, 0.3}, requirement = "kill_humanoid_25", priority = 22},

    -- ===========================================================
    -- BEAST-KILL TITEL
    -- ===========================================================
    {id = "beastmaster", name = locale == "deDE" and "Bestienmeister" or "Beast Master", nameFemale = locale == "deDE" and "Bestienmeisterin" or "Beast Master", desc = locale == "deDE" and "2.000 Wildtiere" or "2,000 Beasts", icon = "Interface\\Icons\\Ability_Hunter_BeastMastery", color = {0.6, 0.4, 0.2}, requirement = "kill_beast_2000", priority = 93},
    {id = "big_game_hunter", name = locale == "deDE" and "Grosswildjaeger" or "Big Game Hunter", nameFemale = locale == "deDE" and "Grosswildjaegerin" or "Big Game Hunter", desc = locale == "deDE" and "500 Wildtiere" or "500 Beasts", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", color = {0.5, 0.4, 0.3}, requirement = "kill_beast_500", priority = 68},
    {id = "tracker", name = locale == "deDE" and "Faehrtenleser" or "Tracker", nameFemale = locale == "deDE" and "Faehrtenleserin" or "Tracker", desc = locale == "deDE" and "100 Wildtiere" or "100 Beasts", icon = "Interface\\Icons\\Ability_Hunter_BeastCall", color = {0.4, 0.5, 0.3}, requirement = "kill_beast_100", priority = 33},
    {id = "hunter", name = locale == "deDE" and "Jaeger" or "Hunter", nameFemale = locale == "deDE" and "Jaegerin" or "Hunter", desc = locale == "deDE" and "25 Wildtiere" or "25 Beasts", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", color = {0.5, 0.6, 0.3}, requirement = "kill_beast_25", priority = 20},

    -- ===========================================================
    -- UNDEAD-KILL TITEL
    -- ===========================================================
    {id = "plague_cleanser", name = locale == "deDE" and "Seuchenreiniger" or "Plague Cleanser", nameFemale = locale == "deDE" and "Seuchenreinigerin" or "Plague Cleanser", desc = locale == "deDE" and "5.000 Untote" or "5,000 Undead", icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing", color = {0.8, 0.7, 0.3}, requirement = "kill_undead_5000", priority = 145},
    {id = "undead_scourge", name = locale == "deDE" and "Geissel der Untoten" or "Scourge of the Undead", nameFemale = locale == "deDE" and "Geissel der Untoten" or "Scourge of the Undead", desc = locale == "deDE" and "1.000 Untote" or "1,000 Undead", icon = "Interface\\Icons\\Spell_Holy_SenseUndead", color = {0.6, 0.6, 0.3}, requirement = "kill_undead_1000", priority = 91},
    {id = "undead_slayer", name = locale == "deDE" and "Untotentoeter" or "Undead Slayer", nameFemale = locale == "deDE" and "Untotentoeterin" or "Undead Slayer", desc = locale == "deDE" and "500 Untote" or "500 Undead", icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", color = {0.5, 0.5, 0.3}, requirement = "kill_undead_500", priority = 67},
    {id = "bone_breaker", name = locale == "deDE" and "Knochenbrecher" or "Bone Breaker", nameFemale = locale == "deDE" and "Knochenbrecherin" or "Bone Breaker", desc = locale == "deDE" and "100 Untote" or "100 Undead", icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", color = {0.4, 0.5, 0.4}, requirement = "kill_undead_100", priority = 32},
    {id = "grave_defiler", name = locale == "deDE" and "Grabschaender" or "Grave Defiler", nameFemale = locale == "deDE" and "Grabschaenderin" or "Grave Defiler", desc = locale == "deDE" and "25 Untote" or "25 Undead", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", color = {0.4, 0.5, 0.4}, requirement = "kill_undead_25", priority = 25},

    -- ===========================================================
    -- DEMON-KILL TITEL
    -- ===========================================================
    {id = "eredarbane", name = locale == "deDE" and "Eredarbane" or "Eredar Bane", nameFemale = locale == "deDE" and "Eredarbane" or "Eredar Bane", desc = locale == "deDE" and "1.000 Daemonen" or "1,000 Demons", icon = "Interface\\Icons\\Spell_Shadow_DemonicTactics", color = {0.6, 0.2, 0.6}, requirement = "kill_demon_1000", priority = 125},
    {id = "demon_slayer", name = locale == "deDE" and "Daemonentoeter" or "Demon Slayer", nameFemale = locale == "deDE" and "Daemonentoeterin" or "Demon Slayer", desc = locale == "deDE" and "500 Daemonen" or "500 Demons", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", color = {0.5, 0.2, 0.5}, requirement = "kill_demon_500", priority = 66},
    {id = "demon_hunter_adv", name = locale == "deDE" and "Daemonenjagd-Veteran" or "Demon Hunting Veteran", nameFemale = locale == "deDE" and "Daemonenjagd-Veteranin" or "Demon Hunting Veteran", desc = locale == "deDE" and "100 Daemonen" or "100 Demons", icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard", color = {0.4, 0.2, 0.4}, requirement = "kill_demon_100", priority = 31},
    {id = "demon_hunter", name = locale == "deDE" and "Daemonenjaeger" or "Demon Hunter", nameFemale = locale == "deDE" and "Daemonenjaegerin" or "Demon Hunter", desc = locale == "deDE" and "25 Daemonen" or "25 Demons", icon = "Interface\\Icons\\Spell_Shadow_SummonImp", color = {0.5, 0.3, 0.5}, requirement = "kill_demon_25", priority = 23},

    -- ===========================================================
    -- DRAGONKIN-KILL TITEL
    -- ===========================================================
    {id = "dragonbane", name = locale == "deDE" and "Drachenbane" or "Dragonbane", nameFemale = locale == "deDE" and "Drachenbane" or "Dragonbane", desc = locale == "deDE" and "1.000 Drachkin" or "1,000 Dragonkin", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", color = {0.8, 0.5, 0.2}, requirement = "kill_dragonkin_1000", priority = 130},
    {id = "dragon_slayer", name = locale == "deDE" and "Drachentoeter" or "Dragon Slayer", nameFemale = locale == "deDE" and "Drachentoeterin" or "Dragon Slayer", desc = locale == "deDE" and "250 Drachkin" or "250 Dragonkin", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", color = {0.7, 0.4, 0.2}, requirement = "kill_dragonkin_250", priority = 65},
    {id = "dragon_hunter", name = locale == "deDE" and "Drachenjaeger" or "Dragon Hunter", nameFemale = locale == "deDE" and "Drachenjaegerin" or "Dragon Hunter", desc = locale == "deDE" and "50 Drachkin" or "50 Dragonkin", icon = "Interface\\Icons\\INV_Misc_MonsterScales_05", color = {0.6, 0.4, 0.2}, requirement = "kill_dragonkin_50", priority = 30},
    {id = "wyrm_tracker", name = locale == "deDE" and "Wyrmjaeger" or "Wyrm Tracker", nameFemale = locale == "deDE" and "Wyrmjaegerin" or "Wyrm Tracker", desc = locale == "deDE" and "10 Drachkin" or "10 Dragonkin", icon = "Interface\\Icons\\INV_Misc_MonsterScales_02", color = {0.5, 0.4, 0.3}, requirement = "kill_dragonkin_10", priority = 15},

    -- ===========================================================
    -- ELEMENTAL-KILL TITEL
    -- ===========================================================
    {id = "elemental_lord", name = locale == "deDE" and "Elementarherr" or "Elemental Lord", nameFemale = locale == "deDE" and "Elementarherrin" or "Elemental Lord", desc = locale == "deDE" and "500 Elementare" or "500 Elementals", icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem", color = {0.7, 0.4, 0.2}, requirement = "kill_elemental_500", priority = 64},
    {id = "elemental_slayer", name = locale == "deDE" and "Elementartoeter" or "Elemental Slayer", nameFemale = locale == "deDE" and "Elementartoeterin" or "Elemental Slayer", desc = locale == "deDE" and "100 Elementare" or "100 Elementals", icon = "Interface\\Icons\\Spell_Fire_FireBolt", color = {0.6, 0.4, 0.2}, requirement = "kill_elemental_100", priority = 29},
    {id = "elementalist", name = locale == "deDE" and "Elementarjaeger" or "Elementalist", nameFemale = locale == "deDE" and "Elementarjaegerin" or "Elementalist", desc = locale == "deDE" and "25 Elementare" or "25 Elementals", icon = "Interface\\Icons\\Spell_Fire_Fire", color = {0.5, 0.4, 0.2}, requirement = "kill_elemental_25", priority = 24},

    -- ===========================================================
    -- GIANT-KILL TITEL
    -- ===========================================================
    {id = "giant_slayer", name = locale == "deDE" and "Riesentoeter" or "Giant Slayer", nameFemale = locale == "deDE" and "Riesentoeterin" or "Giant Slayer", desc = locale == "deDE" and "250 Riesen" or "250 Giants", icon = "Interface\\Icons\\INV_Stone_15", color = {0.6, 0.5, 0.4}, requirement = "kill_giant_250", priority = 63},
    {id = "giant_hunter", name = locale == "deDE" and "Riesenjaeger" or "Giant Hunter", nameFemale = locale == "deDE" and "Riesenjaegerin" or "Giant Hunter", desc = locale == "deDE" and "50 Riesen" or "50 Giants", icon = "Interface\\Icons\\INV_Misc_Foot_Centaur", color = {0.5, 0.5, 0.4}, requirement = "kill_giant_50", priority = 28},
    {id = "giant_tracker", name = locale == "deDE" and "Riesenfaehrte" or "Giant Tracker", nameFemale = locale == "deDE" and "Riesenfaehrte" or "Giant Tracker", desc = locale == "deDE" and "10 Riesen" or "10 Giants", icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", color = {0.4, 0.5, 0.4}, requirement = "kill_giant_10", priority = 14},

    -- ===========================================================
    -- GOLD-TITEL
    -- ===========================================================
    {id = "goldcap", name = locale == "deDE" and "Goldkappe" or "Gold Cap", nameFemale = locale == "deDE" and "Goldkappe" or "Gold Cap", desc = locale == "deDE" and "5.000 Gold" or "5,000 Gold", icon = "Interface\\Icons\\INV_Misc_Coin_17", color = {1, 0.84, 0}, requirement = "gold_5000", priority = 175},
    {id = "wealthy", name = locale == "deDE" and "Steinreich" or "Wealthy", nameFemale = locale == "deDE" and "Steinreich" or "Wealthy", desc = locale == "deDE" and "1.000 Gold" or "1,000 Gold", icon = "Interface\\Icons\\INV_Misc_Coin_06", color = {0.9, 0.7, 0.2}, requirement = "gold_1000", priority = 125},
    {id = "rich", name = locale == "deDE" and "Wohlhabend" or "Rich", nameFemale = locale == "deDE" and "Wohlhabend" or "Rich", desc = locale == "deDE" and "500 Gold" or "500 Gold", icon = "Interface\\Icons\\INV_Misc_Coin_05", color = {0.8, 0.6, 0.2}, requirement = "gold_500", priority = 75},
    {id = "comfortable", name = locale == "deDE" and "Gut situiert" or "Comfortable", nameFemale = locale == "deDE" and "Gut situiert" or "Comfortable", desc = locale == "deDE" and "100 Gold" or "100 Gold", icon = "Interface\\Icons\\INV_Misc_Coin_02", color = {0.7, 0.5, 0.2}, requirement = "gold_100", priority = 37},

    -- ===========================================================
    -- BERUFE-TITEL
    -- ===========================================================
    {id = "grandmaster", name = locale == "deDE" and "Grossmeister" or "Grandmaster", nameFemale = locale == "deDE" and "Grossmeisterin" or "Grandmaster", desc = locale == "deDE" and "Hauptberuf 300" or "Main profession 300", icon = "Interface\\Icons\\Trade_Engineering", color = {0.7, 0.5, 0.3}, requirement = "prof_300", priority = 170},
    {id = "artisan", name = locale == "deDE" and "Fachmann" or "Artisan", nameFemale = locale == "deDE" and "Fachfrau" or "Artisan", desc = locale == "deDE" and "Hauptberuf 225" or "Main profession 225", icon = "Interface\\Icons\\Trade_LeatherWorking", color = {0.6, 0.5, 0.3}, requirement = "prof_225", priority = 72},
    {id = "journeyman", name = locale == "deDE" and "Geselle" or "Journeyman", nameFemale = locale == "deDE" and "Gesellin" or "Journeyman", desc = locale == "deDE" and "Hauptberuf 150" or "Main profession 150", icon = "Interface\\Icons\\Trade_BlackSmithing", color = {0.5, 0.5, 0.3}, requirement = "prof_150", priority = 38},
    {id = "master_angler", name = locale == "deDE" and "Meisterangler" or "Master Angler", nameFemale = locale == "deDE" and "Meisteranglerin" or "Master Angler", desc = locale == "deDE" and "Angeln 300" or "Fishing 300", icon = "Interface\\Icons\\INV_Fishingpole_02", color = {0.3, 0.5, 0.7}, requirement = "fish_300", priority = 165},
    {id = "fisherman", name = locale == "deDE" and "Fischer" or "Fisherman", nameFemale = locale == "deDE" and "Fischerin" or "Fisherman", desc = locale == "deDE" and "Angeln 150" or "Fishing 150", icon = "Interface\\Icons\\Trade_Fishing", color = {0.3, 0.4, 0.6}, requirement = "fish_150", priority = 36},
    {id = "master_chef", name = locale == "deDE" and "Meisterkoch" or "Master Chef", nameFemale = locale == "deDE" and "Meisterkochin" or "Master Chef", desc = locale == "deDE" and "Kochen 300" or "Cooking 300", icon = "Interface\\Icons\\INV_Misc_Food_67", color = {0.7, 0.5, 0.3}, requirement = "cook_300", priority = 160},
    {id = "cook", name = locale == "deDE" and "Koch" or "Cook", nameFemale = locale == "deDE" and "Koechin" or "Cook", desc = locale == "deDE" and "Kochen 150" or "Cooking 150", icon = "Interface\\Icons\\INV_Misc_Food_15", color = {0.6, 0.4, 0.3}, requirement = "cook_150", priority = 34},
    {id = "field_medic", name = locale == "deDE" and "Feldarzt" or "Field Medic", nameFemale = locale == "deDE" and "Feldaerztin" or "Field Medic", desc = locale == "deDE" and "Erste Hilfe 300" or "First Aid 300", icon = "Interface\\Icons\\INV_Misc_Bandage_12", color = {0.8, 0.8, 0.8}, requirement = "firstaid_300", priority = 155},
    {id = "medic", name = locale == "deDE" and "Sanitaeter" or "Medic", nameFemale = locale == "deDE" and "Sanitaeterin" or "Medic", desc = locale == "deDE" and "Erste Hilfe 150" or "First Aid 150", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", color = {0.7, 0.7, 0.7}, requirement = "firstaid_150", priority = 35},
}

-- ==============================================================
-- LOOKUP-TABELLEN
-- ==============================================================

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
    if self.initialized then return end
    self.initialized = true
    GuildDeathLogDB.titles = GuildDeathLogDB.titles or {}
    self:RegisterEvents()
    self:SetupTooltipHook()  -- Tooltip-Hook aktivieren!
    self:SetupChatHook()     -- Chat-Hook für Titel am Namen!
    self:SetupNameplateHook() -- Nameplate-Hook!
    C_Timer.After(SYNC_DELAY, function() self:BroadcastTitle() end)
    C_Timer.NewTicker(BROADCAST_INTERVAL, function() self:BroadcastTitle() end)
    
    -- Bei Login: Titel von anderen anfragen
    C_Timer.After(8, function() self:RequestAllTitles() end)
    
    GDL:Debug("Titles: Modul initialisiert mit Chat + Tooltip + Nameplate Hooks")
end

function Titles:RegisterEvents()
    if self.eventFrame then return end
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:SetScript("OnEvent", function(frame, event, prefix, msg, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == TITLE_PREFIX then
            self:HandleAddonMessage(msg, sender)
        end
    end)
end

function Titles:BroadcastTitle()
    if not IsInGuild() then return end
    local selectedTitle = self:GetSelectedTitle()
    if not selectedTitle then return end
    
    -- Geschlecht: 2 = männlich, 3 = weiblich
    local sex = UnitSex("player") or 2
    local sexCode = (sex == 3) and "F" or "M"
    
    -- Format: TITLE|titleId|M oder TITLE|titleId|F
    C_ChatInfo.SendAddonMessage(TITLE_PREFIX, "TITLE|" .. selectedTitle.id .. "|" .. sexCode, "GUILD")
end

function Titles:RequestAllTitles()
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(TITLE_PREFIX, "REQUEST", "GUILD")
    GDL:Debug("Titles: Request gesendet")
end

function Titles:HandleAddonMessage(msg, sender)
    if not msg or msg == "" then return end
    local name = strsplit("-", sender)
    local myName = UnitName("player")
    
    -- Eigene Nachrichten für Request ignorieren
    if name == myName and msg == "REQUEST" then return end
    
    if msg == "REQUEST" then
        -- Jemand fragt nach Titeln - unseren senden
        C_Timer.After(math.random() * 2, function()
            self:BroadcastTitle()
        end)
        return
    end
    
    -- Titel-Update verarbeiten (Format: TITLE|id|M oder TITLE|id|F)
    local parts = {strsplit("|", msg)}
    local cmd = parts[1]
    local titleId = parts[2]
    local sexCode = parts[3] or "M"  -- Default: männlich
    
    if cmd == "TITLE" and titleId and TITLE_BY_ID[titleId] then
        -- Speichere Titel UND Geschlecht
        guildTitles[name] = {
            titleId = titleId,
            isFemale = (sexCode == "F")
        }
        GDL:Debug("Titles: " .. name .. " hat Titel " .. titleId .. " (" .. sexCode .. ")")
    elseif TITLE_BY_ID[msg] then
        -- Altes Format (nur ID) - Backward-Kompatibilität
        guildTitles[name] = {
            titleId = msg,
            isFemale = false
        }
    end
end

function Titles:GetUnlockedTitles()
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return {} end
    local unlocked = {}
    for _, title in ipairs(TITLE_DEFS) do
        if title.requirement and Milestones:IsMilestoneUnlocked(title.requirement) then
            table.insert(unlocked, title)
        end
    end
    table.sort(unlocked, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
    return unlocked
end

function Titles:GetSelectedTitle()
    local selectedId = GuildDeathLogDB.titles and GuildDeathLogDB.titles.selected
    if selectedId and TITLE_BY_ID[selectedId] then
        local Milestones = GDL:GetModule("Milestones")
        if Milestones and Milestones:IsMilestoneUnlocked(TITLE_BY_ID[selectedId].requirement) then
            return TITLE_BY_ID[selectedId]
        end
    end
    local unlocked = self:GetUnlockedTitles()
    return #unlocked > 0 and unlocked[1] or nil
end

function Titles:SelectTitle(titleId)
    if not TITLE_BY_ID[titleId] then return false end
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones or not Milestones:IsMilestoneUnlocked(TITLE_BY_ID[titleId].requirement) then return false end
    GuildDeathLogDB.titles.selected = titleId
    self:BroadcastTitle()
    return true
end

function Titles:SetSelectedTitle(titleId) return self:SelectTitle(titleId) end

-- Formatiert einen Titel mit der richtigen Geschlechtsform
function Titles:FormatTitle(title, isFemale)
    if not title then return "" end
    local c = title.color or {1, 1, 1}
    -- Wähle männliche oder weibliche Form
    local titleName = (isFemale and title.nameFemale) or title.name
    return string.format("|cff%02x%02x%02x<%s>|r", c[1]*255, c[2]*255, c[3]*255, titleName)
end

-- Formatiert einen Titel ohne Farbe (für Nameplates etc.)
function Titles:GetTitleText(title, isFemale)
    if not title then return "" end
    return (isFemale and title.nameFemale) or title.name
end

-- Holt Titel-Daten für einen Spieler (mit Geschlecht)
function Titles:GetTitleDataForPlayer(playerName)
    local data = guildTitles[playerName]
    if not data then return nil, false end
    
    -- Neue Struktur: {titleId = "...", isFemale = true/false}
    if type(data) == "table" then
        return TITLE_BY_ID[data.titleId], data.isFemale
    else
        -- Alte Struktur (nur titleId als string) - Backward-Kompatibilität
        return TITLE_BY_ID[data], false
    end
end

-- Legacy-Funktion für Kompatibilität
function Titles:GetTitleForPlayer(playerName)
    local title, _ = self:GetTitleDataForPlayer(playerName)
    return title
end

function Titles:GetFormattedName(playerName)
    local title, isFemale = self:GetTitleDataForPlayer(playerName)
    return title and (playerName .. " " .. self:FormatTitle(title, isFemale)) or playerName
end

-- ==============================================================
-- TOOLTIP INTEGRATION - Zeigt Titel bei Gildenmitgliedern!
-- ==============================================================

function Titles:SetupTooltipHook()
    -- Hook GameTooltip um Titel anzuzeigen
    GameTooltip:HookScript("OnTooltipSetUnit", function(tooltip)
        local _, unit = tooltip:GetUnit()
        if not unit then return end
        
        -- Nur für Spieler
        if not UnitIsPlayer(unit) then return end
        
        -- Nur für Gildenmitglieder
        local unitGuild = GetGuildInfo(unit)
        local myGuild = GetGuildInfo("player")
        if not unitGuild or not myGuild or unitGuild ~= myGuild then return end
        
        -- Spielername ohne Realm
        local name = UnitName(unit)
        if not name then return end
        
        -- Hat der Spieler einen Titel? (mit Geschlecht)
        local title, isFemale = self:GetTitleDataForPlayer(name)
        if not title then return end
        
        -- Richtige Geschlechtsform wählen
        local titleText = self:GetTitleText(title, isFemale)
        
        -- Titel zum Tooltip hinzufügen
        local c = title.color or {1, 1, 1}
        tooltip:AddLine(" ")
        tooltip:AddLine("<" .. titleText .. ">", c[1], c[2], c[3])
        tooltip:AddLine(title.desc, 0.7, 0.7, 0.7)
        tooltip:Show()
    end)
    
    GDL:Debug("Titles: Tooltip-Hook aktiviert")
end

-- Chat-Integration entfernt (v5.3.3)
function Titles:SetupChatHook()
    -- Deaktiviert - verursacht Probleme mit WoW Classic
end

-- Toggle Nameplate-Titel
function Titles:ToggleNameplateTitles()
    GuildDeathLogDB.settings = GuildDeathLogDB.settings or {}
    if GuildDeathLogDB.settings.nameplateTitles == nil then
        GuildDeathLogDB.settings.nameplateTitles = true
    end
    GuildDeathLogDB.settings.nameplateTitles = not GuildDeathLogDB.settings.nameplateTitles
    
    local status = GuildDeathLogDB.settings.nameplateTitles and 
        (locale == "deDE" and "|cff00FF00AN|r" or "|cff00FF00ON|r") or 
        (locale == "deDE" and "|cffFF0000AUS|r" or "|cffFF0000OFF|r")
    
    GDL:Print((locale == "deDE" and "Nameplate-Titel: " or "Nameplate Titles: ") .. status)
    
    -- Alle Titel entfernen wenn ausgeschaltet
    if not GuildDeathLogDB.settings.nameplateTitles then
        for unitToken, label in pairs(self.nameplateTitles or {}) do
            label:Hide()
        end
        self.nameplateTitles = {}
    end
end

-- ==============================================================
-- NAMEPLATE INTEGRATION - Titel über dem Kopf!
-- ==============================================================

function Titles:SetupNameplateHook()
    -- Frame für Nameplate-Updates
    local nameplateFrame = CreateFrame("Frame")
    nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    nameplateFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    
    -- Speicher für Titel-Texte
    self.nameplateTitles = {}
    
    nameplateFrame:SetScript("OnEvent", function(_, event, unitToken)
        if event == "NAME_PLATE_UNIT_ADDED" then
            self:UpdateNameplateTitle(unitToken)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then
            self:RemoveNameplateTitle(unitToken)
        end
    end)
    
    -- Periodisch alle Nameplates aktualisieren
    C_Timer.NewTicker(5, function()
        for i = 1, 40 do
            local unitToken = "nameplate" .. i
            if UnitExists(unitToken) then
                self:UpdateNameplateTitle(unitToken)
            end
        end
    end)
    
    GDL:Debug("Titles: Nameplate-Hook aktiviert")
end

function Titles:UpdateNameplateTitle(unitToken)
    -- Setting prüfen
    if GuildDeathLogDB.settings and GuildDeathLogDB.settings.nameplateTitles == false then
        return
    end
    
    if not UnitIsPlayer(unitToken) then return end
    
    -- Nur Gildenmitglieder
    local unitGuild = GetGuildInfo(unitToken)
    local myGuild = GetGuildInfo("player")
    if not unitGuild or not myGuild or unitGuild ~= myGuild then return end
    
    local name = UnitName(unitToken)
    if not name then return end
    
    local title, isFemale
    
    -- Prüfe ob es der eigene Charakter ist
    local myName = UnitName("player")
    if name == myName then
        -- EIGENER Titel - direkt vom Selected Title holen
        title = self:GetSelectedTitle()
        isFemale = self:IsPlayerFemale()
    else
        -- ANDERER Spieler - aus Sync-Daten holen
        title, isFemale = self:GetTitleDataForPlayer(name)
    end
    
    if not title then return end
    
    -- Richtige Geschlechtsform wählen
    local titleText = self:GetTitleText(title, isFemale)
    
    -- Nameplate finden
    local nameplate = C_NamePlate.GetNamePlateForUnit(unitToken)
    if not nameplate then return end
    
    -- Titel-Text erstellen oder aktualisieren
    if not self.nameplateTitles[unitToken] then
        local titleLabel = nameplate:CreateFontString(nil, "OVERLAY")
        titleLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        -- Position: Über der Nameplate (Classic-kompatibel)
        titleLabel:SetPoint("BOTTOM", nameplate, "TOP", 0, 0)
        self.nameplateTitles[unitToken] = titleLabel
    end
    
    local c = title.color or {1, 1, 1}
    self.nameplateTitles[unitToken]:SetText("<" .. titleText .. ">")
    self.nameplateTitles[unitToken]:SetTextColor(c[1], c[2], c[3])
    self.nameplateTitles[unitToken]:Show()
end

function Titles:RemoveNameplateTitle(unitToken)
    if self.nameplateTitles[unitToken] then
        self.nameplateTitles[unitToken]:Hide()
        self.nameplateTitles[unitToken] = nil
    end
end

-- Prüft ob der eigene Charakter weiblich ist
function Titles:IsPlayerFemale()
    local sex = UnitSex("player")
    return sex == 3  -- 3 = female
end

function Titles:OnMilestoneUnlocked(milestoneId)
    local title = TITLE_BY_REQUIREMENT[milestoneId]
    if not title then return end
    
    -- Eigenes Geschlecht für korrekte Anzeige
    local isFemale = self:IsPlayerFemale()
    
    GDL:Print("=======================================")
    GDL:Print("|cffFFD100" .. L_TITLE.NEW_TITLE .. "|r")
    GDL:Print(self:FormatTitle(title, isFemale))
    GDL:Print("|cffAAAAAA" .. title.desc .. "|r")
    GDL:Print("|cff888888" .. L_TITLE.USE_TITLES .. "|r")
    GDL:Print("=======================================")
    PlaySound(8959)
end

function Titles:GetStats()
    local unlocked = self:GetUnlockedTitles()
    return #unlocked, #TITLE_DEFS
end

function Titles:PrintTitles()
    local unlocked = self:GetUnlockedTitles()
    local unlockedCount, total = self:GetStats()
    local selected = self:GetSelectedTitle()
    
    -- Eigenes Geschlecht für korrekte Anzeige
    local isFemale = self:IsPlayerFemale()
    
    GDL:Print("=== " .. L_TITLE.YOUR_TITLES .. " (" .. unlockedCount .. "/" .. total .. ") ===")
    for _, title in ipairs(unlocked) do
        local marker = (selected and selected.id == title.id) and " |cff00FF00< " .. L_TITLE.ACTIVE .. "|r" or ""
        GDL:Print("  " .. self:FormatTitle(title, isFemale) .. marker)
    end
    GDL:Print("|cff888888" .. L_TITLE.USE_TITLES .. "|r")
end

function Titles:GetAllTitles() return TITLE_DEFS end
function Titles:GetTitleById(titleId) return TITLE_BY_ID[titleId] end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(4, function() Titles:Initialize() end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Titles", Titles)
