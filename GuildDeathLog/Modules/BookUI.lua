-- ══════════════════════════════════════════════════════════════
-- MODUL: BookUI - DAS BUCH DER GEFALLENEN v3
-- Komplett überarbeitet mit allen Features
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local BookUI = {}

-- Konstanten
local BOOK_WIDTH = 950
local BOOK_HEIGHT = 540

-- Seitenbereiche (Titel oben, Content mit mehr Abstand)
local LEFT_PAGE = {x = 50, y = 70, width = 370, height = 370}
local RIGHT_PAGE = {x = 530, y = 70, width = 370, height = 370}

-- Abstand vom Titel zum Content
local CONTENT_OFFSET = 48

-- Dezente, warme Tintenfarben für Pergament (wie echte alte Tinte)
local CLASS_COLORS = {
    [1]={0.35,0.25,0.15},   -- Warrior - braune Tinte
    [2]={0.45,0.28,0.35},   -- Paladin - gedämpftes Rosa
    [3]={0.28,0.38,0.2},    -- Hunter - olivgrün
    [4]={0.45,0.4,0.18},    -- Rogue - senfgelb
    [5]={0.38,0.36,0.34},   -- Priest - grau
    [7]={0.18,0.28,0.38},   -- Shaman - gedämpftes Blau
    [8]={0.25,0.35,0.4},    -- Mage - blaugrau
    [9]={0.32,0.25,0.35},   -- Warlock - dunkellila
    [11]={0.45,0.28,0.12}   -- Druid - rostbraun
}

-- Standard Textfarbe (DUNKLE Sepia-Tinte für gute Lesbarkeit)
local INK_COLOR = {0.18, 0.14, 0.1}   -- Sehr dunkel
local INK_LIGHT = {0.28, 0.22, 0.16}  -- Mittel
local INK_FADED = {0.38, 0.32, 0.25}  -- Verblasst

-- Buch-Schriftart für Fließtext (MORPHEUS wie Titel, aber kleiner)
local BOOK_FONT = "Fonts\\MORPHEUS.TTF"
local BOOK_FONT_SIZE = 11

local CLASS_ICONS = {
    [1]="Interface\\Icons\\ClassIcon_Warrior", [2]="Interface\\Icons\\ClassIcon_Paladin",
    [3]="Interface\\Icons\\ClassIcon_Hunter", [4]="Interface\\Icons\\ClassIcon_Rogue",
    [5]="Interface\\Icons\\ClassIcon_Priest", [7]="Interface\\Icons\\ClassIcon_Shaman",
    [8]="Interface\\Icons\\ClassIcon_Mage", [9]="Interface\\Icons\\ClassIcon_Warlock",
    [11]="Interface\\Icons\\ClassIcon_Druid"
}

-- 9 Kapitel jetzt (mit Titel)
local CHAPTERS = {
    {id = "chronicle", nameDE = "Chronik", nameEN = "Chronicle"},
    {id = "guildmembers", nameDE = "Unsere Gilde", nameEN = "Our Guild"},
    {id = "statistics", nameDE = "Statistiken", nameEN = "Statistics"},
    {id = "milestones", nameDE = "Meilensteine", nameEN = "Milestones"},
    {id = "titles", nameDE = "Titel", nameEN = "Titles"},
    {id = "professions", nameDE = "Berufe", nameEN = "Professions"},
    {id = "rules", nameDE = "Regeln", nameEN = "Rules"},
    {id = "calendar", nameDE = "Kalender", nameEN = "Calendar"},
    {id = "settings", nameDE = "Einstellungen", nameEN = "Settings"},
}

local currentChapter = 1
local professionPage = 1

function BookUI:Initialize()
    C_Timer.After(0.5, function() self:CreateBook() end)
end

function BookUI:GetClassColor(classId) return CLASS_COLORS[classId] or {0.5, 0.5, 0.5} end
function BookUI:GetClassIcon(classId) return CLASS_ICONS[classId] or "Interface\\Icons\\INV_Misc_QuestionMark" end

-- ══════════════════════════════════════════════════════════════
-- DAS BUCH ERSTELLEN
-- ══════════════════════════════════════════════════════════════

function BookUI:CreateBook()
    local f = CreateFrame("Frame", "GDLBook", UIParent)
    f:SetSize(BOOK_WIDTH, BOOK_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    table.insert(UISpecialFrames, "GDLBook")
    
    -- Buch-Textur
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\GuildDeathLog\\Textures\\Book")
    
    -- LINKE SEITE
    local leftPage = CreateFrame("Frame", nil, f)
    leftPage:SetPoint("TOPLEFT", LEFT_PAGE.x, -LEFT_PAGE.y)
    leftPage:SetSize(LEFT_PAGE.width, LEFT_PAGE.height)
    f.leftPage = leftPage
    
    local leftTitle = leftPage:CreateFontString(nil, "OVERLAY")
    leftTitle:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    leftTitle:SetPoint("TOP", 0, 0)
    leftTitle:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
    f.leftTitle = leftTitle
    
    -- ScrollFrame für linke Seite (Content weiter unten)
    local leftScroll = CreateFrame("ScrollFrame", "GDLBookLeftScroll", leftPage, "UIPanelScrollFrameTemplate")
    leftScroll:SetPoint("TOPLEFT", 0, -CONTENT_OFFSET)
    leftScroll:SetPoint("BOTTOMRIGHT", -22, 5)
    f.leftScroll = leftScroll
    
    local leftContent = CreateFrame("Frame", nil, leftScroll)
    leftContent:SetSize(LEFT_PAGE.width - 30, 1)
    leftScroll:SetScrollChild(leftContent)
    f.leftContent = leftContent
    
    -- Scrollbar stylen
    local sb = GDLBookLeftScrollScrollBar
    if sb then sb:SetAlpha(0.3) end
    
    -- RECHTE SEITE
    local rightPage = CreateFrame("Frame", nil, f)
    rightPage:SetPoint("TOPLEFT", RIGHT_PAGE.x, -RIGHT_PAGE.y)
    rightPage:SetSize(RIGHT_PAGE.width, RIGHT_PAGE.height)
    f.rightPage = rightPage
    
    local rightTitle = rightPage:CreateFontString(nil, "OVERLAY")
    rightTitle:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    rightTitle:SetPoint("TOP", 0, 0)
    rightTitle:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
    f.rightTitle = rightTitle
    
    -- ScrollFrame für rechte Seite (Content weiter unten)
    local rightScroll = CreateFrame("ScrollFrame", "GDLBookRightScroll", rightPage, "UIPanelScrollFrameTemplate")
    rightScroll:SetPoint("TOPLEFT", 0, -CONTENT_OFFSET)
    rightScroll:SetPoint("BOTTOMRIGHT", -22, 5)
    f.rightScroll = rightScroll
    
    local rightContent = CreateFrame("Frame", nil, rightScroll)
    rightContent:SetSize(RIGHT_PAGE.width - 30, 1)
    rightScroll:SetScrollChild(rightContent)
    f.rightContent = rightContent
    
    local sb2 = GDLBookRightScrollScrollBar
    if sb2 then sb2:SetAlpha(0.3) end
    
    -- NAVIGATION (in die unteren Ecken der Seiten)
    local prevBtn = CreateFrame("Button", nil, f)
    prevBtn:SetSize(80, 20)
    prevBtn:SetPoint("BOTTOMLEFT", 60, 55)  -- Wieder etwas höher
    local prevText = prevBtn:CreateFontString(nil, "OVERLAY")
    prevText:SetFont("Fonts\\MORPHEUS.TTF", 12, "")
    prevText:SetAllPoints()
    prevText:SetText("< Zurueck")
    prevText:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
    prevBtn.text = prevText
    prevBtn:SetScript("OnEnter", function(s) s.text:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3]) end)
    prevBtn:SetScript("OnLeave", function(s) s.text:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3]) end)
    prevBtn:SetScript("OnClick", function() BookUI:PreviousChapter() end)
    f.prevBtn = prevBtn
    
    local nextBtn = CreateFrame("Button", nil, f)
    nextBtn:SetSize(80, 20)
    nextBtn:SetPoint("BOTTOMRIGHT", -60, 55)  -- Wieder etwas höher
    local nextText = nextBtn:CreateFontString(nil, "OVERLAY")
    nextText:SetFont("Fonts\\MORPHEUS.TTF", 12, "")
    nextText:SetAllPoints()
    nextText:SetText("Weiter >")
    nextText:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
    nextBtn.text = nextText
    nextBtn:SetScript("OnEnter", function(s) s.text:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3]) end)
    nextBtn:SetScript("OnLeave", function(s) s.text:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3]) end)
    nextBtn:SetScript("OnClick", function() BookUI:NextChapter() end)
    f.nextBtn = nextBtn
    
    local chapterInfo = f:CreateFontString(nil, "OVERLAY")
    chapterInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    chapterInfo:SetPoint("BOTTOM", 0, 18)
    chapterInfo:SetTextColor(0.32, 0.25, 0.18)
    f.chapterInfo = chapterInfo
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", -25, -25)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
    closeText:SetAllPoints()
    closeText:SetText("x")
    closeText:SetTextColor(0.35, 0.28, 0.2, 0.6)
    closeBtn.text = closeText
    closeBtn:SetScript("OnEnter", function(s) s.text:SetTextColor(0.55, 0.35, 0.25, 1) end)
    closeBtn:SetScript("OnLeave", function(s) s.text:SetTextColor(0.35, 0.28, 0.2, 0.6) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    self.book = f
    self:LoadChapter(1)
end

function BookUI:NextChapter()
    if currentChapter < #CHAPTERS then
        self:LoadChapter(currentChapter + 1)
        PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 844)
    end
end

function BookUI:PreviousChapter()
    if currentChapter > 1 then
        self:LoadChapter(currentChapter - 1)
        PlaySound(SOUNDKIT and SOUNDKIT.IG_QUEST_LOG_OPEN or 844)
    end
end

function BookUI:LoadChapter(index)
    if not self.book then return end
    currentChapter = index
    professionPage = 1
    
    local chapter = CHAPTERS[index]
    local isDE = GetLocale() == "deDE"
    local name = isDE and chapter.nameDE or chapter.nameEN
    
    self.book.chapterInfo:SetText(name .. " (" .. index .. "/" .. #CHAPTERS .. ")")
    self.book.prevBtn:SetAlpha(index > 1 and 1 or 0.3)
    self.book.nextBtn:SetAlpha(index < #CHAPTERS and 1 or 0.3)
    
    -- Scrollbars zurücksetzen
    if self.book.leftScroll then self.book.leftScroll:SetVerticalScroll(0) end
    if self.book.rightScroll then self.book.rightScroll:SetVerticalScroll(0) end
    
    if chapter.id == "chronicle" then self:LoadChronicle()
    elseif chapter.id == "guildmembers" then self:LoadGuildMembers()
    elseif chapter.id == "statistics" then self:LoadStatistics()
    elseif chapter.id == "milestones" then self:LoadMilestones()
    elseif chapter.id == "titles" then self:LoadTitles()
    elseif chapter.id == "professions" then self:LoadProfessions()
    elseif chapter.id == "rules" then self:LoadRules()
    elseif chapter.id == "calendar" then self:LoadCalendar()
    elseif chapter.id == "settings" then self:LoadSettings()
    end
end

-- ══════════════════════════════════════════════════════════════
-- HILFSFUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function BookUI:ClearContent(frame)
    if not frame then return end
    for _, c in pairs({frame:GetChildren()}) do c:Hide(); c:SetParent(nil) end
    for _, r in pairs({frame:GetRegions()}) do r:Hide(); r:SetParent(nil) end
end

function BookUI:GetClassName(classId)
    local isDE = GetLocale() == "deDE"
    local names = {
        [1] = isDE and "Krieger" or "Warrior", [2] = isDE and "Paladin" or "Paladin",
        [3] = isDE and "Jaeger" or "Hunter", [4] = isDE and "Schurke" or "Rogue",
        [5] = isDE and "Priester" or "Priest", [7] = isDE and "Schamane" or "Shaman",
        [8] = isDE and "Magier" or "Mage", [9] = isDE and "Hexer" or "Warlock",
        [11] = isDE and "Druide" or "Druid",
    }
    return names[classId] or "?"
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 1: CHRONIK (Die Gefallenen / Letzte Ruhe)
-- ══════════════════════════════════════════════════════════════

local MEMORIAL_TEXTS_DE = {
    "Moege ihre Seele in Frieden ruhen.",
    "Auf ewig unvergessen in den Hallen der Helden.",
    "Ihr Opfer wird niemals vergessen.",
    "Ein wahrer Held von Azeroth.",
    "Gefallen, aber niemals vergessen.",
    "Die Ahnen heissen sie willkommen.",
    "Ruhe nun, tapferer Kaempfer.",
    "Dein Mut lebt in uns weiter.",
    "In ewigem Gedenken.",
    "Die Sterne leuchten fuer dich.",
}

local MEMORIAL_TEXTS_EN = {
    "May their soul rest in peace.",
    "Forever remembered in the halls of heroes.",
    "Their sacrifice will never be forgotten.",
    "A true hero of Azeroth.",
    "Fallen, but never forgotten.",
    "The ancestors welcome them home.",
    "Rest now, brave warrior.",
    "Your courage lives on in us.",
    "In eternal memory.",
    "The stars shine for you.",
}

function BookUI:LoadChronicle()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    
    f.leftTitle:SetText(isDE and "Die Gefallenen" or "The Fallen")
    f.rightTitle:SetText(isDE and "Letzte Ruhe" or "Final Rest")
    
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    -- Daten aus ALLEN möglichen Quellen holen
    local deaths = {}
    
    -- 1. Versuche über GetGuildData (normale Methode)
    local guildData = GDL:GetGuildData()
    if guildData and guildData.deaths and #guildData.deaths > 0 then
        deaths = guildData.deaths
    end
    
    -- 2. Fallback: Direkt in GuildDeathLogDB.guilds suchen
    if #deaths == 0 and GuildDeathLogDB.guilds then
        for guildName, data in pairs(GuildDeathLogDB.guilds) do
            if data.deaths and #data.deaths > 0 then
                deaths = data.deaths
                break
            end
        end
    end
    
    -- 3. Fallback: Alte Struktur (GuildDeathLogDB.deaths)
    if #deaths == 0 and GuildDeathLogDB.deaths and #GuildDeathLogDB.deaths > 0 then
        deaths = GuildDeathLogDB.deaths
    end
    
    local sorted = {}
    for i, d in ipairs(deaths) do d._index = i; table.insert(sorted, d) end
    table.sort(sorted, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    local y = 0
    
    if #sorted == 0 then
        -- Linke Seite: Hinweis
        local noDeaths = f.leftContent:CreateFontString(nil, "OVERLAY")
        noDeaths:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        noDeaths:SetPoint("TOP", 0, -60)
        noDeaths:SetWidth(LEFT_PAGE.width - 40)
        noDeaths:SetTextColor(0.38, 0.3, 0.22)
        noDeaths:SetText(isDE and "Noch keine Gefallenen\nverzeichnet.\n\nMoegen alle Helden\nlange leben!" or "No fallen recorded yet.\n\nMay all heroes\nlive long!")
        f.leftContent:SetHeight(200)
        
        -- Rechte Seite: Schöner Text
        local ry = -40
        local header = f.rightContent:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        header:SetPoint("TOP", 0, ry)
        header:SetTextColor(0.28, 0.2, 0.14)
        header:SetText(isDE and "Das Buch ist leer" or "The Book is Empty")
        
        ry = ry - 40
        local desc = f.rightContent:CreateFontString(nil, "OVERLAY")
        desc:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        desc:SetPoint("TOP", 0, ry)
        desc:SetWidth(RIGHT_PAGE.width - 40)
        desc:SetTextColor(0.4, 0.32, 0.25)
        desc:SetText(isDE and 
            "Noch hat der Tod keinen\nHelden dieser Gilde ereilt.\n\nMoege es lange so bleiben." or
            "Death has not yet claimed\nany hero of this guild.\n\nMay it stay that way.")
        
        f.rightContent:SetHeight(200)
    else
        -- Todesfälle anzeigen
        for i, death in ipairs(sorted) do
            if i <= 12 then
                self:CreateDeathEntry(f.leftContent, death, y)
                y = y - 38
            end
        end
        f.leftContent:SetHeight(math.abs(y) + 20)
        
        -- Rechte Seite: Letzter Tod detailliert
        self:ShowLastDeathDetails(sorted[1])
    end
end

function BookUI:CreateDeathEntry(parent, death, yOffset)
    local entry = CreateFrame("Button", nil, parent)
    entry:SetSize(LEFT_PAGE.width - 30, 36)
    entry:SetPoint("TOP", 0, yOffset)
    
    local hl = entry:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(0.35, 0.28, 0.2, 0)
    entry.hl = hl
    
    local classId = death.classId or 1
    local icon = entry:CreateTexture(nil, "ARTWORK")
    icon:SetSize(26, 26)
    icon:SetPoint("LEFT", 2, 0)
    icon:SetTexture(self:GetClassIcon(classId))
    
    local color = self:GetClassColor(classId)
    local name = entry:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -2)
    name:SetTextColor(color[1], color[2], color[3])
    name:SetText(death.name or "?")
    
    local info = entry:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    info:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
    info:SetTextColor(0.4, 0.32, 0.25)
    local zone = death.zone or "?"
    if #zone > 18 then zone = zone:sub(1, 16) .. ".." end
    info:SetText("Lv" .. (death.level or "?") .. " - " .. zone)
    
    local dateText = entry:CreateFontString(nil, "OVERLAY")
    dateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    dateText:SetPoint("RIGHT", -3, 0)
    dateText:SetTextColor(0.38, 0.3, 0.22)
    if death.timestamp then dateText:SetText(date("%d.%m", death.timestamp)) end
    
    entry:SetScript("OnEnter", function(s) s.hl:SetColorTexture(0.35, 0.28, 0.2, 0.15) end)
    entry:SetScript("OnLeave", function(s) s.hl:SetColorTexture(0.35, 0.28, 0.2, 0) end)
    entry.deathData = death
    entry:SetScript("OnClick", function(s) BookUI:ShowLastDeathDetails(s.deathData) end)
end

function BookUI:ShowLastDeathDetails(death)
    local f = self.book
    local isDE = GetLocale() == "deDE"
    
    f.rightTitle:SetText(isDE and "Letzte Ruhe" or "Final Rest")
    self:ClearContent(f.rightContent)
    
    local y = -35  -- Mehr Abstand zum Titel
    local classId = death.classId or 1
    
    -- Klassen-Icon (größer, zentriert)
    local icon = f.rightContent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(56, 56)
    icon:SetPoint("TOP", 0, y)
    icon:SetTexture(self:GetClassIcon(classId))
    
    y = y - 70
    
    -- Name in Klassenfarbe
    local color = self:GetClassColor(classId)
    local nameText = f.rightContent:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    nameText:SetPoint("TOP", 0, y)
    nameText:SetTextColor(color[1], color[2], color[3])
    nameText:SetText(death.name or "?")
    
    y = y - 26
    
    -- Level und Klasse
    local classText = f.rightContent:CreateFontString(nil, "OVERLAY")
    classText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    classText:SetPoint("TOP", 0, y)
    classText:SetTextColor(0.35, 0.28, 0.22)
    classText:SetText("Level " .. (death.level or "?") .. " " .. self:GetClassName(classId))
    
    y = y - 35
    
    -- Zone (ohne extra Label - kompakter)
    if death.zone then
        local zoneLabel = f.rightContent:CreateFontString(nil, "OVERLAY")
        zoneLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        zoneLabel:SetPoint("TOP", 0, y)
        zoneLabel:SetTextColor(0.38, 0.3, 0.22)
        zoneLabel:SetText(isDE and "Gefallen in:" or "Fell in:")
        y = y - 16
        
        local zoneText = f.rightContent:CreateFontString(nil, "OVERLAY")
        zoneText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        zoneText:SetPoint("TOP", 0, y)
        zoneText:SetTextColor(0.42, 0.34, 0.26)
        zoneText:SetText(death.zone)
        y = y - 30
    end
    
    -- Datum
    if death.timestamp then
        local dateLabel = f.rightContent:CreateFontString(nil, "OVERLAY")
        dateLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        dateLabel:SetPoint("TOP", 0, y)
        dateLabel:SetTextColor(0.38, 0.3, 0.22)
        dateLabel:SetText(isDE and "Am:" or "On:")
        y = y - 16
        
        local dateText = f.rightContent:CreateFontString(nil, "OVERLAY")
        dateText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        dateText:SetPoint("TOP", 0, y)
        dateText:SetTextColor(0.42, 0.34, 0.26)
        dateText:SetText(date("%d.%m.%Y %H:%M", death.timestamp))
        y = y - 35
    end
    
    -- Zufälliger Gedenkspruch (etwas größer, kursiv-ähnlich)
    local texts = isDE and MEMORIAL_TEXTS_DE or MEMORIAL_TEXTS_EN
    local randomText = texts[math.random(#texts)]
    
    local memorial = f.rightContent:CreateFontString(nil, "OVERLAY")
    memorial:SetFont("Fonts\\MORPHEUS.TTF", 11, "")
    memorial:SetPoint("TOP", 0, y)
    memorial:SetWidth(RIGHT_PAGE.width - 35)
    memorial:SetTextColor(0.45, 0.38, 0.3)
    memorial:SetText("\"" .. randomText .. "\"")
    
    f.rightContent:SetHeight(320)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 2: RUHMESHALLE
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadGuildMembers()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    
    f.leftTitle:SetText(isDE and "Unsere Helden" or "Our Heroes")
    f.rightTitle:SetText(isDE and "Gildenstatistik" or "Guild Statistics")
    
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    -- Gildenmitglieder holen
    local members = {}
    local numMembers = GetNumGuildMembers()
    local classCount = {}
    local totalLevel = 0
    local level60Count = 0
    
    for i = 1, numMembers do
        local name, rank, rankIndex, level, class, zone, note, officerNote, online, status, classFile, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        if name then
            local shortName = name:match("([^%-]+)")
            local classId = 1
            if classFile == "WARRIOR" then classId = 1
            elseif classFile == "PALADIN" then classId = 2
            elseif classFile == "HUNTER" then classId = 3
            elseif classFile == "ROGUE" then classId = 4
            elseif classFile == "PRIEST" then classId = 5
            elseif classFile == "SHAMAN" then classId = 7
            elseif classFile == "MAGE" then classId = 8
            elseif classFile == "WARLOCK" then classId = 9
            elseif classFile == "DRUID" then classId = 11
            end
            
            table.insert(members, {
                name = shortName,
                level = level or 1,
                classId = classId,
                online = online,
                rank = rank or "",
                zone = zone or ""
            })
            
            classCount[classId] = (classCount[classId] or 0) + 1
            totalLevel = totalLevel + (level or 1)
            if level == 60 then level60Count = level60Count + 1 end
        end
    end
    
    -- Nach Level sortieren (höchstes zuerst)
    table.sort(members, function(a, b) 
        if a.level == b.level then return a.name < b.name end
        return a.level > b.level 
    end)
    
    local ly = 0
    
    if #members == 0 then
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        no:SetPoint("TOP", 0, -60)
        no:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
        no:SetText(isDE and "Keine Gildenmitglieder\ngefunden." or "No guild members\nfound.")
        f.leftContent:SetHeight(200)
    else
        -- Mitgliederliste (ALLE anzeigen - scrollbar ist vorhanden)
        for i = 1, #members do
            local m = members[i]
            local color = self:GetClassColor(m.classId)
            
            local row = f.leftContent:CreateFontString(nil, "OVERLAY")
            row:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            row:SetPoint("TOPLEFT", 5, ly)
            row:SetWidth(LEFT_PAGE.width - 40)
            
            -- Online-Indikator
            local onlineMarker = m.online and "|cff44ff44*|r " or "  "
            local levelStr = string.format("%2d", m.level)
            
            row:SetText(onlineMarker .. levelStr .. "  " .. m.name)
            row:SetTextColor(color[1], color[2], color[3])
            
            ly = ly - 16  -- Etwas kompakter
        end
        
        f.leftContent:SetHeight(math.abs(ly) + 20)
    end
    
    -- Rechte Seite: Gildenstatistik
    local ry = 0
    
    -- Gildenname
    local guildName = GDL.currentGuildName or (isDE and "Unbekannt" or "Unknown")
    local guildHeader = f.rightContent:CreateFontString(nil, "OVERLAY")
    guildHeader:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
    guildHeader:SetPoint("TOP", 0, ry)
    guildHeader:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
    guildHeader:SetText("< " .. guildName .. " >")
    ry = ry - 30
    
    -- Statistiken
    local stats = {
        {label = isDE and "Mitglieder:" or "Members:", value = #members},
        {label = isDE and "Level 60:" or "Level 60:", value = level60Count},
        {label = isDE and "Durchschnitt:" or "Average:", value = #members > 0 and string.format("%.1f", totalLevel / #members) or "0"},
    }
    
    for _, stat in ipairs(stats) do
        local row = f.rightContent:CreateFontString(nil, "OVERLAY")
        row:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        row:SetPoint("TOPLEFT", 20, ry)
        row:SetTextColor(INK_LIGHT[1], INK_LIGHT[2], INK_LIGHT[3])
        row:SetText(stat.label)
        
        local val = f.rightContent:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        val:SetPoint("TOPLEFT", 120, ry)
        val:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
        val:SetText(tostring(stat.value))
        
        ry = ry - 18
    end
    
    ry = ry - 15
    
    -- Klassenverteilung
    local classHeader = f.rightContent:CreateFontString(nil, "OVERLAY")
    classHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    classHeader:SetPoint("TOPLEFT", 20, ry)
    classHeader:SetTextColor(INK_LIGHT[1], INK_LIGHT[2], INK_LIGHT[3])
    classHeader:SetText(isDE and "Klassen:" or "Classes:")
    ry = ry - 18
    
    local classNames = {
        [1] = isDE and "Krieger" or "Warrior",
        [2] = isDE and "Paladin" or "Paladin", 
        [3] = isDE and "Jaeger" or "Hunter",
        [4] = isDE and "Schurke" or "Rogue",
        [5] = isDE and "Priester" or "Priest",
        [7] = isDE and "Schamane" or "Shaman",
        [8] = isDE and "Magier" or "Mage",
        [9] = isDE and "Hexenmeister" or "Warlock",
        [11] = isDE and "Druide" or "Druid"
    }
    
    for classId, count in pairs(classCount) do
        local color = self:GetClassColor(classId)
        local row = f.rightContent:CreateFontString(nil, "OVERLAY")
        row:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        row:SetPoint("TOPLEFT", 30, ry)
        row:SetTextColor(color[1], color[2], color[3])
        row:SetText((classNames[classId] or "?") .. ": " .. count)
        ry = ry - 14
    end
    
    f.rightContent:SetHeight(math.abs(ry) + 20)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 3: STATISTIKEN
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadStatistics()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Statistiken" or "Statistics")
    f.rightTitle:SetText(isDE and "Gefahrenzonen" or "Danger Zones")
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    -- Daten aus ALLEN möglichen Quellen holen (wie in LoadChronicle)
    local deaths = {}
    
    local guildData = GDL:GetGuildData()
    if guildData and guildData.deaths and #guildData.deaths > 0 then
        deaths = guildData.deaths
    end
    
    if #deaths == 0 and GuildDeathLogDB.guilds then
        for guildName, data in pairs(GuildDeathLogDB.guilds) do
            if data.deaths and #data.deaths > 0 then
                deaths = data.deaths
                break
            end
        end
    end
    
    if #deaths == 0 and GuildDeathLogDB.deaths and #GuildDeathLogDB.deaths > 0 then
        deaths = GuildDeathLogDB.deaths
    end
    local byZone = {}
    local byLevel = {low = 0, mid = 0, high = 0}
    local byClass = {}
    local thisWeek, thisMonth = 0, 0
    local now = time()
    
    for _, d in ipairs(deaths) do
        -- Zone
        local zone = d.zone or "Unbekannt"
        byZone[zone] = (byZone[zone] or 0) + 1
        
        -- Level
        local l = d.level or 1
        if l <= 20 then byLevel.low = byLevel.low + 1
        elseif l <= 40 then byLevel.mid = byLevel.mid + 1
        else byLevel.high = byLevel.high + 1 end
        
        -- Klasse
        local cid = d.classId or 0
        byClass[cid] = (byClass[cid] or 0) + 1
        
        -- Zeit
        if d.timestamp then
            if now - d.timestamp < 604800 then thisWeek = thisWeek + 1 end
            if now - d.timestamp < 2592000 then thisMonth = thisMonth + 1 end
        end
    end
    
    -- LINKE SEITE: Allgemeine Stats
    local y = 0
    
    local stats = {
        {isDE and "Tode gesamt:" or "Total deaths:", #deaths},
        {isDE and "Diese Woche:" or "This week:", thisWeek},
        {isDE and "Dieser Monat:" or "This month:", thisMonth},
    }
    
    for _, s in ipairs(stats) do
        local row = CreateFrame("Frame", nil, f.leftContent)
        row:SetSize(LEFT_PAGE.width - 40, 22)
        row:SetPoint("TOP", 0, y)
        
        local label = row:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        label:SetPoint("LEFT", 5, 0)
        label:SetTextColor(0.32, 0.25, 0.18)
        label:SetText(s[1])
        
        local val = row:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
        val:SetPoint("RIGHT", -5, 0)
        val:SetTextColor(0.5, 0.15, 0.1)
        val:SetText(tostring(s[2]))
        
        y = y - 24
    end
    
    y = y - 15
    
    -- Level-Verteilung
    local lvlHeader = f.leftContent:CreateFontString(nil, "OVERLAY")
    lvlHeader:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    lvlHeader:SetPoint("TOPLEFT", 5, y)
    lvlHeader:SetTextColor(0.32, 0.25, 0.18)
    lvlHeader:SetText(isDE and "Nach Level:" or "By Level:")
    y = y - 20
    
    local lvlData = {
        {"1-20", byLevel.low, {0.3, 0.6, 0.3}},
        {"21-40", byLevel.mid, {0.6, 0.5, 0.2}},
        {"41-60", byLevel.high, {0.6, 0.2, 0.2}},
    }
    
    for _, lv in ipairs(lvlData) do
        local row = f.leftContent:CreateFontString(nil, "OVERLAY")
        row:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        row:SetPoint("TOPLEFT", 15, y)
        row:SetTextColor(lv[3][1], lv[3][2], lv[3][3])
        row:SetText(lv[1] .. ": " .. lv[2])
        y = y - 16
    end
    
    y = y - 15
    
    -- Klassen-Verteilung
    local classHeader = f.leftContent:CreateFontString(nil, "OVERLAY")
    classHeader:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    classHeader:SetPoint("TOPLEFT", 5, y)
    classHeader:SetTextColor(0.32, 0.25, 0.18)
    classHeader:SetText(isDE and "Nach Klasse:" or "By Class:")
    y = y - 20
    
    local sortedClasses = {}
    for cid, count in pairs(byClass) do
        if cid > 0 then table.insert(sortedClasses, {classId = cid, count = count}) end
    end
    table.sort(sortedClasses, function(a, b) return a.count > b.count end)
    
    for i, cs in ipairs(sortedClasses) do
        if i <= 9 then
            local color = self:GetClassColor(cs.classId)
            local row = f.leftContent:CreateFontString(nil, "OVERLAY")
            row:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            row:SetPoint("TOPLEFT", 15, y)
            row:SetTextColor(color[1], color[2], color[3])
            row:SetText(self:GetClassName(cs.classId) .. ": " .. cs.count)
            y = y - 15
        end
    end
    
    f.leftContent:SetHeight(math.abs(y) + 20)
    
    -- RECHTE SEITE: Gefahrenzonen
    local ry = 0
    
    local sortedZones = {}
    for z, c in pairs(byZone) do table.insert(sortedZones, {zone = z, count = c}) end
    table.sort(sortedZones, function(a, b) return a.count > b.count end)
    
    if #sortedZones == 0 then
        local no = f.rightContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        no:SetPoint("TOP", 0, -80)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText(isDE and "Keine Daten" or "No data")
    else
        for i, z in ipairs(sortedZones) do
            if i <= 15 then
                local zoneName = z.zone
                if #zoneName > 24 then zoneName = zoneName:sub(1, 22) .. ".." end
                
                local row = f.rightContent:CreateFontString(nil, "OVERLAY")
                row:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                row:SetPoint("TOP", 0, ry)
                
                -- Farbe nach Gefährlichkeit
                local dangerColor = {0.4, 0.32, 0.25}
                if z.count >= 5 then dangerColor = {0.7, 0.3, 0.2}
                elseif z.count >= 3 then dangerColor = {0.6, 0.4, 0.2}
                elseif z.count >= 2 then dangerColor = {0.5, 0.4, 0.25} end
                
                row:SetTextColor(dangerColor[1], dangerColor[2], dangerColor[3])
                row:SetText(i .. ". " .. zoneName .. " (" .. z.count .. ")")
                ry = ry - 18
            end
        end
    end
    
    f.rightContent:SetHeight(math.abs(ry) + 20)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 4: MEILENSTEINE (klickbar mit Beschreibungen)
-- ══════════════════════════════════════════════════════════════

local selectedMilestoneCategory = nil

function BookUI:LoadMilestones()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Meilensteine" or "Milestones")
    f.rightTitle:SetText(selectedMilestoneCategory and (isDE and "Details" or "Details") or (isDE and "Fortschritt" or "Progress"))
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        no:SetPoint("TOP", 0, -80)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText("Milestones-Modul nicht geladen")
        f.leftContent:SetHeight(200)
        return
    end
    
    local unlocked, total = Milestones:GetMilestoneProgress()
    
    local categories = {
        {id = "level", nameDE = "Level", nameEN = "Level", icon = "Interface\\Icons\\Spell_Holy_WordFortitude"},
        {id = "dungeon", nameDE = "Dungeons", nameEN = "Dungeons", icon = "Interface\\Icons\\INV_Misc_Key_03"},
        {id = "raid", nameDE = "Raids", nameEN = "Raids", icon = "Interface\\Icons\\INV_Helmet_06"},
        {id = "profession", nameDE = "Berufe", nameEN = "Professions", icon = "Interface\\Icons\\Trade_BlackSmithing"},
        {id = "kills", nameDE = "Kills", nameEN = "Kills", icon = "Interface\\Icons\\Ability_DualWield"},
        {id = "survival", nameDE = "Spielzeit", nameEN = "Playtime", icon = "Interface\\Icons\\Spell_Nature_TimeStop"},
        {id = "wealth", nameDE = "Gold", nameEN = "Gold", icon = "Interface\\Icons\\INV_Misc_Coin_17"},
        {id = "meta", nameDE = "Meta", nameEN = "Meta", icon = "Interface\\Icons\\INV_Misc_Rune_01"},
    }
    
    local y = 0
    
    -- Gesamt-Fortschritt
    local totalRow = f.leftContent:CreateFontString(nil, "OVERLAY")
    totalRow:SetFont("Fonts\\MORPHEUS.TTF", 13, "")
    totalRow:SetPoint("TOP", 0, y)
    totalRow:SetTextColor(0.28, 0.2, 0.14)
    local percent = total > 0 and math.floor((unlocked / total) * 100) or 0
    totalRow:SetText((isDE and "Gesamt: " or "Total: ") .. unlocked .. "/" .. total .. " (" .. percent .. "%)")
    y = y - 25
    
    for _, cat in ipairs(categories) do
        local catUnlocked, catTotal = Milestones:GetCategoryProgress(cat.id)
        
        local row = CreateFrame("Button", nil, f.leftContent)
        row:SetSize(LEFT_PAGE.width - 40, 24)
        row:SetPoint("TOP", 0, y)
        
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(0.35, 0.28, 0.2, selectedMilestoneCategory == cat.id and 0.25 or 0)
        row.hl = hl
        
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 5, 0)
        icon:SetTexture(cat.icon)
        
        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
        name:SetTextColor(0.32, 0.25, 0.18)
        name:SetText(isDE and cat.nameDE or cat.nameEN)
        
        -- Fortschrittsfarbe: rot → gelb → grün
        local prog = row:CreateFontString(nil, "OVERLAY")
        prog:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        prog:SetPoint("RIGHT", -10, 0)
        local percent = catTotal > 0 and (catUnlocked / catTotal) or 0
        local r, g, b
        if percent >= 1.0 then
            r, g, b = 0.15, 0.45, 0.15  -- Grün (fertig)
        elseif percent >= 0.66 then
            r, g, b = 0.35, 0.45, 0.15  -- Gelbgrün
        elseif percent >= 0.33 then
            r, g, b = 0.50, 0.40, 0.15  -- Gelb/Orange
        elseif percent > 0 then
            r, g, b = 0.50, 0.25, 0.15  -- Orange/Rot
        else
            r, g, b = 0.45, 0.35, 0.25  -- Grau (nichts)
        end
        prog:SetTextColor(r, g, b)
        prog:SetText(catUnlocked .. "/" .. catTotal)
        
        row.category = cat.id
        row:SetScript("OnEnter", function(self) if selectedMilestoneCategory ~= self.category then self.hl:SetColorTexture(0.35, 0.28, 0.2, 0.15) end end)
        row:SetScript("OnLeave", function(self) if selectedMilestoneCategory ~= self.category then self.hl:SetColorTexture(0.35, 0.28, 0.2, 0) end end)
        row:SetScript("OnClick", function(self) selectedMilestoneCategory = self.category; BookUI:LoadMilestones() end)
        y = y - 26
    end
    
    if selectedMilestoneCategory then
        y = y - 8
        local backBtn = CreateFrame("Button", nil, f.leftContent)
        backBtn:SetSize(90, 18)
        backBtn:SetPoint("TOP", 0, y)
        local backText = backBtn:CreateFontString(nil, "OVERLAY")
        backText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        backText:SetAllPoints()
        backText:SetText(isDE and "< Uebersicht" or "< Overview")
        backText:SetTextColor(0.4, 0.32, 0.25)
        backBtn:SetScript("OnClick", function() selectedMilestoneCategory = nil; BookUI:LoadMilestones() end)
    end
    
    f.leftContent:SetHeight(math.abs(y) + 30)
    
    if selectedMilestoneCategory then
        self:ShowMilestoneCategory(selectedMilestoneCategory)
    else
        self:ShowRecentMilestones()
    end
end

function BookUI:ShowMilestoneCategory(categoryId)
    local f = self.book
    local isDE = GetLocale() == "deDE"
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return end
    
    local milestones = Milestones:GetMilestonesByCategory(categoryId)
    local ry = 0
    
    for _, m in ipairs(milestones) do
        local isUnlocked = Milestones:IsMilestoneUnlocked(m.id)
        
        local row = CreateFrame("Button", nil, f.rightContent)
        row:SetSize(RIGHT_PAGE.width - 30, 38)
        row:SetPoint("TOP", 0, ry)
        
        local hl = row:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(0.35, 0.28, 0.2, 0)
        row.hl = hl
        
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("LEFT", 2, 0)
        icon:SetTexture(m.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        if not isUnlocked then icon:SetDesaturated(true) end
        
        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, -2)
        name:SetWidth(RIGHT_PAGE.width - 70)
        name:SetJustifyH("LEFT")
        name:SetTextColor(isUnlocked and 0.2 or 0.45, isUnlocked and 0.55 or 0.38, isUnlocked and 0.2 or 0.3)
        name:SetText((isUnlocked and "[X] " or "[  ] ") .. (m.name or m.id))
        
        local desc = row:CreateFontString(nil, "OVERLAY")
        desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -1)
        desc:SetWidth(RIGHT_PAGE.width - 70)
        desc:SetJustifyH("LEFT")
        desc:SetTextColor(0.4, 0.32, 0.25)
        desc:SetText(m.desc or "")
        
        row.milestoneData = m
        row.isUnlocked = isUnlocked
        row:SetScript("OnEnter", function(self)
            self.hl:SetColorTexture(0.35, 0.28, 0.2, 0.1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(self.milestoneData.name, self.isUnlocked and 0.2 or 0.8, self.isUnlocked and 0.7 or 0.7, self.isUnlocked and 0.2 or 0.5)
            GameTooltip:AddLine(self.isUnlocked and (isDE and "Erreicht!" or "Achieved!") or (isDE and "Noch nicht erreicht" or "Not yet achieved"), 0.6, 0.5, 0.4)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.milestoneData.desc or "", 0.9, 0.85, 0.75, true)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self) self.hl:SetColorTexture(0.35, 0.28, 0.2, 0); GameTooltip:Hide() end)
        ry = ry - 40
    end
    f.rightContent:SetHeight(math.abs(ry) + 20)
end

function BookUI:ShowRecentMilestones()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones then return end
    
    local ry = 0
    local hint = f.rightContent:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hint:SetPoint("TOP", 0, ry)
    hint:SetWidth(RIGHT_PAGE.width - 30)
    hint:SetTextColor(0.4, 0.32, 0.25)
    hint:SetText(isDE and "Klicke links auf eine Kategorie\num Details zu sehen!" or "Click a category on the left\nto see details!")
    ry = ry - 40
    
    local recentHeader = f.rightContent:CreateFontString(nil, "OVERLAY")
    recentHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    recentHeader:SetPoint("TOP", 0, ry)
    recentHeader:SetTextColor(0.32, 0.25, 0.18)
    recentHeader:SetText(isDE and "Zuletzt erreicht:" or "Recently achieved:")
    ry = ry - 18
    
    local charMilestones = Milestones:GetCharacterMilestones()
    local recent = {}
    for id, data in pairs(charMilestones) do
        local ts = type(data) == "table" and data.timestamp or data
        table.insert(recent, {id = id, timestamp = type(ts) == "number" and ts or 0})
    end
    table.sort(recent, function(a, b) return a.timestamp > b.timestamp end)
    
    local defs = Milestones:GetAllMilestones()
    local defById = {}
    for _, m in ipairs(defs) do defById[m.id] = m end
    
    local shown = 0
    for _, r in ipairs(recent) do
        if shown < 8 then
            local m = defById[r.id]
            if m then
                local row = f.rightContent:CreateFontString(nil, "OVERLAY")
                row:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                row:SetPoint("TOP", 0, ry)
                row:SetTextColor(0.2, 0.5, 0.2)
                row:SetText("[X] " .. (m.name or r.id))
                ry = ry - 15
                shown = shown + 1
            end
        end
    end
    
    if shown == 0 then
        local noRecent = f.rightContent:CreateFontString(nil, "OVERLAY")
        noRecent:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        noRecent:SetPoint("TOP", 0, ry)
        noRecent:SetTextColor(0.4, 0.32, 0.25)
        noRecent:SetText(isDE and "Noch keine Meilensteine\nerreicht!" or "No milestones achieved yet!")
    end
    f.rightContent:SetHeight(300)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 5: TITEL
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadTitles()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Verfuegbare Titel" or "Available Titles")
    f.rightTitle:SetText(isDE and "Aktiver Titel" or "Active Title")
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local Titles = GDL:GetModule("Titles")
    local Milestones = GDL:GetModule("Milestones")
    
    -- Hilfsfunktion: Farben dämpfen für Pergament-Lesbarkeit
    local function DampenColor(color)
        if not color then return {0.35, 0.28, 0.2} end
        -- Farben um 35% dämpfen und leicht bräunen für Pergament-Look
        return {
            color[1] * 0.65 + 0.05,
            color[2] * 0.6 + 0.05,
            color[3] * 0.55 + 0.05
        }
    end
    
    if not Titles then
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        no:SetPoint("TOP", 0, -80)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText("Titles-Modul nicht geladen")
        f.leftContent:SetHeight(200)
        return
    end
    
    local allTitles = Titles:GetAllTitles() or {}
    local selectedTitle = Titles:GetSelectedTitle()
    local activeId = selectedTitle and selectedTitle.id or nil
    
    local y = 0
    local unlockedCount = 0
    
    for _, title in ipairs(allTitles) do
        local isUnlocked = false
        if Milestones and title.requirement then
            isUnlocked = Milestones:IsMilestoneUnlocked(title.requirement)
        end
        
        if isUnlocked then
            unlockedCount = unlockedCount + 1
            
            local row = CreateFrame("Button", nil, f.leftContent)
            row:SetSize(LEFT_PAGE.width - 40, 32)
            row:SetPoint("TOP", 0, y)
            
            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            if activeId and activeId == title.id then
                hl:SetColorTexture(0.2, 0.4, 0.2, 0.2)
            else
                hl:SetColorTexture(0.35, 0.28, 0.2, 0)
            end
            row.hl = hl
            
            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(24, 24)
            icon:SetPoint("LEFT", 5, 0)
            icon:SetTexture(title.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            
            local name = row:CreateFontString(nil, "OVERLAY")
            name:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            -- Gedämpfte Farbe für Pergament
            local color = DampenColor(title.color)
            name:SetTextColor(color[1], color[2], color[3])
            name:SetText(title.name or "?")
            
            if activeId and activeId == title.id then
                local active = row:CreateFontString(nil, "OVERLAY")
                active:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                active:SetPoint("RIGHT", -5, 0)
                active:SetTextColor(0.2, 0.6, 0.2)
                active:SetText(isDE and "[AKTIV]" or "[ACTIVE]")
            end
            
            row.titleId = title.id
            row.titleData = title
            row.titleColor = color
            row:SetScript("OnEnter", function(self)
                if not (activeId and activeId == self.titleId) then
                    self.hl:SetColorTexture(0.35, 0.28, 0.2, 0.15)
                end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.titleData.name, self.titleColor[1], self.titleColor[2], self.titleColor[3])
                GameTooltip:AddLine(self.titleData.desc or "", 0.7, 0.6, 0.5, true)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(isDE and "Klicken zum Aktivieren" or "Click to activate", 0.5, 0.8, 0.5)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                if not (activeId and activeId == self.titleId) then
                    self.hl:SetColorTexture(0.35, 0.28, 0.2, 0)
                end
                GameTooltip:Hide()
            end)
            row:SetScript("OnClick", function(self)
                if Titles.SetSelectedTitle then
                    Titles:SetSelectedTitle(self.titleId)
                    BookUI:LoadTitles()
                end
            end)
            
            y = y - 34
        end
    end
    
    if unlockedCount == 0 then
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        no:SetPoint("TOP", 0, -80)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText(isDE and "Noch keine Titel\nfreigeschaltet!" or "No titles\nunlocked yet!")
    end
    
    f.leftContent:SetHeight(math.abs(y) + 20)
    
    -- RECHTE SEITE: Aktiver Titel + Info
    local ry = -30
    
    if selectedTitle then
        local icon = f.rightContent:CreateTexture(nil, "ARTWORK")
        icon:SetSize(48, 48)
        icon:SetPoint("TOP", 0, ry)
        icon:SetTexture(selectedTitle.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        
        ry = ry - 60
        
        local name = f.rightContent:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
        name:SetPoint("TOP", 0, ry)
        -- Gedämpfte Farbe auch für aktiven Titel
        local color = DampenColor(selectedTitle.color)
        name:SetTextColor(color[1], color[2], color[3])
        name:SetText(selectedTitle.name or "?")
        
        ry = ry - 25
        
        local desc = f.rightContent:CreateFontString(nil, "OVERLAY")
        desc:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        desc:SetPoint("TOP", 0, ry)
        desc:SetWidth(RIGHT_PAGE.width - 40)
        desc:SetTextColor(0.4, 0.32, 0.25)
        desc:SetText(selectedTitle.desc or "")
        
        -- Deaktivieren-Button
        ry = -200
        local deactivateBtn = CreateFrame("Button", nil, f.rightContent)
        deactivateBtn:SetSize(120, 25)
        deactivateBtn:SetPoint("TOP", 0, ry)
        
        local btnBg = deactivateBtn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetColorTexture(0.4, 0.25, 0.2, 0.3)
        
        local btnText = deactivateBtn:CreateFontString(nil, "OVERLAY")
        btnText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        btnText:SetAllPoints()
        btnText:SetText(isDE and "Deaktivieren" or "Deactivate")
        btnText:SetTextColor(0.6, 0.35, 0.3)
        
        deactivateBtn:SetScript("OnEnter", function() btnBg:SetColorTexture(0.5, 0.3, 0.25, 0.4) end)
        deactivateBtn:SetScript("OnLeave", function() btnBg:SetColorTexture(0.4, 0.25, 0.2, 0.3) end)
        deactivateBtn:SetScript("OnClick", function()
            if Titles and Titles.SetSelectedTitle then
                Titles:SetSelectedTitle(nil)
                BookUI:LoadTitles()
            end
        end)
    else
        local noTitle = f.rightContent:CreateFontString(nil, "OVERLAY")
        noTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noTitle:SetPoint("TOP", 0, ry)
        noTitle:SetTextColor(0.4, 0.32, 0.25)
        noTitle:SetText(isDE and "Kein Titel aktiv" or "No title active")
        
        ry = ry - 40
        
        local hint = f.rightContent:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        hint:SetPoint("TOP", 0, ry)
        hint:SetWidth(RIGHT_PAGE.width - 40)
        hint:SetTextColor(0.4, 0.32, 0.25)
        hint:SetText(isDE and "Schalte Titel durch\nMeilensteine frei!" or "Unlock titles by\nachieving milestones!")
    end
    
    f.rightContent:SetHeight(300)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 6: BERUFE (mit Pagination)
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadProfessions()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Gildenberufe" or "Guild Professions")
    f.rightTitle:SetText(isDE and "Uebersicht" or "Overview")
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local profs = GuildDeathLogDB.professions or {}
    
    local players = {}
    for name, data in pairs(profs) do
        table.insert(players, {
            name = name,
            prof1 = data.prof1,
            prof2 = data.prof2,
            level = data.level,
            classId = data.classId,
        })
    end
    table.sort(players, function(a, b) return (a.level or 0) > (b.level or 0) end)
    
    local playersPerPage = 8
    local totalPages = math.ceil(#players / playersPerPage)
    if totalPages < 1 then totalPages = 1 end
    if professionPage > totalPages then professionPage = totalPages end
    
    local startIdx = (professionPage - 1) * playersPerPage + 1
    local endIdx = math.min(professionPage * playersPerPage, #players)
    
    local y = 0
    
    -- Header mit Seitenzahl
    local header = f.leftContent:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    header:SetPoint("TOPLEFT", 5, y)
    header:SetTextColor(0.32, 0.25, 0.18)
    header:SetText((isDE and "Spieler: " or "Players: ") .. #players .. " (Seite " .. professionPage .. "/" .. totalPages .. ")")
    
    y = y - 25
    
    if #players == 0 then
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        no:SetPoint("TOP", 0, -80)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText(isDE and "Keine Daten.\n/gdl profscan" or "No data.\n/gdl profscan")
    else
        for i = startIdx, endIdx do
            local p = players[i]
            if p then
                local color = self:GetClassColor(p.classId or 1)
                
                local nameText = f.leftContent:CreateFontString(nil, "OVERLAY")
                nameText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
                nameText:SetPoint("TOPLEFT", 5, y)
                nameText:SetTextColor(color[1], color[2], color[3])
                local displayName = p.name
                if p.level and p.level > 0 then displayName = displayName .. " (" .. p.level .. ")" end
                nameText:SetText(displayName)
                
                y = y - 14
                
                local profText = ""
                if p.prof1 and p.prof1.name and p.prof1.name ~= "" then
                    profText = p.prof1.name
                    if p.prof1.skill and p.prof1.skill > 0 then
                        profText = profText .. " " .. p.prof1.skill
                        if p.prof1.max and p.prof1.max > 0 then
                            profText = profText .. "/" .. p.prof1.max
                        end
                    end
                end
                if p.prof2 and p.prof2.name and p.prof2.name ~= "" then
                    if profText ~= "" then profText = profText .. ", " end
                    profText = profText .. p.prof2.name
                    if p.prof2.skill and p.prof2.skill > 0 then
                        profText = profText .. " " .. p.prof2.skill
                        if p.prof2.max and p.prof2.max > 0 then
                            profText = profText .. "/" .. p.prof2.max
                        end
                    end
                end
                
                if profText ~= "" then
                    local profs = f.leftContent:CreateFontString(nil, "OVERLAY")
                    profs:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                    profs:SetPoint("TOPLEFT", 15, y)
                    profs:SetTextColor(0.4, 0.32, 0.25)
                    profs:SetText(profText)
                end
                
                y = y - 18
            end
        end
    end
    
    -- Pagination Buttons
    if totalPages > 1 then
        y = y - 15
        
        if professionPage > 1 then
            local prevPage = CreateFrame("Button", nil, f.leftContent)
            prevPage:SetSize(60, 18)
            prevPage:SetPoint("TOPLEFT", 20, y)
            local prevText = prevPage:CreateFontString(nil, "OVERLAY")
            prevText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            prevText:SetAllPoints()
            prevText:SetText("< Zurueck")
            prevText:SetTextColor(0.35, 0.28, 0.2)
            prevPage:SetScript("OnClick", function()
                professionPage = professionPage - 1
                BookUI:LoadProfessions()
            end)
        end
        
        if professionPage < totalPages then
            local nextPage = CreateFrame("Button", nil, f.leftContent)
            nextPage:SetSize(60, 18)
            nextPage:SetPoint("TOPRIGHT", -20, y)
            local nextText = nextPage:CreateFontString(nil, "OVERLAY")
            nextText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            nextText:SetAllPoints()
            nextText:SetText("Weiter >")
            nextText:SetTextColor(0.35, 0.28, 0.2)
            nextPage:SetScript("OnClick", function()
                professionPage = professionPage + 1
                BookUI:LoadProfessions()
            end)
        end
    end
    
    f.leftContent:SetHeight(math.abs(y) + 40)
    
    -- RECHTE SEITE: Berufe-Zusammenfassung
    local ry = 0
    
    local profCounts = {}
    for _, p in ipairs(players) do
        if p.prof1 and p.prof1.name and p.prof1.name ~= "" then
            local key = p.prof1.name
            if not profCounts[key] then profCounts[key] = {count = 0, maxSkill = 0} end
            profCounts[key].count = profCounts[key].count + 1
            if p.prof1.skill and p.prof1.skill > profCounts[key].maxSkill then
                profCounts[key].maxSkill = p.prof1.skill
            end
        end
        if p.prof2 and p.prof2.name and p.prof2.name ~= "" then
            local key = p.prof2.name
            if not profCounts[key] then profCounts[key] = {count = 0, maxSkill = 0} end
            profCounts[key].count = profCounts[key].count + 1
            if p.prof2.skill and p.prof2.skill > profCounts[key].maxSkill then
                profCounts[key].maxSkill = p.prof2.skill
            end
        end
    end
    
    local sortedProfs = {}
    for name, data in pairs(profCounts) do
        table.insert(sortedProfs, {name = name, count = data.count, maxSkill = data.maxSkill})
    end
    table.sort(sortedProfs, function(a, b) return a.count > b.count end)
    
    local profHeader = f.rightContent:CreateFontString(nil, "OVERLAY")
    profHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    profHeader:SetPoint("TOP", 0, ry)
    profHeader:SetTextColor(0.32, 0.25, 0.18)
    profHeader:SetText(isDE and "Berufe in der Gilde:" or "Guild Professions:")
    
    ry = ry - 22
    
    for i, prof in ipairs(sortedProfs) do
        local row = f.rightContent:CreateFontString(nil, "OVERLAY")
        row:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        row:SetPoint("TOP", 0, ry)
        row:SetTextColor(0.4, 0.32, 0.25)
        
        local skillStr = ""
        if prof.maxSkill > 0 then skillStr = " (max " .. prof.maxSkill .. ")" end
        row:SetText(prof.name .. ": " .. prof.count .. skillStr)
        ry = ry - 15
    end
    
    f.rightContent:SetHeight(math.abs(ry) + 20)
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 7: REGELN (wie ein echtes Buch - fließender Text)
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadRules()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Gildenregeln" or "Guild Rules")
    f.rightTitle:SetText("")  -- Rechte Seite hat keinen Titel (Buch-Stil)
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local Rules = GDL:GetModule("GuildRules")
    local txt = Rules and Rules.GetRules and Rules:GetRules() or ""
    
    -- Bearbeiten-Button für Officers
    local canEdit = (Rules and Rules.CanEdit and Rules:CanEdit()) or GDL:IsGuildOfficer() or IsGuildLeader()
    
    if txt ~= "" then
        -- Text parsen - jede Zeile einzeln
        local lines = {}
        for line in txt:gmatch("[^\n]+") do
            if line:match("%S") then
                table.insert(lines, line)
            end
        end
        
        -- Maximale Höhe pro Seite (in Pixel)
        local maxPageHeight = LEFT_PAGE.height - 60
        
        -- Linke Seite füllen
        local ly = 0
        local leftStartIndex = 1
        local rightStartIndex = #lines + 1  -- Default: nichts für rechts
        
        for i, line in ipairs(lines) do
            local lineText = f.leftContent:CreateFontString(nil, "OVERLAY")
            lineText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            lineText:SetPoint("TOPLEFT", 0, ly)
            lineText:SetWidth(LEFT_PAGE.width - 25)
            lineText:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
            lineText:SetJustifyH("LEFT")
            lineText:SetWordWrap(true)
            lineText:SetText(line)
            
            local textHeight = lineText:GetStringHeight()
            
            -- Prüfen ob wir die Seite überschreiten würden
            if math.abs(ly) + textHeight > maxPageHeight then
                -- Diese Zeile gehört zur rechten Seite
                lineText:Hide()
                lineText:SetParent(nil)
                rightStartIndex = i
                break
            end
            
            ly = ly - textHeight - 4
        end
        
        f.leftContent:SetHeight(math.abs(ly) + 20)
        
        -- Rechte Seite - ab rightStartIndex
        local ry = 0
        for i = rightStartIndex, #lines do
            local line = lines[i]
            local lineText = f.rightContent:CreateFontString(nil, "OVERLAY")
            lineText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            lineText:SetPoint("TOPLEFT", 0, ry)
            lineText:SetWidth(RIGHT_PAGE.width - 25)
            lineText:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
            lineText:SetJustifyH("LEFT")
            lineText:SetWordWrap(true)
            lineText:SetText(line)
            
            local textHeight = lineText:GetStringHeight()
            ry = ry - textHeight - 4
        end
        
        -- Bearbeiten-Link unten rechts
        if canEdit then
            local editBtn = CreateFrame("Button", nil, f.rightContent)
            editBtn:SetSize(80, 16)
            editBtn:SetPoint("BOTTOMRIGHT", f.rightContent, "BOTTOMRIGHT", 0, -30)
            
            local editText = editBtn:CreateFontString(nil, "OVERLAY")
            editText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            editText:SetAllPoints()
            editText:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
            editText:SetText(isDE and "bearbeiten..." or "edit...")
            editBtn.text = editText
            
            editBtn:SetScript("OnEnter", function(self) 
                self.text:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3]) 
            end)
            editBtn:SetScript("OnLeave", function(self) 
                self.text:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3]) 
            end)
            editBtn:SetScript("OnClick", function()
                if Rules and Rules.ShowWindow then
                    Rules:ShowWindow()
                end
            end)
        end
        
        f.rightContent:SetHeight(math.abs(ry) + 50)
    else
        -- Keine Regeln vorhanden
        local y = -60
        local no = f.leftContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        no:SetPoint("TOP", 0, y)
        no:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
        no:SetText(isDE and "Keine Regeln" or "No Rules")
        
        y = y - 35
        local hint = f.leftContent:CreateFontString(nil, "OVERLAY")
        hint:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        hint:SetPoint("TOP", 0, y)
        hint:SetWidth(LEFT_PAGE.width - 40)
        hint:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
        
        if canEdit then
            hint:SetText(isDE and "Klicke auf 'bearbeiten' um\nRegeln hinzuzufuegen." or "Click 'edit' to\nadd rules.")
            
            local editBtn = CreateFrame("Button", nil, f.rightContent)
            editBtn:SetSize(80, 16)
            editBtn:SetPoint("CENTER", 0, 0)
            
            local editText = editBtn:CreateFontString(nil, "OVERLAY")
            editText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            editText:SetAllPoints()
            editText:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
            editText:SetText(isDE and "bearbeiten..." or "edit...")
            editBtn.text = editText
            
            editBtn:SetScript("OnEnter", function(self) 
                self.text:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3]) 
            end)
            editBtn:SetScript("OnLeave", function(self) 
                self.text:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3]) 
            end)
            editBtn:SetScript("OnClick", function()
                if Rules and Rules.ShowWindow then
                    Rules:ShowWindow()
                end
            end)
        else
            hint:SetText(isDE and "Die Gildenleitung hat noch\nkeine Regeln festgelegt." or "Guild leadership has not\nyet set any rules.")
        end
        
        f.leftContent:SetHeight(200)
        f.rightContent:SetHeight(100)
    end
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 8: KALENDER (mit 2 Monaten + Accept/Decline)
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadCalendar()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Kalender" or "Calendar")
    f.rightTitle:SetText("Events")
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local now = date("*t")
    local months = isDE and {"Januar","Februar","Maerz","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember"} or {"January","February","March","April","May","June","July","August","September","October","November","December"}
    local events = GuildDeathLogDB.calendarEvents or {}
    local days = isDE and {"Mo","Di","Mi","Do","Fr","Sa","So"} or {"Mo","Tu","We","Th","Fr","Sa","Su"}
    
    -- Funktion um einen Monat zu zeichnen (kompakt für 3 Monate)
    local function DrawMonth(year, month, startY)
        local dw = 34  -- Kompaktere Zellen für 3 Monate
        local sx = -((7 * dw) / 2) + dw/2
        local y = startY
        
        -- Monatsname
        local h = f.leftContent:CreateFontString(nil, "OVERLAY")
        h:SetFont("Fonts\\MORPHEUS.TTF", 11, "")
        h:SetPoint("TOP", 0, y)
        h:SetTextColor(INK_COLOR[1], INK_COLOR[2], INK_COLOR[3])
        h:SetText(months[month] .. " " .. year)
        y = y - 15
        
        -- Wochentage
        for i, d in ipairs(days) do
            local dl = f.leftContent:CreateFontString(nil, "OVERLAY")
            dl:SetFont("Fonts\\FRIZQT__.TTF", 7, "")
            dl:SetPoint("TOP", sx + (i-1)*dw, y)
            dl:SetTextColor(INK_FADED[1], INK_FADED[2], INK_FADED[3])
            dl:SetText(d)
        end
        y = y - 11
        
        local first = date("*t", time{year=year, month=month, day=1})
        local off = first.wday - 2; if off < 0 then off = 6 end
        local dim = ({31,28,31,30,31,30,31,31,30,31,30,31})[month]
        if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
            if month == 2 then dim = 29 end
        end
        
        local cd = 1
        for w = 0, 5 do
            for d = 0, 6 do
                if w * 7 + d >= off and cd <= dim then
                    local dayBtn = CreateFrame("Button", nil, f.leftContent)
                    dayBtn:SetSize(28, 12)
                    dayBtn:SetPoint("TOP", sx + d * dw, y - w * 12)
                    
                    local dn = dayBtn:CreateFontString(nil, "OVERLAY")
                    dn:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                    dn:SetAllPoints()
                    
                    local hasEvent = false
                    local dayKey = string.format("%04d-%02d-%02d", year, month, cd)
                    for _, ev in ipairs(events) do
                        if ev.date == dayKey then hasEvent = true; break end
                    end
                    
                    local isToday = (cd == now.day and month == now.month and year == now.year)
                    
                    if isToday then
                        dn:SetTextColor(0.65, 0.45, 0.12)
                        dn:SetText("[" .. cd .. "]")
                    elseif hasEvent then
                        dn:SetTextColor(0.28, 0.52, 0.28)
                        dn:SetText("*" .. cd .. "*")
                    else
                        dn:SetTextColor(INK_LIGHT[1], INK_LIGHT[2], INK_LIGHT[3])
                        dn:SetText(tostring(cd))
                    end
                    
                    dayBtn.day = cd
                    dayBtn.dayKey = dayKey
                    dayBtn.monthName = months[month]
                    dayBtn.year = year
                    dayBtn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:ClearLines()
                        GameTooltip:AddLine(self.day .. ". " .. self.monthName, 0.9, 0.8, 0.6)
                        local dayEvents = {}
                        for _, ev in ipairs(events) do
                            if ev.date == self.dayKey then table.insert(dayEvents, ev) end
                        end
                        if #dayEvents > 0 then
                            for _, ev in ipairs(dayEvents) do
                                GameTooltip:AddLine(ev.title or "Event", 0.5, 0.8, 0.5)
                                if ev.attendees then
                                    local accepted = 0
                                    for _, a in ipairs(ev.attendees) do
                                        if a.status == "accepted" then accepted = accepted + 1 end
                                    end
                                    GameTooltip:AddLine("  " .. accepted .. (isDE and " Zusagen" or " accepted"), 0.4, 0.6, 0.4)
                                end
                            end
                        else
                            GameTooltip:AddLine(isDE and "Keine Events" or "No events", 0.5, 0.4, 0.35)
                        end
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(isDE and "Klicken zum Hinzufuegen" or "Click to add event", 0.4, 0.6, 0.4)
                        GameTooltip:Show()
                    end)
                    dayBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                    dayBtn:SetScript("OnClick", function(self)
                        BookUI:ShowAddEventDialog(self.dayKey, self.day, self.monthName, self.year)
                    end)
                    cd = cd + 1
                end
            end
        end
        
        -- Rückgabe: Endposition für nächsten Monat
        return y - (6 * 12) - 10
    end
    
    -- Erster Monat (aktuell)
    local endY = DrawMonth(now.year, now.month, 0)
    
    -- Zweiter Monat (nächster)
    local nextMonth = now.month + 1
    local nextYear = now.year
    if nextMonth > 12 then
        nextMonth = 1
        nextYear = nextYear + 1
    end
    local endY2 = DrawMonth(nextYear, nextMonth, endY)
    
    -- Dritter Monat (übernächster)
    local thirdMonth = nextMonth + 1
    local thirdYear = nextYear
    if thirdMonth > 12 then
        thirdMonth = 1
        thirdYear = thirdYear + 1
    end
    DrawMonth(thirdYear, thirdMonth, endY2)
    
    f.leftContent:SetHeight(math.abs(endY2) + 150)
    
    -- RECHTE SEITE: Event-Liste mit Accept/Decline
    local ry = 0
    local upcomingHeader = f.rightContent:CreateFontString(nil, "OVERLAY")
    upcomingHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    upcomingHeader:SetPoint("TOP", 0, ry)
    upcomingHeader:SetTextColor(0.32, 0.25, 0.18)
    upcomingHeader:SetText(isDE and "Kommende Events:" or "Upcoming Events:")
    ry = ry - 20
    
    local sortedEvents = {}
    for i, ev in ipairs(events) do
        ev._index = i
        table.insert(sortedEvents, ev)
    end
    table.sort(sortedEvents, function(a, b) return (a.date or "") < (b.date or "") end)
    
    local playerName = UnitName("player")
    local shown = 0
    for _, ev in ipairs(sortedEvents) do
        if shown < 4 then  -- Nur 4 Events um Überlappung zu vermeiden
            local row = CreateFrame("Button", nil, f.rightContent)
            row:SetSize(RIGHT_PAGE.width - 30, 70)  -- Höhere Rows
            row:SetPoint("TOP", 0, ry)
            
            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            hl:SetColorTexture(0.35, 0.28, 0.2, 0)
            row.hl = hl
            
            -- Titel
            local title = row:CreateFontString(nil, "OVERLAY")
            title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            title:SetPoint("TOPLEFT", 5, -5)
            title:SetTextColor(0.32, 0.48, 0.32)
            title:SetText(ev.title or "Event")
            
            -- Datum und Creator
            local dateStr = row:CreateFontString(nil, "OVERLAY")
            dateStr:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            dateStr:SetPoint("TOPLEFT", 5, -20)
            dateStr:SetTextColor(0.38, 0.3, 0.22)
            dateStr:SetText((ev.date or "") .. " | " .. (ev.creator or "?"))
            
            -- Teilnehmer-Zähler
            local attendeeCount = 0
            local myStatus = nil
            ev.attendees = ev.attendees or {}
            for _, a in ipairs(ev.attendees) do
                if a.status == "accepted" then attendeeCount = attendeeCount + 1 end
                if a.name == playerName then myStatus = a.status end
            end
            
            local attendeeText = row:CreateFontString(nil, "OVERLAY")
            attendeeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            attendeeText:SetPoint("TOPLEFT", 5, -35)
            attendeeText:SetTextColor(0.38, 0.45, 0.38)
            attendeeText:SetText(attendeeCount .. (isDE and " Zusagen" or " accepted"))
            
            -- Accept Button - weiter unten
            local acceptBtn = CreateFrame("Button", nil, row)
            acceptBtn:SetSize(38, 18)
            acceptBtn:SetPoint("BOTTOMLEFT", 5, 8)
            local acceptBg = acceptBtn:CreateTexture(nil, "BACKGROUND")
            acceptBg:SetAllPoints()
            acceptBg:SetColorTexture(myStatus == "accepted" and 0.18 or 0.12, myStatus == "accepted" and 0.4 or 0.25, myStatus == "accepted" and 0.18 or 0.12, 0.7)
            local acceptText = acceptBtn:CreateFontString(nil, "OVERLAY")
            acceptText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            acceptText:SetAllPoints()
            acceptText:SetText(myStatus == "accepted" and "JA" or "+")
            acceptText:SetTextColor(0.55, 0.75, 0.55)
            acceptBtn.eventData = ev
            acceptBtn:SetScript("OnClick", function(self)
                BookUI:ShowAcceptDialog(self.eventData)
            end)
            acceptBtn:SetScript("OnEnter", function() acceptBg:SetColorTexture(0.22, 0.45, 0.22, 0.8) end)
            acceptBtn:SetScript("OnLeave", function() acceptBg:SetColorTexture(myStatus == "accepted" and 0.18 or 0.12, myStatus == "accepted" and 0.4 or 0.25, myStatus == "accepted" and 0.18 or 0.12, 0.7) end)
            
            -- Decline Button
            local declineBtn = CreateFrame("Button", nil, row)
            declineBtn:SetSize(38, 18)
            declineBtn:SetPoint("LEFT", acceptBtn, "RIGHT", 6, 0)
            local declineBg = declineBtn:CreateTexture(nil, "BACKGROUND")
            declineBg:SetAllPoints()
            declineBg:SetColorTexture(myStatus == "declined" and 0.4 or 0.25, myStatus == "declined" and 0.18 or 0.12, myStatus == "declined" and 0.18 or 0.12, 0.7)
            local declineText = declineBtn:CreateFontString(nil, "OVERLAY")
            declineText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            declineText:SetAllPoints()
            declineText:SetText(myStatus == "declined" and "NEIN" or "-")
            declineText:SetTextColor(0.75, 0.55, 0.55)
            declineBtn.eventData = ev
            declineBtn:SetScript("OnClick", function(self)
                BookUI:DeclineEvent(self.eventData)
            end)
            declineBtn:SetScript("OnEnter", function() declineBg:SetColorTexture(0.45, 0.22, 0.22, 0.8) end)
            declineBtn:SetScript("OnLeave", function() declineBg:SetColorTexture(myStatus == "declined" and 0.4 or 0.25, myStatus == "declined" and 0.18 or 0.12, myStatus == "declined" and 0.18 or 0.12, 0.7) end)
            
            -- Delete Button (nur Creator) - dezenter
            if ev.creator == playerName then
                local delBtn = CreateFrame("Button", nil, row)
                delBtn:SetSize(14, 14)
                delBtn:SetPoint("TOPRIGHT", -4, -5)
                local delText = delBtn:CreateFontString(nil, "OVERLAY")
                delText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
                delText:SetAllPoints()
                delText:SetText("x")
                delText:SetTextColor(0.45, 0.28, 0.28, 0.5)
                delBtn:SetScript("OnEnter", function() delText:SetTextColor(0.6, 0.3, 0.3, 0.9) end)
                delBtn:SetScript("OnLeave", function() delText:SetTextColor(0.45, 0.28, 0.28, 0.5) end)
                delBtn.eventIndex = ev._index
                delBtn:SetScript("OnClick", function(self)
                    table.remove(GuildDeathLogDB.calendarEvents, self.eventIndex)
                    BookUI:LoadCalendar()
                end)
            end
            
            -- Tooltip mit Teilnehmern
            row.eventData = ev
            row:SetScript("OnEnter", function(self)
                self.hl:SetColorTexture(0.35, 0.28, 0.2, 0.1)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self.eventData.title or "Event", 0.9, 0.8, 0.6)
                GameTooltip:AddLine(self.eventData.date .. " | " .. (self.eventData.creator or "?"), 0.6, 0.5, 0.4)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(isDE and "Teilnehmer:" or "Attendees:", 0.7, 0.7, 0.6)
                local hasAttendees = false
                for _, a in ipairs(self.eventData.attendees or {}) do
                    if a.status == "accepted" then
                        local noteStr = a.note and a.note ~= "" and (" [" .. a.note .. "]") or ""
                        GameTooltip:AddLine("  + " .. a.name .. noteStr, 0.4, 0.7, 0.4)
                        hasAttendees = true
                    end
                end
                for _, a in ipairs(self.eventData.attendees or {}) do
                    if a.status == "declined" then
                        GameTooltip:AddLine("  - " .. a.name, 0.6, 0.4, 0.4)
                        hasAttendees = true
                    end
                end
                if not hasAttendees then
                    GameTooltip:AddLine("  " .. (isDE and "Noch keine" or "None yet"), 0.5, 0.4, 0.35)
                end
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function(self)
                self.hl:SetColorTexture(0.35, 0.28, 0.2, 0)
                GameTooltip:Hide()
            end)
            
            ry = ry - 75  -- Mehr Abstand zwischen Events
            shown = shown + 1
        end
    end
    
    if #events == 0 then
        local no = f.rightContent:CreateFontString(nil, "OVERLAY")
        no:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        no:SetPoint("TOP", 0, ry - 20)
        no:SetTextColor(0.4, 0.32, 0.25)
        no:SetText(isDE and "Keine Events." or "No events.")
    end
    
    f.rightContent:SetHeight(math.abs(ry) + 30)
end

function BookUI:ShowAcceptDialog(eventData)
    local isDE = GetLocale() == "deDE"
    if self.acceptDialog then self.acceptDialog:Hide() end
    
    local d = CreateFrame("Frame", nil, UIParent)
    d:SetSize(250, 100)
    d:SetPoint("CENTER")
    d:SetFrameStrata("DIALOG")
    
    local bg = d:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.12, 0.1, 0.95)
    
    local title = d:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    title:SetPoint("TOP", 0, -10)
    title:SetTextColor(0.9, 0.8, 0.6)
    title:SetText(isDE and "Rolle/Notiz (optional):" or "Role/Note (optional):")
    
    local editBox = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    editBox:SetSize(180, 22)
    editBox:SetPoint("TOP", 0, -32)
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(20)
    editBox:SetText("")
    
    local hint = d:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    hint:SetPoint("TOP", editBox, "BOTTOM", 0, -2)
    hint:SetTextColor(0.5, 0.45, 0.4)
    hint:SetText("z.B. Tank, Heal, DD, Reserve...")
    
    local okBtn = CreateFrame("Button", nil, d)
    okBtn:SetSize(70, 20)
    okBtn:SetPoint("BOTTOMLEFT", 30, 10)
    local okBg = okBtn:CreateTexture(nil, "BACKGROUND")
    okBg:SetAllPoints()
    okBg:SetColorTexture(0.25, 0.4, 0.25, 0.8)
    local okText = okBtn:CreateFontString(nil, "OVERLAY")
    okText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    okText:SetAllPoints()
    okText:SetText(isDE and "Zusagen" or "Accept")
    okText:SetTextColor(0.8, 0.9, 0.8)
    okBtn:SetScript("OnClick", function()
        local note = editBox:GetText()
        BookUI:AcceptEvent(eventData, note)
        d:Hide()
    end)
    
    local cancelBtn = CreateFrame("Button", nil, d)
    cancelBtn:SetSize(70, 20)
    cancelBtn:SetPoint("BOTTOMRIGHT", -30, 10)
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetAllPoints()
    cancelBg:SetColorTexture(0.35, 0.25, 0.25, 0.8)
    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    cancelText:SetAllPoints()
    cancelText:SetText(isDE and "Abbrechen" or "Cancel")
    cancelText:SetTextColor(0.9, 0.8, 0.8)
    cancelBtn:SetScript("OnClick", function() d:Hide() end)
    
    editBox:SetScript("OnEnterPressed", function() okBtn:Click() end)
    editBox:SetScript("OnEscapePressed", function() d:Hide() end)
    
    self.acceptDialog = d
    d:Show()
end

function BookUI:AcceptEvent(eventData, note)
    local playerName = UnitName("player")
    eventData.attendees = eventData.attendees or {}
    
    -- Vorherigen Eintrag entfernen
    for i, a in ipairs(eventData.attendees) do
        if a.name == playerName then
            table.remove(eventData.attendees, i)
            break
        end
    end
    
    table.insert(eventData.attendees, {
        name = playerName,
        note = note or "",
        status = "accepted",
        timestamp = time()
    })
    
    self:LoadCalendar()
end

function BookUI:DeclineEvent(eventData)
    local playerName = UnitName("player")
    eventData.attendees = eventData.attendees or {}
    
    for i, a in ipairs(eventData.attendees) do
        if a.name == playerName then
            table.remove(eventData.attendees, i)
            break
        end
    end
    
    table.insert(eventData.attendees, {
        name = playerName,
        status = "declined",
        timestamp = time()
    })
    
    self:LoadCalendar()
end

function BookUI:ShowAddEventDialog(dayKey, day, month, year)
    local isDE = GetLocale() == "deDE"
    if self.eventDialog then self.eventDialog:Hide() end
    
    local d = CreateFrame("Frame", nil, UIParent)
    d:SetSize(280, 110)
    d:SetPoint("CENTER")
    d:SetFrameStrata("DIALOG")
    
    local bg = d:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.12, 0.1, 0.95)
    
    local title = d:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 13, "")
    title:SetPoint("TOP", 0, -10)
    title:SetTextColor(0.9, 0.8, 0.6)
    title:SetText((isDE and "Event am " or "Event on ") .. day .. ". " .. month)
    
    local editBox = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    editBox:SetSize(200, 22)
    editBox:SetPoint("TOP", 0, -35)
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(50)
    
    local addBtn = CreateFrame("Button", nil, d)
    addBtn:SetSize(80, 20)
    addBtn:SetPoint("BOTTOMLEFT", 30, 12)
    local addBg = addBtn:CreateTexture(nil, "BACKGROUND")
    addBg:SetAllPoints()
    addBg:SetColorTexture(0.25, 0.4, 0.25, 0.8)
    local addText = addBtn:CreateFontString(nil, "OVERLAY")
    addText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    addText:SetAllPoints()
    addText:SetText(isDE and "Erstellen" or "Create")
    addText:SetTextColor(0.8, 0.9, 0.8)
    addBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        if text and text ~= "" then
            GuildDeathLogDB.calendarEvents = GuildDeathLogDB.calendarEvents or {}
            table.insert(GuildDeathLogDB.calendarEvents, {
                date = dayKey,
                title = text,
                creator = UnitName("player"),
                attendees = {}
            })
            
            -- Chat-Nachricht für alle
            local playerName = UnitName("player")
            local dateStr = day .. ". " .. month
            if IsInGuild() then
                SendChatMessage("[GDL] " .. playerName .. " hat ein Event erstellt: \"" .. text .. "\" am " .. dateStr, "GUILD")
            end
            GDL:Print(isDE and ("Event erstellt: " .. text .. " am " .. dateStr) or ("Event created: " .. text .. " on " .. dateStr))
            
            d:Hide()
            BookUI:LoadCalendar()
        end
    end)
    
    local cancelBtn = CreateFrame("Button", nil, d)
    cancelBtn:SetSize(80, 20)
    cancelBtn:SetPoint("BOTTOMRIGHT", -30, 12)
    local cancelBg = cancelBtn:CreateTexture(nil, "BACKGROUND")
    cancelBg:SetAllPoints()
    cancelBg:SetColorTexture(0.4, 0.25, 0.25, 0.8)
    local cancelText = cancelBtn:CreateFontString(nil, "OVERLAY")
    cancelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    cancelText:SetAllPoints()
    cancelText:SetText(isDE and "Abbrechen" or "Cancel")
    cancelText:SetTextColor(0.9, 0.8, 0.8)
    cancelBtn:SetScript("OnClick", function() d:Hide() end)
    
    editBox:SetScript("OnEnterPressed", function() addBtn:Click() end)
    editBox:SetScript("OnEscapePressed", function() d:Hide() end)
    
    self.eventDialog = d
    d:Show()
end

-- ══════════════════════════════════════════════════════════════
-- KAPITEL 9: EINSTELLUNGEN (ohne /befehle)
-- ══════════════════════════════════════════════════════════════

function BookUI:LoadSettings()
    local f = self.book
    local isDE = GetLocale() == "deDE"
    f.leftTitle:SetText(isDE and "Einstellungen" or "Settings")
    f.rightTitle:SetText("Info")
    self:ClearContent(f.leftContent)
    self:ClearContent(f.rightContent)
    
    local settings = GuildDeathLogDB.settings or {}
    local opts = {
        {key="announce", de="Gildenchat bei Tod", en="Guild chat on death"},
        {key="sound", de="Sound abspielen", en="Play sound"},
        {key="overlay", de="Todes-Popup anzeigen", en="Show death popup"},
        {key="mapMarkers", de="Karten-Marker", en="Map markers"},
        {key="milestoneAnnounce", de="Meilenstein im Chat", en="Milestone in chat"},
        {key="milestonePopup", de="Meilenstein-Popup", en="Milestone popup"},
    }
    
    local y = 0
    for _, o in ipairs(opts) do
        local row = CreateFrame("Frame", nil, f.leftContent)
        row:SetSize(LEFT_PAGE.width - 40, 26)
        row:SetPoint("TOP", 0, y)
        
        local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        cb:SetPoint("LEFT", 0, 0)
        cb:SetSize(22, 22)
        cb:SetChecked(settings[o.key] or false)
        cb.key = o.key
        cb:SetScript("OnClick", function(s)
            GuildDeathLogDB.settings[s.key] = s:GetChecked()
        end)
        
        local l = row:CreateFontString(nil, "OVERLAY")
        l:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        l:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        l:SetTextColor(0.32, 0.25, 0.18)
        l:SetText(isDE and o.de or o.en)
        
        y = y - 28
    end
    
    f.leftContent:SetHeight(math.abs(y) + 20)
    
    -- RECHTE SEITE: Info
    local ry = -20
    
    local titleInfo = f.rightContent:CreateFontString(nil, "OVERLAY")
    titleInfo:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
    titleInfo:SetPoint("TOP", 0, ry)
    titleInfo:SetTextColor(0.28, 0.2, 0.14)
    titleInfo:SetText("Das Buch der Gefallenen")
    
    ry = ry - 25
    
    local version = f.rightContent:CreateFontString(nil, "OVERLAY")
    version:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    version:SetPoint("TOP", 0, ry)
    version:SetTextColor(0.4, 0.32, 0.25)
    version:SetText("Version " .. (GDL.version or "?"))
    
    ry = ry - 35
    
    local guildName = GetGuildInfo("player") or "?"
    local guildInfo = f.rightContent:CreateFontString(nil, "OVERLAY")
    guildInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    guildInfo:SetPoint("TOP", 0, ry)
    guildInfo:SetTextColor(0.4, 0.32, 0.25)
    guildInfo:SetText((isDE and "Gilde: " or "Guild: ") .. guildName)
    
    ry = ry - 35
    
    local info = f.rightContent:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    info:SetPoint("TOP", 0, ry)
    info:SetWidth(RIGHT_PAGE.width - 40)
    info:SetTextColor(0.4, 0.32, 0.25)
    info:SetText(isDE and 
        "Daten werden automatisch\nmit der Gilde synchronisiert.\n\nMeilensteine und Titel\nwerden beim Spielen\nautomatisch freigeschaltet." or
        "Data syncs automatically\nwith your guild.\n\nMilestones and titles\nunlock automatically\nas you play.")
    
    f.rightContent:SetHeight(300)
end

-- ══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════

function BookUI:Show()
    if not self.book then self:CreateBook() end
    self.book:Show()
    self:LoadChapter(currentChapter)
    PlaySound(SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_OPEN or 829)
end

function BookUI:Hide()
    if self.book then self.book:Hide(); PlaySound(SOUNDKIT and SOUNDKIT.IG_SPELLBOOK_CLOSE or 830) end
    if self.eventDialog then self.eventDialog:Hide() end
end

function BookUI:Toggle()
    if self.book and self.book:IsShown() then self:Hide() else self:Show() end
end

function BookUI:IsShown() return self.book and self.book:IsShown() end
function BookUI:ShowBook() self:Show() end
function BookUI:HideBook() self:Hide() end

if GDL and GDL.RegisterModule then GDL:RegisterModule("BookUI", BookUI) end
_G["GDLBookUI"] = BookUI
