-- ══════════════════════════════════════════════════════════════
-- MODUL: Achievements - Erfolge für Hardcore
-- Überleben, Helfen, Berufe, Gilde - NICHT sterben!
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Achievements = {}

-- Achievement Definitionen
-- difficulty: 1=leicht, 2=mittel, 3=schwer, 4=geheim
local ACHIEVEMENT_DEFS = {
    -- ═══════════════════════════════════════════════════════════
    -- UEBERLEBEN (Das Wichtigste im Hardcore!)
    -- ═══════════════════════════════════════════════════════════
    {id = "survive_10", name = "Vorsichtiger Anfaenger / Careful Beginner", desc = "Level 10 erreicht / Reached level 10", icon = "Interface\\Icons\\Spell_Holy_WordFortitude", threshold = 10, type = "player_level", difficulty = 1},
    {id = "survive_20", name = "Auf gutem Weg / On Track", desc = "Level 20 erreicht / Reached level 20", icon = "Interface\\Icons\\Spell_Holy_GreaterHeal", threshold = 20, type = "player_level", difficulty = 1},
    {id = "survive_30", name = "Halbzeit / Halfway There", desc = "Level 30 erreicht / Reached level 30", icon = "Interface\\Icons\\INV_Shield_06", threshold = 30, type = "player_level", difficulty = 2},
    {id = "survive_40", name = "Erfahrener Kaempfer / Experienced Fighter", desc = "Level 40 erreicht / Reached level 40", icon = "Interface\\Icons\\INV_Shield_05", threshold = 40, type = "player_level", difficulty = 2},
    {id = "survive_50", name = "Fast Unsterblich / Almost Immortal", desc = "Level 50 erreicht / Reached level 50", icon = "Interface\\Icons\\INV_Shield_07", threshold = 50, type = "player_level", difficulty = 3},
    {id = "survive_60", name = "Unsterbliche Legende / Immortal Legend", desc = "Level 60 erreicht! / Reached level 60!", icon = "Interface\\Icons\\INV_Crown_01", threshold = 60, type = "player_level", difficulty = 3},
    
    {id = "playtime_1d", name = "Erster Tag / First Day", desc = "1 Tag /played / 1 day /played", icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", threshold = 1, type = "playtime_days", difficulty = 1},
    {id = "playtime_3d", name = "Durchhalter / Perseverant", desc = "3 Tage /played / 3 days /played", icon = "Interface\\Icons\\INV_Misc_PocketWatch_02", threshold = 3, type = "playtime_days", difficulty = 2},
    {id = "playtime_7d", name = "Eiserner Wille / Iron Will", desc = "7 Tage /played / 7 days /played", icon = "Interface\\Icons\\INV_Misc_Rune_01", threshold = 7, type = "playtime_days", difficulty = 3},
    {id = "playtime_14d", name = "Zeitloser Held / Timeless Hero", desc = "14 Tage /played / 14 days /played", icon = "Interface\\Icons\\INV_Misc_Rune_09", threshold = 14, type = "playtime_days", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- GOLD & REICHTUM
    -- ═══════════════════════════════════════════════════════════
    {id = "gold_10", name = "Erspartes / Savings", desc = "10 Gold besessen / Owned 10 gold", icon = "Interface\\Icons\\INV_Misc_Coin_02", threshold = 10, type = "gold_owned", difficulty = 1},
    {id = "gold_100", name = "Wohlhabend / Wealthy", desc = "100 Gold besessen / Owned 100 gold", icon = "Interface\\Icons\\INV_Misc_Coin_06", threshold = 100, type = "gold_owned", difficulty = 2},
    {id = "gold_500", name = "Reich / Rich", desc = "500 Gold besessen / Owned 500 gold", icon = "Interface\\Icons\\INV_Misc_Coin_17", threshold = 500, type = "gold_owned", difficulty = 3},
    {id = "gold_1000", name = "Goldener Baron / Golden Baron", desc = "1000 Gold besessen / Owned 1000 gold", icon = "Interface\\Icons\\INV_Misc_Coin_01", threshold = 1000, type = "gold_owned", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- QUESTS & ABENTEUER
    -- ═══════════════════════════════════════════════════════════
    {id = "quests_50", name = "Abenteurer / Adventurer", desc = "50 Quests abgeschlossen / Completed 50 quests", icon = "Interface\\Icons\\INV_Misc_Book_08", threshold = 50, type = "quests_completed", difficulty = 1},
    {id = "quests_250", name = "Questjunkie / Quest Addict", desc = "250 Quests abgeschlossen / Completed 250 quests", icon = "Interface\\Icons\\INV_Misc_Book_11", threshold = 250, type = "quests_completed", difficulty = 2},
    {id = "quests_500", name = "Held von Azeroth / Hero of Azeroth", desc = "500 Quests abgeschlossen / Completed 500 quests", icon = "Interface\\Icons\\INV_Misc_Book_09", threshold = 500, type = "quests_completed", difficulty = 3},
    {id = "quests_1000", name = "Legendaerer Questmeister / Legendary Questmaster", desc = "1000 Quests abgeschlossen / Completed 1000 quests", icon = "Interface\\Icons\\INV_Misc_Book_07", threshold = 1000, type = "quests_completed", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- MONSTER ERLEGEN
    -- ═══════════════════════════════════════════════════════════
    {id = "kills_100", name = "Jaeger / Hunter", desc = "100 Feinde besiegt / Defeated 100 enemies", icon = "Interface\\Icons\\Ability_DualWield", threshold = 100, type = "enemies_killed", difficulty = 1},
    {id = "kills_1000", name = "Schlachter / Slayer", desc = "1.000 Feinde besiegt / Defeated 1,000 enemies", icon = "Interface\\Icons\\INV_Sword_04", threshold = 1000, type = "enemies_killed", difficulty = 2},
    {id = "kills_5000", name = "Krieger des Lichts / Warrior of Light", desc = "5.000 Feinde besiegt / Defeated 5,000 enemies", icon = "Interface\\Icons\\INV_Sword_39", threshold = 5000, type = "enemies_killed", difficulty = 3},
    {id = "kills_10000", name = "Todbringer / Deathbringer", desc = "10.000 Feinde besiegt / Defeated 10,000 enemies", icon = "Interface\\Icons\\INV_Sword_48", threshold = 10000, type = "enemies_killed", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- DUNGEONS
    -- ═══════════════════════════════════════════════════════════
    {id = "dungeon_1", name = "Erster Dungeon / First Dungeon", desc = "1 Dungeon abgeschlossen / Completed 1 dungeon", icon = "Interface\\Icons\\INV_Misc_Key_04", threshold = 1, type = "dungeons_completed", difficulty = 1},
    {id = "dungeon_10", name = "Dungeon-Laeufer / Dungeon Runner", desc = "10 Dungeons abgeschlossen / Completed 10 dungeons", icon = "Interface\\Icons\\INV_Misc_Key_13", threshold = 10, type = "dungeons_completed", difficulty = 2},
    {id = "dungeon_50", name = "Dungeon-Meister / Dungeon Master", desc = "50 Dungeons abgeschlossen / Completed 50 dungeons", icon = "Interface\\Icons\\INV_Misc_Key_14", threshold = 50, type = "dungeons_completed", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- BERUFE & CRAFTING
    -- ═══════════════════════════════════════════════════════════
    {id = "prof_150", name = "Lehrling / Apprentice", desc = "Beruf auf 150 / Profession at 150", icon = "Interface\\Icons\\Trade_BlackSmithing", threshold = 150, type = "max_profession", difficulty = 1},
    {id = "prof_225", name = "Geselle / Journeyman", desc = "Beruf auf 225 / Profession at 225", icon = "Interface\\Icons\\Trade_LeatherWorking", threshold = 225, type = "max_profession", difficulty = 2},
    {id = "prof_300", name = "Meister des Handwerks / Master Crafter", desc = "Beruf auf 300 / Profession at 300", icon = "Interface\\Icons\\Trade_Engineering", threshold = 300, type = "max_profession", difficulty = 3},
    
    {id = "fish_skill_150", name = "Angler / Angler", desc = "Angeln auf 150 / Fishing at 150", icon = "Interface\\Icons\\Trade_Fishing", threshold = 150, type = "fishing_skill", difficulty = 1},
    {id = "fish_skill_300", name = "Meisterangler / Master Angler", desc = "Angeln auf 300 / Fishing at 300", icon = "Interface\\Icons\\INV_Misc_Fish_35", threshold = 300, type = "fishing_skill", difficulty = 3},
    
    {id = "cook_skill_150", name = "Hobbykoch / Hobby Cook", desc = "Kochen auf 150 / Cooking at 150", icon = "Interface\\Icons\\INV_Misc_Food_15", threshold = 150, type = "cooking_skill", difficulty = 1},
    {id = "cook_skill_300", name = "Sternekoch / Star Chef", desc = "Kochen auf 300 / Cooking at 300", icon = "Interface\\Icons\\INV_Misc_Food_100", threshold = 300, type = "cooking_skill", difficulty = 3},
    
    {id = "firstaid_300", name = "Ersthelfer / First Aider", desc = "Erste Hilfe auf 300 / First Aid at 300", icon = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", threshold = 300, type = "firstaid_skill", difficulty = 2},
    
    -- ═══════════════════════════════════════════════════════════
    -- GILDEN & SOZIALES
    -- ═══════════════════════════════════════════════════════════
    {id = "guild_join", name = "Willkommen / Welcome", desc = "Einer Gilde beigetreten / Joined a guild", icon = "Interface\\Icons\\INV_BannerPVP_02", threshold = 1, type = "in_guild", difficulty = 1},
    {id = "group_50", name = "Teamplayer / Team Player", desc = "50 Gruppen gebildet / Formed 50 groups", icon = "Interface\\Icons\\INV_Misc_GroupLooking", threshold = 50, type = "groups_formed", difficulty = 2},
    {id = "group_200", name = "Gruppenleiter / Group Leader", desc = "200 Gruppen gebildet / Formed 200 groups", icon = "Interface\\Icons\\INV_Misc_GroupNeedMore", threshold = 200, type = "groups_formed", difficulty = 3},
    
    -- ═══════════════════════════════════════════════════════════
    -- ADDON-NUTZUNG
    -- ═══════════════════════════════════════════════════════════
    {id = "addon_week", name = "Treuer Nutzer / Loyal User", desc = "7 Tage Addon genutzt / Used addon for 7 days", icon = "Interface\\Icons\\INV_Misc_Book_09", threshold = 7, type = "days_used", difficulty = 1},
    {id = "addon_month", name = "Stammnutzer / Regular User", desc = "30 Tage Addon genutzt / Used addon for 30 days", icon = "Interface\\Icons\\INV_Misc_Book_07", threshold = 30, type = "days_used", difficulty = 2},
    {id = "addon_100days", name = "Gruendungsmitglied / Founding Member", desc = "100 Tage Addon genutzt / Used addon for 100 days", icon = "Interface\\Icons\\INV_Misc_Book_11", threshold = 100, type = "days_used", difficulty = 3},
    {id = "book_opened_25", name = "Buecherwurm / Bookworm", desc = "Das Buch 25x geoeffnet / Opened the book 25 times", icon = "Interface\\Icons\\INV_Misc_Book_06", threshold = 25, type = "book_opens", difficulty = 1},
    {id = "book_opened_100", name = "Chronist / Chronicler", desc = "Das Buch 100x geoeffnet / Opened the book 100 times", icon = "Interface\\Icons\\INV_Misc_Book_03", threshold = 100, type = "book_opens", difficulty = 2},
    
    -- ═══════════════════════════════════════════════════════════
    -- TODE BEOBACHTET (nicht selbst sterben!)
    -- ═══════════════════════════════════════════════════════════
    {id = "witness_1", name = "Erster Zeuge / First Witness", desc = "1 Tod beobachtet / Witnessed 1 death", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil", threshold = 1, type = "deaths_witnessed", difficulty = 1},
    {id = "witness_50", name = "Trauergast / Mourner", desc = "50 Tode beobachtet / Witnessed 50 deaths", icon = "Interface\\Icons\\Spell_Shadow_AnimateDead", threshold = 50, type = "deaths_witnessed", difficulty = 2},
    {id = "witness_200", name = "Chronist des Todes / Death Chronicler", desc = "200 Tode beobachtet / Witnessed 200 deaths", icon = "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", threshold = 200, type = "deaths_witnessed", difficulty = 3},
    
    {id = "guild_loss_5", name = "Schwere Zeiten / Hard Times", desc = "5 Gildenmitglieder verloren / Lost 5 guild members", icon = "Interface\\Icons\\Spell_Holy_PrayerofSpirit", threshold = 5, type = "guild_deaths", difficulty = 1},
    {id = "guild_loss_25", name = "Dezimiert / Decimated", desc = "25 Gildenmitglieder verloren / Lost 25 guild members", icon = "Interface\\Icons\\Spell_Shadow_DeathPact", threshold = 25, type = "guild_deaths", difficulty = 2},
    
    -- ═══════════════════════════════════════════════════════════
    -- GEHEIME ACHIEVEMENTS
    -- ═══════════════════════════════════════════════════════════
    {id = "secret_mount", name = "Reiter / Rider", desc = "Erstes Mount erhalten / Got first mount", icon = "Interface\\Icons\\Ability_Mount_BlackDireWolf", threshold = 1, type = "has_mount", difficulty = 4, secret = true},
    {id = "secret_epic_mount", name = "Schneller Reiter / Fast Rider", desc = "Episches Mount erhalten / Got epic mount", icon = "Interface\\Icons\\Ability_Mount_Dreadsteed", threshold = 1, type = "has_epic_mount", difficulty = 4, secret = true},
    {id = "secret_midnight", name = "Nachtschwaermer / Night Owl", desc = "Um Mitternacht online / Online at midnight", icon = "Interface\\Icons\\Spell_Shadow_Twilight", threshold = 1, type = "midnight_login", difficulty = 4, secret = true},
    {id = "secret_full_hp", name = "Niemals Aufgeben / Never Give Up", desc = "Von unter 5% HP ueberlebt / Survived from under 5% HP", icon = "Interface\\Icons\\Spell_Holy_BlessedRecovery", threshold = 1, type = "survived_low_hp", difficulty = 4, secret = true},
}

function Achievements:Initialize()
    GuildDeathLogDB.achievements = GuildDeathLogDB.achievements or {}
    GuildDeathLogDB.achievementStats = GuildDeathLogDB.achievementStats or {
        deaths_witnessed = 0,
        guild_deaths = 0,
        days_used = 0,
        book_opens = 0,
        first_login = time(),
        last_login_date = "",
        max_gold_owned = 0,
        max_profession = 0,
        fishing_skill = 0,
        cooking_skill = 0,
        firstaid_skill = 0,
        dungeons_completed = 0,
        groups_formed = 0,
        enemies_killed = 0,
        quests_completed = 0,
        midnight_login = 0,
        survived_low_hp = 0,
        has_mount = 0,
        has_epic_mount = 0,
    }
    
    self:TrackDailyLogin()
    self:TrackPlayerStats()
    self:RegisterEvents()
    
    -- Regelmaessig Stats aktualisieren
    C_Timer.NewTicker(60, function() self:TrackPlayerStats() end)
end

function Achievements:RegisterEvents()
    if not self.eventFrame then
        self.eventFrame = CreateFrame("Frame")
        self.eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
        self.eventFrame:RegisterEvent("PLAYER_MONEY")
        self.eventFrame:RegisterEvent("QUEST_TURNED_IN")
        self.eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
        self.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.eventFrame:RegisterEvent("UNIT_HEALTH")
        self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    end
end

function Achievements:OnEvent(event, ...)
    local stats = GuildDeathLogDB.achievementStats
    
    if event == "PLAYER_MONEY" then
        local gold = math.floor(GetMoney() / 10000)
        if gold > (stats.max_gold_owned or 0) then
            stats.max_gold_owned = gold
            self:CheckAchievements()
        end
    elseif event == "QUEST_TURNED_IN" then
        stats.quests_completed = (stats.quests_completed or 0) + 1
        self:CheckAchievements()
    elseif event == "GROUP_ROSTER_UPDATE" then
        if IsInGroup() then
            stats.groups_formed = (stats.groups_formed or 0) + 1
            self:CheckAchievements()
        end
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo()
        if subEvent == "PARTY_KILL" and sourceGUID == UnitGUID("player") then
            stats.enemies_killed = (stats.enemies_killed or 0) + 1
            self:CheckAchievements()
        end
    elseif event == "UNIT_HEALTH" then
        local unit = ...
        if unit == "player" then
            local hp = UnitHealth("player")
            local maxHp = UnitHealthMax("player")
            if hp > 0 and maxHp > 0 and (hp / maxHp) < 0.05 then
                stats.survived_low_hp = 1
                self:CheckAchievements()
            end
        end
    end
end

function Achievements:TrackDailyLogin()
    local stats = GuildDeathLogDB.achievementStats
    local today = date("%Y-%m-%d")
    
    if stats.last_login_date ~= today then
        stats.days_used = (stats.days_used or 0) + 1
        stats.last_login_date = today
    end
    
    -- Mitternacht-Check (geheim)
    local hour = tonumber(date("%H"))
    if hour == 0 then
        stats.midnight_login = 1
    end
    
    self:CheckAchievements()
end

function Achievements:TrackPlayerStats()
    local stats = GuildDeathLogDB.achievementStats
    
    -- Gold tracken
    local gold = math.floor(GetMoney() / 10000)
    if gold > (stats.max_gold_owned or 0) then
        stats.max_gold_owned = gold
    end
    
    -- Berufe tracken (Classic Era API)
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
                if skillRank > (stats.max_profession or 0) then
                    stats.max_profession = skillRank
                end
            -- Sekundaere Berufe
            elseif name == "Fishing" or name == "Angeln" then
                stats.fishing_skill = skillRank
            elseif name == "Cooking" or name == "Kochen" then
                stats.cooking_skill = skillRank
            elseif name == "First Aid" or name == "Erste Hilfe" then
                stats.firstaid_skill = skillRank
            end
        end
    end
    
    -- In Gilde?
    if IsInGuild() then
        stats.in_guild = 1
    end
    
    -- Mount check
    if IsMounted() then
        stats.has_mount = 1
        local speed = GetUnitSpeed("player")
        if speed > 14 then -- Schneller als 100% = Epic Mount
            stats.has_epic_mount = 1
        end
    end
    
    self:CheckAchievements()
end

function Achievements:OnDeathWitnessed(death)
    local stats = GuildDeathLogDB.achievementStats
    stats.deaths_witnessed = (stats.deaths_witnessed or 0) + 1
    self:CheckAchievements()
end

function Achievements:OnGuildDeath(death)
    local stats = GuildDeathLogDB.achievementStats
    stats.guild_deaths = (stats.guild_deaths or 0) + 1
    self:OnDeathWitnessed(death)
end

function Achievements:OnBookOpened()
    local stats = GuildDeathLogDB.achievementStats
    stats.book_opens = (stats.book_opens or 0) + 1
    self:CheckAchievements()
end

function Achievements:OnSync()
    local stats = GuildDeathLogDB.achievementStats
    stats.sync_count = (stats.sync_count or 0) + 1
    self:CheckAchievements()
end

function Achievements:OnDungeonComplete()
    local stats = GuildDeathLogDB.achievementStats
    stats.dungeons_completed = (stats.dungeons_completed or 0) + 1
    self:CheckAchievements()
end

function Achievements:CheckAchievements()
    local stats = GuildDeathLogDB.achievementStats
    local unlocked = GuildDeathLogDB.achievements
    
    for _, ach in ipairs(ACHIEVEMENT_DEFS) do
        if not unlocked[ach.id] then
            local value = 0
            
            if ach.type == "player_level" then
                value = UnitLevel("player")
            elseif ach.type == "playtime_days" then
                -- /played wird async abgefragt, nutze gespeicherten Wert
                value = stats.playtime_days or 0
            elseif ach.type == "gold_owned" then
                value = stats.max_gold_owned or 0
            elseif ach.type == "quests_completed" then
                value = stats.quests_completed or 0
            elseif ach.type == "enemies_killed" then
                value = stats.enemies_killed or 0
            elseif ach.type == "max_profession" then
                value = stats.max_profession or 0
            elseif ach.type == "fishing_skill" then
                value = stats.fishing_skill or 0
            elseif ach.type == "cooking_skill" then
                value = stats.cooking_skill or 0
            elseif ach.type == "firstaid_skill" then
                value = stats.firstaid_skill or 0
            elseif ach.type == "dungeons_completed" then
                value = stats.dungeons_completed or 0
            elseif ach.type == "groups_formed" then
                value = stats.groups_formed or 0
            elseif ach.type == "in_guild" then
                value = IsInGuild() and 1 or 0
            elseif ach.type == "has_mount" then
                value = stats.has_mount or 0
            elseif ach.type == "has_epic_mount" then
                value = stats.has_epic_mount or 0
            elseif ach.type == "midnight_login" then
                value = stats.midnight_login or 0
            elseif ach.type == "survived_low_hp" then
                value = stats.survived_low_hp or 0
            else
                value = stats[ach.type] or 0
            end
            
            if value >= ach.threshold then
                self:UnlockAchievement(ach)
            end
        end
    end
end

function Achievements:UnlockAchievement(ach)
    GuildDeathLogDB.achievements[ach.id] = {
        unlocked = true,
        date = time()
    }
    
    self:ShowAchievementPopup(ach)
    
    GDL:Print("|cffFFD100Achievement:|r " .. ach.name)
end

function Achievements:ShowAchievementPopup(ach)
    if not self.popup then
        local p = CreateFrame("Frame", "GDLAchievementPopup", UIParent, "BackdropTemplate")
        p:SetSize(300, 70)
        p:SetPoint("TOP", 0, -200)
        p:SetFrameStrata("FULLSCREEN_DIALOG")
        p:Hide()
        
        p:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            edgeSize = 20,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        p:SetBackdropColor(0.1, 0.08, 0.02, 0.95)
        p:SetBackdropBorderColor(1, 0.84, 0, 1)
        
        p.icon = p:CreateTexture(nil, "ARTWORK")
        p.icon:SetSize(40, 40)
        p.icon:SetPoint("LEFT", 15, 0)
        
        p.title = p:CreateFontString(nil, "OVERLAY")
        p.title:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        p.title:SetPoint("TOPLEFT", p.icon, "TOPRIGHT", 10, -2)
        p.title:SetTextColor(1, 0.84, 0)
        p.title:SetText("Achievement freigeschaltet!")
        
        p.name = p:CreateFontString(nil, "OVERLAY")
        p.name:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        p.name:SetPoint("TOPLEFT", p.title, "BOTTOMLEFT", 0, -2)
        p.name:SetTextColor(1, 1, 1)
        
        p.desc = p:CreateFontString(nil, "OVERLAY")
        p.desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        p.desc:SetPoint("TOPLEFT", p.name, "BOTTOMLEFT", 0, -2)
        p.desc:SetTextColor(0.7, 0.7, 0.7)
        
        self.popup = p
    end
    
    local p = self.popup
    p.icon:SetTexture(ach.icon)
    p.name:SetText(ach.name)
    p.desc:SetText(ach.desc)
    
    p:SetAlpha(1)
    p:Show()
    PlaySound(8959, "Master")
    
    C_Timer.After(5, function()
        p:Hide()
    end)
end

function Achievements:GetAllAchievements()
    return ACHIEVEMENT_DEFS
end

function Achievements:GetUnlocked()
    return GuildDeathLogDB.achievements or {}
end

function Achievements:GetStats()
    return GuildDeathLogDB.achievementStats or {}
end

function Achievements:GetProgress(achId)
    local stats = GuildDeathLogDB.achievementStats or {}
    
    for _, ach in ipairs(ACHIEVEMENT_DEFS) do
        if ach.id == achId then
            local value = 0
            
            if ach.type == "player_level" then
                value = UnitLevel("player")
            elseif ach.type == "playtime_days" then
                value = stats.playtime_days or 0
            elseif ach.type == "gold_owned" then
                value = stats.max_gold_owned or 0
            elseif ach.type == "max_profession" then
                value = stats.max_profession or 0
            elseif ach.type == "in_guild" then
                value = IsInGuild() and 1 or 0
            else
                value = stats[ach.type] or 0
            end
            
            return value, ach.threshold
        end
    end
    return 0, 0
end

function Achievements:GetDifficulty(achId)
    for _, ach in ipairs(ACHIEVEMENT_DEFS) do
        if ach.id == achId then
            return ach.difficulty or 1
        end
    end
    return 1
end

function Achievements:GetDifficultyColor(difficulty)
    local colors = {
        [1] = {0.2, 0.8, 0.2},  -- Leicht - Gruen
        [2] = {1.0, 0.8, 0.0},  -- Mittel - Gelb
        [3] = {0.8, 0.2, 0.2},  -- Schwer - Rot
        [4] = {0.6, 0.0, 0.8},  -- Geheim - Lila
    }
    return colors[difficulty] or colors[1]
end

function Achievements:GetDifficultyText(difficulty)
    local texts = {
        [1] = "|cff33CC33[Leicht/Easy]|r",
        [2] = "|cffFFCC00[Mittel/Medium]|r",
        [3] = "|cffCC3333[Schwer/Hard]|r",
        [4] = "|cff9900CC[Geheim/Secret]|r",
    }
    return texts[difficulty] or texts[1]
end

GDL:RegisterModule("Achievements", Achievements)
