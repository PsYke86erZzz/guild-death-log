-- ══════════════════════════════════════════════════════════════
-- MODUL: HallOfFame - Ruhmeshalle für Level 60 Überlebende
-- Ehrt die Unsterblichen der Gilde
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local HallOfFame = {}

function HallOfFame:Initialize()
    -- SavedVariables für Hall of Fame
    GuildDeathLogDB.hallOfFame = GuildDeathLogDB.hallOfFame or {}
end

function HallOfFame:AddSurvivor(name, classId, playedTime, achievedDate)
    local survivors = GuildDeathLogDB.hallOfFame
    
    -- Prüfen ob schon eingetragen
    for _, survivor in ipairs(survivors) do
        if survivor.name == name then
            return false -- Bereits eingetragen
        end
    end
    
    table.insert(survivors, {
        name = name,
        classId = classId or 0,
        playedTime = playedTime or 0,
        achievedDate = achievedDate or time(),
        addedBy = UnitName("player"),
    })
    
    -- Sortieren nach Datum
    table.sort(survivors, function(a, b)
        return (a.achievedDate or 0) < (b.achievedDate or 0)
    end)
    
    return true
end

function HallOfFame:RemoveSurvivor(name)
    local survivors = GuildDeathLogDB.hallOfFame
    for i, survivor in ipairs(survivors) do
        if survivor.name == name then
            table.remove(survivors, i)
            return true
        end
    end
    return false
end

function HallOfFame:GetSurvivors()
    return GuildDeathLogDB.hallOfFame or {}
end

function HallOfFame:GetSurvivorCount()
    return #(GuildDeathLogDB.hallOfFame or {})
end

function HallOfFame:IsSurvivor(name)
    for _, survivor in ipairs(GuildDeathLogDB.hallOfFame or {}) do
        if survivor.name == name then
            return true
        end
    end
    return false
end

-- UI für Hall of Fame Tab
function HallOfFame:CreateTab(parent)
    local tab = CreateFrame("Frame", nil, parent)
    tab:SetAllPoints()
    tab:Hide()
    
    -- Header
    local header = tab:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\MORPHEUS.TTF", 20, "")
    header:SetPoint("TOP", 0, -10)
    header:SetText("|cff1a0a00-- Ruhmeshalle der Unsterblichen --|r")
    
    local subHeader = tab:CreateFontString(nil, "OVERLAY")
    subHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    subHeader:SetPoint("TOP", header, "BOTTOM", 0, -5)
    subHeader:SetText("|cff2a1a10-- Hall of Fame - The Immortals --|r")
    
    -- Krone Icon
    local crown = tab:CreateTexture(nil, "ARTWORK")
    crown:SetSize(48, 48)
    crown:SetPoint("TOP", subHeader, "BOTTOM", 0, -10)
    crown:SetTexture("Interface\\Icons\\INV_Crown_01")
    
    -- Anzahl
    tab.countText = tab:CreateFontString(nil, "OVERLAY")
    tab.countText:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    tab.countText:SetPoint("TOP", crown, "BOTTOM", 0, -5)
    tab.countText:SetTextColor(0.1, 0.05, 0.0)
    
    -- Scroll Frame für Liste
    local scroll = CreateFrame("ScrollFrame", nil, tab, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -130)
    scroll:SetPoint("BOTTOMRIGHT", -35, 80)
    
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(scroll:GetWidth(), 1)
    scroll:SetScrollChild(child)
    tab.scrollChild = child
    
    -- Add Button
    local addBtn = CreateFrame("Button", nil, tab, "UIPanelButtonTemplate")
    addBtn:SetSize(140, 24)
    addBtn:SetPoint("BOTTOMLEFT", 20, 15)
    addBtn:SetText("+ Hinzufügen / Add")
    addBtn:SetScript("OnClick", function()
        self:ShowAddDialog()
    end)
    
    -- Info Text
    local infoText = tab:CreateFontString(nil, "OVERLAY")
    infoText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    infoText:SetPoint("BOTTOM", 0, 50)
    infoText:SetText("|cff2a1a10Level 60 erreicht ohne zu sterben / Reached level 60 without dying|r")
    
    tab.Update = function()
        self:UpdateTab(tab)
    end
    
    return tab
end

function HallOfFame:UpdateTab(tab)
    -- Child clearen
    for _, c in ipairs({tab.scrollChild:GetChildren()}) do
        c:Hide()
        c:SetParent(nil)
    end
    
    local survivors = self:GetSurvivors()
    tab.countText:SetText(string.format("%d Unsterbliche / Immortals", #survivors))
    
    if #survivors == 0 then
        local empty = tab.scrollChild:CreateFontString(nil, "OVERLAY")
        empty:SetFont("Fonts\\MORPHEUS.TTF", 14, "")
        empty:SetPoint("TOP", 0, -50)
        empty:SetText("|cff2a2a1aNoch keine Level 60 Ueberlebenden!\nNo level 60 survivors yet!|r")
        return
    end
    
    local y = 0
    for i, survivor in ipairs(survivors) do
        local row = CreateFrame("Frame", nil, tab.scrollChild, "BackdropTemplate")
        row:SetSize(380, 50)
        row:SetPoint("TOPLEFT", 0, y)
        
        -- Hintergrund
        row:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        
        -- Abwechselnde Farben
        local bgAlpha = i % 2 == 0 and 0.3 or 0.15
        row:SetBackdropColor(0.2, 0.15, 0.05, bgAlpha)
        row:SetBackdropBorderColor(0.6, 0.5, 0.2, 0.5)
        
        -- Rang Nummer
        local rank = row:CreateFontString(nil, "OVERLAY")
        rank:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
        rank:SetPoint("LEFT", 10, 0)
        rank:SetText("|cff1a0a00#" .. i .. "|r")
        
        -- Klassen Icon
        local classIcon = row:CreateTexture(nil, "ARTWORK")
        classIcon:SetSize(32, 32)
        classIcon:SetPoint("LEFT", 50, 0)
        local UI = GDL:GetModule("UI")
        if UI then
            classIcon:SetTexture(UI:GetClassIcon(survivor.classId))
        else
            classIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
        
        -- Name
        local nameText = row:CreateFontString(nil, "OVERLAY")
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "")
        nameText:SetPoint("LEFT", classIcon, "RIGHT", 10, 5)
        local col = UI and UI:GetClassColor(survivor.classId) or {1, 1, 1}
        nameText:SetText(survivor.name)
        nameText:SetTextColor(col[1], col[2], col[3])
        
        -- Datum
        local dateText = row:CreateFontString(nil, "OVERLAY")
        dateText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        dateText:SetPoint("LEFT", classIcon, "RIGHT", 10, -10)
        dateText:SetText("|cff2a1a10" .. date("%d.%m.%Y", survivor.achievedDate or 0) .. "|r")
        
        -- Krone
        local crownIcon = row:CreateTexture(nil, "ARTWORK")
        crownIcon:SetSize(24, 24)
        crownIcon:SetPoint("RIGHT", -10, 0)
        crownIcon:SetTexture("Interface\\Icons\\INV_Crown_01")
        crownIcon:SetAlpha(0.8)
        
        -- Remove Button (klein)
        local removeBtn = CreateFrame("Button", nil, row)
        removeBtn:SetSize(16, 16)
        removeBtn:SetPoint("TOPRIGHT", -5, -5)
        removeBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        removeBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
        removeBtn:GetHighlightTexture():SetVertexColor(1, 0, 0)
        removeBtn:SetAlpha(0.5)
        removeBtn.survivorName = survivor.name
        removeBtn:SetScript("OnClick", function(self)
            HallOfFame:RemoveSurvivor(self.survivorName)
            tab.Update()
        end)
        removeBtn:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
        removeBtn:SetScript("OnLeave", function(self) self:SetAlpha(0.5) end)
        
        y = y - 55
    end
    
    tab.scrollChild:SetHeight(math.max(math.abs(y) + 20, 200))
end

function HallOfFame:ShowAddDialog()
    if not self.addDialog then
        local d = CreateFrame("Frame", "GDLHallOfFameAdd", UIParent, "BackdropTemplate")
        d:SetSize(320, 200)
        d:SetPoint("CENTER")
        d:SetFrameStrata("FULLSCREEN_DIALOG")
        d:SetMovable(true)
        d:EnableMouse(true)
        d:RegisterForDrag("LeftButton")
        d:SetScript("OnDragStart", d.StartMoving)
        d:SetScript("OnDragStop", d.StopMovingOrSizing)
        
        d:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
            edgeSize = 20,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        d:SetBackdropColor(0.1, 0.08, 0.05, 0.95)
        d:SetBackdropBorderColor(0.7, 0.6, 0.3, 1)
        
        local title = d:CreateFontString(nil, "OVERLAY")
        title:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        title:SetPoint("TOP", 0, -15)
        title:SetText("|cffFFD100Unsterblichen hinzufuegen / Add Immortal|r")
        
        local nameLabel = d:CreateFontString(nil, "OVERLAY")
        nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        nameLabel:SetPoint("TOPLEFT", 20, -45)
        nameLabel:SetText("Charakter Name:")
        
        local nameBox = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
        nameBox:SetSize(200, 22)
        nameBox:SetPoint("TOPLEFT", 20, -60)
        nameBox:SetAutoFocus(false)
        d.nameBox = nameBox
        
        local classLabel = d:CreateFontString(nil, "OVERLAY")
        classLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        classLabel:SetPoint("TOPLEFT", 20, -90)
        classLabel:SetText("Klasse / Class (1-11):")
        classLabel:SetTextColor(0.9, 0.9, 0.9)
        
        local classHint = d:CreateFontString(nil, "OVERLAY")
        classHint:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        classHint:SetPoint("TOPLEFT", 20, -105)
        classHint:SetWidth(280)
        classHint:SetText("|cff8888881=War 2=Pal 3=Hun 4=Rog 5=Pri\n7=Sha 8=Mag 9=Lock 11=Dru|r")
        
        local classBox = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
        classBox:SetSize(50, 22)
        classBox:SetPoint("TOPLEFT", 20, -135)
        classBox:SetAutoFocus(false)
        classBox:SetText("1")
        d.classBox = classBox
        
        local addBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        addBtn:SetSize(100, 24)
        addBtn:SetPoint("BOTTOMLEFT", 30, 15)
        addBtn:SetText("Hinzufügen")
        addBtn:SetScript("OnClick", function()
            local name = d.nameBox:GetText():trim()
            local classId = tonumber(d.classBox:GetText()) or 1
            if name ~= "" then
                if self:AddSurvivor(name, classId, 0, time()) then
                    GDL:Print("|cffFFD100" .. name .. "|r zur Ruhmeshalle hinzugefügt!")
                    local UI = GDL:GetModule("UI")
                    if UI and UI.hallOfFameTab then
                        UI.hallOfFameTab.Update()
                    end
                else
                    GDL:Print(name .. " ist bereits in der Ruhmeshalle!")
                end
            end
            d:Hide()
        end)
        
        local cancelBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
        cancelBtn:SetSize(100, 24)
        cancelBtn:SetPoint("BOTTOMRIGHT", -30, 15)
        cancelBtn:SetText("Abbrechen")
        cancelBtn:SetScript("OnClick", function() d:Hide() end)
        
        self.addDialog = d
    end
    
    self.addDialog.nameBox:SetText("")
    self.addDialog.classBox:SetText("1")
    self.addDialog:Show()
end

GDL:RegisterModule("HallOfFame", HallOfFame)
