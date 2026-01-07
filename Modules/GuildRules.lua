-- ══════════════════════════════════════════════════════════════
-- MODUL: GUILD RULES - GILDENREGELN / GUILD RULES
-- Editierbare Regelseite im Buch-Style
-- Supports German & English clients
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local GuildRules = {}

-- ══════════════════════════════════════════════════════════════
-- INITIALIZATION
-- ══════════════════════════════════════════════════════════════

function GuildRules:Initialize()
    -- SavedVariables initialisieren
    GuildDeathLogDB.guildRules = GuildDeathLogDB.guildRules or {}
    GuildDeathLogDB.guildRulesVersion = GuildDeathLogDB.guildRulesVersion or 0
    
    -- Sync-Channel registrieren
    C_ChatInfo.RegisterAddonMessagePrefix("GDLRules")
    
    -- Event-Frame für Sync
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == "GDLRules" then
            self:OnAddonMessage(message, sender)
        end
    end)
    
    -- UI erstellen
    C_Timer.After(0.6, function() self:CreateRulesFrame() end)
    
    -- WICHTIG: Bei Login automatisch Regeln anfragen!
    C_Timer.After(5, function()
        if IsInGuild() then
            self:RequestRules()
            GDL:Debug("[GuildRules] Automatischer Request gesendet")
        end
    end)
    
    GDL:Debug("[GuildRules] Module initialized")
end

-- ══════════════════════════════════════════════════════════════
-- SYNC FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function GuildRules:OnAddonMessage(message, sender)
    -- Eigene Nachrichten ignorieren
    local myName = UnitName("player")
    if sender:match("^" .. myName) then return end
    
    local cmd, data = message:match("^(%S+)%s*(.*)$")
    
    if cmd == "RULES_UPDATE" then
        -- Neue Regeln empfangen (komplette Nachricht)
        local version, rulesText = data:match("^(%d+)|(.*)$")
        version = tonumber(version) or 0
        
        if version > (GuildDeathLogDB.guildRulesVersion or 0) then
            local guildName = GDL.currentGuildName
            if guildName then
                GuildDeathLogDB.guildRules[guildName] = rulesText
                GuildDeathLogDB.guildRulesVersion = version
                
                -- Benachrichtigung im Chat
                GDL:Print("|cffFFD100" .. GDL:L("RULES_UPDATED") .. "|r")
                
                -- UI aktualisieren wenn offen
                if self.rulesFrame and self.rulesFrame:IsShown() then
                    self:UpdateRulesDisplay()
                end
            end
        end
    elseif cmd == "RULES_CHUNK" then
        -- Chunk einer langen Nachricht empfangen
        local chunkInfo, chunkData = data:match("^([^|]+)|(.*)$")
        local version, chunkNum, totalChunks = chunkInfo:match("^(%d+):(%d+)/(%d+)$")
        version = tonumber(version) or 0
        chunkNum = tonumber(chunkNum) or 1
        totalChunks = tonumber(totalChunks) or 1
        
        if version > (GuildDeathLogDB.guildRulesVersion or 0) then
            -- Initialisiere Chunk-Buffer wenn nötig
            self.chunkBuffer = self.chunkBuffer or {}
            self.chunkBuffer[version] = self.chunkBuffer[version] or {chunks = {}, total = totalChunks}
            self.chunkBuffer[version].chunks[chunkNum] = chunkData
            
            -- Prüfe ob alle Chunks da sind
            local complete = true
            for i = 1, totalChunks do
                if not self.chunkBuffer[version].chunks[i] then
                    complete = false
                    break
                end
            end
            
            if complete then
                -- Zusammenbauen
                local fullText = ""
                for i = 1, totalChunks do
                    fullText = fullText .. self.chunkBuffer[version].chunks[i]
                end
                
                local guildName = GDL.currentGuildName
                if guildName then
                    GuildDeathLogDB.guildRules[guildName] = fullText
                    GuildDeathLogDB.guildRulesVersion = version
                    
                    GDL:Print("|cffFFD100" .. GDL:L("RULES_UPDATED") .. "|r")
                    
                    if self.rulesFrame and self.rulesFrame:IsShown() then
                        self:UpdateRulesDisplay()
                    end
                end
                
                -- Buffer leeren
                self.chunkBuffer[version] = nil
            end
        end
    elseif cmd == "RULES_REQUEST" then
        -- Jemand fragt nach den aktuellen Regeln
        C_Timer.After(math.random() * 2, function()
            self:BroadcastRules(false)  -- Ohne Chat-Nachricht
        end)
    end
end

function GuildRules:BroadcastRules(showChatMessage)
    if not IsInGuild() then return end
    
    local guildName = GDL.currentGuildName
    if not guildName then return end
    
    local rulesText = GuildDeathLogDB.guildRules[guildName] or ""
    local version = GuildDeathLogDB.guildRulesVersion or 0
    
    -- Max 230 Zeichen pro Chunk (Reserve für Header)
    local CHUNK_SIZE = 200
    
    if #rulesText <= CHUNK_SIZE then
        -- Kurze Regeln: Direkt senden
        local message = "RULES_UPDATE " .. version .. "|" .. rulesText
        C_ChatInfo.SendAddonMessage("GDLRules", message, "GUILD")
    else
        -- Lange Regeln: In Chunks aufteilen
        local totalChunks = math.ceil(#rulesText / CHUNK_SIZE)
        
        for i = 1, totalChunks do
            local startPos = (i - 1) * CHUNK_SIZE + 1
            local endPos = math.min(i * CHUNK_SIZE, #rulesText)
            local chunk = rulesText:sub(startPos, endPos)
            
            -- Format: RULES_CHUNK version:chunkNum/totalChunks|chunkData
            local message = "RULES_CHUNK " .. version .. ":" .. i .. "/" .. totalChunks .. "|" .. chunk
            
            -- Verzögert senden um Spam zu vermeiden
            C_Timer.After((i - 1) * 0.3, function()
                C_ChatInfo.SendAddonMessage("GDLRules", message, "GUILD")
            end)
        end
    end
    
    if showChatMessage then
        -- Gildennachricht senden
        SendChatMessage(GDL:L("RULES_CHAT_UPDATED"), "GUILD")
    end
end

function GuildRules:RequestRules()
    if IsInGuild() then
        C_ChatInfo.SendAddonMessage("GDLRules", "RULES_REQUEST", "GUILD")
    end
end

-- ══════════════════════════════════════════════════════════════
-- DATEN-FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function GuildRules:GetRules()
    local guildName = GDL.currentGuildName
    if not guildName then return "" end
    return GuildDeathLogDB.guildRules[guildName] or ""
end

function GuildRules:SetRules(text)
    local guildName = GDL.currentGuildName
    if not guildName then return false end
    
    GuildDeathLogDB.guildRules[guildName] = text
    GuildDeathLogDB.guildRulesVersion = (GuildDeathLogDB.guildRulesVersion or 0) + 1
    
    return true
end

function GuildRules:CanEdit()
    -- Nur Gildenleiter und Offiziere dürfen editieren
    return GDL:IsGuildOfficer() or IsGuildLeader()
end

-- ══════════════════════════════════════════════════════════════
-- UI - REGELN FENSTER
-- ══════════════════════════════════════════════════════════════

function GuildRules:CreateRulesFrame()
    if self.rulesFrame then return end
    
    -- Hauptframe - Gleicher Style wie andere Seiten
    local f = CreateFrame("Frame", "GDLRulesFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 600)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(120)
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
    
    -- Haupthintergrund - Elegantes Pergament (gleich wie UI.lua)
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
    
    -- Regel-Icon links
    local ruleIcon = f:CreateTexture(nil, "OVERLAY")
    ruleIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_06")
    ruleIcon:SetSize(50, 50)
    ruleIcon:SetPoint("TOPLEFT", 30, -28)
    
    -- Icon Rahmen
    local iconBorder = f:CreateTexture(nil, "OVERLAY", nil, 1)
    iconBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    iconBorder:SetSize(68, 68)
    iconBorder:SetPoint("CENTER", ruleIcon, "CENTER", 10, -10)
    
    -- Titel (lokalisiert)
    f.titleText = f:CreateFontString(nil, "OVERLAY")
    f.titleText:SetFont("Fonts\\MORPHEUS.TTF", 22, "")
    f.titleText:SetPoint("TOP", 15, -30)
    f.titleText:SetText("|cff8B4513" .. GDL:L("RULES_TITLE") .. "|r")
    f.titleText:SetShadowOffset(2, -2)
    f.titleText:SetShadowColor(0, 0, 0, 0.8)
    
    -- Untertitel / Gildenname
    f.guildName = f:CreateFontString(nil, "OVERLAY")
    f.guildName:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    f.guildName:SetPoint("TOP", f.titleText, "BOTTOM", 0, -4)
    f.guildName:SetTextColor(0.5, 0.4, 0.3)
    
    -- Schließen-Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)
    
    -- ═══ TRENNLINIE MIT ORNAMENT ═══
    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\ACHIEVEMENTFRAME\\UI-Achievement-HorizontalShadow")
    divider:SetPoint("TOPLEFT", 25, -95)
    divider:SetPoint("TOPRIGHT", -25, -95)
    divider:SetHeight(15)
    divider:SetVertexColor(0.35, 0.28, 0.2, 0.6)
    
    -- Schriftrolle-Symbol in der Mitte (WoW-Icon statt Unicode)
    local scrollDivider = f:CreateTexture(nil, "OVERLAY")
    scrollDivider:SetTexture("Interface\\Icons\\INV_Scroll_02")
    scrollDivider:SetSize(20, 20)
    scrollDivider:SetPoint("CENTER", divider, "CENTER", 0, 0)
    scrollDivider:SetAlpha(0.7)
    
    -- ═══ EDIT-BEREICH MIT SCROLLFRAME ═══
    local editContainer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    editContainer:SetPoint("TOPLEFT", 22, -115)
    editContainer:SetPoint("BOTTOMRIGHT", -22, 70)
    editContainer:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    editContainer:SetBackdropColor(0.05, 0.03, 0.02, 0.85)
    editContainer:SetBackdropBorderColor(0.4, 0.3, 0.2, 0.6)
    
    -- ScrollFrame für EditBox
    local scrollFrame = CreateFrame("ScrollFrame", "GDLRulesScrollFrame", editContainer, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 8, -8)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    
    -- ScrollBar Styling
    local scrollBar = scrollFrame.ScrollBar or _G["GDLRulesScrollFrameScrollBar"]
    if scrollBar then
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
    end
    
    -- EditBox für Regeln
    local editBox = CreateFrame("EditBox", "GDLRulesEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    editBox:SetTextColor(0.85, 0.75, 0.6)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    -- Text-Änderung tracken
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            f.hasChanges = true
            if f.saveBtn then
                f.saveBtn.label:SetTextColor(0, 1, 0)  -- Grün = ungespeicherte Änderungen
            end
        end
        -- ScrollChild-Höhe anpassen
        local _, height = self:GetFont()
        local numLines = self:GetNumLetters() > 0 and select(2, self:GetText():gsub("\n", "\n")) + 2 or 1
        self:SetHeight(math.max(scrollFrame:GetHeight(), numLines * (height + 4)))
    end)
    
    scrollFrame:SetScrollChild(editBox)
    f.editBox = editBox
    f.scrollFrame = scrollFrame
    f.hasChanges = false
    
    -- ═══ FOOTER MIT BUTTONS ═══
    local footerLine = f:CreateTexture(nil, "ARTWORK")
    footerLine:SetPoint("BOTTOMLEFT", 30, 65)
    footerLine:SetPoint("BOTTOMRIGHT", -30, 65)
    footerLine:SetHeight(1)
    footerLine:SetColorTexture(0.4, 0.3, 0.2, 0.5)
    
    -- Status-Text
    f.statusText = f:CreateFontString(nil, "OVERLAY")
    f.statusText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.statusText:SetPoint("BOTTOM", 0, 50)
    f.statusText:SetTextColor(0.5, 0.45, 0.4)
    
    -- Buttons
    local btnWidth = 100
    local btnSpacing = 10
    
    -- Speichern-Button (lokalisiert)
    f.saveBtn = self:CreateRulesButton(f, GDL:L("SAVE"), -btnWidth - btnSpacing/2, 20, function()
        if not GuildRules:CanEdit() then
            GDL:Print("|cffFF6666" .. GDL:L("RULES_ONLY_OFFICERS") .. "|r")
            return
        end
        
        local text = f.editBox:GetText()
        if GuildRules:SetRules(text) then
            f.hasChanges = false
            f.saveBtn.label:SetTextColor(0.9, 0.8, 0.6)
            GuildRules:BroadcastRules(true)  -- Mit Gildennachricht
            GDL:Print("|cff00FF00" .. GDL:L("RULES_SAVED") .. "|r")
        end
    end)
    
    -- Sync-Button (lokalisiert)
    f.syncBtn = self:CreateRulesButton(f, GDL:L("BTN_SYNC"), btnWidth/2 + btnSpacing/2, 20, function()
        GuildRules:RequestRules()
        GDL:Print("|cff00AAFF" .. GDL:L("RULES_REQUESTING") .. "|r")
    end)
    
    -- Zurück zum Buch Button (lokalisiert)
    f.backBtn = self:CreateRulesButton(f, "<- " .. GDL:L("BTN_BOOK"), btnWidth + btnSpacing + btnWidth/2, 20, function()
        f:Hide()
        local UI = GDL:GetModule("UI")
        if UI then UI:ShowBook() end
    end)
    
    -- OnShow: Regeln laden und Status aktualisieren
    f:SetScript("OnShow", function(self)
        GuildRules:UpdateRulesDisplay()
    end)
    
    self.rulesFrame = f
end

function GuildRules:CreateRulesButton(parent, text, x, y, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(100, 24)
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
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
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

function GuildRules:UpdateRulesDisplay()
    if not self.rulesFrame then return end
    local f = self.rulesFrame
    
    -- Titel aktualisieren (für Sprachwechsel)
    f.titleText:SetText("|cff8B4513" .. GDL:L("RULES_TITLE") .. "|r")
    
    -- Gildenname
    if GDL.currentGuildName then
        f.guildName:SetText("< " .. GDL.currentGuildName .. " >")
    else
        f.guildName:SetText("|cff666666" .. GDL:L("NO_GUILD") .. "|r")
    end
    
    -- Regeln laden
    local rules = self:GetRules()
    f.editBox:SetText(rules)
    f.hasChanges = false
    
    -- Edit-Status (lokalisiert)
    if self:CanEdit() then
        f.editBox:EnableMouse(true)
        f.editBox:EnableKeyboard(true)
        f.statusText:SetText("|cff00AA00" .. GDL:L("RULES_CAN_EDIT") .. "|r")
        f.saveBtn:Enable()
        f.saveBtn:SetAlpha(1)
    else
        f.editBox:EnableMouse(false)
        f.editBox:EnableKeyboard(false)
        f.statusText:SetText("|cffAAAA00" .. GDL:L("RULES_CANNOT_EDIT") .. "|r")
        f.saveBtn:Disable()
        f.saveBtn:SetAlpha(0.5)
    end
    
    -- Version anzeigen
    local version = GuildDeathLogDB.guildRulesVersion or 0
    if version > 0 then
        f.statusText:SetText(f.statusText:GetText() .. "  |cff666666(v" .. version .. ")|r")
    end
end

-- ══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════

function GuildRules:ShowWindow()
    if not self.rulesFrame then
        self:CreateRulesFrame()
    end
    
    if self.rulesFrame then
        self.rulesFrame:Show()
        self.rulesFrame:Raise()
    end
end

function GuildRules:HideWindow()
    if self.rulesFrame then
        self.rulesFrame:Hide()
    end
end

function GuildRules:ToggleWindow()
    if self.rulesFrame and self.rulesFrame:IsShown() then
        self:HideWindow()
    else
        self:ShowWindow()
    end
end

-- ══════════════════════════════════════════════════════════════
-- MODUL REGISTRIEREN
-- ══════════════════════════════════════════════════════════════

GDL:RegisterModule("GuildRules", GuildRules)
