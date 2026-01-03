-- ══════════════════════════════════════════════════════════════
-- MODUL: GuildTracker - ECHTZEIT Gilden-Tracking auf der Weltkarte
-- Live-Tracking: Positionen werden alle 0.75 Sekunden gesynct
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local GuildTracker = {}

local ADDON_PREFIX = "GDLTrack"
local BROADCAST_INTERVAL = 0.75  -- Alle 0.75 Sekunden Position senden (ULTRA ECHTZEIT!)
local STALE_TIMEOUT = 5          -- Nach 5 Sekunden ohne Update = offline
local UPDATE_INTERVAL = 0.03     -- Pin-Update alle 30ms für ultra-flüssige Bewegung (33 FPS)

-- Speichert Positionen anderer Spieler
-- Format: {name = {mapId, x, y, targetX, targetY, timestamp, classId}}
local guildPositions = {}
local mapPins = {}
local updateFrame = nil

-- Prüft ob GuildTracker aktiviert ist
local function IsEnabled()
    if GuildDeathLogDB and GuildDeathLogDB.settings then
        if GuildDeathLogDB.settings.guildTracker == false then
            return false
        end
    end
    return true
end

-- Prefix registrieren
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

function GuildTracker:Initialize()
    if self.initialized then return end
    self.initialized = true
    
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) self:OnEvent(event, ...) end)
    
    -- ECHTZEIT: Position alle 1.5 Sekunden broadcasten
    C_Timer.NewTicker(BROADCAST_INTERVAL, function()
        if IsEnabled() and IsInGuild() then
            self:BroadcastPosition()
        end
    end)
    
    -- OnUpdate Frame für flüssige Pin-Bewegung
    updateFrame = CreateFrame("Frame")
    local elapsed = 0
    updateFrame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= UPDATE_INTERVAL then
            elapsed = 0
            if WorldMapFrame and WorldMapFrame:IsShown() and IsEnabled() then
                self:UpdatePinPositions()
            end
        end
    end)
    
    -- Hook in WorldMap
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function() self:UpdatePins() end)
        WorldMapFrame:HookScript("OnHide", function() self:HidePins() end)
        
        -- Bei Map-Wechsel aktualisieren
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            self:UpdatePins()
        end)
    end
    
    -- Aufräumen: Alte Einträge entfernen (alle 5 Sekunden wegen Echtzeit)
    C_Timer.NewTicker(5, function()
        self:CleanupStalePositions()
    end)
    
    -- Initiales Broadcast nach Login
    C_Timer.After(3, function()
        if IsInGuild() then
            self:BroadcastPosition()
        end
    end)
    
    GDL:Print("|cff00AAFFGuildTracker:|r |cff00FF00ULTRA Echtzeit|r Gilden-Karte aktiv (Updates alle 0.75s)")
    GDL:Debug("GuildTracker: Initialisiert, Prefix=" .. ADDON_PREFIX .. ", Interval=" .. BROADCAST_INTERVAL .. "s")
end

function GuildTracker:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_PREFIX and channel == "GUILD" then
            self:HandleMessage(message, sender)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function()
            if IsInGuild() then
                self:BroadcastPosition()
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- POSITION SENDEN
-- ══════════════════════════════════════════════════════════════

function GuildTracker:BroadcastPosition()
    if not IsInGuild() or not IsEnabled() then return end
    
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId then return end
    
    local position = C_Map.GetPlayerMapPosition(mapId, "player")
    if not position then return end
    
    local x, y = position:GetXY()
    if not x or not y then return end
    
    -- Klassen-ID holen
    local _, _, classId = UnitClass("player")
    
    -- Format: mapId|x|y|classId
    local data = string.format("%d|%.4f|%.4f|%d", mapId, x, y, classId or 0)
    
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, data, "GUILD")
end

-- ══════════════════════════════════════════════════════════════
-- POSITION EMPFANGEN - Mit Interpolation für flüssige Bewegung
-- ══════════════════════════════════════════════════════════════

function GuildTracker:HandleMessage(message, sender)
    -- Eigene Nachrichten ignorieren
    local senderName = strsplit("-", sender)
    if senderName == GDL.playerName then return end
    
    -- Parse: mapId|x|y|classId
    local mapId, x, y, classId = strsplit("|", message)
    mapId = tonumber(mapId)
    x = tonumber(x)
    y = tonumber(y)
    classId = tonumber(classId) or 0
    
    if not mapId or not x or not y then return end
    
    local existing = guildPositions[senderName]
    
    if existing and existing.mapId == mapId then
        -- Gleiche Map: Interpolation von alter zu neuer Position
        existing.startX = existing.currentX or existing.x
        existing.startY = existing.currentY or existing.y
        existing.targetX = x
        existing.targetY = y
        existing.interpStart = GetTime()
        existing.interpDuration = BROADCAST_INTERVAL  -- Über 0.75 Sekunden interpolieren
        existing.timestamp = time()
    else
        -- Neue Map oder erster Eintrag: Direkt setzen
        guildPositions[senderName] = {
            mapId = mapId,
            x = x,
            y = y,
            currentX = x,
            currentY = y,
            startX = x,
            startY = y,
            targetX = x,
            targetY = y,
            interpStart = GetTime(),
            interpDuration = 0,
            classId = classId,
            timestamp = time()
        }
    end
    
    -- Pins aktualisieren wenn Karte offen
    if WorldMapFrame and WorldMapFrame:IsShown() then
        self:UpdatePins()
    end
end

-- ══════════════════════════════════════════════════════════════
-- ECHTZEIT PIN-UPDATE - Flüssige Bewegung durch Interpolation
-- ══════════════════════════════════════════════════════════════

function GuildTracker:UpdatePinPositions()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    
    local currentMapId = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID() or WorldMapFrame.mapID
    if not currentMapId then return end
    
    local canvas = nil
    if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
        canvas = WorldMapFrame.ScrollContainer.Child
    elseif WorldMapFrame.GetCanvas then
        canvas = WorldMapFrame:GetCanvas()
    end
    if not canvas then return end
    
    local canvasWidth = canvas:GetWidth()
    local canvasHeight = canvas:GetHeight()
    if canvasWidth == 0 or canvasHeight == 0 then return end
    
    local now = GetTime()
    local timeNow = time()
    
    for name, pos in pairs(guildPositions) do
        if pos.mapId == currentMapId and (timeNow - pos.timestamp) < STALE_TIMEOUT then
            local pin = mapPins[name]
            if pin and pin:IsShown() then
                -- Interpolation berechnen
                local progress = 1
                if pos.interpDuration > 0 then
                    progress = math.min((now - pos.interpStart) / pos.interpDuration, 1)
                    -- Smooth easing
                    progress = progress * progress * (3 - 2 * progress)
                end
                
                -- Aktuelle Position berechnen
                local currentX = pos.startX + (pos.targetX - pos.startX) * progress
                local currentY = pos.startY + (pos.targetY - pos.startY) * progress
                
                pos.currentX = currentX
                pos.currentY = currentY
                
                -- Pin-Position aktualisieren
                pin:ClearAllPoints()
                local px = currentX * canvasWidth
                local py = -currentY * canvasHeight
                pin:SetPoint("CENTER", canvas, "TOPLEFT", px, py)
            end
        end
    end
end

function GuildTracker:UpdatePins()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not IsEnabled() then 
        self:HidePins()
        return 
    end
    
    -- Aktuelle Map-ID
    local currentMapId = nil
    if WorldMapFrame.GetMapID then
        currentMapId = WorldMapFrame:GetMapID()
    elseif WorldMapFrame.mapID then
        currentMapId = WorldMapFrame.mapID
    end
    if not currentMapId then return end
    
    -- Canvas finden
    local canvas = nil
    if WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child then
        canvas = WorldMapFrame.ScrollContainer.Child
    elseif WorldMapFrame.GetCanvas then
        canvas = WorldMapFrame:GetCanvas()
    end
    if not canvas then return end
    
    local canvasWidth = canvas:GetWidth()
    local canvasHeight = canvas:GetHeight()
    if canvasWidth == 0 or canvasHeight == 0 then return end
    
    -- Alle Pins verstecken
    for _, pin in pairs(mapPins) do
        pin:Hide()
    end
    
    -- Pins für alle Spieler auf dieser Map erstellen
    local now = time()
    for name, pos in pairs(guildPositions) do
        -- Nur wenn auf gleicher Map und nicht zu alt
        if pos.mapId == currentMapId and (now - pos.timestamp) < STALE_TIMEOUT then
            local pin = self:GetOrCreatePin(canvas, name)
            
            -- Nutze interpolierte Position (currentX/Y) oder Fallback auf x/y
            local displayX = pos.currentX or pos.x
            local displayY = pos.currentY or pos.y
            
            -- Position setzen
            pin:ClearAllPoints()
            local px = displayX * canvasWidth
            local py = -displayY * canvasHeight
            pin:SetPoint("CENTER", canvas, "TOPLEFT", px, py)
            
            -- Klassenfarbe auf Icon, Glow und Name
            local col = self:GetClassColor(pos.classId)
            pin.icon:SetVertexColor(col[1], col[2], col[3])
            pin.nameText:SetTextColor(col[1], col[2], col[3])
            if pin.glow then
                pin.glow:SetVertexColor(col[1], col[2], col[3])
            end
            
            pin:Show()
        end
    end
end

function GuildTracker:HidePins()
    for _, pin in pairs(mapPins) do
        pin:Hide()
    end
end

function GuildTracker:GetOrCreatePin(canvas, name)
    if mapPins[name] then
        mapPins[name]:SetParent(canvas)
        return mapPins[name]
    end
    
    local pin = self:CreatePin(canvas, name)
    mapPins[name] = pin
    return pin
end

function GuildTracker:CreatePin(canvas, name)
    local pin = CreateFrame("Frame", nil, canvas)
    pin:SetSize(36, 36)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(110)
    
    -- Pulsierender Glow-Ring (außen)
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(32, 32)
    glow:SetPoint("CENTER", 0, 0)
    glow:SetTexture("Interface\\BUTTONS\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.7)
    pin.glow = glow
    
    -- Hauptsymbol: Einfaches Quadrat (wird zu Kreis mit Klassenfarbe)
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(10, 10)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    icon:SetVertexColor(1, 1, 1)  -- Wird später eingefärbt
    pin.icon = icon
    
    -- Name - klein, unter dem Icon, nur bei Hover
    local nameText = pin:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    nameText:SetPoint("TOP", icon, "BOTTOM", 0, -3)
    nameText:SetText(name)
    nameText:Hide()
    pin.nameText = nameText
    
    -- Pulsierender Glow-Effekt Animation
    local pulseTime = 0
    pin:SetScript("OnUpdate", function(self, elapsed)
        pulseTime = pulseTime + elapsed
        local pulse = 0.5 + 0.4 * math.sin(pulseTime * 2.5)
        glow:SetAlpha(pulse)
        local glowSize = 28 + 10 * math.sin(pulseTime * 2.5)
        glow:SetSize(glowSize, glowSize)
    end)
    
    -- Hover-Bereich
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        nameText:Show()
        icon:SetSize(14, 14)
        glow:SetAlpha(1.0)
        glow:SetSize(40, 40)
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(name, 1, 0.85, 0.5)
        local pos = guildPositions[name]
        if pos then
            local mapInfo = C_Map.GetMapInfo(pos.mapId)
            local mapName = mapInfo and mapInfo.name or "Unbekannt"
            GameTooltip:AddLine(mapName, 0.3, 0.8, 0.3)
            local ago = time() - pos.timestamp
            local status = ago < 2 and "|cff00FF00LIVE|r" or ("vor " .. ago .. "s")
            GameTooltip:AddLine(status, 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function()
        nameText:Hide()
        icon:SetSize(10, 10)
        GameTooltip:Hide()
    end)
    
    return pin
end

-- ══════════════════════════════════════════════════════════════
-- HILFSFUNKTIONEN
-- ══════════════════════════════════════════════════════════════

function GuildTracker:GetClassColor(classId)
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

function GuildTracker:CleanupStalePositions()
    local now = time()
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) > STALE_TIMEOUT then
            guildPositions[name] = nil
            if mapPins[name] then
                mapPins[name]:Hide()
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════

function GuildTracker:Toggle()
    -- Toggle in Settings
    if not GuildDeathLogDB.settings then GuildDeathLogDB.settings = {} end
    
    local newState = not IsEnabled()
    GuildDeathLogDB.settings.guildTracker = newState
    
    if newState then
        GDL:Print("|cff00FF00Echtzeit Gilden-Karte aktiviert|r - Positionen werden alle " .. BROADCAST_INTERVAL .. "s gesynct")
        self:BroadcastPosition()
        if WorldMapFrame and WorldMapFrame:IsShown() then
            self:UpdatePins()
        end
    else
        GDL:Print("|cffFF6666Gilden-Karte deaktiviert|r")
        self:HidePins()
    end
    return newState
end

function GuildTracker:IsEnabled()
    return IsEnabled()
end

function GuildTracker:GetOnlineCount()
    local count = 0
    local now = time()
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) < STALE_TIMEOUT then
            count = count + 1
        end
    end
    return count
end

function GuildTracker:GetOnlinePlayers()
    local players = {}
    local now = time()
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) < STALE_TIMEOUT then
            table.insert(players, {
                name = name,
                mapId = pos.mapId,
                classId = pos.classId,
                lastSeen = now - pos.timestamp
            })
        end
    end
    return players
end

-- Debug: Zeige empfangene Positionen
function GuildTracker:PrintStatus()
    local count = self:GetOnlineCount()
    GDL:Print("=== GuildTracker Status (ECHTZEIT) ===")
    GDL:Print("Aktiviert: " .. (IsEnabled() and "|cff00FF00Ja|r" or "|cffFF0000Nein|r"))
    GDL:Print("Update-Intervall: |cff00FFFF" .. BROADCAST_INTERVAL .. "s|r")
    GDL:Print("Spieler getrackt: |cffFFD100" .. count .. "|r")
    
    if count > 0 then
        local now = time()
        for name, pos in pairs(guildPositions) do
            local ago = now - pos.timestamp
            local mapInfo = C_Map.GetMapInfo(pos.mapId)
            local mapName = mapInfo and mapInfo.name or "Unknown"
            local status = ago < 3 and "|cff00FF00LIVE|r" or ("|cffFFFF00vor " .. ago .. "s|r")
            GDL:Print("  - " .. name .. ": " .. mapName .. " " .. status)
        end
    else
        GDL:Print("|cff888888Keine Gildenmitglieder mit Addon in Reichweite.|r")
        GDL:Print("|cff888888Andere muessen auch v4.6.0+ nutzen!|r")
    end
end

-- ======================================================================
-- MODULE INITIALIZATION
-- ======================================================================

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            GuildTracker:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("GuildTracker", GuildTracker)
