-- ══════════════════════════════════════════════════════════════
-- MODUL: Memorial - Gedenken an verstorbene Gildenmitglieder
-- Zeigt zufällige Nachrufe und entfernt Tote aus Berufe-Liste
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Memorial = {}

-- Zufällige Nachrufe/Danksagungen
local MEMORIALS_DE = {
    -- Ehrenvoll
    "Ruhe in Frieden, tapferer Held.",
    "Dein Opfer wird nicht vergessen.",
    "Die Gilde trauert um dich.",
    "Moege deine Seele Frieden finden.",
    "Ein wahrer Held ist gefallen.",
    "Wir werden dich niemals vergessen.",
    "Dein Mut wird ewig in Erinnerung bleiben.",
    "Die Ahnen heissen dich willkommen.",
    "Ruhe nun, Krieger. Dein Kampf ist vorbei.",
    "Moegen die Geister dich leiten.",
    
    -- Humorvoll
    "Er stand im Feuer. Buchstaeblich.",
    "Hat wohl den Heiler nicht bezahlt.",
    "Darwin Award Kandidat.",
    "'Ich tank das' - Letzte Worte.",
    "Leroy waere stolz gewesen.",
    "AFK war keine Option.",
    "Der Boden war zu bequem.",
    "Respawn in 3... 2... 1... oh wait.",
    "Hardcore heisst Hardcore.",
    "Sollte wohl doch nicht pullen...",
    
    -- Episch
    "Ein Stern erlischt am Himmel Azeroths.",
    "Die Chroniken werden von dir berichten.",
    "Selbst der Tod konnte deinen Ruhm nicht mindern.",
    "Von Helden zu Legenden.",
    "Dein Name hallt durch die Hallen der Gefallenen.",
    "Die Flamme deines Lebens erlosch - doch dein Licht bleibt.",
    "Azeroth hat einen Beschuetzer verloren.",
    "Moege das Licht dich auf ewig begleiten.",
}

local MEMORIALS_EN = {
    -- Honorable
    "Rest in peace, brave hero.",
    "Your sacrifice will not be forgotten.",
    "The guild mourns your loss.",
    "May your soul find peace.",
    "A true hero has fallen.",
    "We will never forget you.",
    "Your courage will be remembered forever.",
    "The ancestors welcome you.",
    "Rest now, warrior. Your fight is over.",
    "May the spirits guide you.",
    
    -- Humorous
    "Stood in the fire. Literally.",
    "Probably didn't tip the healer.",
    "Darwin Award candidate.",
    "'I can tank this' - Famous last words.",
    "Leroy would be proud.",
    "AFK was not an option.",
    "The floor was too comfortable.",
    "Respawn in 3... 2... 1... oh wait.",
    "Hardcore means hardcore.",
    "Should not have pulled that...",
    
    -- Epic
    "A star fades from Azeroth's sky.",
    "The chronicles will speak of you.",
    "Even death could not diminish your glory.",
    "From heroes to legends.",
    "Your name echoes through the Halls of the Fallen.",
    "Your flame extinguished - but your light remains.",
    "Azeroth has lost a protector.",
    "May the Light guide you eternally.",
}

function Memorial:GetRandomMemorial()
    local locale = GetLocale()
    local list = (locale == "deDE") and MEMORIALS_DE or MEMORIALS_EN
    return list[math.random(#list)]
end

function Memorial:GetMemorialForDeath(death)
    -- Generiert einen personalisierten Nachruf
    local name = death.name or "Unbekannt"
    local level = death.level or "?"
    local className = GDL:GetClassName(death.classId)
    local zone = death.zone or "Unbekannt"
    
    local memorial = self:GetRandomMemorial()
    
    return {
        name = name,
        level = level,
        class = className,
        classId = death.classId,
        zone = zone,
        timestamp = death.timestamp,
        memorial = memorial,
        killerName = death.killerName,
    }
end

-- ══════════════════════════════════════════════════════════════
-- VERSTORBENE AUS BERUFE-LISTE ENTFERNEN
-- ══════════════════════════════════════════════════════════════

function Memorial:GetDeceasedNames()
    local deceased = {}
    local guildData = GDL:GetGuildData()
    if guildData and guildData.deaths then
        for _, death in ipairs(guildData.deaths) do
            if death.name then
                deceased[death.name] = true
            end
        end
    end
    return deceased
end

function Memorial:CleanProfessions()
    local Professions = GDL:GetModule("Professions")
    if not Professions then return 0 end
    
    local allProfs = Professions:GetAllProfessions()
    if not allProfs then return 0 end
    
    local deceased = self:GetDeceasedNames()
    local removed = 0
    
    for name, _ in pairs(allProfs) do
        if deceased[name] then
            allProfs[name] = nil
            removed = removed + 1
            GDL:Debug("Memorial: " .. name .. " aus Berufe-Liste entfernt (verstorben)")
        end
    end
    
    if removed > 0 then
        GDL:Debug("Memorial: " .. removed .. " Verstorbene aus Berufe-Liste entfernt")
    end
    
    return removed
end

-- ══════════════════════════════════════════════════════════════
-- UI: GEDENK-FENSTER
-- ══════════════════════════════════════════════════════════════

function Memorial:ShowMemorialWindow()
    if self.frame and self.frame:IsShown() then
        self.frame:Hide()
        return
    end
    
    if not self.frame then
        self:CreateMemorialWindow()
    end
    
    self:UpdateMemorialList()
    self.frame:Show()
end

function Memorial:CreateMemorialWindow()
    local f = CreateFrame("Frame", "GDLMemorialFrame", UIParent, "BackdropTemplate")
    f:SetSize(450, 500)
    f:SetPoint("CENTER", UIParent, "CENTER", -480, 200)  -- Links-oben (cascade)
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
    title:SetText("|cff8B4513Gedenkhalle der Gefallenen|r")
    
    -- Untertitel
    local subtitle = f:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 11)
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -5)
    subtitle:SetTextColor(0.4, 0.3, 0.2)
    subtitle:SetText("In Erinnerung an unsere gefallenen Helden")
    f.subtitle = subtitle
    
    -- Close Button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 20)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(390, 1)
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    
    self.frame = f
end

function Memorial:UpdateMemorialList()
    local scrollChild = self.frame.scrollChild
    
    -- Alte Einträge löschen
    for _, child in ipairs({scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.deaths then return end
    
    -- Nach Zeit sortieren (neueste zuerst)
    local deaths = {}
    for _, death in ipairs(guildData.deaths) do
        table.insert(deaths, death)
    end
    table.sort(deaths, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    local y = 0
    for i, death in ipairs(deaths) do
        local memData = self:GetMemorialForDeath(death)
        local row = self:CreateMemorialEntry(scrollChild, memData, y)
        y = y - 85
    end
    
    scrollChild:SetHeight(math.abs(y) + 20)
    
    -- Untertitel aktualisieren
    self.frame.subtitle:SetText("In Erinnerung an " .. #deaths .. " gefallene Helden")
end

function Memorial:CreateMemorialEntry(parent, data, yOffset)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(385, 80)
    row:SetPoint("TOPLEFT", 0, yOffset)
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    row:SetBackdropColor(0.1, 0.08, 0.05, 0.7)
    row:SetBackdropBorderColor(0.3, 0.25, 0.2, 0.8)
    
    -- ClassId zu englischem Klassennamen für Icon-Lookup
    local CLASS_ID_TO_NAME = {
        [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE",
        [5] = "PRIEST", [6] = "DEATHKNIGHT", [7] = "SHAMAN", [8] = "MAGE",
        [9] = "WARLOCK", [10] = "MONK", [11] = "DRUID",
    }
    local classKey = CLASS_ID_TO_NAME[data.classId] or "WARRIOR"
    
    -- Klassen-Icon
    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(32, 32)
    classIcon:SetPoint("TOPLEFT", 8, -8)
    local coords = CLASS_ICON_TCOORDS[classKey]
    if coords then
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        classIcon:SetTexCoord(unpack(coords))
    else
        -- Fallback: Weißes Quadrat mit Klassenfarbe
        classIcon:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        local col = self:GetClassColor(data.classId)
        classIcon:SetVertexColor(col.r, col.g, col.b)
    end
    
    -- Totenkopf-Overlay
    local skull = row:CreateTexture(nil, "OVERLAY")
    skull:SetSize(16, 16)
    skull:SetPoint("BOTTOMRIGHT", classIcon, "BOTTOMRIGHT", 4, -4)
    skull:SetTexture("Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_8")
    
    -- Klassenfarbe holen
    local classColor = RAID_CLASS_COLORS[classKey] or {r=0.7, g=0.7, b=0.7}
    
    -- Name + Level
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    nameText:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", 8, 0)
    nameText:SetText(string.format("|cff%02x%02x%02x%s|r |cffAAAAAA(Lvl %s %s)|r", 
        classColor.r * 255, classColor.g * 255, classColor.b * 255,
        data.name, data.level, data.class or ""))
    
    -- Zone + Killer
    local zoneText = row:CreateFontString(nil, "OVERLAY")
    zoneText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    zoneText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    zoneText:SetTextColor(0.6, 0.5, 0.4)
    local zoneStr = data.zone or "Unbekannt"
    if data.killerName and data.killerName ~= "" then
        zoneStr = zoneStr .. " - getoetet von " .. data.killerName
    end
    zoneText:SetText(zoneStr)
    
    -- Datum
    local dateText = row:CreateFontString(nil, "OVERLAY")
    dateText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    dateText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -10, -8)
    dateText:SetTextColor(0.5, 0.4, 0.3)
    if data.timestamp then
        dateText:SetText(date("%d.%m.%Y %H:%M", data.timestamp))
    end
    
    -- Memorial-Text (Nachruf)
    local memorialText = row:CreateFontString(nil, "OVERLAY")
    memorialText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    memorialText:SetPoint("BOTTOMLEFT", 10, 8)
    memorialText:SetPoint("BOTTOMRIGHT", -10, 8)
    memorialText:SetTextColor(0.8, 0.7, 0.5)
    memorialText:SetText("|cffDDCCAA\"" .. data.memorial .. "\"|r")
    
    return row
end

-- ══════════════════════════════════════════════════════════════
-- HILFSFUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function Memorial:GetClassColor(classId)
    local colors = {
        [1] = {r=0.78, g=0.61, b=0.43},  -- Krieger
        [2] = {r=0.96, g=0.55, b=0.73},  -- Paladin
        [3] = {r=0.67, g=0.83, b=0.45},  -- Jäger
        [4] = {r=1.00, g=0.96, b=0.41},  -- Schurke
        [5] = {r=1.00, g=1.00, b=1.00},  -- Priester
        [6] = {r=0.77, g=0.12, b=0.23},  -- DK
        [7] = {r=0.00, g=0.44, b=0.87},  -- Schamane
        [8] = {r=0.25, g=0.78, b=0.92},  -- Magier
        [9] = {r=0.53, g=0.53, b=0.93},  -- Hexer
        [10] = {r=0.00, g=1.00, b=0.59}, -- Mönch
        [11] = {r=1.00, g=0.49, b=0.04}, -- Druide
    }
    return colors[classId] or {r=0.7, g=0.7, b=0.7}
end

-- ══════════════════════════════════════════════════════════════
-- EVENT HANDLING
-- ══════════════════════════════════════════════════════════════

function Memorial:OnDeath(death)
    -- Bei jedem Tod: Verstorbene aus Berufe-Liste entfernen
    C_Timer.After(2, function()
        self:CleanProfessions()
    end)
end

function Memorial:Initialize()
    if self.initialized then return end
    self.initialized = true
    
    -- Initial Berufe-Liste bereinigen
    C_Timer.After(10, function()
        local removed = self:CleanProfessions()
        if removed > 0 then
            GDL:Debug("Memorial: " .. removed .. " Verstorbene aus Berufe-Liste entfernt")
        end
    end)
    
    GDL:Debug("Memorial-Modul aktiv")
end

-- ══════════════════════════════════════════════════════════════
-- MODULE INITIALIZATION
-- ══════════════════════════════════════════════════════════════

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(8, function()
            Memorial:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Memorial", Memorial)
