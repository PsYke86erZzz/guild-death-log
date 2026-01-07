-- ==============================================================
-- MODUL: Milestones - Charakter-Meilensteine für Hardcore
-- v5.3.3 - Classic-kompatible Berufe-Tracking + DE/EN
-- 100% Character-basiert, synchronisiert mit Gilde
-- ==============================================================

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Milestones = {}

local MILESTONE_PREFIX = "GDLMile"
local COMM_DELIM = "|"

-- ==============================================================
-- LOKALISIERUNG - ALLE STRINGS!
-- ==============================================================

local L = {}
local locale = GetLocale()

if locale == "deDE" then
    L = {
        -- System
        LEVEL_UP = "Level Up!",
        IS_NOW_LEVEL = "ist jetzt Level",
        NEW_MILESTONE = "*** NEUER MEILENSTEIN! ***",
        SECRET_DESC = "???",
        SECRET_CATEGORY = "Geheim",
        
        -- Level
        LEVEL_10 = "Level 10",
        LEVEL_10_DESC = "Hat Level 10 erreicht",
        LEVEL_20 = "Level 20",
        LEVEL_20_DESC = "Hat Level 20 erreicht",
        LEVEL_30 = "Level 30",
        LEVEL_30_DESC = "Hat Level 30 erreicht",
        LEVEL_40 = "Level 40",
        LEVEL_40_DESC = "Hat Level 40 erreicht (erstes Mount!)",
        LEVEL_50 = "Level 50",
        LEVEL_50_DESC = "Hat Level 50 erreicht",
        LEVEL_60 = "Level 60 - UNSTERBLICH!",
        LEVEL_60_DESC = "Hat Level 60 erreicht!",
        
        -- Spielzeit
        PLAYED_24H = "Ein Tag Hardcore",
        PLAYED_24H_DESC = "24 Stunden /played ueberlebt",
        PLAYED_72H = "Drei Tage Hardcore",
        PLAYED_72H_DESC = "72 Stunden /played ueberlebt",
        PLAYED_168H = "Eine Woche Hardcore",
        PLAYED_168H_DESC = "168 Stunden (7 Tage) /played ueberlebt",
        PLAYED_336H = "Zwei Wochen Hardcore",
        PLAYED_336H_DESC = "336 Stunden (14 Tage) /played ueberlebt",
        PLAYED_720H = "Ein Monat Hardcore",
        PLAYED_720H_DESC = "720 Stunden (30 Tage) /played ueberlebt!",
        
        -- Dungeons Low
        BOSS_RFC = "Flammenschlund",
        BOSS_RFC_DESC = "Taragaman der Hungrige besiegt",
        BOSS_WC = "Hoehlen des Wehklagens",
        BOSS_WC_DESC = "Mutanus der Verschlinger besiegt",
        BOSS_DM = "Die Todesminen",
        BOSS_DM_DESC = "Edwin VanCleef besiegt",
        BOSS_SFK = "Burg Schattenfang",
        BOSS_SFK_DESC = "Erzmagier Arugal besiegt",
        BOSS_BFD = "Tiefschwarze Grotte",
        BOSS_BFD_DESC = "Aku'mai besiegt",
        BOSS_STOCKS = "Das Verlies",
        BOSS_STOCKS_DESC = "Bazil Thredd besiegt",
        
        -- Dungeons Mid
        BOSS_GNOMER = "Gnomeregan",
        BOSS_GNOMER_DESC = "Mekgineer Thermaplugg besiegt",
        BOSS_SM_LIB = "SM: Bibliothek",
        BOSS_SM_LIB_DESC = "Arkanist Doan besiegt",
        BOSS_SM_ARM = "SM: Waffenkammer",
        BOSS_SM_ARM_DESC = "Herod besiegt",
        BOSS_SM_CATH = "SM: Kathedrale",
        BOSS_SM_CATH_DESC = "Hochinquisitor Mograine besiegt",
        BOSS_SM_GY = "SM: Friedhof",
        BOSS_SM_GY_DESC = "Blutmagier Thalnos besiegt",
        BOSS_RFK = "Kral der Klingenhauer",
        BOSS_RFK_DESC = "Charlga Razorflank besiegt",
        BOSS_RFD = "Huegel der Klingenhauer",
        BOSS_RFD_DESC = "Amnennar der Kaeltebringer besiegt",
        BOSS_ULDA = "Uldaman",
        BOSS_ULDA_DESC = "Archaedas besiegt",
        BOSS_ZF = "Zul'Farrak",
        BOSS_ZF_DESC = "Haeuptling Ukorz Sandscalp besiegt",
        BOSS_MARA = "Maraudon",
        BOSS_MARA_DESC = "Prinzessin Theradras besiegt",
        
        -- Dungeons High
        BOSS_ST = "Versunkener Tempel",
        BOSS_ST_DESC = "Eranikus' Schatten besiegt",
        BOSS_BRD_EMP = "BRT: Imperator",
        BOSS_BRD_EMP_DESC = "Imperator Dagran Thaurissan besiegt",
        BOSS_DM_NORTH = "Duesterbruch: Nord",
        BOSS_DM_NORTH_DESC = "Koenig Gordok besiegt",
        BOSS_DM_EAST = "Duesterbruch: Ost",
        BOSS_DM_EAST_DESC = "Alzzin der Wildformer besiegt",
        BOSS_DM_WEST = "Duesterbruch: West",
        BOSS_DM_WEST_DESC = "Prinz Tortheldrin besiegt",
        BOSS_LBRS = "Untere Schwarzfelsspitze",
        BOSS_LBRS_DESC = "Kriegsherr Voone besiegt",
        BOSS_UBRS = "Obere Schwarzfelsspitze",
        BOSS_UBRS_DESC = "General Drakkisath besiegt",
        BOSS_SCHOLO = "Scholomance",
        BOSS_SCHOLO_DESC = "Dunkelmeister Gandling besiegt",
        BOSS_STRAT_UD = "Stratholme: Untot",
        BOSS_STRAT_UD_DESC = "Baron Rivendare besiegt",
        BOSS_STRAT_LIVE = "Stratholme: Lebend",
        BOSS_STRAT_LIVE_DESC = "Balnazzar besiegt",
        
        -- Raids
        BOSS_ONY = "Onyxia",
        BOSS_ONY_DESC = "Onyxia besiegt!",
        BOSS_MC_RAG = "Geschmolzener Kern: Ragnaros",
        BOSS_MC_RAG_DESC = "Ragnaros besiegt!",
        BOSS_BWL_NEF = "Pechschwingenhort: Nefarian",
        BOSS_BWL_NEF_DESC = "Nefarian besiegt!",
        BOSS_ZG_HAKKAR = "Zul'Gurub: Hakkar",
        BOSS_ZG_HAKKAR_DESC = "Hakkar besiegt!",
        BOSS_AQ20 = "AQ20: Ossirian",
        BOSS_AQ20_DESC = "Ossirian besiegt!",
        BOSS_AQ40 = "AQ40: C'Thun",
        BOSS_AQ40_DESC = "C'Thun besiegt!",
        BOSS_NAXX = "Naxxramas: Kel'Thuzad",
        BOSS_NAXX_DESC = "Kel'Thuzad besiegt!",
        
        -- Meta
        META_LOW_DUNGEONS = "Anfaenger-Kerkermeister",
        META_LOW_DUNGEONS_DESC = "Alle Lowlevel-Dungeons (10-25) abgeschlossen",
        META_MID_DUNGEONS = "Kerkermeister",
        META_MID_DUNGEONS_DESC = "Alle Midlevel-Dungeons (25-45) abgeschlossen",
        META_HIGH_DUNGEONS = "Meister der Kerker",
        META_HIGH_DUNGEONS_DESC = "Alle Highlevel-Dungeons (45-60) abgeschlossen",
        META_ALL_DUNGEONS = "Herr der Dungeons",
        META_ALL_DUNGEONS_DESC = "ALLE Dungeon-Endbosse besiegt!",
        META_ALL_RAIDS = "Raidmeister",
        META_ALL_RAIDS_DESC = "Alle Raid-Endbosse besiegt!",
        META_DUNGEON_LEGEND = "Dungeon-Legende",
        META_DUNGEON_LEGEND_DESC = "Alle Dungeons UND Raids gemeistert!",
        META_ALL_SECONDARY = "Alleskoenner",
        META_ALL_SECONDARY_DESC = "Alle Nebenberufe auf 300",
        META_COMPLETE_CRAFTER = "Der Perfekte Handwerker",
        META_COMPLETE_CRAFTER_DESC = "ALLE Berufe auf 300!",
        META_IMMORTAL_VET = "Unsterblicher Veteran",
        META_IMMORTAL_VET_DESC = "Level 60 + 7 Tage /played",
        META_LEGEND = "Legende von Azeroth",
        META_LEGEND_DESC = "Level 60 + Alle Dungeons + 5.000 Kills",
        META_TRUE_IMMORTAL = "Wahrer Unsterblicher",
        META_TRUE_IMMORTAL_DESC = "Level 60 + Alle Raids + 30 Tage /played",
        META_GODSLAYER = "Goetterschlaechter",
        META_GODSLAYER_DESC = "C'Thun UND Kel'Thuzad besiegt!",
        META_PERFECT = "Der Perfektionist",
        META_PERFECT_DESC = "Level 60 + Alle Berufe 300 + Alle Dungeons",
        
        -- Berufe
        PROF_150 = "Geselle",
        PROF_150_DESC = "Einen Beruf auf 150 gebracht",
        PROF_225 = "Experte",
        PROF_225_DESC = "Einen Beruf auf 225 gebracht",
        PROF_300 = "Meister",
        PROF_300_DESC = "Einen Beruf auf 300 gebracht!",
        FISH_150 = "Angler",
        FISH_150_DESC = "Angeln auf 150",
        FISH_300 = "Meisterangler",
        FISH_300_DESC = "Angeln auf 300",
        COOK_150 = "Koch",
        COOK_150_DESC = "Kochen auf 150",
        COOK_300 = "Meisterkoch",
        COOK_300_DESC = "Kochen auf 300",
        FIRST_150 = "Sanitaeter",
        FIRST_150_DESC = "Erste Hilfe auf 150",
        FIRST_300 = "Meister-Ersthelfer",
        FIRST_300_DESC = "Erste Hilfe auf 300",
        
        -- Total Kills
        KILLS_1000 = "Tausendtoeter",
        KILLS_1000_DESC = "1.000 Kreaturen insgesamt getoetet",
        KILLS_5000 = "Schlachtmeister",
        KILLS_5000_DESC = "5.000 Kreaturen insgesamt getoetet",
        KILLS_10000 = "Todesengel",
        KILLS_10000_DESC = "10.000 Kreaturen insgesamt getoetet!",
        KILLS_25000 = "Schrecken von Azeroth",
        KILLS_25000_DESC = "25.000 Kreaturen insgesamt getoetet!!",
        KILLS_50000 = "Apokalypse",
        KILLS_50000_DESC = "50.000 Kreaturen insgesamt getoetet!!!",
        
        -- Gold
        GOLD_100 = "Wohlhabend",
        GOLD_100_DESC = "100 Gold angesammelt",
        GOLD_500 = "Reich",
        GOLD_500_DESC = "500 Gold angesammelt",
        GOLD_1000 = "Steinreich",
        GOLD_1000_DESC = "1.000 Gold angesammelt!",
        GOLD_5000 = "Goldener Drache",
        GOLD_5000_DESC = "5.000 Gold angesammelt!",
        
        -- Kreaturtypen
        HUMANOID_25 = "Wegelagerer",
        HUMANOID_25_DESC = "25 Humanoide getoetet",
        HUMANOID_100 = "Banditenjaeger",
        HUMANOID_100_DESC = "100 Humanoide getoetet",
        HUMANOID_500 = "Kopfgeldjaeger",
        HUMANOID_500_DESC = "500 Humanoide getoetet",
        HUMANOID_2000 = "Schlaechter",
        HUMANOID_2000_DESC = "2.000 Humanoide getoetet!",
        
        BEAST_25 = "Jaeger",
        BEAST_25_DESC = "25 Wildtiere getoetet",
        BEAST_100 = "Wildnisjaeger",
        BEAST_100_DESC = "100 Wildtiere getoetet",
        BEAST_500 = "Grosswildjaeger",
        BEAST_500_DESC = "500 Wildtiere getoetet",
        BEAST_2000 = "Bestienmeister",
        BEAST_2000_DESC = "2.000 Wildtiere getoetet!",
        
        UNDEAD_25 = "Grabschaender",
        UNDEAD_25_DESC = "25 Untote getoetet",
        UNDEAD_100 = "Untotenjaeger",
        UNDEAD_100_DESC = "100 Untote getoetet",
        UNDEAD_500 = "Untotenschlaechter",
        UNDEAD_500_DESC = "500 Untote getoetet",
        UNDEAD_1000 = "Lichbane",
        UNDEAD_1000_DESC = "1.000 Untote getoetet",
        UNDEAD_5000 = "Seuchenreiniger",
        UNDEAD_5000_DESC = "5.000 Untote getoetet!",
        
        DEMON_25 = "Daemonentoeter",
        DEMON_25_DESC = "25 Daemonen getoetet",
        DEMON_100 = "Daemonenbekaempfer",
        DEMON_100_DESC = "100 Daemonen getoetet",
        DEMON_500 = "Daemonenjaeger",
        DEMON_500_DESC = "500 Daemonen getoetet",
        DEMON_1000 = "Eredarbane",
        DEMON_1000_DESC = "1.000 Daemonen getoetet!",
        
        ELEMENTAL_25 = "Elementarjaeger",
        ELEMENTAL_25_DESC = "25 Elementare getoetet",
        ELEMENTAL_100 = "Funkensammler",
        ELEMENTAL_100_DESC = "100 Elementare getoetet",
        ELEMENTAL_500 = "Elementarbrecher",
        ELEMENTAL_500_DESC = "500 Elementare getoetet!",
        
        DRAGON_10 = "Welpentoeter",
        DRAGON_10_DESC = "10 Drachkin getoetet",
        DRAGON_50 = "Schuppensammler",
        DRAGON_50_DESC = "50 Drachkin getoetet",
        DRAGON_250 = "Drachenjaeger",
        DRAGON_250_DESC = "250 Drachkin getoetet",
        DRAGON_1000 = "Drachenbane",
        DRAGON_1000_DESC = "1.000 Drachkin getoetet!",
        
        GIANT_10 = "Riesentoeter",
        GIANT_10_DESC = "10 Riesen getoetet",
        GIANT_50 = "Riesen-Bezwinger",
        GIANT_50_DESC = "50 Riesen getoetet",
        GIANT_250 = "Titanentoeter",
        GIANT_250_DESC = "250 Riesen getoetet!",
    }
else
    -- English (Default)
    L = {
        -- System
        LEVEL_UP = "Level Up!",
        IS_NOW_LEVEL = "is now Level",
        NEW_MILESTONE = "*** NEW MILESTONE! ***",
        SECRET_DESC = "???",
        SECRET_CATEGORY = "Secret",
        
        -- Level
        LEVEL_10 = "Level 10",
        LEVEL_10_DESC = "Reached Level 10",
        LEVEL_20 = "Level 20",
        LEVEL_20_DESC = "Reached Level 20",
        LEVEL_30 = "Level 30",
        LEVEL_30_DESC = "Reached Level 30",
        LEVEL_40 = "Level 40",
        LEVEL_40_DESC = "Reached Level 40 (first mount!)",
        LEVEL_50 = "Level 50",
        LEVEL_50_DESC = "Reached Level 50",
        LEVEL_60 = "Level 60 - IMMORTAL!",
        LEVEL_60_DESC = "Reached Level 60!",
        
        -- Playtime
        PLAYED_24H = "One Day Hardcore",
        PLAYED_24H_DESC = "Survived 24 hours /played",
        PLAYED_72H = "Three Days Hardcore",
        PLAYED_72H_DESC = "Survived 72 hours /played",
        PLAYED_168H = "One Week Hardcore",
        PLAYED_168H_DESC = "Survived 168 hours (7 days) /played",
        PLAYED_336H = "Two Weeks Hardcore",
        PLAYED_336H_DESC = "Survived 336 hours (14 days) /played",
        PLAYED_720H = "One Month Hardcore",
        PLAYED_720H_DESC = "Survived 720 hours (30 days) /played!",
        
        -- Dungeons Low
        BOSS_RFC = "Ragefire Chasm",
        BOSS_RFC_DESC = "Defeated Taragaman the Hungerer",
        BOSS_WC = "Wailing Caverns",
        BOSS_WC_DESC = "Defeated Mutanus the Devourer",
        BOSS_DM = "The Deadmines",
        BOSS_DM_DESC = "Defeated Edwin VanCleef",
        BOSS_SFK = "Shadowfang Keep",
        BOSS_SFK_DESC = "Defeated Archmage Arugal",
        BOSS_BFD = "Blackfathom Deeps",
        BOSS_BFD_DESC = "Defeated Aku'mai",
        BOSS_STOCKS = "The Stockade",
        BOSS_STOCKS_DESC = "Defeated Bazil Thredd",
        
        -- Dungeons Mid
        BOSS_GNOMER = "Gnomeregan",
        BOSS_GNOMER_DESC = "Defeated Mekgineer Thermaplugg",
        BOSS_SM_LIB = "SM: Library",
        BOSS_SM_LIB_DESC = "Defeated Arcanist Doan",
        BOSS_SM_ARM = "SM: Armory",
        BOSS_SM_ARM_DESC = "Defeated Herod",
        BOSS_SM_CATH = "SM: Cathedral",
        BOSS_SM_CATH_DESC = "Defeated High Inquisitor Mograine",
        BOSS_SM_GY = "SM: Graveyard",
        BOSS_SM_GY_DESC = "Defeated Bloodmage Thalnos",
        BOSS_RFK = "Razorfen Kraul",
        BOSS_RFK_DESC = "Defeated Charlga Razorflank",
        BOSS_RFD = "Razorfen Downs",
        BOSS_RFD_DESC = "Defeated Amnennar the Coldbringer",
        BOSS_ULDA = "Uldaman",
        BOSS_ULDA_DESC = "Defeated Archaedas",
        BOSS_ZF = "Zul'Farrak",
        BOSS_ZF_DESC = "Defeated Chief Ukorz Sandscalp",
        BOSS_MARA = "Maraudon",
        BOSS_MARA_DESC = "Defeated Princess Theradras",
        
        -- Dungeons High
        BOSS_ST = "Sunken Temple",
        BOSS_ST_DESC = "Defeated Shade of Eranikus",
        BOSS_BRD_EMP = "BRD: Emperor",
        BOSS_BRD_EMP_DESC = "Defeated Emperor Dagran Thaurissan",
        BOSS_DM_NORTH = "Dire Maul: North",
        BOSS_DM_NORTH_DESC = "Defeated King Gordok",
        BOSS_DM_EAST = "Dire Maul: East",
        BOSS_DM_EAST_DESC = "Defeated Alzzin the Wildshaper",
        BOSS_DM_WEST = "Dire Maul: West",
        BOSS_DM_WEST_DESC = "Defeated Prince Tortheldrin",
        BOSS_LBRS = "Lower Blackrock Spire",
        BOSS_LBRS_DESC = "Defeated War Master Voone",
        BOSS_UBRS = "Upper Blackrock Spire",
        BOSS_UBRS_DESC = "Defeated General Drakkisath",
        BOSS_SCHOLO = "Scholomance",
        BOSS_SCHOLO_DESC = "Defeated Darkmaster Gandling",
        BOSS_STRAT_UD = "Stratholme: Undead",
        BOSS_STRAT_UD_DESC = "Defeated Baron Rivendare",
        BOSS_STRAT_LIVE = "Stratholme: Living",
        BOSS_STRAT_LIVE_DESC = "Defeated Balnazzar",
        
        -- Raids
        BOSS_ONY = "Onyxia",
        BOSS_ONY_DESC = "Defeated Onyxia!",
        BOSS_MC_RAG = "Molten Core: Ragnaros",
        BOSS_MC_RAG_DESC = "Defeated Ragnaros!",
        BOSS_BWL_NEF = "Blackwing Lair: Nefarian",
        BOSS_BWL_NEF_DESC = "Defeated Nefarian!",
        BOSS_ZG_HAKKAR = "Zul'Gurub: Hakkar",
        BOSS_ZG_HAKKAR_DESC = "Defeated Hakkar!",
        BOSS_AQ20 = "AQ20: Ossirian",
        BOSS_AQ20_DESC = "Defeated Ossirian!",
        BOSS_AQ40 = "AQ40: C'Thun",
        BOSS_AQ40_DESC = "Defeated C'Thun!",
        BOSS_NAXX = "Naxxramas: Kel'Thuzad",
        BOSS_NAXX_DESC = "Defeated Kel'Thuzad!",
        
        -- Meta
        META_LOW_DUNGEONS = "Apprentice Dungeon Master",
        META_LOW_DUNGEONS_DESC = "Completed all lowlevel dungeons (10-25)",
        META_MID_DUNGEONS = "Dungeon Master",
        META_MID_DUNGEONS_DESC = "Completed all midlevel dungeons (25-45)",
        META_HIGH_DUNGEONS = "Master of Dungeons",
        META_HIGH_DUNGEONS_DESC = "Completed all highlevel dungeons (45-60)",
        META_ALL_DUNGEONS = "Lord of Dungeons",
        META_ALL_DUNGEONS_DESC = "Defeated ALL dungeon end bosses!",
        META_ALL_RAIDS = "Raid Master",
        META_ALL_RAIDS_DESC = "Defeated all raid end bosses!",
        META_DUNGEON_LEGEND = "Dungeon Legend",
        META_DUNGEON_LEGEND_DESC = "Mastered all dungeons AND raids!",
        META_ALL_SECONDARY = "Jack of All Trades",
        META_ALL_SECONDARY_DESC = "All secondary professions at 300",
        META_COMPLETE_CRAFTER = "The Perfect Crafter",
        META_COMPLETE_CRAFTER_DESC = "ALL professions at 300!",
        META_IMMORTAL_VET = "Immortal Veteran",
        META_IMMORTAL_VET_DESC = "Level 60 + 7 days /played",
        META_LEGEND = "Legend of Azeroth",
        META_LEGEND_DESC = "Level 60 + All Dungeons + 5,000 Kills",
        META_TRUE_IMMORTAL = "True Immortal",
        META_TRUE_IMMORTAL_DESC = "Level 60 + All Raids + 30 days /played",
        META_GODSLAYER = "Godslayer",
        META_GODSLAYER_DESC = "Defeated C'Thun AND Kel'Thuzad!",
        META_PERFECT = "The Perfectionist",
        META_PERFECT_DESC = "Level 60 + All Profs 300 + All Dungeons",
        
        -- Professions
        PROF_150 = "Journeyman",
        PROF_150_DESC = "Profession at 150",
        PROF_225 = "Expert",
        PROF_225_DESC = "Profession at 225",
        PROF_300 = "Artisan",
        PROF_300_DESC = "Profession at 300!",
        FISH_150 = "Angler",
        FISH_150_DESC = "Fishing at 150",
        FISH_300 = "Master Angler",
        FISH_300_DESC = "Fishing at 300",
        COOK_150 = "Cook",
        COOK_150_DESC = "Cooking at 150",
        COOK_300 = "Master Chef",
        COOK_300_DESC = "Cooking at 300",
        FIRST_150 = "Medic",
        FIRST_150_DESC = "First Aid at 150",
        FIRST_300 = "Master Medic",
        FIRST_300_DESC = "First Aid at 300",
        
        -- Total Kills
        KILLS_1000 = "Thousand Slayer",
        KILLS_1000_DESC = "Killed 1,000 creatures total",
        KILLS_5000 = "Battle Master",
        KILLS_5000_DESC = "Killed 5,000 creatures total",
        KILLS_10000 = "Angel of Death",
        KILLS_10000_DESC = "Killed 10,000 creatures total!",
        KILLS_25000 = "Terror of Azeroth",
        KILLS_25000_DESC = "Killed 25,000 creatures total!!",
        KILLS_50000 = "Apocalypse",
        KILLS_50000_DESC = "Killed 50,000 creatures total!!!",
        
        -- Gold
        GOLD_100 = "Wealthy",
        GOLD_100_DESC = "Accumulated 100 gold",
        GOLD_500 = "Rich",
        GOLD_500_DESC = "Accumulated 500 gold",
        GOLD_1000 = "Filthy Rich",
        GOLD_1000_DESC = "Accumulated 1,000 gold!",
        GOLD_5000 = "Golden Dragon",
        GOLD_5000_DESC = "Accumulated 5,000 gold!",
        
        -- Creature Types
        HUMANOID_25 = "Highwayman",
        HUMANOID_25_DESC = "Killed 25 humanoids",
        HUMANOID_100 = "Bandit Hunter",
        HUMANOID_100_DESC = "Killed 100 humanoids",
        HUMANOID_500 = "Bounty Hunter",
        HUMANOID_500_DESC = "Killed 500 humanoids",
        HUMANOID_2000 = "Slaughterer",
        HUMANOID_2000_DESC = "Killed 2,000 humanoids!",
        
        BEAST_25 = "Hunter",
        BEAST_25_DESC = "Killed 25 beasts",
        BEAST_100 = "Wilderness Hunter",
        BEAST_100_DESC = "Killed 100 beasts",
        BEAST_500 = "Big Game Hunter",
        BEAST_500_DESC = "Killed 500 beasts",
        BEAST_2000 = "Beast Master",
        BEAST_2000_DESC = "Killed 2,000 beasts!",
        
        UNDEAD_25 = "Grave Defiler",
        UNDEAD_25_DESC = "Killed 25 undead",
        UNDEAD_100 = "Undead Hunter",
        UNDEAD_100_DESC = "Killed 100 undead",
        UNDEAD_500 = "Undead Slayer",
        UNDEAD_500_DESC = "Killed 500 undead",
        UNDEAD_1000 = "Lichbane",
        UNDEAD_1000_DESC = "Killed 1,000 undead",
        UNDEAD_5000 = "Plague Cleanser",
        UNDEAD_5000_DESC = "Killed 5,000 undead!",
        
        DEMON_25 = "Demon Slayer",
        DEMON_25_DESC = "Killed 25 demons",
        DEMON_100 = "Demon Fighter",
        DEMON_100_DESC = "Killed 100 demons",
        DEMON_500 = "Demon Hunter",
        DEMON_500_DESC = "Killed 500 demons",
        DEMON_1000 = "Eredar Bane",
        DEMON_1000_DESC = "Killed 1,000 demons!",
        
        ELEMENTAL_25 = "Elemental Hunter",
        ELEMENTAL_25_DESC = "Killed 25 elementals",
        ELEMENTAL_100 = "Spark Collector",
        ELEMENTAL_100_DESC = "Killed 100 elementals",
        ELEMENTAL_500 = "Elemental Breaker",
        ELEMENTAL_500_DESC = "Killed 500 elementals!",
        
        DRAGON_10 = "Whelp Slayer",
        DRAGON_10_DESC = "Killed 10 dragonkin",
        DRAGON_50 = "Scale Collector",
        DRAGON_50_DESC = "Killed 50 dragonkin",
        DRAGON_250 = "Dragon Hunter",
        DRAGON_250_DESC = "Killed 250 dragonkin",
        DRAGON_1000 = "Dragonbane",
        DRAGON_1000_DESC = "Killed 1,000 dragonkin!",
        
        GIANT_10 = "Giant Slayer",
        GIANT_10_DESC = "Killed 10 giants",
        GIANT_50 = "Giant Conqueror",
        GIANT_50_DESC = "Killed 50 giants",
        GIANT_250 = "Titan Slayer",
        GIANT_250_DESC = "Killed 250 giants!",
    }
end

-- ==============================================================
-- MEILENSTEIN-DEFINITIONEN (100% LOKALISIERT)
-- ==============================================================

local MILESTONE_DEFS = {
    -- Level
    {id = "level_10", name = L.LEVEL_10, desc = L.LEVEL_10_DESC, icon = "Interface\\Icons\\Spell_Holy_WordFortitude", type = "level", threshold = 10, category = "level"},
    {id = "level_20", name = L.LEVEL_20, desc = L.LEVEL_20_DESC, icon = "Interface\\Icons\\Spell_Holy_GreaterHeal", type = "level", threshold = 20, category = "level"},
    {id = "level_30", name = L.LEVEL_30, desc = L.LEVEL_30_DESC, icon = "Interface\\Icons\\INV_Shield_06", type = "level", threshold = 30, category = "level"},
    {id = "level_40", name = L.LEVEL_40, desc = L.LEVEL_40_DESC, icon = "Interface\\Icons\\Ability_Mount_RidingHorse", type = "level", threshold = 40, category = "level"},
    {id = "level_50", name = L.LEVEL_50, desc = L.LEVEL_50_DESC, icon = "Interface\\Icons\\INV_Shield_07", type = "level", threshold = 50, category = "level"},
    {id = "level_60", name = L.LEVEL_60, desc = L.LEVEL_60_DESC, icon = "Interface\\Icons\\INV_Crown_01", type = "level", threshold = 60, category = "level"},
    
    -- Spielzeit
    {id = "played_24h", name = L.PLAYED_24H, desc = L.PLAYED_24H_DESC, icon = "Interface\\Icons\\Spell_Nature_TimeStop", type = "playtime", threshold = 86400, category = "survival"},
    {id = "played_72h", name = L.PLAYED_72H, desc = L.PLAYED_72H_DESC, icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", type = "playtime", threshold = 259200, category = "survival"},
    {id = "played_168h", name = L.PLAYED_168H, desc = L.PLAYED_168H_DESC, icon = "Interface\\Icons\\INV_Misc_PocketWatch_02", type = "playtime", threshold = 604800, category = "survival"},
    {id = "played_336h", name = L.PLAYED_336H, desc = L.PLAYED_336H_DESC, icon = "Interface\\Icons\\Spell_Holy_BorrowedTime", type = "playtime", threshold = 1209600, category = "survival"},
    {id = "played_720h", name = L.PLAYED_720H, desc = L.PLAYED_720H_DESC, icon = "Interface\\Icons\\Achievement_GuildPerk_WorkingOvertime_Rank2", type = "playtime", threshold = 2592000, category = "survival"},
    
    -- Dungeons Low (10-25)
    {id = "boss_rfc", name = L.BOSS_RFC, desc = L.BOSS_RFC_DESC, icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard", type = "boss", bossId = 11520, category = "dungeon", tier = "low"},
    {id = "boss_wc", name = L.BOSS_WC, desc = L.BOSS_WC_DESC, icon = "Interface\\Icons\\INV_Misc_MonsterHead_01", type = "boss", bossId = 3654, category = "dungeon", tier = "low"},
    {id = "boss_dm", name = L.BOSS_DM, desc = L.BOSS_DM_DESC, icon = "Interface\\Icons\\INV_Helmet_25", type = "boss", bossId = 639, category = "dungeon", tier = "low"},
    {id = "boss_sfk", name = L.BOSS_SFK, desc = L.BOSS_SFK_DESC, icon = "Interface\\Icons\\Spell_Shadow_Charm", type = "boss", bossId = 4275, category = "dungeon", tier = "low"},
    {id = "boss_bfd", name = L.BOSS_BFD, desc = L.BOSS_BFD_DESC, icon = "Interface\\Icons\\Spell_Shadow_DeathScream", type = "boss", bossId = 4829, category = "dungeon", tier = "low"},
    {id = "boss_stocks", name = L.BOSS_STOCKS, desc = L.BOSS_STOCKS_DESC, icon = "Interface\\Icons\\INV_Misc_Key_13", type = "boss", bossId = 1716, category = "dungeon", tier = "low"},
    
    -- Dungeons Mid (25-45)
    {id = "boss_gnomer", name = L.BOSS_GNOMER, desc = L.BOSS_GNOMER_DESC, icon = "Interface\\Icons\\INV_Gizmo_02", type = "boss", bossId = 7800, category = "dungeon", tier = "mid"},
    {id = "boss_sm_lib", name = L.BOSS_SM_LIB, desc = L.BOSS_SM_LIB_DESC, icon = "Interface\\Icons\\INV_Misc_Book_07", type = "boss", bossId = 6487, category = "dungeon", tier = "mid"},
    {id = "boss_sm_arm", name = L.BOSS_SM_ARM, desc = L.BOSS_SM_ARM_DESC, icon = "Interface\\Icons\\INV_Axe_12", type = "boss", bossId = 3975, category = "dungeon", tier = "mid"},
    {id = "boss_sm_cath", name = L.BOSS_SM_CATH, desc = L.BOSS_SM_CATH_DESC, icon = "Interface\\Icons\\INV_Sword_27", type = "boss", bossId = 3976, category = "dungeon", tier = "mid"},
    {id = "boss_sm_gy", name = L.BOSS_SM_GY, desc = L.BOSS_SM_GY_DESC, icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", type = "boss", bossId = 4543, category = "dungeon", tier = "mid"},
    {id = "boss_rfk", name = L.BOSS_RFK, desc = L.BOSS_RFK_DESC, icon = "Interface\\Icons\\INV_Misc_Head_Gnoll_01", type = "boss", bossId = 4421, category = "dungeon", tier = "mid"},
    {id = "boss_rfd", name = L.BOSS_RFD, desc = L.BOSS_RFD_DESC, icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", type = "boss", bossId = 7358, category = "dungeon", tier = "mid"},
    {id = "boss_ulda", name = L.BOSS_ULDA, desc = L.BOSS_ULDA_DESC, icon = "Interface\\Icons\\INV_Misc_Gem_Stone_01", type = "boss", bossId = 2748, category = "dungeon", tier = "mid"},
    {id = "boss_zf", name = L.BOSS_ZF, desc = L.BOSS_ZF_DESC, icon = "Interface\\Icons\\INV_Helmet_53", type = "boss", bossId = 7267, category = "dungeon", tier = "mid"},
    {id = "boss_mara", name = L.BOSS_MARA, desc = L.BOSS_MARA_DESC, icon = "Interface\\Icons\\Spell_Nature_EarthElemental_Totem", type = "boss", bossId = 12201, category = "dungeon", tier = "mid"},
    
    -- Dungeons High (45-60)
    {id = "boss_st", name = L.BOSS_ST, desc = L.BOSS_ST_DESC, icon = "Interface\\Icons\\Spell_Shadow_GatherShadows", type = "boss", bossId = 5709, category = "dungeon", tier = "high"},
    {id = "boss_brd_emp", name = L.BOSS_BRD_EMP, desc = L.BOSS_BRD_EMP_DESC, icon = "Interface\\Icons\\INV_Hammer_Unique_Sulfuron", type = "boss", bossId = 9019, category = "dungeon", tier = "high"},
    {id = "boss_dm_north", name = L.BOSS_DM_NORTH, desc = L.BOSS_DM_NORTH_DESC, icon = "Interface\\Icons\\INV_Misc_MonsterHead_02", type = "boss", bossId = 11501, category = "dungeon", tier = "high"},
    {id = "boss_dm_east", name = L.BOSS_DM_EAST, desc = L.BOSS_DM_EAST_DESC, icon = "Interface\\Icons\\Spell_Nature_Regeneration", type = "boss", bossId = 11492, category = "dungeon", tier = "high"},
    {id = "boss_dm_west", name = L.BOSS_DM_WEST, desc = L.BOSS_DM_WEST_DESC, icon = "Interface\\Icons\\INV_Sword_26", type = "boss", bossId = 11486, category = "dungeon", tier = "high"},
    {id = "boss_lbrs", name = L.BOSS_LBRS, desc = L.BOSS_LBRS_DESC, icon = "Interface\\Icons\\INV_Misc_MonsterHead_03", type = "boss", bossId = 9237, category = "dungeon", tier = "high"},
    {id = "boss_ubrs", name = L.BOSS_UBRS, desc = L.BOSS_UBRS_DESC, icon = "Interface\\Icons\\Spell_Fire_Lavaspawn", type = "boss", bossId = 10363, category = "dungeon", tier = "high"},
    {id = "boss_scholo", name = L.BOSS_SCHOLO, desc = L.BOSS_SCHOLO_DESC, icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "boss", bossId = 1853, category = "dungeon", tier = "high"},
    {id = "boss_strat_ud", name = L.BOSS_STRAT_UD, desc = L.BOSS_STRAT_UD_DESC, icon = "Interface\\Icons\\INV_Sword_25", type = "boss", bossId = 10440, category = "dungeon", tier = "high"},
    {id = "boss_strat_live", name = L.BOSS_STRAT_LIVE, desc = L.BOSS_STRAT_LIVE_DESC, icon = "Interface\\Icons\\Spell_Shadow_PainSpike", type = "boss", bossId = 10813, category = "dungeon", tier = "high"},
    
    -- Raids
    {id = "boss_ony", name = L.BOSS_ONY, desc = L.BOSS_ONY_DESC, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", type = "boss", bossId = 10184, category = "raid"},
    {id = "boss_mc_rag", name = L.BOSS_MC_RAG, desc = L.BOSS_MC_RAG_DESC, icon = "Interface\\Icons\\Spell_Fire_Ragnaros_Lavabolt", type = "boss", bossId = 11502, category = "raid"},
    {id = "boss_bwl_nef", name = L.BOSS_BWL_NEF, desc = L.BOSS_BWL_NEF_DESC, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "boss", bossId = 11583, category = "raid"},
    {id = "boss_zg_hakkar", name = L.BOSS_ZG_HAKKAR, desc = L.BOSS_ZG_HAKKAR_DESC, icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "boss", bossId = 14834, category = "raid"},
    {id = "boss_aq20_ossirian", name = L.BOSS_AQ20, desc = L.BOSS_AQ20_DESC, icon = "Interface\\Icons\\INV_Jewelry_Ring_40", type = "boss", bossId = 15339, category = "raid"},
    {id = "boss_aq40_cthun", name = L.BOSS_AQ40, desc = L.BOSS_AQ40_DESC, icon = "Interface\\Icons\\Spell_Nature_WispHeal", type = "boss", bossId = 15727, category = "raid"},
    {id = "boss_naxx_kt", name = L.BOSS_NAXX, desc = L.BOSS_NAXX_DESC, icon = "Interface\\Icons\\INV_Trinket_Naxxramas06", type = "boss", bossId = 15990, category = "raid"},
    
    -- Meta-Achievements
    {id = "meta_low_dungeons", name = L.META_LOW_DUNGEONS, desc = L.META_LOW_DUNGEONS_DESC, icon = "Interface\\Icons\\INV_Misc_Key_03", type = "meta", requirements = {"boss_rfc", "boss_wc", "boss_dm", "boss_sfk", "boss_bfd", "boss_stocks"}, category = "meta"},
    {id = "meta_mid_dungeons", name = L.META_MID_DUNGEONS, desc = L.META_MID_DUNGEONS_DESC, icon = "Interface\\Icons\\INV_Misc_Key_07", type = "meta", requirements = {"boss_gnomer", "boss_sm_lib", "boss_sm_arm", "boss_sm_cath", "boss_sm_gy", "boss_rfk", "boss_rfd", "boss_ulda", "boss_zf", "boss_mara"}, category = "meta"},
    {id = "meta_high_dungeons", name = L.META_HIGH_DUNGEONS, desc = L.META_HIGH_DUNGEONS_DESC, icon = "Interface\\Icons\\INV_Misc_Key_14", type = "meta", requirements = {"boss_st", "boss_brd_emp", "boss_dm_north", "boss_dm_east", "boss_dm_west", "boss_lbrs", "boss_ubrs", "boss_scholo", "boss_strat_ud", "boss_strat_live"}, category = "meta"},
    {id = "meta_all_dungeons", name = L.META_ALL_DUNGEONS, desc = L.META_ALL_DUNGEONS_DESC, icon = "Interface\\Icons\\INV_Jewelry_Talisman_08", type = "meta", requirements = {"meta_low_dungeons", "meta_mid_dungeons", "meta_high_dungeons"}, category = "meta"},
    {id = "meta_all_raids", name = L.META_ALL_RAIDS, desc = L.META_ALL_RAIDS_DESC, icon = "Interface\\Icons\\INV_Helmet_06", type = "meta", requirements = {"boss_ony", "boss_mc_rag", "boss_bwl_nef", "boss_zg_hakkar", "boss_aq20_ossirian", "boss_aq40_cthun", "boss_naxx_kt"}, category = "meta"},
    {id = "meta_dungeon_legend", name = L.META_DUNGEON_LEGEND, desc = L.META_DUNGEON_LEGEND_DESC, icon = "Interface\\Icons\\Spell_Holy_ChampionsBond", type = "meta", requirements = {"meta_all_dungeons", "meta_all_raids"}, category = "meta"},
    
    -- Berufe
    {id = "prof_150", name = L.PROF_150, desc = L.PROF_150_DESC, icon = "Interface\\Icons\\Trade_BlackSmithing", type = "profession", threshold = 150, category = "profession"},
    {id = "prof_225", name = L.PROF_225, desc = L.PROF_225_DESC, icon = "Interface\\Icons\\Trade_LeatherWorking", type = "profession", threshold = 225, category = "profession"},
    {id = "prof_300", name = L.PROF_300, desc = L.PROF_300_DESC, icon = "Interface\\Icons\\Trade_Engineering", type = "profession", threshold = 300, category = "profession"},
    {id = "fish_150", name = L.FISH_150, desc = L.FISH_150_DESC, icon = "Interface\\Icons\\Trade_Fishing", type = "fishing", threshold = 150, category = "profession"},
    {id = "fish_300", name = L.FISH_300, desc = L.FISH_300_DESC, icon = "Interface\\Icons\\INV_Fishingpole_02", type = "fishing", threshold = 300, category = "profession"},
    {id = "cook_150", name = L.COOK_150, desc = L.COOK_150_DESC, icon = "Interface\\Icons\\INV_Misc_Food_15", type = "cooking", threshold = 150, category = "profession"},
    {id = "cook_300", name = L.COOK_300, desc = L.COOK_300_DESC, icon = "Interface\\Icons\\INV_Misc_Food_67", type = "cooking", threshold = 300, category = "profession"},
    {id = "firstaid_150", name = L.FIRST_150, desc = L.FIRST_150_DESC, icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", type = "firstaid", threshold = 150, category = "profession"},
    {id = "firstaid_300", name = L.FIRST_300, desc = L.FIRST_300_DESC, icon = "Interface\\Icons\\INV_Misc_Bandage_12", type = "firstaid", threshold = 300, category = "profession"},
    {id = "meta_all_secondary", name = L.META_ALL_SECONDARY, desc = L.META_ALL_SECONDARY_DESC, icon = "Interface\\Icons\\Spell_Nature_EnchantArmor", type = "meta", requirements = {"fish_300", "cook_300", "firstaid_300"}, category = "meta"},
    {id = "meta_complete_crafter", name = L.META_COMPLETE_CRAFTER, desc = L.META_COMPLETE_CRAFTER_DESC, icon = "Interface\\Icons\\Achievement_Profession_Chefhat", type = "meta", requirements = {"prof_300", "meta_all_secondary"}, category = "meta"},
    
    -- Total Kills
    {id = "kills_total_1000", name = L.KILLS_1000, desc = L.KILLS_1000_DESC, icon = "Interface\\Icons\\Ability_DualWield", type = "total_kills", threshold = 1000, category = "kills"},
    {id = "kills_total_5000", name = L.KILLS_5000, desc = L.KILLS_5000_DESC, icon = "Interface\\Icons\\Ability_Warrior_Rampage", type = "total_kills", threshold = 5000, category = "kills"},
    {id = "kills_total_10000", name = L.KILLS_10000, desc = L.KILLS_10000_DESC, icon = "Interface\\Icons\\Ability_Warrior_BattleShout", type = "total_kills", threshold = 10000, category = "kills"},
    {id = "kills_total_25000", name = L.KILLS_25000, desc = L.KILLS_25000_DESC, icon = "Interface\\Icons\\Ability_Warrior_WarCry", type = "total_kills", threshold = 25000, category = "kills"},
    {id = "kills_total_50000", name = L.KILLS_50000, desc = L.KILLS_50000_DESC, icon = "Interface\\Icons\\Spell_Shadow_DeathScream", type = "total_kills", threshold = 50000, category = "kills"},
    
    -- Gold (GetMoney() = Copper! 1 Gold = 10000 Copper)
    {id = "gold_100", name = L.GOLD_100, desc = L.GOLD_100_DESC, icon = "Interface\\Icons\\INV_Misc_Coin_02", type = "gold", threshold = 1000000, category = "wealth"},
    {id = "gold_500", name = L.GOLD_500, desc = L.GOLD_500_DESC, icon = "Interface\\Icons\\INV_Misc_Coin_05", type = "gold", threshold = 5000000, category = "wealth"},
    {id = "gold_1000", name = L.GOLD_1000, desc = L.GOLD_1000_DESC, icon = "Interface\\Icons\\INV_Misc_Coin_06", type = "gold", threshold = 10000000, category = "wealth"},
    {id = "gold_5000", name = L.GOLD_5000, desc = L.GOLD_5000_DESC, icon = "Interface\\Icons\\INV_Misc_Coin_17", type = "gold", threshold = 50000000, category = "wealth"},
    
    -- Kreaturtypen
    {id = "kill_humanoid_25", name = L.HUMANOID_25, desc = L.HUMANOID_25_DESC, icon = "Interface\\Icons\\Ability_Rogue_Ambush", type = "kills", creatureType = "humanoid", threshold = 25, category = "kills"},
    {id = "kill_humanoid_100", name = L.HUMANOID_100, desc = L.HUMANOID_100_DESC, icon = "Interface\\Icons\\Ability_Rogue_Disguise", type = "kills", creatureType = "humanoid", threshold = 100, category = "kills"},
    {id = "kill_humanoid_500", name = L.HUMANOID_500, desc = L.HUMANOID_500_DESC, icon = "Interface\\Icons\\INV_Misc_Coin_02", type = "kills", creatureType = "humanoid", threshold = 500, category = "kills"},
    {id = "kill_humanoid_2000", name = L.HUMANOID_2000, desc = L.HUMANOID_2000_DESC, icon = "Interface\\Icons\\Ability_Warrior_BattleShout", type = "kills", creatureType = "humanoid", threshold = 2000, category = "kills"},
    
    {id = "kill_beast_25", name = L.BEAST_25, desc = L.BEAST_25_DESC, icon = "Interface\\Icons\\Ability_Hunter_SniperShot", type = "kills", creatureType = "beast", threshold = 25, category = "kills"},
    {id = "kill_beast_100", name = L.BEAST_100, desc = L.BEAST_100_DESC, icon = "Interface\\Icons\\Ability_Hunter_BeastCall", type = "kills", creatureType = "beast", threshold = 100, category = "kills"},
    {id = "kill_beast_500", name = L.BEAST_500, desc = L.BEAST_500_DESC, icon = "Interface\\Icons\\Ability_Hunter_BeastTaming", type = "kills", creatureType = "beast", threshold = 500, category = "kills"},
    {id = "kill_beast_2000", name = L.BEAST_2000, desc = L.BEAST_2000_DESC, icon = "Interface\\Icons\\Ability_Hunter_BeastMastery", type = "kills", creatureType = "beast", threshold = 2000, category = "kills"},
    
    {id = "kill_undead_25", name = L.UNDEAD_25, desc = L.UNDEAD_25_DESC, icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", type = "kills", creatureType = "undead", threshold = 25, category = "kills"},
    {id = "kill_undead_100", name = L.UNDEAD_100, desc = L.UNDEAD_100_DESC, icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", type = "kills", creatureType = "undead", threshold = 100, category = "kills"},
    {id = "kill_undead_500", name = L.UNDEAD_500, desc = L.UNDEAD_500_DESC, icon = "Interface\\Icons\\Spell_Shadow_RaiseDead", type = "kills", creatureType = "undead", threshold = 500, category = "kills"},
    {id = "kill_undead_1000", name = L.UNDEAD_1000, desc = L.UNDEAD_1000_DESC, icon = "Interface\\Icons\\Spell_Holy_SenseUndead", type = "kills", creatureType = "undead", threshold = 1000, category = "kills"},
    {id = "kill_undead_5000", name = L.UNDEAD_5000, desc = L.UNDEAD_5000_DESC, icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing", type = "kills", creatureType = "undead", threshold = 5000, category = "kills"},
    
    {id = "kill_demon_25", name = L.DEMON_25, desc = L.DEMON_25_DESC, icon = "Interface\\Icons\\Spell_Shadow_SummonImp", type = "kills", creatureType = "demon", threshold = 25, category = "kills"},
    {id = "kill_demon_100", name = L.DEMON_100, desc = L.DEMON_100_DESC, icon = "Interface\\Icons\\Spell_Shadow_SummonFelGuard", type = "kills", creatureType = "demon", threshold = 100, category = "kills"},
    {id = "kill_demon_500", name = L.DEMON_500, desc = L.DEMON_500_DESC, icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis", type = "kills", creatureType = "demon", threshold = 500, category = "kills"},
    {id = "kill_demon_1000", name = L.DEMON_1000, desc = L.DEMON_1000_DESC, icon = "Interface\\Icons\\Spell_Shadow_DemonicTactics", type = "kills", creatureType = "demon", threshold = 1000, category = "kills"},
    
    {id = "kill_elemental_25", name = L.ELEMENTAL_25, desc = L.ELEMENTAL_25_DESC, icon = "Interface\\Icons\\Spell_Fire_Fire", type = "kills", creatureType = "elemental", threshold = 25, category = "kills"},
    {id = "kill_elemental_100", name = L.ELEMENTAL_100, desc = L.ELEMENTAL_100_DESC, icon = "Interface\\Icons\\Spell_Fire_FireBolt", type = "kills", creatureType = "elemental", threshold = 100, category = "kills"},
    {id = "kill_elemental_500", name = L.ELEMENTAL_500, desc = L.ELEMENTAL_500_DESC, icon = "Interface\\Icons\\Spell_Fire_Elemental_Totem", type = "kills", creatureType = "elemental", threshold = 500, category = "kills"},
    
    {id = "kill_dragonkin_10", name = L.DRAGON_10, desc = L.DRAGON_10_DESC, icon = "Interface\\Icons\\INV_Misc_MonsterScales_02", type = "kills", creatureType = "dragonkin", threshold = 10, category = "kills"},
    {id = "kill_dragonkin_50", name = L.DRAGON_50, desc = L.DRAGON_50_DESC, icon = "Interface\\Icons\\INV_Misc_MonsterScales_05", type = "kills", creatureType = "dragonkin", threshold = 50, category = "kills"},
    {id = "kill_dragonkin_250", name = L.DRAGON_250, desc = L.DRAGON_250_DESC, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "kills", creatureType = "dragonkin", threshold = 250, category = "kills"},
    {id = "kill_dragonkin_1000", name = L.DRAGON_1000, desc = L.DRAGON_1000_DESC, icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", type = "kills", creatureType = "dragonkin", threshold = 1000, category = "kills"},
    
    {id = "kill_giant_10", name = L.GIANT_10, desc = L.GIANT_10_DESC, icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", type = "kills", creatureType = "giant", threshold = 10, category = "kills"},
    {id = "kill_giant_50", name = L.GIANT_50, desc = L.GIANT_50_DESC, icon = "Interface\\Icons\\INV_Misc_Foot_Centaur", type = "kills", creatureType = "giant", threshold = 50, category = "kills"},
    {id = "kill_giant_250", name = L.GIANT_250, desc = L.GIANT_250_DESC, icon = "Interface\\Icons\\INV_Stone_15", type = "kills", creatureType = "giant", threshold = 250, category = "kills"},
    
    -- Legendäre Meta-Achievements (GEHEIM!)
    {id = "meta_immortal_veteran", name = L.META_IMMORTAL_VET, desc = L.META_IMMORTAL_VET_DESC, icon = "Interface\\Icons\\Spell_Holy_AshesToAshes", type = "meta", requirements = {"level_60", "played_168h"}, category = "secret", secret = true},
    {id = "meta_legend_azeroth", name = L.META_LEGEND, desc = L.META_LEGEND_DESC, icon = "Interface\\Icons\\INV_Misc_Map02", type = "meta", requirements = {"level_60", "meta_all_dungeons", "kills_total_5000"}, category = "secret", secret = true},
    {id = "meta_true_immortal", name = L.META_TRUE_IMMORTAL, desc = L.META_TRUE_IMMORTAL_DESC, icon = "Interface\\Icons\\Spell_Holy_Resurrection", type = "meta", requirements = {"level_60", "meta_all_raids", "played_720h"}, category = "secret", secret = true},
    {id = "meta_godslayer", name = L.META_GODSLAYER, desc = L.META_GODSLAYER_DESC, icon = "Interface\\Icons\\INV_Misc_Eye_01", type = "meta", requirements = {"boss_aq40_cthun", "boss_naxx_kt"}, category = "secret", secret = true},
    {id = "meta_perfectionist", name = L.META_PERFECT, desc = L.META_PERFECT_DESC, icon = "Interface\\Icons\\Achievement_GuildPerk_EverybodysFriend", type = "meta", requirements = {"level_60", "meta_complete_crafter", "meta_all_dungeons"}, category = "secret", secret = true},
}

-- Lookup-Tabellen
local BOSS_TO_MILESTONE = {}
local MILESTONE_BY_ID = {}
for _, m in ipairs(MILESTONE_DEFS) do
    MILESTONE_BY_ID[m.id] = m
    if m.type == "boss" and m.bossId then
        BOSS_TO_MILESTONE[m.bossId] = m.id
    end
end

-- ==============================================================
-- INITIALISIERUNG
-- ==============================================================

function Milestones:Initialize()
    if self.initialized then return end
    self.initialized = true
    
    C_ChatInfo.RegisterAddonMessagePrefix(MILESTONE_PREFIX)
    
    GuildDeathLogDB.milestones = GuildDeathLogDB.milestones or {}
    GuildDeathLogDB.guildMilestones = GuildDeathLogDB.guildMilestones or {}
    
    local charKey = self:GetCharacterKey()
    GuildDeathLogDB.milestones[charKey] = GuildDeathLogDB.milestones[charKey] or {
        unlocked = {},
        stats = { totalKills = 0 }
    }
    
    self:RegisterEvents()
    
    C_Timer.NewTicker(60, function() 
        self:TrackPlayerStats() 
        self:CheckMetaMilestones()
    end)
    
    C_Timer.After(2, function() 
        self:CheckCurrentLevel() 
        self:TrackPlayerStats()
        self:CheckMetaMilestones()
    end)
    
    GDL:Debug("Milestones: Initialized")
end

function Milestones:GetCharacterKey(name, realm)
    if not name then
        name = UnitName("player")
        realm = GetRealmName()
    end
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
-- EVENTS
-- ==============================================================

function Milestones:RegisterEvents()
    if self.eventFrame then return end
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:SetScript("OnEvent", function(frame, event, ...)
        if self[event] then self[event](self, ...) end
    end)
    
    self.eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
    self.eventFrame:RegisterEvent("PLAYER_LOGIN")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PLAYER_MONEY")
    self.eventFrame:RegisterEvent("TIME_PLAYED_MSG")
    self.eventFrame:RegisterEvent("SKILL_LINES_CHANGED")  -- Für Berufe-Tracking!
    self.eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")   -- Wenn Berufsfenster geöffnet
end

function Milestones:SKILL_LINES_CHANGED()
    -- Berufe haben sich geändert - prüfe Meilensteine
    C_Timer.After(0.5, function()
        self:TrackPlayerStats()
    end)
end

function Milestones:TRADE_SKILL_UPDATE()
    -- Berufsfenster wurde aktualisiert
    C_Timer.After(0.5, function()
        self:TrackPlayerStats()
    end)
end

function Milestones:PLAYER_LEVEL_UP(newLevel)
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    
    GDL:Print("|cff00FF00" .. L.LEVEL_UP .. "|r " .. charName .. " " .. L.IS_NOW_LEVEL .. " " .. tostring(newLevel))
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" and m.threshold == newLevel then
            self:UnlockMilestone(m.id, charKey, charName, newLevel)
        end
    end
    
    C_Timer.After(1, function() self:CheckMetaMilestones() end)
end

function Milestones:PLAYER_LOGIN()
    C_Timer.After(2, function()
        self:CheckCurrentLevel()
        self:TrackPlayerStats()
        RequestTimePlayed()
    end)
end

function Milestones:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        C_Timer.After(3, function()
            self:CheckCurrentLevel()
            self:RequestMilestoneSync()
            RequestTimePlayed()
        end)
    end
end

function Milestones:PLAYER_MONEY()
    self:CheckGoldMilestones()
end

function Milestones:TIME_PLAYED_MSG(totalTime)
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    charData.stats.totalPlaytime = totalTime
    self:CheckPlaytimeMilestones(totalTime)
end

function Milestones:COMBAT_LOG_EVENT_UNFILTERED()
    local _, subEvent, _, sourceGUID, _, _, _, destGUID, destName = CombatLogGetCurrentEventInfo()
    
    if subEvent ~= "UNIT_DIED" then return end
    
    local npcId = self:GetNPCIdFromGUID(destGUID)
    if not npcId then return end
    
    local milestoneId = BOSS_TO_MILESTONE[npcId]
    if milestoneId then
        local charKey = self:GetCharacterKey()
        local charName = UnitName("player")
        local charLevel = UnitLevel("player")
        self:UnlockMilestone(milestoneId, charKey, charName, charLevel)
        C_Timer.After(1, function() self:CheckMetaMilestones() end)
    end
    
    if sourceGUID == UnitGUID("player") then
        self:TrackKill(destGUID)
    end
end

function Milestones:CHAT_MSG_ADDON(prefix, message, channel, sender)
    if prefix == MILESTONE_PREFIX and channel == "GUILD" then
        self:HandleMilestoneSync(message, sender)
    end
end

-- ==============================================================
-- CHECKS
-- ==============================================================

function Milestones:CheckCurrentLevel()
    local currentLevel = UnitLevel("player")
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "level" and currentLevel >= m.threshold then
            local charData = self:GetCharacterData(charKey)
            if not charData.unlocked[m.id] then
                self:UnlockMilestone(m.id, charKey, charName, currentLevel, true)
            end
        end
    end
end

function Milestones:CheckPlaytimeMilestones(totalTime)
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "playtime" and totalTime >= m.threshold then
            local charData = self:GetCharacterData(charKey)
            if not charData.unlocked[m.id] then
                self:UnlockMilestone(m.id, charKey, charName, charLevel)
            end
        end
    end
end

function Milestones:CheckGoldMilestones()
    local gold = GetMoney()
    local charKey = self:GetCharacterKey()
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    local charData = self:GetCharacterData(charKey)
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "gold" and gold >= m.threshold then
            if not charData.unlocked[m.id] then
                self:UnlockMilestone(m.id, charKey, charName, charLevel)
            end
        end
    end
end

function Milestones:CheckTotalKillMilestones()
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    -- Verwende KillStats für Total Kills (character-spezifisch!)
    local KillStats = GDL:GetModule("KillStats")
    local totalKills = 0
    if KillStats and KillStats.GetTotalKills then
        totalKills = KillStats:GetTotalKills(charKey)
    end
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "total_kills" and totalKills >= m.threshold then
            if not charData.unlocked[m.id] then
                self:UnlockMilestone(m.id, charKey, charName, charLevel)
            end
        end
    end
end

-- Auch Kreaturtyp-Kills über KillStats prüfen
function Milestones:CheckCreatureKillMilestones()
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    local KillStats = GDL:GetModule("KillStats")
    if not KillStats then return end
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "kills" and m.creatureType and m.threshold then
            local killCount = KillStats:GetKillCount(m.creatureType, charKey)
            if killCount >= m.threshold then
                if not charData.unlocked[m.id] then
                    self:UnlockMilestone(m.id, charKey, charName, charLevel)
                end
            end
        end
    end
end

function Milestones:CheckMetaMilestones()
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "meta" and m.requirements then
            if not charData.unlocked[m.id] then
                local allMet = true
                for _, reqId in ipairs(m.requirements) do
                    if not charData.unlocked[reqId] then
                        allMet = false
                        break
                    end
                end
                if allMet then
                    self:UnlockMilestone(m.id, charKey, charName, charLevel)
                end
            end
        end
    end
end

-- TrackKill wird nicht mehr benötigt - KillStats trackt alle Kills
-- Diese Funktion bleibt für Kompatibilität, ruft aber nur die Checks auf
function Milestones:TrackKill(destGUID)
    -- KillStats trackt die Kills bereits
    -- Wir prüfen nur alle 50 Kills ob neue Meilensteine freigeschaltet werden
    local KillStats = GDL:GetModule("KillStats")
    if KillStats then
        local totalKills = KillStats:GetTotalKills()
        if totalKills % 50 == 0 then
            self:CheckTotalKillMilestones()
            self:CheckCreatureKillMilestones()
        end
    end
end

function Milestones:TrackPlayerStats()
    local charKey = self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local charName = UnitName("player")
    local charLevel = UnitLevel("player")
    
    -- Berufe über Classic API (GetSkillLineInfo)
    local profSkills = self:GetProfessionSkills()
    
    -- Hauptberufe prüfen
    local maxMainSkill = profSkills.maxMain or 0
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.type == "profession" and maxMainSkill >= m.threshold then
            if not charData.unlocked[m.id] then
                self:UnlockMilestone(m.id, charKey, charName, charLevel)
            end
        end
    end
    
    -- Angeln
    if profSkills.fishing and profSkills.fishing > 0 then
        for _, m in ipairs(MILESTONE_DEFS) do
            if m.type == "fishing" and profSkills.fishing >= m.threshold then
                if not charData.unlocked[m.id] then
                    self:UnlockMilestone(m.id, charKey, charName, charLevel)
                end
            end
        end
    end
    
    -- Kochen
    if profSkills.cooking and profSkills.cooking > 0 then
        for _, m in ipairs(MILESTONE_DEFS) do
            if m.type == "cooking" and profSkills.cooking >= m.threshold then
                if not charData.unlocked[m.id] then
                    self:UnlockMilestone(m.id, charKey, charName, charLevel)
                end
            end
        end
    end
    
    -- Erste Hilfe
    if profSkills.firstaid and profSkills.firstaid > 0 then
        for _, m in ipairs(MILESTONE_DEFS) do
            if m.type == "firstaid" and profSkills.firstaid >= m.threshold then
                if not charData.unlocked[m.id] then
                    self:UnlockMilestone(m.id, charKey, charName, charLevel)
                end
            end
        end
    end
    
    self:CheckGoldMilestones()
    self:CheckTotalKillMilestones()
    self:CheckCreatureKillMilestones()
    self:CheckMetaMilestones()
end

-- ==============================================================
-- CLASSIC-KOMPATIBLE BERUFE-ABFRAGE
-- ==============================================================

function Milestones:GetProfessionSkills()
    local result = {
        maxMain = 0,
        fishing = 0,
        cooking = 0,
        firstaid = 0,
        mainSkills = {}
    }
    
    local numSkills = GetNumSkillLines and GetNumSkillLines() or 0
    if numSkills == 0 then return result end
    
    local inProfessionHeader = false
    local inSecondaryHeader = false
    
    -- Berufe-Header Namen (DE/EN) - ohne Umlaute für Kompatibilität
    local profHeaders = {
        ["Berufe"] = true, ["Professions"] = true, 
        ["Trade Skills"] = true, ["Handelsfertigkeiten"] = true
    }
    local secondaryHeaders = {
        ["Sekundäre Fertigkeiten"] = true, ["Secondary Skills"] = true,
        ["Sekundärberufe"] = true, ["Secondary"] = true,
        ["Sekundare Fertigkeiten"] = true, ["Sekundarberufe"] = true  -- Ohne Umlaute
    }
    -- Nebenberuf-Namen (mit und ohne Umlaute)
    local fishingNames = {["Angeln"] = true, ["Fishing"] = true}
    local cookingNames = {["Kochen"] = true, ["Cooking"] = true, ["Kochkunst"] = true}
    local firstaidNames = {["Erste Hilfe"] = true, ["First Aid"] = true}
    
    for i = 1, numSkills do
        local skillName, isHeader, _, skillRank = GetSkillLineInfo(i)
        
        if isHeader then
            if profHeaders[skillName] then
                inProfessionHeader = true
                inSecondaryHeader = false
            elseif secondaryHeaders[skillName] then
                inSecondaryHeader = true
                inProfessionHeader = false
            else
                inProfessionHeader = false
                inSecondaryHeader = false
            end
        elseif skillName and skillRank then
            if inProfessionHeader then
                -- Hauptberuf
                table.insert(result.mainSkills, {name = skillName, skill = skillRank})
                if skillRank > result.maxMain then
                    result.maxMain = skillRank
                end
            elseif inSecondaryHeader then
                -- Sekundärberuf
                if fishingNames[skillName] then
                    result.fishing = skillRank
                elseif cookingNames[skillName] then
                    result.cooking = skillRank
                elseif firstaidNames[skillName] then
                    result.firstaid = skillRank
                end
            end
        end
    end
    
    return result
end

-- ==============================================================
-- UNLOCK
-- ==============================================================

function Milestones:UnlockMilestone(milestoneId, charKey, charName, charLevel, silent)
    charKey = charKey or self:GetCharacterKey()
    charName = charName or UnitName("player")
    charLevel = charLevel or UnitLevel("player")
    
    local charData = self:GetCharacterData(charKey)
    if charData.unlocked[milestoneId] then return false end
    
    local milestone = MILESTONE_BY_ID[milestoneId]
    if not milestone then return false end
    
    charData.unlocked[milestoneId] = {
        timestamp = time(),
        level = charLevel,
        name = charName,
    }
    
    self:BroadcastMilestone(milestoneId, charName, charLevel)
    
    GuildDeathLogDB.guildMilestones[charKey] = GuildDeathLogDB.guildMilestones[charKey] or {}
    GuildDeathLogDB.guildMilestones[charKey][milestoneId] = charData.unlocked[milestoneId]
    
    if not silent then
        self:ShowMilestonePopup(milestone, charName)
        local Titles = GDL:GetModule("Titles")
        if Titles and Titles.OnMilestoneUnlocked then
            Titles:OnMilestoneUnlocked(milestoneId)
        end
    end
    
    C_Timer.After(0.5, function() self:CheckMetaMilestones() end)
    return true
end

function Milestones:GetNPCIdFromGUID(guid)
    if not guid then return nil end
    local guidType, _, _, _, _, npcId = strsplit("-", guid)
    if guidType == "Creature" or guidType == "Vehicle" then
        return tonumber(npcId)
    end
    return nil
end

-- ==============================================================
-- SYNC
-- ==============================================================

function Milestones:BroadcastMilestone(milestoneId, charName, charLevel)
    if not IsInGuild() then return end
    local message = "UNLOCK" .. COMM_DELIM .. milestoneId .. COMM_DELIM .. charName .. COMM_DELIM .. charLevel
    C_ChatInfo.SendAddonMessage(MILESTONE_PREFIX, message, "GUILD")
end

function Milestones:RequestMilestoneSync()
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(MILESTONE_PREFIX, "REQUEST", "GUILD")
end

function Milestones:HandleMilestoneSync(message, sender)
    local myName = UnitName("player")
    local senderName = Ambiguate(sender, "short")
    if senderName == myName then return end
    
    if message == "REQUEST" then
        C_Timer.After(math.random() * 3, function() end)
        return
    end
    
    local cmd, data = strsplit(COMM_DELIM, message, 2)
    if cmd == "UNLOCK" then
        local mId, cName = strsplit(COMM_DELIM, data)
        if mId and cName then
            local m = MILESTONE_BY_ID[mId]
            if m then
                GDL:Print("|cffFFD100" .. cName .. "|r: |cff00FF00" .. m.name .. "|r")
            end
        end
    end
end

-- ==============================================================
-- POPUP
-- ==============================================================

function Milestones:ShowMilestonePopup(milestone, charName)
    if self.popupFrame then self.popupFrame:Hide() end
    
    local p = CreateFrame("Frame", "GDLMilestonePopup", UIParent, "BackdropTemplate")
    p:SetSize(350, 100)
    p:SetPoint("TOP", 0, -150)
    p:SetFrameStrata("DIALOG")
    p:SetFrameLevel(200)
    
    p:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 24,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    
    local icon = p:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(milestone.icon)
    icon:SetSize(50, 50)
    icon:SetPoint("LEFT", 15, 0)
    
    local title = p:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -5)
    title:SetText("|cffFFD100" .. L.NEW_MILESTONE .. "|r")
    
    local name = p:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    name:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    name:SetText("|cff00FF00" .. milestone.name .. "|r")
    
    local desc = p:CreateFontString(nil, "OVERLAY")
    desc:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    desc:SetText("|cffAAAAAA" .. milestone.desc .. "|r")
    
    self.popupFrame = p
    p:Show()
    PlaySound(8959, "Master")
    
    C_Timer.After(5, function() if p:IsShown() then p:Hide() end end)
end

-- ==============================================================
-- API
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
    for _ in pairs(charData.unlocked) do unlocked = unlocked + 1 end
    return unlocked, #MILESTONE_DEFS
end

function Milestones:GetCategoryProgress(category, charKey)
    charKey = charKey or self:GetCharacterKey()
    local charData = self:GetCharacterData(charKey)
    local unlocked, total = 0, 0
    
    for _, m in ipairs(MILESTONE_DEFS) do
        if m.category == category then
            total = total + 1
            if charData.unlocked[m.id] then unlocked = unlocked + 1 end
        end
    end
    return unlocked, total
end

function Milestones:IsSecretMilestone(milestoneId)
    local m = MILESTONE_BY_ID[milestoneId]
    return m and m.secret == true
end

function Milestones:GetMilestoneDescription(milestoneId, charKey)
    charKey = charKey or self:GetCharacterKey()
    local m = MILESTONE_BY_ID[milestoneId]
    if not m then return "" end
    
    -- Wenn geheim und nicht freigeschaltet, zeige "???"
    if m.secret and not self:IsMilestoneUnlocked(milestoneId, charKey) then
        return L.SECRET_DESC
    end
    
    return m.desc
end

function Milestones:GetSecretLocale()
    return L.SECRET_DESC, L.SECRET_CATEGORY
end

function Milestones:CheckAllMilestones()
    self:CheckCurrentLevel()
    self:TrackPlayerStats()
    self:CheckMetaMilestones()
    RequestTimePlayed()
end

-- Module registrieren
GDL:RegisterModule("Milestones", Milestones)
GDL:RegisterModule("Achievements", Milestones)

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function() Milestones:Initialize() end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
