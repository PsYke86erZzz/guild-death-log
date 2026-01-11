-- ══════════════════════════════════════════════════════════════
-- MODUL: GuildLeader - GEHEIMES Gildenleiter-Modul
-- NUR sichtbar für Gildenleiter und Offiziere!
-- Anwesenheitsliste aller Gildenmitglieder (auch ohne Addon)
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local GuildLeader = {}

local locale = GetLocale()

-- ══════════════════════════════════════════════════════════════
-- LOKALISIERUNG
-- ══════════════════════════════════════════════════════════════

local L = {
    TITLE = locale == "deDE" and "Gildenleitung" or "Guild Leadership",
    ATTENDANCE = locale == "deDE" and "Anwesenheit" or "Attendance",
    MEMBER = locale == "deDE" and "Mitglied" or "Member",
    RANK = locale == "deDE" and "Rang" or "Rank",
    LEVEL = locale == "deDE" and "Level" or "Level",
    LAST_ONLINE = locale == "deDE" and "Zuletzt online" or "Last online",
    STATUS = locale == "deDE" and "Status" or "Status",
    ONLINE = locale == "deDE" and "Online" or "Online",
    OFFLINE = locale == "deDE" and "Offline" or "Offline",
    DAYS_AGO = locale == "deDE" and "vor %d Tag(en)" or "%d day(s) ago",
    HOURS_AGO = locale == "deDE" and "vor %d Std." or "%d hrs ago",
    JUST_NOW = locale == "deDE" and "Gerade eben" or "Just now",
    TOTAL_MEMBERS = locale == "deDE" and "Gesamt: %d Mitglieder" or "Total: %d members",
    ONLINE_NOW = locale == "deDE" and "Online: %d" or "Online: %d",
    ACTIVE_7D = locale == "deDE" and "Aktiv (7 Tage): %d" or "Active (7 days): %d",
    INACTIVE = locale == "deDE" and "Inaktiv (30+ Tage): %d" or "Inactive (30+ days): %d",
    REFRESH = locale == "deDE" and "Aktualisieren" or "Refresh",
    SORT_NAME = locale == "deDE" and "Name" or "Name",
    SORT_RANK = locale == "deDE" and "Rang" or "Rank",
    SORT_LEVEL = locale == "deDE" and "Level" or "Level",
    SORT_ONLINE = locale == "deDE" and "Zuletzt" or "Last seen",
    NO_PERMISSION = locale == "deDE" and "Keine Berechtigung!" or "No permission!",
    FILTER_ALL = locale == "deDE" and "Alle" or "All",
    FILTER_ONLINE = locale == "deDE" and "Online" or "Online",
    FILTER_INACTIVE = locale == "deDE" and "Inaktiv" or "Inactive",
    HAS_ADDON = locale == "deDE" and "Hat Addon" or "Has Addon",
    NO_ADDON = locale == "deDE" and "Kein Addon" or "No Addon",
    NOTES = locale == "deDE" and "Notizen" or "Notes",
    OFFICER_NOTE = locale == "deDE" and "Offizier-Notiz" or "Officer Note",
    PUBLIC_NOTE = locale == "deDE" and "Oeffentliche Notiz" or "Public Note",
}

-- ══════════════════════════════════════════════════════════════
-- BERECHTIGUNGSPRÜFUNG
-- ══════════════════════════════════════════════════════════════

function GuildLeader:CanAccess()
    if not IsInGuild() then return false end
    
    -- Methode 1: CanGuildRemove (nur Leader/Offiziere können kicken)
    if CanGuildRemove() then return true end
    
    -- Methode 2: Rang prüfen (0 = Leader, 1 = meist Offizier)
    local myName = UnitName("player")
    local numMembers = GetNumGuildMembers()
    
    for i = 1, numMembers do
        local name, rankName, rankIndex = GetGuildRosterInfo(i)
        if name then
            local shortName = strsplit("-", name)
            if shortName == myName then
                -- Rang 0 = Gildenleiter, Rang 1-2 = meist Offiziere
                if rankIndex <= 2 then
                    return true
                end
                break
            end
        end
    end
    
    return false
end

function GuildLeader:IsGuildLeader()
    if not IsInGuild() then return false end
    
    local myName = UnitName("player")
    local numMembers = GetNumGuildMembers()
    
    for i = 1, numMembers do
        local name, _, rankIndex = GetGuildRosterInfo(i)
        if name then
            local shortName = strsplit("-", name)
            if shortName == myName then
                return rankIndex == 0
            end
        end
    end
    
    return false
end

-- ══════════════════════════════════════════════════════════════
-- INITIALISIERUNG
-- ══════════════════════════════════════════════════════════════

function GuildLeader:Initialize()
    GuildDeathLogDB.guildLeader = GuildDeathLogDB.guildLeader or {
        attendance = {},
        notes = {},
        lastUpdate = 0,
    }
    
    -- Addon-Nutzer tracken
    self.addonUsers = {}
    
    -- Roster-Update Events
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "GUILD_ROSTER_UPDATE" then
            if self.frame and self.frame:IsShown() then
                self:UpdateMemberList()
            end
        elseif event == "CHAT_MSG_ADDON" then
            local prefix, message, channel, sender = ...
            if channel == "GUILD" then
                -- Jede Addon-Nachricht = Spieler hat unser Addon
                local senderName = strsplit("-", sender)
                self.addonUsers[senderName] = time()
            end
        end
    end)
    
    GDL:Debug("GuildLeader: Initialisiert")
end

-- ══════════════════════════════════════════════════════════════
-- DATEN SAMMELN
-- ══════════════════════════════════════════════════════════════

function GuildLeader:GetAllMembers()
    if not IsInGuild() then return {} end
    
    -- Roster aktualisieren
    GuildRoster()
    
    local members = {}
    local numMembers, _, numOnline = GetNumGuildMembers()
    
    for i = 1, numMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone, 
              publicNote, officerNote, isOnline, status, classFileName, 
              achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        
        if name then
            local shortName = strsplit("-", name)
            
            -- Letzten Online-Zeitpunkt berechnen
            local yearsOffline, monthsOffline, daysOffline, hoursOffline = GetGuildRosterLastOnline(i)
            local lastOnlineSeconds = 0
            
            if isOnline then
                lastOnlineSeconds = 0
            elseif yearsOffline then
                lastOnlineSeconds = (yearsOffline * 365 * 24 * 3600) + 
                                   (monthsOffline * 30 * 24 * 3600) + 
                                   (daysOffline * 24 * 3600) + 
                                   (hoursOffline * 3600)
            end
            
            -- Class ID ermitteln
            local classId = nil
            local classMap = {
                ["WARRIOR"] = 1, ["PALADIN"] = 2, ["HUNTER"] = 3, ["ROGUE"] = 4,
                ["PRIEST"] = 5, ["DEATHKNIGHT"] = 6, ["SHAMAN"] = 7, ["MAGE"] = 8,
                ["WARLOCK"] = 9, ["MONK"] = 10, ["DRUID"] = 11, ["DEMONHUNTER"] = 12,
            }
            classId = classMap[classFileName] or 0
            
            table.insert(members, {
                name = shortName,
                fullName = name,
                rank = rankName,
                rankIndex = rankIndex,
                level = level,
                class = classDisplayName,
                classId = classId,
                classFileName = classFileName,
                zone = zone or "",
                isOnline = isOnline,
                isMobile = isMobile,
                publicNote = publicNote or "",
                officerNote = officerNote or "",
                lastOnlineSeconds = lastOnlineSeconds,
                hasAddon = self.addonUsers[shortName] and (time() - self.addonUsers[shortName] < 86400),
                index = i,
            })
        end
    end
    
    return members, numMembers, numOnline
end

function GuildLeader:FormatLastOnline(seconds)
    if seconds == 0 then
        return "|cff00FF00" .. L.ONLINE .. "|r"
    end
    
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    
    if days > 30 then
        return "|cffFF4444" .. string.format(L.DAYS_AGO, days) .. "|r"
    elseif days > 7 then
        return "|cffFFAA00" .. string.format(L.DAYS_AGO, days) .. "|r"
    elseif days > 0 then
        return "|cffFFFF00" .. string.format(L.DAYS_AGO, days) .. "|r"
    elseif hours > 0 then
        return "|cffAAFFAA" .. string.format(L.HOURS_AGO, hours) .. "|r"
    else
        return "|cff00FF00" .. L.JUST_NOW .. "|r"
    end
end

-- ══════════════════════════════════════════════════════════════
-- STATISTIKEN
-- ══════════════════════════════════════════════════════════════

function GuildLeader:GetStatistics(members)
    local stats = {
        total = #members,
        online = 0,
        active7d = 0,
        inactive30d = 0,
        withAddon = 0,
    }
    
    for _, m in ipairs(members) do
        if m.isOnline then
            stats.online = stats.online + 1
        end
        
        -- Aktiv in letzten 7 Tagen
        if m.lastOnlineSeconds < (7 * 86400) then
            stats.active7d = stats.active7d + 1
        end
        
        -- Inaktiv über 30 Tage
        if m.lastOnlineSeconds > (30 * 86400) then
            stats.inactive30d = stats.inactive30d + 1
        end
        
        if m.hasAddon then
            stats.withAddon = stats.withAddon + 1
        end
    end
    
    return stats
end

-- ══════════════════════════════════════════════════════════════
-- UI - HAUPTFENSTER
-- ══════════════════════════════════════════════════════════════

function GuildLeader:CreateFrame()
    if self.frame then return self.frame end
    
    local f = CreateFrame("Frame", "GDLGuildLeader", UIParent, "BackdropTemplate")
    f:SetSize(750, 580)  -- Breiter für mehr Spalten
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    
    -- Schatten
    local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", -5, 5)
    shadow:SetPoint("BOTTOMRIGHT", 5, -5)
    shadow:SetFrameLevel(f:GetFrameLevel() - 1)
    shadow:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
    shadow:SetBackdropColor(0, 0, 0, 0.6)
    
    -- Hintergrund - Dunkler für "geheimes" Feeling
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    f:SetBackdropColor(0.9, 0.85, 0.8, 1)
    f:SetBackdropBorderColor(0.5, 0.4, 0.3, 1)
    
    -- Titel mit "Geheim"-Indikator
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 20, "")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff8B0000" .. L.TITLE .. "|r")
    
    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cff666666(Nur fuer Offiziere sichtbar)|r")
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    
    -- Statistik-Bereich oben
    local statsFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    statsFrame:SetSize(710, 50)
    statsFrame:SetPoint("TOP", 0, -50)
    statsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    statsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    statsFrame:SetBackdropBorderColor(0.4, 0.3, 0.2, 0.8)
    f.statsFrame = statsFrame
    
    -- Stats Text
    f.statsTotal = self:CreateStatLabel(statsFrame, "TOPLEFT", 15, -10, L.TOTAL_MEMBERS)
    f.statsOnline = self:CreateStatLabel(statsFrame, "TOPLEFT", 170, -10, L.ONLINE_NOW)
    f.statsActive = self:CreateStatLabel(statsFrame, "TOPLEFT", 310, -10, L.ACTIVE_7D)
    f.statsInactive = self:CreateStatLabel(statsFrame, "TOPLEFT", 470, -10, L.INACTIVE)
    f.statsAddon = self:CreateStatLabel(statsFrame, "TOPLEFT", 600, -10, "Addon:")
    
    -- Filter-Buttons
    local filterY = -105
    
    local filterAll = self:CreateFilterButton(f, L.FILTER_ALL, 20, filterY, "all")
    local filterOnline = self:CreateFilterButton(f, L.FILTER_ONLINE, 90, filterY, "online")
    local filterInactive = self:CreateFilterButton(f, L.FILTER_INACTIVE, 170, filterY, "inactive")
    local filterAddon = self:CreateFilterButton(f, "Mit Addon", 260, filterY, "addon")
    local filterNoAddon = self:CreateFilterButton(f, "Ohne Addon", 355, filterY, "noaddon")
    
    f.filterButtons = {filterAll, filterOnline, filterInactive, filterAddon, filterNoAddon}
    f.currentFilter = "all"
    filterAll.selected:Show()
    
    -- Sortier-Header - WER / WIE / WAS / WO
    local headerY = -130
    f.sortBy = "name"
    f.sortAsc = true
    
    -- WER
    f.headerName = self:CreateSortHeader(f, "Wer", 15, headerY, 100, "name")
    f.headerRank = self:CreateSortHeader(f, "Rang", 120, headerY, 80, "rank")
    f.headerLevel = self:CreateSortHeader(f, "Lvl", 205, headerY, 35, "level")
    
    -- WAS (Klasse)
    f.headerClass = self:CreateSortHeader(f, "Klasse", 245, headerY, 70, "class")
    
    -- WO (Zone)
    f.headerZone = self:CreateSortHeader(f, "Wo (Zone)", 320, headerY, 120, "zone")
    
    -- WIE (Status)
    f.headerStatus = self:CreateSortHeader(f, "Status", 445, headerY, 80, "status")
    f.headerOnline = self:CreateSortHeader(f, "Zuletzt", 530, headerY, 80, "lastOnline")
    
    -- Addon
    f.headerAddon = self:CreateSortHeader(f, "Addon", 615, headerY, 45, "addon")
    
    -- Notiz
    f.headerNote = self:CreateSortHeader(f, "Notiz", 665, headerY, 70, "note")
    
    -- Scroll Frame für Mitgliederliste
    local scrollFrame = CreateFrame("ScrollFrame", "GDLGuildLeaderScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -155)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(690, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    f.scrollChild = scrollChild
    f.memberRows = {}
    
    -- Refresh Button
    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(120, 24)
    refreshBtn:SetPoint("BOTTOM", 0, 15)
    refreshBtn:SetText(L.REFRESH)
    refreshBtn:SetScript("OnClick", function()
        GuildRoster()
        C_Timer.After(0.5, function()
            self:UpdateMemberList()
        end)
    end)
    
    self.frame = f
    return f
end

function GuildLeader:CreateStatLabel(parent, point, x, y, text)
    local label = parent:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    label:SetPoint(point, x, y)
    label:SetText("|cffCCCCCC" .. text .. "|r")
    return label
end

function GuildLeader:CreateFilterButton(parent, text, x, y, filter)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(65, 22)
    btn:SetPoint("TOPLEFT", x, y)
    
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    local selected = btn:CreateTexture(nil, "BORDER")
    selected:SetAllPoints()
    selected:SetColorTexture(0.4, 0.3, 0.1, 0.8)
    selected:Hide()
    btn.selected = selected
    
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    label:SetPoint("CENTER")
    label:SetText("|cffFFFFFF" .. text .. "|r")
    
    btn.filter = filter
    btn:SetScript("OnClick", function()
        self.frame.currentFilter = filter
        for _, b in ipairs(self.frame.filterButtons) do
            b.selected:Hide()
        end
        selected:Show()
        self:UpdateMemberList()
    end)
    
    btn:SetScript("OnEnter", function() bg:SetColorTexture(0.3, 0.3, 0.3, 0.8) end)
    btn:SetScript("OnLeave", function() bg:SetColorTexture(0.2, 0.2, 0.2, 0.8) end)
    
    return btn
end

function GuildLeader:CreateSortHeader(parent, text, x, y, width, sortKey)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 18)
    btn:SetPoint("TOPLEFT", x, y)
    
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.12, 0.08, 0.9)
    
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetPoint("LEFT", 5, 0)
    label:SetText("|cffDDCCBB" .. text .. "|r")
    
    btn.sortKey = sortKey
    btn:SetScript("OnClick", function()
        if parent.sortBy == sortKey then
            parent.sortAsc = not parent.sortAsc
        else
            parent.sortBy = sortKey
            parent.sortAsc = true
        end
        self:UpdateMemberList()
    end)
    
    btn:SetScript("OnEnter", function() bg:SetColorTexture(0.25, 0.2, 0.15, 0.9) end)
    btn:SetScript("OnLeave", function() bg:SetColorTexture(0.15, 0.12, 0.08, 0.9) end)
    
    return btn
end

-- ══════════════════════════════════════════════════════════════
-- MITGLIEDERLISTE AKTUALISIEREN
-- ══════════════════════════════════════════════════════════════

function GuildLeader:UpdateMemberList()
    if not self.frame then return end
    
    local scrollChild = self.frame.scrollChild
    
    -- Alte Rows entfernen
    for _, row in pairs(self.frame.memberRows) do
        row:Hide()
        row:SetParent(nil)
    end
    self.frame.memberRows = {}
    
    local members, totalCount, onlineCount = self:GetAllMembers()
    local stats = self:GetStatistics(members)
    
    -- Stats aktualisieren
    self.frame.statsTotal:SetText("|cffFFFFFF" .. string.format(L.TOTAL_MEMBERS, stats.total) .. "|r")
    self.frame.statsOnline:SetText("|cff00FF00" .. string.format(L.ONLINE_NOW, stats.online) .. "|r")
    self.frame.statsActive:SetText("|cffFFFF00" .. string.format(L.ACTIVE_7D, stats.active7d) .. "|r")
    self.frame.statsInactive:SetText("|cffFF4444" .. string.format(L.INACTIVE, stats.inactive30d) .. "|r")
    self.frame.statsAddon:SetText("|cff00AAFF" .. stats.withAddon .. " mit Addon|r")
    
    -- Filtern
    local filtered = {}
    local filter = self.frame.currentFilter
    
    for _, m in ipairs(members) do
        local include = false
        
        if filter == "all" then
            include = true
        elseif filter == "online" then
            include = m.isOnline
        elseif filter == "inactive" then
            include = m.lastOnlineSeconds > (30 * 86400)
        elseif filter == "addon" then
            include = m.hasAddon
        elseif filter == "noaddon" then
            include = not m.hasAddon
        end
        
        if include then
            table.insert(filtered, m)
        end
    end
    
    -- Sortieren
    local sortBy = self.frame.sortBy
    local sortAsc = self.frame.sortAsc
    
    table.sort(filtered, function(a, b)
        local valA, valB
        
        if sortBy == "name" then
            valA, valB = a.name:lower(), b.name:lower()
        elseif sortBy == "rank" then
            valA, valB = a.rankIndex, b.rankIndex
        elseif sortBy == "level" then
            valA, valB = a.level, b.level
        elseif sortBy == "class" then
            valA, valB = a.class:lower(), b.class:lower()
        elseif sortBy == "zone" then
            valA, valB = (a.zone or ""):lower(), (b.zone or ""):lower()
        elseif sortBy == "status" then
            valA = a.isOnline and 0 or (a.isMobile and 1 or 2)
            valB = b.isOnline and 0 or (b.isMobile and 1 or 2)
        elseif sortBy == "lastOnline" then
            valA, valB = a.lastOnlineSeconds, b.lastOnlineSeconds
        elseif sortBy == "addon" then
            valA, valB = a.hasAddon and 0 or 1, b.hasAddon and 0 or 1
        elseif sortBy == "note" then
            valA, valB = a.officerNote:lower(), b.officerNote:lower()
        else
            valA, valB = a.name:lower(), b.name:lower()
        end
        
        if sortAsc then
            return valA < valB
        else
            return valA > valB
        end
    end)
    
    -- Rows erstellen
    local y = 0
    local rowHeight = 22
    
    for i, member in ipairs(filtered) do
        local row = self:CreateMemberRow(scrollChild, member, y, i)
        y = y - rowHeight
    end
    
    scrollChild:SetHeight(math.abs(y) + 20)
end

function GuildLeader:CreateMemberRow(parent, member, yOffset, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(690, 20)
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Abwechselnde Hintergrundfarbe
    local bgAlpha = (index % 2 == 0) and 0.15 or 0.08
    row:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
    row:SetBackdropColor(0.3, 0.25, 0.2, bgAlpha)
    
    -- Klassenfarbe
    local classColors = {
        [1] = {0.78, 0.61, 0.43},  -- Warrior
        [2] = {0.96, 0.55, 0.73},  -- Paladin
        [3] = {0.67, 0.83, 0.45},  -- Hunter
        [4] = {1, 0.96, 0.41},     -- Rogue
        [5] = {1, 1, 1},           -- Priest
        [6] = {0.77, 0.12, 0.23},  -- DK
        [7] = {0, 0.44, 0.87},     -- Shaman
        [8] = {0.41, 0.8, 0.94},   -- Mage
        [9] = {0.58, 0.51, 0.79},  -- Warlock
        [11] = {1, 0.49, 0.04},    -- Druid
    }
    local cc = classColors[member.classId] or {0.7, 0.7, 0.7}
    local colorHex = string.format("%02x%02x%02x", cc[1]*255, cc[2]*255, cc[3]*255)
    
    -- ═══ WER ═══
    
    -- Online-Indikator (Punkt)
    local onlineDot = row:CreateTexture(nil, "ARTWORK")
    onlineDot:SetSize(8, 8)
    onlineDot:SetPoint("LEFT", 5, 0)
    onlineDot:SetTexture("Interface\\COMMON\\Indicator-Green")
    if member.isOnline then
        onlineDot:SetVertexColor(0, 1, 0, 1)
    elseif member.isMobile then
        onlineDot:SetVertexColor(1, 1, 0, 0.8)
        onlineDot:SetTexture("Interface\\COMMON\\Indicator-Yellow")
    else
        onlineDot:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        onlineDot:SetTexture("Interface\\COMMON\\Indicator-Gray")
    end
    
    -- Name
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    nameText:SetPoint("LEFT", 18, 0)
    nameText:SetWidth(95)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("|cff" .. colorHex .. member.name .. "|r")
    
    -- Rang
    local rankText = row:CreateFontString(nil, "OVERLAY")
    rankText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    rankText:SetPoint("LEFT", 118, 0)
    rankText:SetWidth(80)
    rankText:SetJustifyH("LEFT")
    
    -- Rang-Farbe basierend auf Rang-Index
    local rankColor = "AAAAAA"
    if member.rankIndex == 0 then
        rankColor = "FFD700"  -- Gold für Gildenleiter
    elseif member.rankIndex <= 2 then
        rankColor = "FF8800"  -- Orange für Offiziere
    end
    rankText:SetText("|cff" .. rankColor .. (member.rank or "?") .. "|r")
    
    -- Level
    local levelText = row:CreateFontString(nil, "OVERLAY")
    levelText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    levelText:SetPoint("LEFT", 203, 0)
    levelText:SetWidth(35)
    levelText:SetJustifyH("CENTER")
    
    local levelColor = member.level >= 60 and "FFD700" or (member.level >= 40 and "FFFFFF" or "888888")
    levelText:SetText("|cff" .. levelColor .. member.level .. "|r")
    
    -- ═══ WAS (Klasse) ═══
    local classText = row:CreateFontString(nil, "OVERLAY")
    classText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    classText:SetPoint("LEFT", 243, 0)
    classText:SetWidth(70)
    classText:SetJustifyH("LEFT")
    classText:SetText("|cff" .. colorHex .. (member.class or "?") .. "|r")
    
    -- ═══ WO (Zone) ═══
    local zoneText = row:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    zoneText:SetPoint("LEFT", 318, 0)
    zoneText:SetWidth(120)
    zoneText:SetJustifyH("LEFT")
    
    if member.isOnline and member.zone and member.zone ~= "" then
        -- Zone kürzen wenn zu lang
        local zoneName = member.zone
        if #zoneName > 18 then
            zoneName = zoneName:sub(1, 16) .. ".."
        end
        zoneText:SetText("|cffAAFFAA" .. zoneName .. "|r")
    elseif member.isMobile then
        zoneText:SetText("|cffFFFF00Mobile App|r")
    else
        zoneText:SetText("|cff666666-|r")
    end
    
    -- ═══ WIE (Status) ═══
    local statusText = row:CreateFontString(nil, "OVERLAY")
    statusText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    statusText:SetPoint("LEFT", 443, 0)
    statusText:SetWidth(80)
    statusText:SetJustifyH("LEFT")
    
    if member.isOnline then
        if member.status == 1 then
            statusText:SetText("|cffFFFF00<AFK>|r")
        elseif member.status == 2 then
            statusText:SetText("|cffFF0000<DND>|r")
        else
            statusText:SetText("|cff00FF00Online|r")
        end
    elseif member.isMobile then
        statusText:SetText("|cffFFAA00Mobile|r")
    else
        statusText:SetText("|cff888888Offline|r")
    end
    
    -- Zuletzt online
    local onlineText = row:CreateFontString(nil, "OVERLAY")
    onlineText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    onlineText:SetPoint("LEFT", 528, 0)
    onlineText:SetWidth(80)
    onlineText:SetJustifyH("LEFT")
    onlineText:SetText(self:FormatLastOnline(member.lastOnlineSeconds))
    
    -- Addon Status
    local addonText = row:CreateFontString(nil, "OVERLAY")
    addonText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    addonText:SetPoint("LEFT", 613, 0)
    addonText:SetWidth(45)
    addonText:SetJustifyH("CENTER")
    if member.hasAddon then
        addonText:SetText("|cff00FF00Ja|r")
    else
        addonText:SetText("|cff444444-|r")
    end
    
    -- Offizier-Notiz (gekürzt)
    local noteText = row:CreateFontString(nil, "OVERLAY")
    noteText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    noteText:SetPoint("LEFT", 663, 0)
    noteText:SetWidth(65)
    noteText:SetJustifyH("LEFT")
    
    local note = member.officerNote ~= "" and member.officerNote or member.publicNote
    if #note > 10 then
        note = note:sub(1, 8) .. ".."
    end
    if member.officerNote ~= "" then
        noteText:SetText("|cffFF8800" .. note .. "|r")  -- Orange für Offizier-Notiz
    elseif member.publicNote ~= "" then
        noteText:SetText("|cff888888" .. note .. "|r")
    else
        noteText:SetText("")
    end
    
    -- Hover-Effekt und Tooltip
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.4, 0.35, 0.25, 0.5)
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(member.name, cc[1], cc[2], cc[3])
        GameTooltip:AddLine(" ")
        
        -- WAS
        GameTooltip:AddDoubleLine("Klasse:", member.class .. " (Level " .. member.level .. ")", 0.7, 0.7, 0.7, cc[1], cc[2], cc[3])
        GameTooltip:AddDoubleLine("Rang:", member.rank .. " (#" .. member.rankIndex .. ")", 0.7, 0.7, 0.7, 1, 0.8, 0.4)
        
        -- WO
        if member.zone and member.zone ~= "" then
            GameTooltip:AddDoubleLine("Zone:", member.zone, 0.7, 0.7, 0.7, 0.6, 1, 0.6)
        end
        
        -- WIE
        GameTooltip:AddLine(" ")
        if member.isOnline then
            local statusStr = "Online"
            if member.status == 1 then statusStr = "AFK" end
            if member.status == 2 then statusStr = "Beschaeftigt" end
            GameTooltip:AddDoubleLine("Status:", statusStr, 0.7, 0.7, 0.7, 0, 1, 0)
        elseif member.isMobile then
            GameTooltip:AddDoubleLine("Status:", "Mobile App", 0.7, 0.7, 0.7, 1, 0.7, 0)
        else
            local lastOnline = GuildLeader:FormatLastOnline(member.lastOnlineSeconds):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
            GameTooltip:AddDoubleLine("Zuletzt online:", lastOnline, 0.7, 0.7, 0.7, 0.8, 0.6, 0.4)
        end
        
        -- Addon
        if member.hasAddon then
            GameTooltip:AddDoubleLine("GuildDeathLog:", "Installiert", 0.7, 0.7, 0.7, 0, 1, 0)
        else
            GameTooltip:AddDoubleLine("GuildDeathLog:", "Nicht installiert", 0.7, 0.7, 0.7, 0.5, 0.5, 0.5)
        end
        
        -- Notizen
        if member.publicNote ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Oeffentliche Notiz:", 0.7, 0.7, 0.5)
            GameTooltip:AddLine(member.publicNote, 1, 1, 1, true)
        end
        
        if member.officerNote ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Offizier-Notiz:", 1, 0.5, 0)
            GameTooltip:AddLine(member.officerNote, 1, 0.8, 0.6, true)
        end
        
        GameTooltip:Show()
    end)
    
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.25, 0.2, bgAlpha)
        GameTooltip:Hide()
    end)
    
    table.insert(self.frame.memberRows, row)
    return row
end

-- ══════════════════════════════════════════════════════════════
-- ÖFFENTLICHE FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function GuildLeader:Show()
    if not self:CanAccess() then
        GDL:Print("|cffFF0000" .. L.NO_PERMISSION .. "|r")
        return
    end
    
    if not self.frame then
        self:CreateFrame()
    end
    
    GuildRoster()
    C_Timer.After(0.3, function()
        self:UpdateMemberList()
        self.frame:Show()
    end)
end

function GuildLeader:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function GuildLeader:Toggle()
    if not self:CanAccess() then
        GDL:Print("|cffFF0000" .. L.NO_PERMISSION .. "|r")
        return
    end
    
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Prüft ob der Button in der UI angezeigt werden soll
function GuildLeader:ShouldShowButton()
    return self:CanAccess()
end

-- ══════════════════════════════════════════════════════════════
-- MODULE REGISTRATION
-- ══════════════════════════════════════════════════════════════

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(5, function() GuildLeader:Initialize() end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("GuildLeader", GuildLeader)
