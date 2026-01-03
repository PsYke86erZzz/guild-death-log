-- ══════════════════════════════════════════════════════════════
-- MODUL: UI - IMMERSIVE CHRONICLE OF THE FALLEN
-- Inspiriert von Total RP 3, Immersion, Storyline
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local UI = {}

local CLASS_COLORS = {
    [1]={0.78,0.61,0.43}, [2]={0.96,0.55,0.73}, [3]={0.67,0.83,0.45},
    [4]={1,0.96,0.41}, [5]={1,1,1}, [7]={0,0.44,0.87},
    [8]={0.41,0.8,0.94}, [9]={0.58,0.51,0.79}, [11]={1,0.49,0.04}
}
local CLASS_ICONS = {
    [1]="Interface\\Icons\\ClassIcon_Warrior", [2]="Interface\\Icons\\ClassIcon_Paladin",
    [3]="Interface\\Icons\\ClassIcon_Hunter", [4]="Interface\\Icons\\ClassIcon_Rogue",
    [5]="Interface\\Icons\\ClassIcon_Priest", [7]="Interface\\Icons\\ClassIcon_Shaman",
    [8]="Interface\\Icons\\ClassIcon_Mage", [9]="Interface\\Icons\\ClassIcon_Warlock",
    [11]="Interface\\Icons\\ClassIcon_Druid"
}

local overlayQueue = {}
local isShowingOverlay = false

function UI:Initialize()
    C_Timer.After(0.5, function() self:CreateChronicle() end)
end

function UI:GetClassColor(classId) return CLASS_COLORS[classId] or {0.5, 0.5, 0.5} end
function UI:GetClassIcon(classId) return CLASS_ICONS[classId] or "Interface\\Icons\\INV_Misc_QuestionMark" end

-- ══════════════════════════════════════════════════════════════
-- DAS BUCH - IMMERSIVE CHRONICLE
-- ══════════════════════════════════════════════════════════════

function UI:CreateChronicle()
    -- Hauptframe mit Schatten-Effekt
    local f = CreateFrame("Frame", "GDLChronicle", UIParent, "BackdropTemplate")
    f:SetSize(500, 650)  -- Größer: 500x650
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    f:Hide()
    
    -- Äußerer Schatten für Tiefe
    local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", -8, 8)
    shadow:SetPoint("BOTTOMRIGHT", 8, -8)
    shadow:SetFrameLevel(f:GetFrameLevel() - 1)
    shadow:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 3,
    })
    shadow:SetBackdropColor(0, 0, 0, 0.7)
    shadow:SetBackdropBorderColor(0, 0, 0, 0.5)
    
    -- Haupthintergrund - Elegantes Pergament
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = false,
        tileSize = 256,
        edgeSize = 32,
        insets = { left = 6, right = 6, top = 6, bottom = 6 }
    })
    f:SetBackdropColor(1, 1, 1, 1)
    f:SetBackdropBorderColor(0.8, 0.7, 0.5, 1)
    
    -- Innerer Rahmen für mehr Tiefe
    local innerBorder = CreateFrame("Frame", nil, f, "BackdropTemplate")
    innerBorder:SetPoint("TOPLEFT", 12, -12)
    innerBorder:SetPoint("BOTTOMRIGHT", -12, 12)
    innerBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    innerBorder:SetBackdropBorderColor(0.4, 0.3, 0.2, 0.5)
    
    -- ═══ HEADER BEREICH ═══
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetPoint("TOPLEFT", 20, -20)
    headerBg:SetPoint("TOPRIGHT", -20, -20)
    headerBg:SetHeight(70)
    headerBg:SetColorTexture(0.08, 0.05, 0.03, 0.6)
    
    -- Buch-Icon links
    local bookIcon = f:CreateTexture(nil, "OVERLAY")
    bookIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    bookIcon:SetSize(50, 50)
    bookIcon:SetPoint("TOPLEFT", 30, -28)
    
    -- Icon Rahmen
    local iconBorder = f:CreateTexture(nil, "OVERLAY", nil, 1)
    iconBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    iconBorder:SetSize(68, 68)
    iconBorder:SetPoint("CENTER", bookIcon, "CENTER", 10, -10)
    
    -- Titel
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 24, "")
    title:SetPoint("TOP", 15, -30)
    title:SetText("|cff8B4513Das Buch der Gefallenen|r")
    title:SetShadowOffset(2, -2)
    title:SetShadowColor(0, 0, 0, 0.8)
    
    -- Untertitel / Gildenname
    f.guildName = f:CreateFontString(nil, "OVERLAY")
    f.guildName:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    f.guildName:SetPoint("TOP", title, "BOTTOM", 0, -4)
    f.guildName:SetTextColor(0.5, 0.4, 0.3)
    
    -- Schließen-Button (elegant)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- ═══ STATISTIK BEREICH ═══
    local statsFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    statsFrame:SetPoint("TOPLEFT", 25, -95)
    statsFrame:SetPoint("TOPRIGHT", -25, -95)
    statsFrame:SetHeight(55)
    statsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    statsFrame:SetBackdropColor(0.1, 0.08, 0.05, 0.9)
    statsFrame:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
    
    -- Statistiken in Spalten
    f.statTotal = self:CreateStatColumn(statsFrame, "TOPLEFT", 15, -8, "Gefallene", "0")
    f.statToday = self:CreateStatColumn(statsFrame, "TOP", -60, -8, "Heute", "0")
    f.statWeek = self:CreateStatColumn(statsFrame, "TOP", 60, -8, "Diese Woche", "0")
    f.statAvgLvl = self:CreateStatColumn(statsFrame, "TOPRIGHT", -15, -8, "Ø Level", "0")
    
    -- ═══ TRENNLINIE MIT ORNAMENT ═══
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-HorizontalShadow")
    divider:SetPoint("TOPLEFT", statsFrame, "BOTTOMLEFT", -10, -8)
    divider:SetPoint("TOPRIGHT", statsFrame, "BOTTOMRIGHT", 10, -8)
    divider:SetHeight(15)
    divider:SetVertexColor(0.35, 0.28, 0.2, 0.6)
    
    -- Totenkopf-Symbol in der Mitte (kleiner, dezenter)
    local skullDivider = f:CreateTexture(nil, "OVERLAY")
    skullDivider:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    skullDivider:SetSize(18, 18)
    skullDivider:SetPoint("CENTER", divider, "CENTER", 0, 0)
    skullDivider:SetAlpha(0.6)
    
    -- ═══ LISTE DER GEFALLENEN ═══
    local listHeader = f:CreateFontString(nil, "OVERLAY")
    listHeader:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    listHeader:SetPoint("TOPLEFT", 30, -175)
    listHeader:SetText("|cff5a4530- Chronik der Gefallenen -|r")
    
    -- Scroll Container
    local scrollContainer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollContainer:SetPoint("TOPLEFT", 22, -195)
    scrollContainer:SetPoint("BOTTOMRIGHT", -22, 100)  -- Mehr Platz für Buttons
    scrollContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollContainer:SetBackdropColor(0.05, 0.03, 0.02, 0.7)
    scrollContainer:SetBackdropBorderColor(0.4, 0.3, 0.2, 0.6)
    
    -- ScrollFrame
    local scroll = CreateFrame("ScrollFrame", "GDLChronicleScroll", scrollContainer, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 8, -8)
    scroll:SetPoint("BOTTOMRIGHT", -28, 8)
    
    -- ScrollBar Styling
    local scrollBar = scroll.ScrollBar or _G["GDLChronicleScrollScrollBar"]
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 2, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 16)
    end
    
    local scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetSize(scroll:GetWidth(), 1)
    scroll:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    f.scrollFrame = scroll
    
    -- ═══ FOOTER MIT ZITAT ═══
    local footerLine = f:CreateTexture(nil, "ARTWORK")
    footerLine:SetPoint("BOTTOMLEFT", 30, 95)
    footerLine:SetPoint("BOTTOMRIGHT", -30, 95)
    footerLine:SetHeight(1)
    footerLine:SetColorTexture(0.4, 0.3, 0.2, 0.5)
    
    f.quote = f:CreateFontString(nil, "OVERLAY")
    f.quote:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.quote:SetPoint("BOTTOM", 0, 78)
    f.quote:SetWidth(420)
    f.quote:SetTextColor(0.45, 0.35, 0.25)
    f.quote:SetJustifyH("CENTER")
    
    -- ═══════════════════════════════════════════════════════════════
    -- BUTTONS - 3 Reihen à 5 Buttons, einheitlich 90px breit
    -- ═══════════════════════════════════════════════════════════════
    local btnWidth = 90
    local btnSpacing = 4
    local totalWidth = (btnWidth * 5) + (btnSpacing * 4)  -- 470px
    local startX = -totalWidth / 2 + btnWidth / 2  -- Zentriert
    
    -- Reihe 1 (oben)
    local btnY1 = 68
    f.btnRefresh = self:CreateElegantButton(f, "Aktualisieren", startX + (btnWidth + btnSpacing) * 0, btnY1, function()
        local D = GDL:GetModule("Deathlog") if D then D:ScanData() end
        self:UpdateChronicle()
    end)
    
    f.btnSettings = self:CreateElegantButton(f, "Einstellungen", startX + (btnWidth + btnSpacing) * 1, btnY1, function()
        self:ShowSettings()
    end)
    
    f.btnSync = self:CreateElegantButton(f, "Sync", startX + (btnWidth + btnSpacing) * 2, btnY1, function()
        local S = GDL:GetModule("Sync") if S then S:RequestFullSync() end
    end)
    
    f.btnExport = self:CreateElegantButton(f, "Export", startX + (btnWidth + btnSpacing) * 3, btnY1, function()
        local E = GDL:GetModule("Export") if E then E:ShowExportWindow() end
    end)
    
    f.btnDebug = self:CreateElegantButton(f, "Debug", startX + (btnWidth + btnSpacing) * 4, btnY1, function()
        local D = GDL:GetModule("Debug") if D then D:ShowWindow() end
    end)
    
    -- Reihe 2 (mitte)
    local btnY2 = 42
    f.btnHallOfFame = self:CreateElegantButton(f, "Ruhmeshalle", startX + (btnWidth + btnSpacing) * 0, btnY2, function()
        self:ShowHallOfFame()
    end)
    
    f.btnStats = self:CreateElegantButton(f, "Statistiken", startX + (btnWidth + btnSpacing) * 1, btnY2, function()
        self:ShowStatistics()
    end)
    
    f.btnAchievements = self:CreateElegantButton(f, "Meilensteine", startX + (btnWidth + btnSpacing) * 2, btnY2, function()
        self:ShowAchievements()
    end)
    
    f.btnProfessions = self:CreateElegantButton(f, "Berufe", startX + (btnWidth + btnSpacing) * 3, btnY2, function()
        local P = GDL:GetModule("Professions") if P then P:ShowWindow() end
    end)
    
    f.btnGuildMap = self:CreateElegantButton(f, "Gilden-Karte", startX + (btnWidth + btnSpacing) * 4, btnY2, function()
        local GT = GDL:GetModule("GuildTracker") 
        if GT then 
            GT:Toggle()
        end
    end)
    
    -- Reihe 3 (unten) - Neue Features
    local btnY3 = 20
    f.btnTitles = self:CreateElegantButton(f, "Titel", startX + (btnWidth + btnSpacing) * 0, btnY3, function()
        self:ToggleTitles()
    end)
    
    f.btnMemorial = self:CreateElegantButton(f, "Gedenkhalle", startX + (btnWidth + btnSpacing) * 1, btnY3, function()
        local M = GDL:GetModule("Memorial") if M then M:ShowMemorialWindow() end
    end)
    
    f.btnGuildStats = self:CreateElegantButton(f, "Gilden-Stats", startX + (btnWidth + btnSpacing) * 2, btnY3, function()
        local GS = GDL:GetModule("GuildStats") if GS then GS:ShowStatsWindow() end
    end)
    
    -- ═══ OPEN ANIMATION ═══
    f.openAnim = f:CreateAnimationGroup()
    local fadeIn = f.openAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.3)
    fadeIn:SetSmoothing("OUT")
    
    f.openAnim:SetScript("OnFinished", function()
        f:SetAlpha(1)
    end)
    
    f:SetScript("OnShow", function(self)
        self:SetAlpha(1)
        UI:UpdateChronicle()
    end)
    
    self.mainFrame = f
end

function UI:CreateStatColumn(parent, point, x, y, label, value)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(90, 40)
    container:SetPoint(point, x, y)
    
    local valueText = container:CreateFontString(nil, "OVERLAY")
    valueText:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    valueText:SetPoint("TOP", 0, 0)
    valueText:SetTextColor(0.85, 0.7, 0.4)
    valueText:SetText(value)
    
    local labelText = container:CreateFontString(nil, "OVERLAY")
    labelText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    labelText:SetPoint("TOP", valueText, "BOTTOM", 0, -2)
    labelText:SetTextColor(0.5, 0.45, 0.4)
    labelText:SetText(label)
    
    container.value = valueText
    container.label = labelText
    return container
end

function UI:CreateElegantButton(parent, text, x, y, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(90, 22)  -- 90px breit, einheitlich
    btn:SetPoint("BOTTOM", x, y)
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
    btn:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
    
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 9, "")  -- Etwas kleiner für lange Texte
    label:SetPoint("CENTER", 0, 1)
    label:SetText(text)
    label:SetTextColor(0.9, 0.8, 0.6)
    btn.label = label
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.2, 0.12, 1)
        self:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
        self.label:SetTextColor(1, 0.9, 0.7)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
        self:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
        self.label:SetTextColor(0.9, 0.8, 0.6)
    end)
    
    btn:SetScript("OnMouseDown", function(self)
        self.label:SetPoint("CENTER", 1, 0)
    end)
    
    btn:SetScript("OnMouseUp", function(self)
        self.label:SetPoint("CENTER", 0, 1)
    end)
    
    btn:SetScript("OnClick", onClick)
    
    return btn
end

-- ══════════════════════════════════════════════════════════════
-- CHRONICLE UPDATE
-- ══════════════════════════════════════════════════════════════

function UI:ShowBook() 
    if self.mainFrame then 
        self.mainFrame:Show() 
    end 
end

function UI:HideBook() 
    if self.mainFrame then self.mainFrame:Hide() end 
end

function UI:UpdateChronicle()
    if not self.mainFrame then return end
    local f = self.mainFrame
    
    -- Clear scroll content
    for _, c in ipairs({f.scrollChild:GetChildren()}) do c:Hide() c:SetParent(nil) end
    
    -- Guild Name
    if GDL.currentGuildName then
        f.guildName:SetText("< " .. GDL.currentGuildName .. " >")
    else
        f.guildName:SetText("|cff666666Keine Gilde|r")
    end
    
    -- Daten sammeln
    local guildData = GDL:GetGuildData()
    local deaths = guildData and guildData.deaths or {}
    
    local sortedDeaths = {}
    for _, d in ipairs(deaths) do table.insert(sortedDeaths, d) end
    table.sort(sortedDeaths, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    -- Statistiken berechnen
    local count, levelSum, today, thisWeek = #sortedDeaths, 0, 0, 0
    local now, todayStart = time(), time() - (time() % 86400)
    
    for _, d in ipairs(sortedDeaths) do
        levelSum = levelSum + (d.level or 0)
        if (d.timestamp or 0) >= todayStart then today = today + 1 end
        if (d.timestamp or 0) >= todayStart - 604800 then thisWeek = thisWeek + 1 end
    end
    
    f.statTotal.value:SetText(count)
    f.statToday.value:SetText(today)
    f.statWeek.value:SetText(thisWeek)
    f.statAvgLvl.value:SetText(count > 0 and string.format("%.1f", levelSum/count) or "-")
    
    -- Zitat
    local Locale = GDL:GetModule("Locale")
    if Locale and Locale.L and Locale.L.BOOK_QUOTES then
        f.quote:SetText('"' .. Locale.L.BOOK_QUOTES[math.random(#Locale.L.BOOK_QUOTES)] .. '"')
    end
    
    -- Einträge erstellen
    local scrollY = 0
    
    if count == 0 then
        local empty = f.scrollChild:CreateFontString(nil, "OVERLAY")
        empty:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        empty:SetPoint("TOP", 0, -80)
        empty:SetText("|cff556644Keine Gefallenen verzeichnet.|r\n|cff445533Die Gilde steht stark.|r")
        empty:SetJustifyH("CENTER")
    else
        for i, d in ipairs(sortedDeaths) do
            if i > 100 then break end
            
            local entry = self:CreateDeathEntry(f.scrollChild, d, i)
            entry:SetPoint("TOPLEFT", 5, scrollY)
            entry:SetPoint("TOPRIGHT", -5, scrollY)
            
            scrollY = scrollY - 52
        end
    end
    
    f.scrollChild:SetHeight(math.max(math.abs(scrollY) + 20, 300))
end

function UI:CreateDeathEntry(parent, death, index)
    local col = self:GetClassColor(death.classId)
    
    local entry = CreateFrame("Button", nil, parent)
    entry:SetHeight(48)
    
    -- Alternierende Hintergrundfarbe
    local bg = entry:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    if index % 2 == 0 then
        bg:SetColorTexture(0.08, 0.06, 0.04, 0.5)
    else
        bg:SetColorTexture(0.05, 0.04, 0.03, 0.3)
    end
    
    -- Hover Highlight (golden glow)
    local highlight = entry:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(1, 0.85, 0.5, 0.15)
    highlight:SetAllPoints()
    
    -- Klassenfarben-Akzent links
    local accent = entry:CreateTexture(nil, "ARTWORK")
    accent:SetSize(3, 40)
    accent:SetPoint("LEFT", 4, 0)
    accent:SetColorTexture(col[1], col[2], col[3], 0.9)
    
    -- Klassen-Icon
    local icon = entry:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("LEFT", 14, 0)
    icon:SetTexture(self:GetClassIcon(death.classId))
    
    -- Name
    local nameText = entry:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
    nameText:SetTextColor(col[1], col[2], col[3])
    
    local sourceTag = ""
    if death.syncedFrom then sourceTag = " |cff4488AA[S]|r"
    elseif death.fromDeathlog then sourceTag = " |cff88AA44[D]|r"
    elseif death.fromBlizzard then sourceTag = " |cffAA8844[B]|r"
    end
    nameText:SetText(death.name .. sourceTag)
    
    -- Level & Klasse
    local infoText = entry:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    infoText:SetText("Level " .. (death.level or "?") .. " " .. GDL:GetClassName(death.classId))
    infoText:SetTextColor(0.6, 0.55, 0.5)
    
    -- Zone
    local zoneText = entry:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    zoneText:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -1)
    zoneText:SetText(death.zone or "")
    zoneText:SetTextColor(0.5, 0.45, 0.4)
    
    -- Datum rechts
    if death.timestamp and death.timestamp > 0 then
        local dateText = entry:CreateFontString(nil, "OVERLAY")
        dateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        dateText:SetPoint("TOPRIGHT", -28, -8)  -- Platz für X-Button
        dateText:SetText(date("%d.%m.%y", death.timestamp))
        dateText:SetTextColor(0.5, 0.45, 0.4)
        
        local timeText = entry:CreateFontString(nil, "OVERLAY")
        timeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        timeText:SetPoint("TOPRIGHT", -28, -20)  -- Platz für X-Button
        timeText:SetText(date("%H:%M", death.timestamp))
        timeText:SetTextColor(0.45, 0.4, 0.35)
    end
    
    -- ═══ SANFTER X-BUTTON (nur wenn Passwort gesetzt) ═══
    if GuildDeathLogDB.adminPassword then
        local deleteBtn = CreateFrame("Button", nil, entry)
        deleteBtn:SetSize(16, 16)
        deleteBtn:SetPoint("RIGHT", -6, 0)
        deleteBtn:SetAlpha(0.3)  -- Sehr sanft/dezent
        
        -- X-Symbol als Text (WoW-kompatibel)
        local xText = deleteBtn:CreateFontString(nil, "OVERLAY")
        xText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        xText:SetPoint("CENTER", 0, 0)
        xText:SetText("x")
        xText:SetTextColor(0.8, 0.3, 0.3)
        deleteBtn.xText = xText
        
        -- Hover-Effekt
        deleteBtn:SetScript("OnEnter", function(self)
            self:SetAlpha(1.0)
            self.xText:SetTextColor(1, 0.4, 0.4)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Eintrag loeschen", 1, 0.4, 0.4)
            GameTooltip:AddLine("Erfordert Admin-Passwort", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        deleteBtn:SetScript("OnLeave", function(self)
            self:SetAlpha(0.3)
            self.xText:SetTextColor(0.8, 0.3, 0.3)
            GameTooltip:Hide()
        end)
        
        -- Klick-Handler - zeigt Passwort-Dialog
        deleteBtn:SetScript("OnClick", function()
            UI:ShowPasswordDialog(index, death.name)
        end)
    end
    
    -- Click Handler - Overlay anzeigen
    entry:SetScript("OnClick", function()
        self:ShowOverlay(death, death.syncedFrom ~= nil)
    end)
    
    return entry
end

-- ══════════════════════════════════════════════════════════════
-- PASSWORT-DIALOG
-- ══════════════════════════════════════════════════════════════

function UI:ShowPasswordDialog(deathIndex, charName)
    if not self.pwDialog then
        self:CreatePasswordDialog()
    end
    
    self.pwDialog.deathIndex = deathIndex
    self.pwDialog.charName = charName
    self.pwDialog.titleText:SetText("|cffFF6666" .. charName .. "|r loeschen?")
    self.pwDialog.editBox:SetText("")
    self.pwDialog:Show()
    self.pwDialog.editBox:SetFocus()
end

function UI:CreatePasswordDialog()
    local f = CreateFrame("Frame", "GDLPasswordDialog", UIParent, "BackdropTemplate")
    f:SetSize(280, 130)
    f:SetPoint("CENTER", 0, 100)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(200)
    f:EnableMouse(true)
    f:Hide()
    
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 20,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
    })
    
    -- Titel
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    title:SetPoint("TOP", 0, -15)
    title:SetTextColor(1, 0.85, 0.5)
    f.titleText = title
    
    -- Info-Text
    local info = f:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    info:SetPoint("TOP", title, "BOTTOM", 0, -5)
    info:SetText("Admin-Passwort eingeben:")
    info:SetTextColor(0.7, 0.7, 0.7)
    
    -- Eingabefeld
    local editBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    editBox:SetSize(200, 20)
    editBox:SetPoint("TOP", info, "BOTTOM", 0, -10)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(50)
    -- Passwort verstecken (Sternchen)
    editBox:SetScript("OnTextChanged", function(self)
        -- Zeige Sternchen statt echtem Text
    end)
    f.editBox = editBox
    
    -- OK Button
    local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    okBtn:SetSize(80, 22)
    okBtn:SetPoint("BOTTOMLEFT", 30, 15)
    okBtn:SetText("OK")
    okBtn:SetScript("OnClick", function()
        local input = editBox:GetText()
        local valid, err = GDL:VerifyPassword(input)
        
        if valid then
            GDL:DeleteDeath(f.deathIndex)
            f:Hide()
        else
            GDL:Print("|cffFF0000Falsches Passwort!|r")
            editBox:SetText("")
            editBox:SetFocus()
        end
    end)
    
    -- Abbrechen Button
    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", -30, 15)
    cancelBtn:SetText("Abbrechen")
    cancelBtn:SetScript("OnClick", function()
        f:Hide()
    end)
    
    -- Enter-Taste = OK
    editBox:SetScript("OnEnterPressed", function()
        okBtn:Click()
    end)
    
    -- Escape = Abbrechen
    editBox:SetScript("OnEscapePressed", function()
        f:Hide()
    end)
    
    self.pwDialog = f
end

-- ══════════════════════════════════════════════════════════════
-- ELEGANTES TODES-OVERLAY
-- ══════════════════════════════════════════════════════════════

function UI:ShowOverlay(death, isSynced)
    table.insert(overlayQueue, {death = death, synced = isSynced})
    if not isShowingOverlay then self:ShowNextOverlay() end
end

function UI:ShowNextOverlay()
    if #overlayQueue == 0 then isShowingOverlay = false return end
    isShowingOverlay = true
    self:DisplayOverlay(table.remove(overlayQueue, 1))
end

function UI:DisplayOverlay(data)
    if not self.overlay then self:CreateOverlay() end
    
    local o = self.overlay
    local death = data.death
    local col = self:GetClassColor(death.classId)
    
    if o.hideTimer then o.hideTimer:Cancel() end
    
    -- Daten setzen
    o.nameText:SetText(death.name)
    o.classText:SetText("Level " .. (death.level or "?") .. " " .. GDL:GetClassName(death.classId))
    o.classText:SetTextColor(col[1], col[2], col[3])
    o.classIcon:SetTexture(self:GetClassIcon(death.classId))
    o.accent:SetColorTexture(col[1], col[2], col[3], 1)
    
    local zone = death.zone
    if zone and zone ~= "" then
        o.zoneText:SetText("† " .. zone)
    else
        o.zoneText:SetText("")
    end
    
    -- Killer Info (v4.0)
    local killer = death.killerName or death.killer
    if killer and killer ~= "" and killer ~= "Unknown" then
        o.killerText:SetText("Getötet von / Killed by: " .. killer)
        o.killerText:Show()
    else
        o.killerText:SetText("")
        o.killerText:Hide()
    end
    
    -- LastWords (v4.0)
    local lastWords = death.lastWords
    if lastWords and lastWords ~= "" then
        -- Max 60 Zeichen, mit "..." wenn länger
        if #lastWords > 60 then
            lastWords = lastWords:sub(1, 57) .. "..."
        end
        o.lastWordsText:SetText('"' .. lastWords .. '"')
        o.lastWordsText:Show()
    else
        o.lastWordsText:SetText("")
        o.lastWordsText:Hide()
    end
    
    -- Sounds
    PlaySound(8959, "Master")
    C_Timer.After(0.15, function() PlaySound(SOUNDKIT.RAID_WARNING, "Master") end)
    
    -- Show directly - no animation that resets alpha
    o:SetAlpha(1)
    o:Show()
    
    -- Hide after 8 seconds with fade
    o.hideTimer = C_Timer.NewTimer(8, function()
        -- Manuelles Fade-Out über OnUpdate
        local fadeStart = GetTime()
        local fadeDuration = 1.0
        o:SetScript("OnUpdate", function(self, elapsed)
            local progress = (GetTime() - fadeStart) / fadeDuration
            if progress >= 1 then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                self:SetAlpha(1)
                C_Timer.After(0.2, function() UI:ShowNextOverlay() end)
            else
                self:SetAlpha(1 - progress)
            end
        end)
    end)
end

function UI:CreateOverlay()
    local o = CreateFrame("Frame", "GDLDeathOverlay", UIParent, "BackdropTemplate")
    o:SetSize(340, 110)
    o:SetFrameStrata("FULLSCREEN_DIALOG")
    o:Hide()
    
    -- Skalierung anwenden
    local scale = GuildDeathLogDB.settings.overlayScale or 1.0
    o:SetScale(scale)
    
    -- Position laden oder Standard
    local pos = GuildDeathLogDB.settings.overlayPosition
    if pos and pos.point then
        o:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        o:SetPoint("TOP", 0, -100)
    end
    
    -- Verschiebbar machen
    o:SetMovable(true)
    o:EnableMouse(true)
    o:RegisterForDrag("LeftButton")
    o:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    o:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        GuildDeathLogDB.settings.overlayPosition = {
            point = point, relPoint = relPoint, x = x, y = y
        }
    end)
    o:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then self:Hide() end
    end)
    
    -- Dunkler eleganter Hintergrund
    o:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    o:SetBackdropColor(0.08, 0.05, 0.03, 0.95)
    o:SetBackdropBorderColor(0.4, 0.3, 0.2, 1)
    
    -- Rote Linie oben (Todesmarkierung)
    local topLine = o:CreateTexture(nil, "ARTWORK")
    topLine:SetPoint("TOPLEFT", 8, -8)
    topLine:SetPoint("TOPRIGHT", -8, -8)
    topLine:SetHeight(2)
    topLine:SetColorTexture(0.6, 0.1, 0.1, 0.9)
    
    -- Klassenfarben-Akzent links
    o.accent = o:CreateTexture(nil, "ARTWORK")
    o.accent:SetPoint("TOPLEFT", 8, -12)
    o.accent:SetPoint("BOTTOMLEFT", 8, 8)
    o.accent:SetWidth(3)
    
    -- GROSSES Totenkopf-Symbol links (statt Klassen-Icon)
    local deathIcon = o:CreateTexture(nil, "OVERLAY")
    deathIcon:SetSize(48, 48)
    deathIcon:SetPoint("LEFT", 18, 5)
    deathIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8") -- Totenkopf
    deathIcon:SetAlpha(0.85)
    
    -- Kleines Klassen-Icon rechts vom Totenkopf
    o.classIcon = o:CreateTexture(nil, "OVERLAY")
    o.classIcon:SetSize(20, 20)
    o.classIcon:SetPoint("BOTTOMRIGHT", deathIcon, "BOTTOMRIGHT", 6, -4)
    
    -- NAME (gross und golden)
    o.nameText = o:CreateFontString(nil, "OVERLAY")
    o.nameText:SetFont("Fonts\\MORPHEUS.TTF", 20, "")
    o.nameText:SetPoint("TOPLEFT", deathIcon, "TOPRIGHT", 12, 2)
    o.nameText:SetTextColor(1, 0.85, 0.4)
    
    -- Level & Class
    o.classText = o:CreateFontString(nil, "OVERLAY")
    o.classText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    o.classText:SetPoint("TOPLEFT", o.nameText, "BOTTOMLEFT", 0, -2)
    
    -- Zone + Killer in einer Zeile
    o.zoneText = o:CreateFontString(nil, "OVERLAY")
    o.zoneText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    o.zoneText:SetPoint("TOPLEFT", o.classText, "BOTTOMLEFT", 0, -2)
    o.zoneText:SetTextColor(0.6, 0.6, 0.6)
    
    -- Killer
    o.killerText = o:CreateFontString(nil, "OVERLAY")
    o.killerText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    o.killerText:SetPoint("TOPLEFT", o.zoneText, "BOTTOMLEFT", 0, -1)
    o.killerText:SetTextColor(0.9, 0.4, 0.4)
    
    -- LastWords (unten, kursiv-style)
    o.lastWordsText = o:CreateFontString(nil, "OVERLAY")
    o.lastWordsText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    o.lastWordsText:SetPoint("BOTTOMLEFT", 18, 10)
    o.lastWordsText:SetPoint("BOTTOMRIGHT", -12, 10)
    o.lastWordsText:SetTextColor(0.7, 0.7, 0.5)
    o.lastWordsText:SetJustifyH("LEFT")
    
    -- Dezenter Hinweis (nur kleine Punkte)
    local moveHint = o:CreateFontString(nil, "OVERLAY")
    moveHint:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    moveHint:SetPoint("BOTTOMRIGHT", -10, 3)
    moveHint:SetText("|cff444444...|r")
    moveHint:SetAlpha(0.5)
    
    self.overlay = o
end

-- ══════════════════════════════════════════════════════════════
-- EINSTELLUNGEN
-- ══════════════════════════════════════════════════════════════

function UI:ShowSettings()
    if not self.settingsFrame then self:CreateSettings() end
    self.settingsFrame:Show()
end

function UI:CreateSettings()
    local s = CreateFrame("Frame", "GDLSettings", UIParent, "BackdropTemplate")
    s:SetSize(300, 370)  -- Etwas größer für neue Option
    s:SetPoint("CENTER", UIParent, "CENTER", 450, 350)  -- Rechts-ganz-oben (cascade)
    s:SetFrameStrata("DIALOG")
    s:SetFrameLevel(110)
    s:SetMovable(true)
    s:EnableMouse(true)
    s:RegisterForDrag("LeftButton")
    s:SetScript("OnDragStart", s.StartMoving)
    s:SetScript("OnDragStop", s.StopMovingOrSizing)
    s:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    s:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    s:SetBackdropColor(1, 1, 1, 1)
    s:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
    
    -- Title
    local title = s:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    title:SetPoint("TOP", 0, -18)
    title:SetText("|cff4a3520Einstellungen|r")
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, s, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    
    local y, cbs = -45, {}
    local opts = {
        {"Gildenchat-Ankuendigung", "announce"}, 
        {"Sound abspielen", "sound"}, 
        {"Todes-Popup anzeigen", "overlay"}, 
        {"Karten-Markierungen (Tode)", "mapMarkers"}, 
        {"Gilden-Karte (Live-Positionen)", "guildTracker"},
        {"Blizzard HC-Channel", "useBlizzardChannel"}, 
        {"Addon-Sync aktiv", "useAddonChannel"}, 
        {"Debug-Ausgaben", "debugPrint"}
    }
    
    for _, opt in ipairs(opts) do
        local cb = CreateFrame("CheckButton", nil, s, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 25, y)
        cb:SetSize(24, 24)
        
        local label = cb:CreateFontString(nil, "OVERLAY")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        label:SetText(opt[1])
        label:SetTextColor(0.3, 0.25, 0.2)
        
        cb.key = opt[2]
        cb:SetScript("OnClick", function(self) 
            GuildDeathLogDB.settings[self.key] = self:GetChecked() 
        end)
        table.insert(cbs, cb)
        y = y - 26
    end
    
    -- ═══════════════════════════════════════════════════════════
    -- POPUP SKALIERUNG SLIDER
    -- ═══════════════════════════════════════════════════════════
    y = y - 15
    
    local scaleLabel = s:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    scaleLabel:SetPoint("TOPLEFT", 25, y)
    scaleLabel:SetText("Popup-Groesse / Popup Size:")
    scaleLabel:SetTextColor(0.3, 0.25, 0.2)
    
    y = y - 20
    
    local slider = CreateFrame("Slider", "GDLScaleSlider", s, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 30, y)
    slider:SetSize(200, 17)
    slider:SetMinMaxValues(0.5, 2.0)
    slider:SetValueStep(0.1)
    slider:SetObeyStepOnDrag(true)
    
    slider.Low:SetText("50%")
    slider.High:SetText("200%")
    slider.Text:SetText("")
    
    local scaleValue = s:CreateFontString(nil, "OVERLAY")
    scaleValue:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    scaleValue:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    scaleValue:SetTextColor(0.5, 0.4, 0.3)
    s.scaleValue = scaleValue
    
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value * 10 + 0.5) / 10 -- Runden auf 0.1
        GuildDeathLogDB.settings.overlayScale = value
        scaleValue:SetText(math.floor(value * 100) .. "%")
        -- Live-Update des Overlays
        if UI.overlay then
            UI.overlay:SetScale(value)
        end
    end)
    
    s.scaleSlider = slider
    
    s.cbs = cbs
    s:SetScript("OnShow", function(self) 
        for _, cb in ipairs(self.cbs) do 
            cb:SetChecked(GuildDeathLogDB.settings[cb.key]) 
        end
        -- Slider auf aktuellen Wert setzen
        local scale = GuildDeathLogDB.settings.overlayScale or 1.0
        self.scaleSlider:SetValue(scale)
        self.scaleValue:SetText(math.floor(scale * 100) .. "%")
    end)
    
    -- Buttons in einer Reihe
    local testBtn = self:CreateElegantButton(s, "Test", -95, 18, function()
        local testDeath = {
            name = UnitName("player"),
            level = UnitLevel("player"),
            classId = select(3, UnitClass("player")),
            zone = GetZoneText(),
            timestamp = time(),
            lastWords = "Dies sind meine letzten Worte...",
            killerName = "Test-Monster",
        }
        UI:ShowOverlay(testDeath, false)
    end)
    testBtn:SetSize(70, 26)
    
    local resetBtn = self:CreateElegantButton(s, "Reset Pos", 0, 18, function()
        GuildDeathLogDB.settings.overlayPosition = nil
        GuildDeathLogDB.settings.overlayScale = 1.0
        if UI.overlay then
            UI.overlay:ClearAllPoints()
            UI.overlay:SetPoint("TOP", 0, -100)
            UI.overlay:SetScale(1.0)
        end
        s.scaleSlider:SetValue(1.0)
        GDL:Print("Popup-Position zurueckgesetzt!")
    end)
    resetBtn:SetSize(75, 26)
    
    local okBtn = self:CreateElegantButton(s, "OK", 90, 18, function()
        s:Hide()
    end)
    okBtn:SetSize(60, 26)
    
    self.settingsFrame = s
end

-- ══════════════════════════════════════════════════════════════
-- RUHMESHALLE / HALL OF FAME (v4.0)
-- ══════════════════════════════════════════════════════════════
function UI:ShowHallOfFame()
    if not self.hallOfFameFrame then
        self:CreateHallOfFameWindow()
    end
    self.hallOfFameFrame:Show()
    self:UpdateHallOfFame()
end

function UI:CreateHallOfFameWindow()
    local HoF = GDL:GetModule("HallOfFame")
    if not HoF then return end
    
    local f = CreateFrame("Frame", "GDLHallOfFame", UIParent, "BackdropTemplate")
    f:SetSize(450, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", 520, 0)  -- Rechts-mitte (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(120)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    f:SetBackdropColor(1, 1, 1, 1)
    f:SetBackdropBorderColor(0.8, 0.7, 0.4, 1)
    
    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Content
    self.hallOfFameTab = HoF:CreateTab(f)
    self.hallOfFameTab:Show()
    
    self.hallOfFameFrame = f
end

function UI:UpdateHallOfFame()
    if self.hallOfFameTab and self.hallOfFameTab.Update then
        self.hallOfFameTab.Update()
    end
end

-- ══════════════════════════════════════════════════════════════
-- STATISTIKEN / STATISTICS (v4.0)
-- ══════════════════════════════════════════════════════════════
function UI:ShowStatistics()
    if not self.statsFrame then
        self:CreateStatisticsWindow()
    end
    self.statsFrame:Show()
    self:UpdateStatistics()
end

function UI:CreateStatisticsWindow()
    local f = CreateFrame("Frame", "GDLStatistics", UIParent, "BackdropTemplate")
    f:SetSize(420, 480)
    f:SetPoint("CENTER", UIParent, "CENTER", 500, -300)  -- Rechts-unten (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(130)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Title mit Icon
    local titleIcon = f:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(28, 28)
    titleIcon:SetPoint("TOP", -100, -12)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
    
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 8, 0)
    title:SetText("|cff1a0a00Statistiken|r")
    
    -- Scroll für Content
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -50)
    scroll:SetPoint("BOTTOMRIGHT", -35, 20)
    
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(scroll:GetWidth(), 800)
    scroll:SetScrollChild(child)
    f.contentFrame = child
    
    self.statsFrame = f
end

function UI:UpdateStatistics()
    local Stats = GDL:GetModule("Statistics")
    if not Stats or not self.statsFrame then return end
    
    local content = self.statsFrame.contentFrame
    -- Clear
    for _, c in ipairs({content:GetChildren()}) do c:Hide() c:SetParent(nil) end
    for _, r in ipairs({content:GetRegions()}) do r:Hide() end
    
    local y = 0
    local summary = Stats:GetSummary()
    local zones = Stats:GetDangerousZones(5)
    local killers = Stats:GetDeadliestKillers(5)
    local classes = Stats:GetDeathsByClass()
    
    -- ═══════════════════════════════════════════════════════════
    -- ZUSAMMENFASSUNG BOX
    -- ═══════════════════════════════════════════════════════════
    local sumBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
    sumBox:SetSize(360, 95)
    sumBox:SetPoint("TOPLEFT", 0, y)
    sumBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    sumBox:SetBackdropColor(0.1, 0.08, 0.05, 0.7)
    sumBox:SetBackdropBorderColor(0.6, 0.5, 0.3, 0.9)
    
    local sumIcon = sumBox:CreateTexture(nil, "ARTWORK")
    sumIcon:SetSize(32, 32)
    sumIcon:SetPoint("TOPLEFT", 10, -10)
    sumIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    
    local sumTitle = sumBox:CreateFontString(nil, "OVERLAY")
    sumTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    sumTitle:SetPoint("TOPLEFT", sumIcon, "TOPRIGHT", 8, -2)
    sumTitle:SetText("|cffFFDD88Zusammenfassung / Summary|r")
    
    -- Statistik-Werte in 2 Spalten
    local col1X, col2X = 15, 190
    local row1Y, row2Y, row3Y = -50, -65, -80
    
    local function StatLabel(parent, x, y, label, value)
        local lbl = parent:CreateFontString(nil, "OVERLAY")
        lbl:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        lbl:SetPoint("TOPLEFT", x, y)
        lbl:SetText("|cffCCBBAA" .. label .. ":|r")
        
        local val = parent:CreateFontString(nil, "OVERLAY")
        val:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        val:SetPoint("TOPLEFT", x + 80, y)
        val:SetText("|cffFFFFFF" .. tostring(value) .. "|r")
    end
    
    StatLabel(sumBox, col1X, row1Y, "Gesamt/Total", summary.total .. " Tode/Deaths")
    StatLabel(sumBox, col2X, row1Y, "Heute/Today", summary.today)
    StatLabel(sumBox, col1X, row2Y, "Woche/Week", summary.thisWeek)
    StatLabel(sumBox, col2X, row2Y, "Avg Level", string.format("%.1f", summary.avgLevel))
    StatLabel(sumBox, col1X, row3Y, "Max Level", summary.highestLevel)
    StatLabel(sumBox, col2X, row3Y, "Min Level", summary.lowestLevel)
    
    y = y - 105
    
    -- ═══════════════════════════════════════════════════════════
    -- GEFAEHRLICHSTE ZONEN
    -- ═══════════════════════════════════════════════════════════
    local zoneBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
    zoneBox:SetSize(175, 120)
    zoneBox:SetPoint("TOPLEFT", 0, y)
    zoneBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    zoneBox:SetBackdropColor(0.15, 0.05, 0.05, 0.6)
    zoneBox:SetBackdropBorderColor(0.6, 0.3, 0.3, 0.9)
    
    local zoneIcon = zoneBox:CreateTexture(nil, "ARTWORK")
    zoneIcon:SetSize(20, 20)
    zoneIcon:SetPoint("TOPLEFT", 8, -8)
    zoneIcon:SetTexture("Interface\\Icons\\Ability_Hunter_Pathfinding")
    
    local zoneTitle = zoneBox:CreateFontString(nil, "OVERLAY")
    zoneTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    zoneTitle:SetPoint("LEFT", zoneIcon, "RIGHT", 5, 0)
    zoneTitle:SetText("|cffFF9999Zonen / Zones|r")
    
    local zy = -35
    if #zones == 0 then
        local noData = zoneBox:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        noData:SetPoint("TOPLEFT", 10, zy)
        noData:SetText("|cff888888Keine Daten / No data|r")
    else
        for i, zone in ipairs(zones) do
            if i > 5 then break end
            local zt = zoneBox:CreateFontString(nil, "OVERLAY")
            zt:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            zt:SetPoint("TOPLEFT", 10, zy)
            local zoneName = (zone.zone or "?"):sub(1, 12)
            zt:SetText(string.format("|cffFFAAAA%d.|r |cffFFFFFF%s|r |cffCCCCCC(%d)|r", i, zoneName, zone.count))
            zy = zy - 14
        end
    end
    
    -- ═══════════════════════════════════════════════════════════
    -- TOEDLICHSTE MONSTER
    -- ═══════════════════════════════════════════════════════════
    local killerBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
    killerBox:SetSize(175, 120)
    killerBox:SetPoint("TOPLEFT", 185, y)
    killerBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    killerBox:SetBackdropColor(0.1, 0.05, 0.15, 0.6)
    killerBox:SetBackdropBorderColor(0.5, 0.3, 0.6, 0.9)
    
    local killerIcon = killerBox:CreateTexture(nil, "ARTWORK")
    killerIcon:SetSize(20, 20)
    killerIcon:SetPoint("TOPLEFT", 8, -8)
    killerIcon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")
    
    local killerTitle = killerBox:CreateFontString(nil, "OVERLAY")
    killerTitle:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    killerTitle:SetPoint("LEFT", killerIcon, "RIGHT", 5, 0)
    killerTitle:SetText("|cffCC99FFMonster / Killers|r")
    
    local ky = -35
    if #killers == 0 then
        local noData = killerBox:CreateFontString(nil, "OVERLAY")
        noData:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        noData:SetPoint("TOPLEFT", 10, ky)
        noData:SetText("|cff888888Keine Daten / No data|r")
    else
        for i, killer in ipairs(killers) do
            if i > 5 then break end
            local kt = killerBox:CreateFontString(nil, "OVERLAY")
            kt:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            kt:SetPoint("TOPLEFT", 10, ky)
            local killerName = (killer.name or "?"):sub(1, 12)
            kt:SetText(string.format("|cffDDBBFF%d.|r |cffFFFFFF%s|r |cffCCCCCC(%d)|r", i, killerName, killer.count))
            ky = ky - 14
        end
    end
    
    y = y - 130
    
    -- ═══════════════════════════════════════════════════════════
    -- TODE NACH KLASSE
    -- ═══════════════════════════════════════════════════════════
    local classBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
    classBox:SetSize(360, 145)
    classBox:SetPoint("TOPLEFT", 0, y)
    classBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    classBox:SetBackdropColor(0.08, 0.08, 0.12, 0.6)
    classBox:SetBackdropBorderColor(0.4, 0.4, 0.6, 0.9)
    
    local classIcon = classBox:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("TOPLEFT", 8, -8)
    classIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupLooking")
    
    local classTitle = classBox:CreateFontString(nil, "OVERLAY")
    classTitle:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    classTitle:SetPoint("LEFT", classIcon, "RIGHT", 5, 0)
    classTitle:SetText("|cff99BBFFKlassen / Classes|r")
    
    -- 2 Spalten fuer Klassen
    local cy = -35
    local classCol = 0
    for i, class in ipairs(classes) do
        local col = self:GetClassColor(class.classId)
        local xOffset = classCol == 0 and 10 or 185
        
        -- Klassen-Icon
        local cIcon = classBox:CreateTexture(nil, "ARTWORK")
        cIcon:SetSize(16, 16)
        cIcon:SetPoint("TOPLEFT", xOffset, cy)
        cIcon:SetTexture(self:GetClassIcon(class.classId))
        
        -- Klassen-Name und Count - helle Klassenfarben
        local ct = classBox:CreateFontString(nil, "OVERLAY")
        ct:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        ct:SetPoint("LEFT", cIcon, "RIGHT", 5, 0)
        -- Farben aufhellen
        local r = math.min(1, col[1] + 0.3)
        local g = math.min(1, col[2] + 0.3)
        local b = math.min(1, col[3] + 0.3)
        ct:SetText(string.format("|cff%02x%02x%02x%s|r: |cffFFFFFF%d|r", 
            r*255, g*255, b*255, 
            (class.name or "?"):sub(1,10), class.count))
        
        classCol = classCol + 1
        if classCol >= 2 then
            classCol = 0
            cy = cy - 22
        end
    end
    
    y = y - 155
    
    content:SetHeight(math.abs(y) + 20)
end

-- ══════════════════════════════════════════════════════════════
-- ERFOLGE / ACHIEVEMENTS (v4.0)
-- ══════════════════════════════════════════════════════════════
function UI:ShowAchievements()
    if not self.achieveFrame then
        self:CreateMilestonesWindow()
    end
    self.achieveFrame:Show()
    self:UpdateMilestones()
end

function UI:CreateMilestonesWindow()
    local f = CreateFrame("Frame", "GDLMilestones", UIParent, "BackdropTemplate")
    f:SetSize(450, 550)
    f:SetPoint("CENTER", UIParent, "CENTER", 560, -330)  -- Rechts-unten diagonal versetzt (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(140)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff1a0a00Meilensteine / Milestones|r")
    
    -- Charakter-Name Anzeige
    local charInfo = f:CreateFontString(nil, "OVERLAY")
    charInfo:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    charInfo:SetPoint("TOP", title, "BOTTOM", 0, -5)
    charInfo:SetTextColor(0.2, 0.15, 0.1)  -- Dunkelbraun für bessere Lesbarkeit
    f.charInfo = charInfo
    
    -- Kategorie-Buttons - 5 Kategorien
    local categories = {
        {id = "level", name = "Level", icon = "Interface\\Icons\\Spell_Holy_WordFortitude"},
        {id = "dungeon", name = "Dungeons", icon = "Interface\\Icons\\INV_Misc_Key_04"},
        {id = "raid", name = "Raids", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01"},
        {id = "profession", name = "Berufe", icon = "Interface\\Icons\\Trade_BlackSmithing"},
        {id = "kills", name = "Kills", icon = "Interface\\Icons\\Ability_DualWield"},
    }
    
    f.categoryButtons = {}
    f.selectedCategory = "level"
    
    local btnWidth = 82
    local totalWidth = #categories * btnWidth + (#categories - 1) * 5
    local btnX = -totalWidth / 2
    for i, cat in ipairs(categories) do
        local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
        btn:SetSize(btnWidth, 28)
        btn:SetPoint("TOP", btnX + (i-1)*(btnWidth + 5) + btnWidth/2, -55)
        
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
        
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 5, 0)
        icon:SetTexture(cat.icon)
        
        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
        text:SetText(cat.name)
        
        btn.categoryId = cat.id
        btn:SetScript("OnClick", function()
            f.selectedCategory = cat.id
            self:UpdateMilestones()
        end)
        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.15, 0.9)
        end)
        btn:SetScript("OnLeave", function(self)
            if f.selectedCategory == self.categoryId then
                self:SetBackdropColor(0.2, 0.15, 0.1, 0.9)
            else
                self:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            end
        end)
        
        f.categoryButtons[cat.id] = btn
    end
    
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -95)
    scroll:SetPoint("BOTTOMRIGHT", -35, 20)
    
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(scroll:GetWidth(), 800)
    scroll:SetScrollChild(child)
    f.contentFrame = child
    
    self.achieveFrame = f
end

function UI:UpdateMilestones()
    local Milestones = GDL:GetModule("Milestones")
    if not Milestones or not self.achieveFrame then return end
    
    local f = self.achieveFrame
    local content = f.contentFrame
    local category = f.selectedCategory or "level"
    
    -- Charakter-Info aktualisieren
    local charKey = Milestones:GetCharacterKey()
    local charName = UnitName("player")
    local unlocked, total = Milestones:GetMilestoneProgress(charKey)
    f.charInfo:SetText("|cffFFD100" .. charName .. "|r |cff3a2a10- " .. unlocked .. "/" .. total .. " Meilensteine|r")
    
    -- Button-Farben aktualisieren
    for catId, btn in pairs(f.categoryButtons) do
        if catId == category then
            btn:SetBackdropColor(0.2, 0.15, 0.1, 0.9)
            btn:SetBackdropBorderColor(0.8, 0.7, 0.4, 1)
        else
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
        end
    end
    
    -- Content leeren
    for _, c in ipairs({content:GetChildren()}) do c:Hide() c:SetParent(nil) end
    for _, r in ipairs({content:GetRegions()}) do r:Hide() end
    
    local milestones = Milestones:GetMilestonesByCategory(category)
    local charMilestones = Milestones:GetCharacterMilestones(charKey)
    local y = 0
    
    -- Kategorie-Header
    local catUnlocked, catTotal = Milestones:GetCategoryProgress(category, charKey)
    local header = content:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    header:SetPoint("TOPLEFT", 5, y)
    
    local categoryNames = {
        level = "Level-Meilensteine",
        dungeon = "Dungeon-Bosse",
        raid = "Raid-Bosse",
        profession = "Berufe",
        kills = "Kill-Meilensteine"
    }
    header:SetText("|cff1a0a00" .. (categoryNames[category] or category) .. "|r |cff806040- " .. catUnlocked .. "/" .. catTotal .. "|r")
    y = y - 25
    
    -- Sortiere nach Threshold
    table.sort(milestones, function(a, b)
        return (a.threshold or 0) < (b.threshold or 0)
    end)
    
    for _, m in ipairs(milestones) do
        local isUnlocked = charMilestones[m.id] ~= nil
        local unlockData = charMilestones[m.id]
        
        -- Kill-Meilensteine brauchen mehr Platz für Progress-Leiste
        local rowHeight = 55
        if not isUnlocked and m.type == "kills" then
            rowHeight = 68
        end
        
        local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
        row:SetSize(380, rowHeight)
        row:SetPoint("TOPLEFT", 0, y)
        
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        
        -- Farbe basierend auf Kategorie und Status
        local catColors = {
            level = {0.2, 0.6, 0.2},
            dungeon = {0.4, 0.4, 0.8},
            raid = {0.8, 0.4, 0.2},
            profession = {0.6, 0.5, 0.2},
            kills = {0.7, 0.2, 0.2}
        }
        local color = catColors[category] or {0.5, 0.5, 0.5}
        
        if isUnlocked then
            row:SetBackdropColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.8)
            row:SetBackdropBorderColor(color[1], color[2], color[3], 0.9)
        else
            row:SetBackdropColor(0.08, 0.08, 0.08, 0.5)
            row:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.5)
        end
        
        -- Icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(42, 42)
        icon:SetPoint("LEFT", 6, 0)
        icon:SetTexture(m.icon)
        if not isUnlocked then 
            icon:SetDesaturated(true) 
            icon:SetAlpha(0.4) 
        end
        
        -- Name
        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -5)
        name:SetWidth(280)
        if isUnlocked then
            name:SetText("|cff00FF00[+]|r " .. m.name)
        else
            name:SetText("|cff666666" .. m.name .. "|r")
        end
        
        -- Beschreibung
        local desc = row:CreateFontString(nil, "OVERLAY")
        desc:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        desc:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        desc:SetWidth(280)
        desc:SetText("|cff888888" .. m.desc .. "|r")
        
        -- Datum wenn freigeschaltet
        if isUnlocked and unlockData then
            local dateText = row:CreateFontString(nil, "OVERLAY")
            dateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            dateText:SetPoint("BOTTOMRIGHT", -10, 8)
            local dateStr = unlockData.timestamp and date("%d.%m.%Y", unlockData.timestamp) or "?"
            dateText:SetText("|cff00AA00" .. dateStr .. "|r")
            
            if unlockData.level then
                local lvlText = row:CreateFontString(nil, "OVERLAY")
                lvlText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                lvlText:SetPoint("TOPRIGHT", -10, -8)
                lvlText:SetText("|cffAAAA00Lvl " .. unlockData.level .. "|r")
            end
        end
        
        -- Fortschrittsbalken für Kill-Meilensteine (wenn nicht freigeschaltet)
        if not isUnlocked and m.type == "kills" and m.creatureType and m.threshold then
            local KillStats = GDL:GetModule("KillStats")
            if KillStats then
                local currentKills = KillStats:GetKillCount(m.creatureType)
                local threshold = m.threshold
                
                -- Wenn Ziel erreicht aber noch nicht freigeschaltet: Jetzt freischalten!
                if currentKills >= threshold then
                    -- Meilenstein sollte freigeschaltet werden
                    local charKey = Milestones:GetCharacterKey()
                    local charName = UnitName("player")
                    local level = UnitLevel("player")
                    Milestones:UnlockMilestone(m.id, charKey, charName, level, true)
                    
                    -- Zeige als erreicht an
                    row:SetBackdropColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.8)
                    row:SetBackdropBorderColor(color[1], color[2], color[3], 0.9)
                    icon:SetDesaturated(false)
                    icon:SetAlpha(1)
                    name:SetText("|cff00FF00[+]|r " .. m.name)
                    
                    -- Datum anzeigen
                    local dateText = row:CreateFontString(nil, "OVERLAY")
                    dateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                    dateText:SetPoint("BOTTOMRIGHT", -10, 8)
                    dateText:SetText("|cff00AA00" .. date("%d.%m.%Y") .. "|r")
                else
                    -- Progress noch nicht erreicht - zeige Balken
                    local progress = currentKills / threshold
                    
                    -- Progress Bar Background - kompakt unter der Beschreibung
                    local barBg = row:CreateTexture(nil, "ARTWORK")
                    barBg:SetSize(120, 8)
                    barBg:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -4)
                    barBg:SetColorTexture(0.1, 0.08, 0.05, 0.9)
                    
                    -- Progress Bar Fill
                    if progress > 0 then
                        local barFill = row:CreateTexture(nil, "OVERLAY")
                        barFill:SetSize(math.max(120 * progress, 1), 8)
                        barFill:SetPoint("LEFT", barBg, "LEFT", 0, 0)
                        barFill:SetColorTexture(color[1], color[2], color[3], 1)
                    end
                    
                    -- Progress Text - rechts neben der Leiste
                    local progressText = row:CreateFontString(nil, "OVERLAY")
                    progressText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
                    progressText:SetPoint("LEFT", barBg, "RIGHT", 5, 0)
                    progressText:SetText("|cffDDDDDD" .. currentKills .. "/" .. threshold .. "|r")
                end
            end
        end
        
        y = y - (rowHeight + 5)  -- Dynamische Höhe + Abstand
    end
    
    content:SetHeight(math.abs(y) + 30)
end

-- ══════════════════════════════════════════════════════════════
-- TITLES WINDOW - Titel-Auswahl Fenster
-- ══════════════════════════════════════════════════════════════

function UI:ToggleTitles()
    if not self.titlesFrame then
        self:CreateTitlesWindow()
    end
    
    if self.titlesFrame:IsShown() then
        self.titlesFrame:Hide()
    else
        self.titlesFrame:Show()
        self:UpdateTitles()
    end
end

function UI:CreateTitlesWindow()
    local f = CreateFrame("Frame", "GDLTitles", UIParent, "BackdropTemplate")
    f:SetSize(420, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", 550, 150)  -- Rechts-oben (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(150)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Titel-Icon oben
    local headerIcon = f:CreateTexture(nil, "ARTWORK")
    headerIcon:SetSize(40, 40)
    headerIcon:SetPoint("TOP", 0, -15)
    headerIcon:SetTexture("Interface\\Icons\\INV_Crown_01")
    
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    title:SetPoint("TOP", headerIcon, "BOTTOM", 0, -5)
    title:SetText("|cff1a0a00Titel / Titles|r")
    
    -- Aktueller Titel Anzeige
    local currentFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    currentFrame:SetSize(380, 60)
    currentFrame:SetPoint("TOP", title, "BOTTOM", 0, -15)
    currentFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    currentFrame:SetBackdropColor(0.1, 0.08, 0.05, 0.9)
    currentFrame:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
    
    local currentLabel = currentFrame:CreateFontString(nil, "OVERLAY")
    currentLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    currentLabel:SetPoint("TOPLEFT", 10, -8)
    currentLabel:SetText("|cffAAAA00Aktueller Titel:|r")
    
    local currentTitle = currentFrame:CreateFontString(nil, "OVERLAY")
    currentTitle:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    currentTitle:SetPoint("LEFT", 50, -5)
    f.currentTitleText = currentTitle
    
    local currentIcon = currentFrame:CreateTexture(nil, "ARTWORK")
    currentIcon:SetSize(32, 32)
    currentIcon:SetPoint("LEFT", 10, -5)
    f.currentTitleIcon = currentIcon
    
    -- Progress-Anzeige
    local progressText = f:CreateFontString(nil, "OVERLAY")
    progressText:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    progressText:SetPoint("TOP", currentFrame, "BOTTOM", 0, -10)
    f.progressText = progressText
    
    -- Info-Text
    local infoText = f:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    infoText:SetPoint("TOP", progressText, "BOTTOM", 0, -5)
    infoText:SetText("|cff888888Titel sind für alle Gildenmitglieder mit dem Addon sichtbar!|r")
    
    -- Scroll-Bereich für Titel-Liste
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -175)
    scroll:SetPoint("BOTTOMRIGHT", -35, 15)
    
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(scroll:GetWidth(), 600)
    scroll:SetScrollChild(child)
    f.contentFrame = child
    
    f:Hide()
    self.titlesFrame = f
end

function UI:UpdateTitles()
    local Titles = GDL:GetModule("Titles")
    if not Titles or not self.titlesFrame then return end
    
    local f = self.titlesFrame
    local content = f.contentFrame
    
    -- Content leeren
    for _, child in ipairs({content:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Aktueller Titel
    local selected = Titles:GetSelectedTitle()
    if selected then
        local color = selected.color or {1, 1, 1}
        f.currentTitleText:SetText(string.format("|cff%02x%02x%02x<%s>|r", 
            color[1]*255, color[2]*255, color[3]*255, selected.name))
        f.currentTitleIcon:SetTexture(selected.icon)
    end
    
    -- Progress
    local unlocked, total = Titles:GetStats()
    f.progressText:SetText("|cffFFD100" .. unlocked .. "|r / |cff888888" .. total .. " Titel freigeschaltet|r")
    
    -- Titel-Liste
    local allTitles = Titles:GetUnlockedTitles()
    local y = 0
    
    for _, t in ipairs(allTitles) do
        local isSelected = selected and selected.id == t.id
        
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetSize(350, 55)
        row:SetPoint("TOPLEFT", 0, y)
        
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        
        local color = t.color or {0.5, 0.5, 0.5}
        
        if isSelected then
            row:SetBackdropColor(color[1] * 0.4, color[2] * 0.4, color[3] * 0.4, 0.9)
            row:SetBackdropBorderColor(0, 1, 0, 1)  -- Grüner Rahmen
        else
            row:SetBackdropColor(0.1, 0.08, 0.05, 0.7)
            row:SetBackdropBorderColor(color[1] * 0.6, color[2] * 0.6, color[3] * 0.6, 0.8)
        end
        
        -- Icon
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(40, 40)
        icon:SetPoint("LEFT", 8, 0)
        icon:SetTexture(t.icon)
        
        -- Titel-Name
        local nameText = row:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -5)
        nameText:SetText(string.format("|cff%02x%02x%02x<%s>|r", 
            color[1]*255, color[2]*255, color[3]*255, t.name))
        
        -- Beschreibung
        local descText = row:CreateFontString(nil, "OVERLAY")
        descText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        descText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -3)
        descText:SetText("|cff888888" .. t.desc .. "|r")
        
        -- Aktiv-Marker
        if isSelected then
            local marker = row:CreateFontString(nil, "OVERLAY")
            marker:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
            marker:SetPoint("RIGHT", -10, 0)
            marker:SetText("|cff00FF00< AKTIV|r")
        end
        
        -- Hover-Effekte
        row:SetScript("OnEnter", function(self)
            if not isSelected then
                self:SetBackdropColor(color[1] * 0.3, color[2] * 0.3, color[3] * 0.3, 0.9)
            end
            
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine(t.name, color[1], color[2], color[3])
            GameTooltip:AddLine(t.desc, 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            if t.requirement then
                GameTooltip:AddLine("Benötigt: " .. t.requirement, 0.7, 0.7, 0.7)
            end
            GameTooltip:AddLine("Priorität: " .. (t.priority or 0), 0.5, 0.5, 0.5)
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Klicken zum Auswählen", 0, 1, 0)
            GameTooltip:Show()
        end)
        
        row:SetScript("OnLeave", function(self)
            if not isSelected then
                self:SetBackdropColor(0.1, 0.08, 0.05, 0.7)
            end
            GameTooltip:Hide()
        end)
        
        -- Klick zum Auswählen
        row:SetScript("OnClick", function()
            Titles:SetSelectedTitle(t.id)
            self:UpdateTitles()
        end)
        
        y = y - 60
    end
    
    content:SetHeight(math.abs(y) + 20)
end

GDL:RegisterModule("UI", UI)
