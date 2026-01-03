-- ══════════════════════════════════════════════════════════════
-- MODUL: GuildStats - Gilden-Statistiken
-- Durchschnittslevel aller Mitglieder + Tode pro Charakter
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local GuildStats = {}

-- ══════════════════════════════════════════════════════════════
-- DATEN SAMMELN
-- ══════════════════════════════════════════════════════════════

function GuildStats:GetGuildMemberStats()
    local stats = {
        totalMembers = 0,
        onlineMembers = 0,
        offlineMembers = 0,
        totalLevel = 0,
        avgLevel = 0,
        avgLevelOnline = 0,
        avgLevelOffline = 0,
        onlineLevelTotal = 0,
        offlineLevelTotal = 0,
        levelDistribution = {},  -- [level] = count
        classDistribution = {},  -- [classId] = count
        members = {},  -- Liste aller Mitglieder
    }
    
    if not IsInGuild() then return stats end
    
    local numMembers = GetNumGuildMembers()
    
    for i = 1, numMembers do
        local name, _, _, level, _, _, _, _, online, _, classFile = GetGuildRosterInfo(i)
        if name and level then
            -- Realm-Teil entfernen
            name = strsplit("-", name)
            
            stats.totalMembers = stats.totalMembers + 1
            stats.totalLevel = stats.totalLevel + level
            
            -- Level-Verteilung
            stats.levelDistribution[level] = (stats.levelDistribution[level] or 0) + 1
            
            -- Klassen-Verteilung
            local classId = 0
            for id, class in pairs(CLASS_NAMES) do
                if class == classFile then
                    classId = id
                    break
                end
            end
            stats.classDistribution[classId] = (stats.classDistribution[classId] or 0) + 1
            
            -- Online/Offline
            if online then
                stats.onlineMembers = stats.onlineMembers + 1
                stats.onlineLevelTotal = stats.onlineLevelTotal + level
            else
                stats.offlineMembers = stats.offlineMembers + 1
                stats.offlineLevelTotal = stats.offlineLevelTotal + level
            end
            
            -- Mitglieder-Liste
            table.insert(stats.members, {
                name = name,
                level = level,
                classFile = classFile,
                online = online,
            })
        end
    end
    
    -- Durchschnitte berechnen
    if stats.totalMembers > 0 then
        stats.avgLevel = stats.totalLevel / stats.totalMembers
    end
    if stats.onlineMembers > 0 then
        stats.avgLevelOnline = stats.onlineLevelTotal / stats.onlineMembers
    end
    if stats.offlineMembers > 0 then
        stats.avgLevelOffline = stats.offlineLevelTotal / stats.offlineMembers
    end
    
    return stats
end

-- Klassen-Namen Mapping
CLASS_NAMES = {
    [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE",
    [5] = "PRIEST", [6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE",
    [9] = "WARLOCK", [10] = "MONK", [11] = "DRUID",
}

function GuildStats:GetDeathsPerCharacter()
    local deathCounts = {}  -- [name] = {count, lastDeath, levels}
    
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.deaths then return deathCounts end
    
    for _, death in ipairs(guildData.deaths) do
        local name = death.name
        if name then
            if not deathCounts[name] then
                deathCounts[name] = {
                    count = 0,
                    deaths = {},
                    classId = death.classId,
                }
            end
            deathCounts[name].count = deathCounts[name].count + 1
            table.insert(deathCounts[name].deaths, {
                level = death.level,
                timestamp = death.timestamp,
                zone = death.zone,
            })
        end
    end
    
    -- Als sortierte Liste zurückgeben
    local sorted = {}
    for name, data in pairs(deathCounts) do
        table.insert(sorted, {
            name = name,
            count = data.count,
            deaths = data.deaths,
            classId = data.classId,
        })
    end
    
    -- Nach Anzahl sortieren (meiste zuerst)
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    return sorted
end

-- ══════════════════════════════════════════════════════════════
-- UI: STATISTIK-FENSTER
-- ══════════════════════════════════════════════════════════════

function GuildStats:ShowStatsWindow()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
        return
    end
    
    if not self.frame then
        self:CreateStatsWindow()
    end
    
    self:UpdateStats()
    self.frame:Show()
end

function GuildStats:CreateStatsWindow()
    local f = CreateFrame("Frame", "GDLGuildStatsFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 550)
    f:SetPoint("CENTER", UIParent, "CENTER", 540, -150)  -- Rechts diagonal (cascade)
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = false, edgeSize = 26,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    f:SetBackdropColor(1, 1, 1, 1)  -- Vollständig deckend
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(150)
    
    -- Titel
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 20)
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff4a3520Gilden-Statistiken|r")
    
    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Refresh Button
    local refresh = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refresh:SetSize(80, 22)
    refresh:SetPoint("TOPRIGHT", -35, -10)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", function() self:UpdateStats() end)
    
    -- ══════════════════════════════════════════════════════════════
    -- OBERER BEREICH: Durchschnittslevel
    -- ══════════════════════════════════════════════════════════════
    
    local levelBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    levelBox:SetSize(460, 100)
    levelBox:SetPoint("TOP", 0, -50)
    levelBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    levelBox:SetBackdropColor(0.12, 0.10, 0.06, 0.7)
    levelBox:SetBackdropBorderColor(0.5, 0.4, 0.3, 1)
    f.levelBox = levelBox
    
    local levelTitle = levelBox:CreateFontString(nil, "OVERLAY")
    levelTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    levelTitle:SetPoint("TOP", 0, -8)
    levelTitle:SetText("|cffDDCCAADurchschnittslevel der Gilde|r")
    
    -- Gesamt - große goldene Zahl
    local avgTotal = levelBox:CreateFontString(nil, "OVERLAY")
    avgTotal:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
    avgTotal:SetPoint("CENTER", 0, -5)
    avgTotal:SetTextColor(1, 0.85, 0.4)  -- Helles Gold
    f.avgTotal = avgTotal
    
    -- Online / Offline
    local avgOnline = levelBox:CreateFontString(nil, "OVERLAY")
    avgOnline:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    avgOnline:SetPoint("BOTTOMLEFT", 20, 10)
    avgOnline:SetTextColor(0.4, 0.9, 0.4)  -- Helles Grün
    f.avgOnline = avgOnline
    
    local avgOffline = levelBox:CreateFontString(nil, "OVERLAY")
    avgOffline:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    avgOffline:SetPoint("BOTTOMRIGHT", -20, 10)
    avgOffline:SetTextColor(0.6, 0.55, 0.5)  -- Mittleres Grau
    f.avgOffline = avgOffline
    
    -- Mitglieder-Zahlen
    local memberCount = levelBox:CreateFontString(nil, "OVERLAY")
    memberCount:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    memberCount:SetPoint("BOTTOM", 0, 10)
    memberCount:SetTextColor(0.8, 0.7, 0.55)  -- Helles Braun
    f.memberCount = memberCount
    
    -- ══════════════════════════════════════════════════════════════
    -- UNTERER BEREICH: Tode pro Charakter
    -- ══════════════════════════════════════════════════════════════
    
    local deathsTitle = f:CreateFontString(nil, "OVERLAY")
    deathsTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    deathsTitle:SetPoint("TOP", levelBox, "BOTTOM", 0, -15)
    deathsTitle:SetText("|cff5a4530Tode pro Charakter|r")
    f.deathsTitle = deathsTitle
    
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", deathsTitle, "BOTTOM", 0, -10)
    scrollFrame:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
    scrollFrame:SetPoint("LEFT", 20, 0)
    scrollFrame:SetPoint("RIGHT", -35, 0)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(425, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    
    self.frame = f
end

function GuildStats:UpdateStats()
    local f = self.frame
    if not f then return end
    
    -- Gilden-Daten laden
    GuildRoster()  -- Roster aktualisieren
    
    C_Timer.After(0.5, function()
        local stats = self:GetGuildMemberStats()
        
        -- Durchschnittslevel anzeigen
        f.avgTotal:SetText(string.format("%.1f", stats.avgLevel))
        f.avgOnline:SetText(string.format("|cff00FF00Online:|r %.1f (%d)", stats.avgLevelOnline, stats.onlineMembers))
        f.avgOffline:SetText(string.format("|cff888888Offline:|r %.1f (%d)", stats.avgLevelOffline, stats.offlineMembers))
        f.memberCount:SetText(stats.totalMembers .. " Mitglieder gesamt")
        
        -- Tode pro Charakter
        self:UpdateDeathsList()
    end)
end

function GuildStats:UpdateDeathsList()
    local scrollChild = self.frame.scrollChild
    
    -- Alte Einträge löschen
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local deathsPerChar = self:GetDeathsPerCharacter()
    
    if #deathsPerChar == 0 then
        local noData = scrollChild:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noData:SetPoint("TOP", 0, -20)
        noData:SetTextColor(0.5, 0.45, 0.4)
        noData:SetText("Keine Tode verzeichnet")
        scrollChild:SetHeight(50)
        return
    end
    
    -- Header
    local header = CreateFrame("Frame", nil, scrollChild)
    header:SetSize(420, 24)
    header:SetPoint("TOPLEFT", 0, 0)
    
    local hRank = header:CreateFontString(nil, "OVERLAY")
    hRank:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hRank:SetPoint("LEFT", 8, 0)
    hRank:SetText("|cff8a7a60#|r")
    
    local hChar = header:CreateFontString(nil, "OVERLAY")
    hChar:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hChar:SetPoint("LEFT", 65, 0)
    hChar:SetText("|cff8a7a60Charakter|r")
    
    local hCount = header:CreateFontString(nil, "OVERLAY")
    hCount:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    hCount:SetPoint("RIGHT", -15, 0)
    hCount:SetText("|cff8a7a60Tode (Hover fuer Details)|r")
    
    local y = -28
    local totalDeaths = 0
    
    for i, data in ipairs(deathsPerChar) do
        local row = self:CreateDeathRow(scrollChild, i, data, y)
        y = y - 28
        totalDeaths = totalDeaths + data.count
    end
    
    scrollChild:SetHeight(math.abs(y) + 30)
    
    -- Titel aktualisieren
    self.frame.deathsTitle:SetText("|cff5a4530Tode pro Charakter|r |cff7a6a50(" .. totalDeaths .. " gesamt, " .. #deathsPerChar .. " Charaktere)|r")
end

function GuildStats:CreateDeathRow(parent, rank, data, yOffset)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(420, 26)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Abwechselnde Hintergrundfarbe
    if rank % 2 == 0 then
        row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        row:SetBackdropColor(0.12, 0.10, 0.06, 0.5)
    end
    
    -- ClassId zu englischem Klassennamen für Icon-Lookup
    local CLASS_ID_TO_NAME = {
        [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE",
        [5] = "PRIEST", [6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE",
        [9] = "WARLOCK", [10] = "MONK", [11] = "DRUID",
    }
    local classKey = CLASS_ID_TO_NAME[data.classId] or "WARRIOR"
    
    -- Rang (mit Medaille für Top 3) - lesbare Farben
    local rankText = row:CreateFontString(nil, "OVERLAY")
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    rankText:SetPoint("LEFT", 8, 0)
    if rank == 1 then
        rankText:SetText("|cffFFD700#1|r")  -- Gold
    elseif rank == 2 then
        rankText:SetText("|cffC0C0C0#2|r")  -- Silber
    elseif rank == 3 then
        rankText:SetText("|cffCD7F32#3|r")  -- Bronze
    else
        rankText:SetText("|cff8a7a60#" .. rank .. "|r")  -- Mittleres Braun
    end
    
    -- Klassen-Icon
    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("LEFT", 40, 0)
    local coords = CLASS_ICON_TCOORDS[classKey]
    if coords then
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        classIcon:SetTexCoord(unpack(coords))
    end
    
    -- Klassenfarbe - normale Helligkeit für Lesbarkeit
    local classColor = RAID_CLASS_COLORS[classKey] or {r=0.6, g=0.5, b=0.4}
    
    -- Name (in Klassenfarbe)
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    nameText:SetPoint("LEFT", classIcon, "RIGHT", 8, 0)
    nameText:SetText(string.format("|cff%02x%02x%02x%s|r", 
        classColor.r * 255, classColor.g * 255, classColor.b * 255, data.name))
    
    -- Anzahl Tode (prominenter, rechts) - lesbare Farben
    local countText = row:CreateFontString(nil, "OVERLAY")
    countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    countText:SetPoint("RIGHT", -15, 0)
    if data.count >= 5 then
        countText:SetText("|cffCC3333" .. data.count .. " Tode|r")  -- Rot
    elseif data.count >= 3 then
        countText:SetText("|cffCC7700" .. data.count .. " Tode|r")  -- Orange
    else
        countText:SetText("|cffAA9933" .. data.count .. " Tod" .. (data.count > 1 and "e" or "") .. "|r")  -- Gelb-Braun
    end
    
    -- Hover-Highlight
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        self:SetBackdropColor(0.2, 0.18, 0.12, 0.7)
        
        -- Tooltip mit allen Details
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(data.name, classColor.r, classColor.g, classColor.b)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(data.count .. " Tode verzeichnet:", 1, 0.5, 0.5)
        GameTooltip:AddLine(" ")
        
        -- Alle Tode auflisten
        for j, death in ipairs(data.deaths) do
            local dateStr = death.timestamp and date("%d.%m.%Y", death.timestamp) or "?"
            local zoneStr = death.zone or "Unbekannt"
            GameTooltip:AddDoubleLine(
                "Level " .. (death.level or "?"), 
                zoneStr .. " (" .. dateStr .. ")",
                1, 0.85, 0,  -- Gold für Level
                0.6, 0.6, 0.6  -- Grau für Zone/Datum
            )
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        if rank % 2 == 0 then
            self:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
            self:SetBackdropColor(0.15, 0.12, 0.08, 0.6)
        else
            self:SetBackdrop(nil)
        end
        GameTooltip:Hide()
    end)
    
    return row
end
-- ══════════════════════════════════════════════════════════════
-- MODULE REGISTRATION
-- ══════════════════════════════════════════════════════════════

GDL:RegisterModule("GuildStats", GuildStats)
