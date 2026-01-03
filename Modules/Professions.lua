-- ══════════════════════════════════════════════════════════════
-- MODUL: Professions - Trackt Berufe aller Gildenmitglieder
-- Synct automatisch mit anderen Addon-Nutzern
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Professions = {}

local ADDON_PREFIX = "GDLProf"
local BROADCAST_INTERVAL = 60  -- Alle 60 Sekunden Berufe senden
local STALE_TIMEOUT = 600      -- Nach 10 Minuten ohne Update = veraltet

-- Speichert Berufe aller Spieler
-- Format: {name = {prof1 = {name, skill, max}, prof2 = {name, skill, max}, timestamp, classId, level}}
local guildProfessions = {}

-- Prefix registrieren
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- ══════════════════════════════════════════════════════════════
-- INITIALISIERUNG
-- ══════════════════════════════════════════════════════════════

function Professions:Initialize()
    -- Gespeicherte Daten laden
    if GuildDeathLogDB.professions then
        guildProfessions = GuildDeathLogDB.professions
    end
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
    self.eventFrame:RegisterEvent("TRADE_SKILL_UPDATE")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    
    -- Berufe regelmäßig broadcasten
    C_Timer.NewTicker(BROADCAST_INTERVAL, function()
        if IsInGuild() then
            self:BroadcastProfessions()
        end
    end)
    
    -- Nach Login broadcasten
    C_Timer.After(8, function()
        if IsInGuild() then
            self:BroadcastProfessions()
        end
    end)
    
    -- Request von allen nach Login
    C_Timer.After(10, function()
        if IsInGuild() then
            self:RequestAllProfessions()
        end
    end)
    
    GDL:Debug("Professions-Modul aktiv")
end

function Professions:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_PREFIX and channel == "GUILD" then
            self:HandleMessage(message, sender)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(5, function()
            if IsInGuild() then
                self:BroadcastProfessions()
            end
        end)
    elseif event == "SKILL_LINES_CHANGED" or event == "TRADE_SKILL_UPDATE" then
        -- Bei Skill-Änderung neu broadcasten
        C_Timer.After(2, function()
            if IsInGuild() then
                self:BroadcastProfessions()
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- SPEZIALISIERUNG ERMITTELN (Talentbaum mit meisten Punkten)
-- ══════════════════════════════════════════════════════════════

function Professions:GetSpecialization()
    -- Sichere Variante für verschiedene Classic-Versionen
    if not GetNumTalentTabs or not GetTalentTabInfo then 
        return "", 0 
    end
    
    local ok, numTabs = pcall(GetNumTalentTabs)
    if not ok or not numTabs or numTabs == 0 then 
        return "", 0 
    end
    
    local maxPoints = 0
    local specIndex = 0
    local specName = ""
    
    for i = 1, numTabs do
        local ok2, results = pcall(function()
            return {GetTalentTabInfo(i)}
        end)
        
        if ok2 and results then
            -- Finde den Namen (erster String) und Punkte (erste Zahl nach dem Namen)
            local tabName = ""
            local points = 0
            local foundName = false
            
            for j, v in ipairs(results) do
                if type(v) == "string" and not foundName and v ~= "" then
                    tabName = v
                    foundName = true
                elseif type(v) == "number" and foundName and v < 100 then
                    -- Punkte sind typischerweise < 100, IDs sind größer
                    points = v
                    break
                end
            end
            
            if points > maxPoints then
                maxPoints = points
                specIndex = i
                specName = tabName
            end
        end
    end
    
    -- Spec-Namen - ALLE VOLLSTÄNDIG AUSGESCHRIEBEN
    local shortNames = {
        -- Krieger
        ["Waffen"] = "Waffen", ["Arms"] = "Waffen",
        ["Furor"] = "Furor", ["Fury"] = "Furor",
        ["Schutz"] = "Schutz", ["Protection"] = "Schutz",
        -- Paladin
        ["Heilig"] = "Heilig", ["Holy"] = "Heilig",
        ["Vergeltung"] = "Vergelter", ["Retribution"] = "Vergelter",
        -- Jäger
        ["Tierherrschaft"] = "Tierherrschaft", ["Beast Mastery"] = "Tierherrschaft",
        ["Treffsicherheit"] = "Treffsicherheit", ["Marksmanship"] = "Treffsicherheit",
        ["Überleben"] = "Überleben", ["Survival"] = "Überleben",
        -- Schurke
        ["Meucheln"] = "Meucheln", ["Assassination"] = "Meucheln",
        ["Kampf"] = "Kampf", ["Combat"] = "Kampf",
        ["Täuschung"] = "Täuschung", ["Subtlety"] = "Täuschung",
        -- Priester
        ["Disziplin"] = "Disziplin", ["Discipline"] = "Disziplin",
        ["Schatten"] = "Schatten", ["Shadow"] = "Schatten",
        -- Schamane
        ["Elementar"] = "Elementar", ["Elemental"] = "Elementar",
        ["Verstärkung"] = "Verstärkung", ["Enhancement"] = "Verstärkung",
        ["Wiederherstellung"] = "Wiederherstellung", ["Restoration"] = "Wiederherstellung",
        -- Magier
        ["Arkan"] = "Arkan", ["Arcane"] = "Arkan",
        ["Feuer"] = "Feuer", ["Fire"] = "Feuer",
        ["Frost"] = "Frost",
        -- Hexenmeister
        ["Gebrechen"] = "Gebrechen", ["Affliction"] = "Gebrechen",
        ["Dämonologie"] = "Dämonologie", ["Demonology"] = "Dämonologie",
        ["Zerstörung"] = "Zerstörung", ["Destruction"] = "Zerstörung",
        -- Druide
        ["Gleichgewicht"] = "Gleichgewicht", ["Balance"] = "Gleichgewicht",
        ["Wildheit"] = "Wildheit", ["Feral Combat"] = "Wildheit",
    }
    
    local shortSpec = shortNames[specName] or specName
    
    -- Weniger als 10 Punkte = keine echte Spec
    if maxPoints < 10 then
        return "", 0
    end
    
    return shortSpec, specIndex
end

-- ══════════════════════════════════════════════════════════════
-- BERUFE AUSLESEN (Classic API)
-- ══════════════════════════════════════════════════════════════

function Professions:GetOwnProfessions()
    local professions = {}
    local inProfessionHeader = false
    
    -- In Classic: Skill-Liste durchgehen
    local numSkills = GetNumSkillLines()
    
    for i = 1, numSkills do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        
        if isHeader then
            -- Prüfe ob wir im Berufe-Header sind
            -- Deutsche: "Berufe", English: "Professions"
            if skillName == "Berufe" or skillName == "Professions" or 
               skillName == "Trade Skills" or skillName == "Handelsfertigkeiten" then
                inProfessionHeader = true
            else
                inProfessionHeader = false
            end
        elseif inProfessionHeader and skillName then
            -- Das ist ein Beruf!
            table.insert(professions, {
                name = skillName,
                skill = skillRank or 0,
                max = skillMaxRank or 300
            })
        end
    end
    
    -- Auch Sekundärberufe (Erste Hilfe, Kochen, Angeln) prüfen
    local secondaryHeader = false
    for i = 1, numSkills do
        local skillName, isHeader, isExpanded, skillRank, numTempPoints, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        
        if isHeader then
            if skillName == "Sekundäre Fertigkeiten" or skillName == "Secondary Skills" or
               skillName == "Sekundärberufe" or skillName == "Secondary" then
                secondaryHeader = true
            elseif secondaryHeader then
                secondaryHeader = false
            end
        elseif secondaryHeader and skillName then
            table.insert(professions, {
                name = skillName,
                skill = skillRank or 0,
                max = skillMaxRank or 300,
                secondary = true
            })
        end
    end
    
    return professions
end

-- ══════════════════════════════════════════════════════════════
-- BROADCAST / SYNC
-- ══════════════════════════════════════════════════════════════

function Professions:BroadcastProfessions()
    if not IsInGuild() then return end
    
    local profs = self:GetOwnProfessions()
    local _, _, classId = UnitClass("player")
    local level = UnitLevel("player")
    local spec, specIndex = self:GetSpecialization()
    
    -- Format: PROF|prof1Name|prof1Skill|prof1Max|prof2Name|prof2Skill|prof2Max|classId|level|spec
    local parts = {"PROF"}
    
    -- Maximal 2 Hauptberufe senden
    local mainCount = 0
    for _, prof in ipairs(profs) do
        if not prof.secondary and mainCount < 2 then
            table.insert(parts, prof.name or "")
            table.insert(parts, prof.skill or 0)
            table.insert(parts, prof.max or 300)
            mainCount = mainCount + 1
        end
    end
    
    -- Auffüllen falls weniger als 2 Berufe
    while mainCount < 2 do
        table.insert(parts, "")
        table.insert(parts, 0)
        table.insert(parts, 0)
        mainCount = mainCount + 1
    end
    
    table.insert(parts, classId or 0)
    table.insert(parts, level or 1)
    table.insert(parts, spec or "")
    
    local data = table.concat(parts, "|")
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, data, "GUILD")
end

function Professions:RequestAllProfessions()
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "REQ", "GUILD")
end

function Professions:HandleMessage(message, sender)
    local senderName = strsplit("-", sender)
    if senderName == GDL.playerName then return end
    
    -- Request - sende unsere Daten zurück
    if message == "REQ" then
        C_Timer.After(math.random() * 3, function()  -- Zufällige Verzögerung
            self:BroadcastProfessions()
        end)
        return
    end
    
    -- Parse PROF Nachricht
    local parts = {strsplit("|", message)}
    if parts[1] ~= "PROF" then return end
    
    -- Format: PROF|prof1Name|prof1Skill|prof1Max|prof2Name|prof2Skill|prof2Max|classId|level|spec
    local prof1Name = parts[2] or ""
    local prof1Skill = tonumber(parts[3]) or 0
    local prof1Max = tonumber(parts[4]) or 0
    local prof2Name = parts[5] or ""
    local prof2Skill = tonumber(parts[6]) or 0
    local prof2Max = tonumber(parts[7]) or 0
    local classId = tonumber(parts[8]) or 0
    local level = tonumber(parts[9]) or 1
    local spec = parts[10] or ""
    
    -- Speichern
    guildProfessions[senderName] = {
        prof1 = {name = prof1Name, skill = prof1Skill, max = prof1Max},
        prof2 = {name = prof2Name, skill = prof2Skill, max = prof2Max},
        classId = classId,
        level = level,
        spec = spec,
        timestamp = time()
    }
    
    -- In DB speichern
    GuildDeathLogDB.professions = guildProfessions
    
    -- UI aktualisieren falls offen
    if self.frame and self.frame:IsShown() then
        self:UpdateWindow()
    end
end

-- ══════════════════════════════════════════════════════════════
-- UI FENSTER
-- ══════════════════════════════════════════════════════════════

-- Eleganter Filter-Button (wie im Hauptfenster)
function Professions:CreateFilterButton(parent, text, width, x, y)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 22)
    btn:SetPoint("TOPLEFT", x, y)
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    btn:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
    btn:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
    
    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    label:SetPoint("CENTER", 0, 1)
    label:SetText(text)
    label:SetTextColor(0.9, 0.8, 0.6)
    btn.label = label
    btn.filterName = text
    
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.2, 0.12, 1)
        self:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
        self.label:SetTextColor(1, 0.9, 0.7)
    end)
    
    btn:SetScript("OnLeave", function(self)
        if parent.currentFilter == self.filterName then
            self:SetBackdropColor(0.25, 0.18, 0.08, 1)
            self:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
            self.label:SetTextColor(1, 0.85, 0.5)
        else
            self:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
            self:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
            self.label:SetTextColor(0.9, 0.8, 0.6)
        end
    end)
    
    btn:SetScript("OnClick", function(self)
        parent.currentFilter = self.filterName
        Professions:UpdateWindow()
    end)
    
    return btn
end

function Professions:ShowWindow()
    if not self.frame then
        self:CreateWindow()
    end
    self.frame:Show()
    self:UpdateWindow()
    
    -- Request frische Daten
    self:RequestAllProfessions()
end

function Professions:CreateWindow()
    local f = CreateFrame("Frame", "GDLProfessionsFrame", UIParent, "BackdropTemplate")
    f:SetSize(480, 520)  -- Passend für 5 Buttons à 88px
    f:SetPoint("CENTER", UIParent, "CENTER", -460, -200)  -- Links-unten (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(120)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    -- Pergament-Hintergrund wie andere Fenster
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    f:SetBackdropColor(1, 1, 1, 1)
    f:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
    
    -- Title - wie andere Fenster, DUNKEL für Lesbarkeit
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 20, "")
    title:SetPoint("TOP", 0, -18)
    title:SetText("|cff3a2510Gilden-Berufe|r")  -- Sehr dunkelbraun
    
    -- Subtitle
    local sub = f:CreateFontString(nil, "OVERLAY")
    sub:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    sub:SetPoint("TOP", title, "BOTTOM", 0, -2)
    sub:SetTextColor(0.4, 0.3, 0.2)  -- Dunkelbraun
    f.subtitle = sub
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    
    -- Refresh button - eleganter Stil
    local refreshBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    refreshBtn:SetSize(75, 22)
    refreshBtn:SetPoint("TOPRIGHT", -35, -18)
    refreshBtn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    refreshBtn:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
    refreshBtn:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
    
    local refreshLabel = refreshBtn:CreateFontString(nil, "OVERLAY")
    refreshLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    refreshLabel:SetPoint("CENTER")
    refreshLabel:SetText("Refresh")
    refreshLabel:SetTextColor(0.9, 0.8, 0.6)
    
    refreshBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.2, 0.12, 1)
        self:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
        refreshLabel:SetTextColor(1, 0.9, 0.7)
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
        self:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
        refreshLabel:SetTextColor(0.9, 0.8, 0.6)
    end)
    refreshBtn:SetScript("OnClick", function()
        self:RequestAllProfessions()
        self:BroadcastProfessions()
        -- Still, ohne Chat-Meldung
    end)
    
    -- Filter Buttons - ELEGANTE BUTTONS gleichmäßig verteilt
    -- 5 Buttons pro Reihe, alle gleich breit, ZENTRIERT
    local filterY = -52
    local btnWidth = 88
    local btnSpacing = 4
    local totalWidth = (5 * btnWidth) + (4 * btnSpacing)  -- 456px
    local startX = (480 - totalWidth) / 2  -- Zentriert im 480px Fenster
    
    local filters1 = {"Alle", "Schmied", "Leder", "Schneider", "Alchemie"}
    local filters2 = {"Ingenieur", "Verzauber", "Bergbau", "Kräuter", "Kürschner"}
    f.currentFilter = "Alle"
    f.filterButtons = {}
    
    -- Erste Reihe
    for i, filterName in ipairs(filters1) do
        local xPos = startX + (i - 1) * (btnWidth + btnSpacing)
        local btn = self:CreateFilterButton(f, filterName, btnWidth, xPos, filterY)
        table.insert(f.filterButtons, btn)
    end
    
    -- Zweite Reihe
    local filterY2 = filterY - 26
    for i, filterName in ipairs(filters2) do
        local xPos = startX + (i - 1) * (btnWidth + btnSpacing)
        local btn = self:CreateFilterButton(f, filterName, btnWidth, xPos, filterY2)
        table.insert(f.filterButtons, btn)
    end
    
    -- "Alle" Button als aktiv markieren
    for _, btn in ipairs(f.filterButtons) do
        if btn.filterName == "Alle" then
            btn:SetBackdropColor(0.25, 0.18, 0.08, 1)
            btn:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
            btn.label:SetTextColor(1, 0.85, 0.5)
        end
    end
    
    -- Scroll Container - dunkler Hintergrund wie Todesliste
    local scrollContainer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollContainer:SetPoint("TOPLEFT", 18, -108)
    scrollContainer:SetPoint("BOTTOMRIGHT", -18, 18)
    scrollContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollContainer:SetBackdropColor(0.05, 0.03, 0.02, 0.7)
    scrollContainer:SetBackdropBorderColor(0.4, 0.3, 0.2, 0.6)
    
    -- Scroll Frame - mehr Platz rechts für Scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", "GDLProfessionsScroll", scrollContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 8)  -- Mehr Platz für Scrollbar
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(410, 1)  -- Schmaler
    scrollFrame:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild
    
    self.frame = f
end

function Professions:UpdateWindow()
    if not self.frame then return end
    local f = self.frame
    
    -- Clear old entries
    for _, child in ipairs({f.scrollChild:GetChildren()}) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Eigene Daten hinzufügen
    local myProfs = self:GetOwnProfessions()
    local _, _, myClassId = UnitClass("player")
    local myLevel = UnitLevel("player")
    local mySpec = self:GetSpecialization()
    
    guildProfessions[GDL.playerName] = {
        prof1 = myProfs[1] and {name = myProfs[1].name, skill = myProfs[1].skill, max = myProfs[1].max} or {name = "", skill = 0, max = 0},
        prof2 = myProfs[2] and {name = myProfs[2].name, skill = myProfs[2].skill, max = myProfs[2].max} or {name = "", skill = 0, max = 0},
        classId = myClassId,
        level = myLevel,
        spec = mySpec,
        timestamp = time()
    }
    
    -- Sortieren nach Name
    local sorted = {}
    for name, data in pairs(guildProfessions) do
        table.insert(sorted, {name = name, data = data})
    end
    table.sort(sorted, function(a, b) return a.name < b.name end)
    
    -- Filter anwenden
    local filterMap = {
        ["Schmied"] = {"Schmiedekunst", "Blacksmithing"},
        ["Leder"] = {"Lederverarbeitung", "Leatherworking"},
        ["Schneider"] = {"Schneiderei", "Tailoring"},
        ["Alchemie"] = {"Alchemie", "Alchemy"},
        ["Ingenieur"] = {"Ingenieurskunst", "Engineering"},
        ["Verzauber"] = {"Verzauberkunst", "Enchanting"},
        ["Bergbau"] = {"Bergbau", "Mining"},
        ["Kräuter"] = {"Kräuterkunde", "Herbalism", "Krauterkunde"},
        ["Kürschner"] = {"Kürschnerei", "Skinning"},
    }
    
    local y = 0
    local count = 0
    
    for _, entry in ipairs(sorted) do
        local name = entry.name
        local data = entry.data
        
        -- Filter prüfen
        local showEntry = true
        if f.currentFilter ~= "Alle" then
            showEntry = false
            local filterTerms = filterMap[f.currentFilter]
            if filterTerms then
                for _, term in ipairs(filterTerms) do
                    if (data.prof1.name and data.prof1.name:find(term)) or
                       (data.prof2.name and data.prof2.name:find(term)) then
                        showEntry = true
                        break
                    end
                end
            end
        end
        
        if showEntry then
            local row = self:CreateProfessionRow(f.scrollChild, name, data, y)
            y = y - 46  -- Mehr Platz für zweizeilige Berufe
            count = count + 1
        end
    end
    
    f.scrollChild:SetHeight(math.max(1, -y))
    f.subtitle:SetText(count .. " Gildenmitglieder")
    
    -- Filter-Buttons aktualisieren
    if f.filterButtons then
        for _, btn in ipairs(f.filterButtons) do
            if f.currentFilter == btn.filterName then
                -- Aktiver Button - hervorgehoben
                btn:SetBackdropColor(0.25, 0.18, 0.08, 1)
                btn:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
                btn.label:SetTextColor(1, 0.85, 0.5)
            else
                -- Inaktiver Button - normal
                btn:SetBackdropColor(0.15, 0.12, 0.08, 0.9)
                btn:SetBackdropBorderColor(0.5, 0.4, 0.3, 0.8)
                btn.label:SetTextColor(0.9, 0.8, 0.6)
            end
        end
    end
end

function Professions:CreateProfessionRow(parent, playerName, data, yOffset)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(400, 42)  -- Schmaler passend zum ScrollChild
    row:SetPoint("TOPLEFT", 0, yOffset)
    
    -- Klassenfarbe
    local col = self:GetClassColor(data.classId)
    
    -- Klassen-Icon
    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(28, 28)
    classIcon:SetPoint("LEFT", 4, 0)
    local iconPath = self:GetClassIcon(data.classId)
    classIcon:SetTexture(iconPath)
    
    -- Online-Status Punkt (kleine grüne/graue Ecke)
    local isOnline = (time() - (data.timestamp or 0)) < STALE_TIMEOUT
    local statusDot = row:CreateTexture(nil, "OVERLAY")
    statusDot:SetSize(8, 8)
    statusDot:SetPoint("BOTTOMRIGHT", classIcon, "BOTTOMRIGHT", 2, -2)
    statusDot:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    if isOnline then
        statusDot:SetVertexColor(0, 1, 0, 1)  -- Grün
    else
        statusDot:SetVertexColor(0.4, 0.4, 0.4, 1)  -- Grau
    end
    
    -- Spielername in Klassenfarbe
    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    nameText:SetPoint("LEFT", classIcon, "RIGHT", 6, 4)
    nameText:SetTextColor(col[1], col[2], col[3])
    nameText:SetText(playerName)
    
    -- Level + Spec
    local infoText = row:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    infoText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1)
    
    local specStr = ""
    if data.spec and data.spec ~= "" then
        specStr = " |cffBBBBBB" .. data.spec .. "|r"
    end
    infoText:SetText("|cff999999Level " .. (data.level or "?") .. "|r" .. specStr)
    
    -- Berufe rechts - OHNE Scrollbar-Bereich
    local prof1Text = row:CreateFontString(nil, "OVERLAY")
    prof1Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    prof1Text:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -6)
    prof1Text:SetJustifyH("RIGHT")
    prof1Text:SetWidth(160)
    
    local prof2Text = row:CreateFontString(nil, "OVERLAY")
    prof2Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    prof2Text:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -20)
    prof2Text:SetJustifyH("RIGHT")
    prof2Text:SetWidth(160)
    
    if data.prof1 and data.prof1.name and data.prof1.name ~= "" then
        local skillCol = self:GetSkillColor(data.prof1.skill, data.prof1.max)
        prof1Text:SetText(string.format("|cff%s%d|r |cffCCCCCC%s|r", skillCol, data.prof1.skill, data.prof1.name))
    else
        prof1Text:SetText("")
    end
    
    if data.prof2 and data.prof2.name and data.prof2.name ~= "" then
        local skillCol = self:GetSkillColor(data.prof2.skill, data.prof2.max)
        prof2Text:SetText(string.format("|cff%s%d|r |cffCCCCCC%s|r", skillCol, data.prof2.skill, data.prof2.name))
    else
        prof2Text:SetText("")
    end
    
    -- Keine Berufe?
    if (not data.prof1 or not data.prof1.name or data.prof1.name == "") and
       (not data.prof2 or not data.prof2.name or data.prof2.name == "") then
        prof1Text:SetText("|cff666666- Keine Berufe -|r")
    end
    
    return row
end

-- Berufsnamen NICHT mehr kürzen - ausschreiben
function Professions:ShortenProfName(name)
    -- Behalte die vollen Namen
    return name
end

-- Klassen-Icon Pfad 
function Professions:GetClassIcon(classId)
    -- Standard WoW Icons - existieren in allen Versionen
    local icons = {
        [1] = "Interface\\Icons\\ClassIcon_Warrior",
        [2] = "Interface\\Icons\\ClassIcon_Paladin",
        [3] = "Interface\\Icons\\ClassIcon_Hunter",
        [4] = "Interface\\Icons\\ClassIcon_Rogue",
        [5] = "Interface\\Icons\\ClassIcon_Priest",
        [6] = "Interface\\Icons\\ClassIcon_DeathKnight",
        [7] = "Interface\\Icons\\ClassIcon_Shaman",
        [8] = "Interface\\Icons\\ClassIcon_Mage",
        [9] = "Interface\\Icons\\ClassIcon_Warlock",
        [10] = "Interface\\Icons\\ClassIcon_Monk",
        [11] = "Interface\\Icons\\ClassIcon_Druid",
    }
    return icons[classId] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ══════════════════════════════════════════════════════════════
-- HILFSFUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function Professions:GetClassColor(classId)
    local colors = {
        [1] = {0.78, 0.61, 0.43},  -- Krieger
        [2] = {0.96, 0.55, 0.73},  -- Paladin
        [3] = {0.67, 0.83, 0.45},  -- Jäger
        [4] = {1.00, 0.96, 0.41},  -- Schurke
        [5] = {1.00, 1.00, 1.00},  -- Priester
        [6] = {0.77, 0.12, 0.23},  -- DK
        [7] = {0.00, 0.44, 0.87},  -- Schamane
        [8] = {0.25, 0.78, 0.92},  -- Magier
        [9] = {0.53, 0.53, 0.93},  -- Hexer
        [10] = {0.00, 1.00, 0.59}, -- Mönch
        [11] = {1.00, 0.49, 0.04}, -- Druide
    }
    return colors[classId] or {0.7, 0.7, 0.7}
end

function Professions:GetSkillColor(skill, max)
    if not skill or skill == 0 then return "666666" end
    local pct = skill / (max or 300)
    if pct >= 1.0 then return "FFD100" end      -- Gold = Max
    if pct >= 0.9 then return "00FF00" end      -- Grün = Fast Max
    if pct >= 0.5 then return "FFFF00" end      -- Gelb = Mittel
    if pct >= 0.25 then return "FF8800" end     -- Orange = Niedrig
    return "FF4444"                              -- Rot = Sehr niedrig
end

-- Suche nach Spielern mit bestimmtem Beruf
function Professions:FindByProfession(profName)
    local results = {}
    local searchLower = profName:lower()
    
    for name, data in pairs(guildProfessions) do
        local found = false
        if data.prof1 and data.prof1.name and data.prof1.name:lower():find(searchLower) then
            found = true
        end
        if data.prof2 and data.prof2.name and data.prof2.name:lower():find(searchLower) then
            found = true
        end
        if found then
            table.insert(results, {name = name, data = data})
        end
    end
    
    return results
end

-- API für andere Module
function Professions:GetAllProfessions()
    return guildProfessions
end

function Professions:GetPlayerProfession(playerName)
    return guildProfessions[playerName]
end

-- ======================================================================
-- MODULE INITIALIZATION
-- ======================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function()
            Professions:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Professions", Professions)
