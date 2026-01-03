-- ══════════════════════════════════════════════════════════════
-- MODUL: GuildTracker v2.0 - LIVE Gilden-Tracking auf der Weltkarte
-- Basierend auf GuildMap/MapMate Best Practices
-- 
-- FEATURES:
--   • Adaptive Broadcast: 3s bei Bewegung, 15s bei Stillstand
--   • 60s Stale-Timeout für stabiles Tracking ohne Flackern
--   • Delta-basiertes Senden (nur bei Positionsänderung)
--   • Robustes Cleanup-System
--   • Smooth Hermite-Interpolation für flüssige Pin-Bewegung
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local GuildTracker = {}

-- ══════════════════════════════════════════════════════════════
-- KONFIGURATION (GuildMap/MapMate Best Practices)
-- ══════════════════════════════════════════════════════════════

local ADDON_PREFIX = "GDLTrack"

-- BROADCAST SETTINGS (GuildMap: 2-5s, MapMate: 3s)
local BROADCAST_INTERVAL_MOVING = 3    -- Sekunden bei Bewegung
local BROADCAST_INTERVAL_STATIC = 15   -- Sekunden bei Stillstand
local MOVEMENT_THRESHOLD = 0.001       -- Delta für Bewegungserkennung
local HEARTBEAT_INTERVAL = 30          -- Sekunden für Heartbeat bei Stillstand

-- STALE DETECTION (GuildMap: 60s empfohlen)
local STALE_TIMEOUT = 60               -- Sekunden bis Spieler als offline gilt
local CLEANUP_INTERVAL = 10            -- Sekunden zwischen Cleanup-Runs

-- PIN UPDATE (Performance-optimiert)
local PIN_UPDATE_INTERVAL = 0.05       -- 50ms = 20 FPS für Pin-Bewegung
local INTERPOLATION_DURATION = 3       -- Sekunden für Bewegungs-Interpolation

-- ══════════════════════════════════════════════════════════════
-- DATENSTRUKTUREN
-- ══════════════════════════════════════════════════════════════

-- Speichert Positionen anderer Spieler
local guildPositions = {}
local mapPins = {}
local updateFrame = nil

-- Eigene letzte gesendete Position (für Delta-Check)
local lastSentPosition = {
    mapId = 0,
    x = 0,
    y = 0,
    timestamp = 0
}

-- Bewegungsstatus
local isMoving = false
local lastMoveCheck = {x = 0, y = 0}

-- ══════════════════════════════════════════════════════════════
-- UTILITY FUNKTIONEN
-- ══════════════════════════════════════════════════════════════

local function IsEnabled()
    if GuildDeathLogDB and GuildDeathLogDB.settings then
        if GuildDeathLogDB.settings.guildTracker == false then
            return false
        end
    end
    return true
end

-- Berechne ob Spieler sich bewegt
local function CheckMovement()
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId then return false end
    
    local position = C_Map.GetPlayerMapPosition(mapId, "player")
    if not position then return false end
    
    local x, y = position:GetXY()
    if not x or not y then return false end
    
    local dx = math.abs(x - lastMoveCheck.x)
    local dy = math.abs(y - lastMoveCheck.y)
    
    lastMoveCheck.x = x
    lastMoveCheck.y = y
    
    return (dx > MOVEMENT_THRESHOLD or dy > MOVEMENT_THRESHOLD)
end

-- Hermite Interpolation (smoother als linear)
local function HermiteInterpolate(t)
    return t * t * (3 - 2 * t)
end

-- ══════════════════════════════════════════════════════════════
-- INITIALISIERUNG
-- ══════════════════════════════════════════════════════════════

-- Prefix registrieren (MUSS vor Empfang erfolgen!)
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

function GuildTracker:Initialize()
    if self.initialized then return end
    self.initialized = true
    
    -- Event Frame
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    self.eventFrame:RegisterEvent("ZONE_CHANGED")
    self.eventFrame:SetScript("OnEvent", function(_, event, ...) 
        self:OnEvent(event, ...) 
    end)
    
    -- Adaptiver Broadcast-Timer starten
    self:StartBroadcastTimer()
    
    -- OnUpdate Frame für flüssige Pin-Bewegung
    updateFrame = CreateFrame("Frame")
    local elapsed = 0
    updateFrame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= PIN_UPDATE_INTERVAL then
            elapsed = 0
            if WorldMapFrame and WorldMapFrame:IsShown() and IsEnabled() then
                self:UpdatePinPositions()
            end
        end
    end)
    
    -- Bewegungscheck alle 0.5s für adaptive Intervalle
    C_Timer.NewTicker(0.5, function()
        isMoving = CheckMovement()
    end)
    
    -- Hook in WorldMap
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function() 
            self:UpdatePins() 
        end)
        WorldMapFrame:HookScript("OnHide", function() 
            self:HidePins() 
        end)
        
        -- Bei Map-Wechsel aktualisieren
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            self:UpdatePins()
        end)
    end
    
    -- Stale Cleanup Timer
    C_Timer.NewTicker(CLEANUP_INTERVAL, function()
        self:CleanupStalePositions()
    end)
    
    -- Initiales Broadcast nach Login (verzögert)
    C_Timer.After(5, function()
        if IsInGuild() and IsEnabled() then
            self:BroadcastPosition(true)
        end
    end)
    
    GDL:Print("|cff00AAFFGuildTracker v2.0:|r |cff00FF00Live-Sync|r aktiv")
    GDL:Print("  Bewegung: |cff00FFFF" .. BROADCAST_INTERVAL_MOVING .. "s|r | Stillstand: |cff00FFFF" .. BROADCAST_INTERVAL_STATIC .. "s|r | Timeout: |cffFFD100" .. STALE_TIMEOUT .. "s|r")
end

-- ══════════════════════════════════════════════════════════════
-- ADAPTIVER BROADCAST TIMER
-- Sendet häufiger bei Bewegung, seltener bei Stillstand
-- ══════════════════════════════════════════════════════════════

function GuildTracker:StartBroadcastTimer()
    local function DoBroadcast()
        if IsEnabled() and IsInGuild() then
            self:BroadcastPosition()
        end
        
        -- Nächsten Timer mit adaptivem Intervall setzen
        local interval = isMoving and BROADCAST_INTERVAL_MOVING or BROADCAST_INTERVAL_STATIC
        C_Timer.After(interval, DoBroadcast)
    end
    
    -- Ersten Timer starten
    C_Timer.After(BROADCAST_INTERVAL_MOVING, DoBroadcast)
end

-- ══════════════════════════════════════════════════════════════
-- EVENT HANDLING
-- ══════════════════════════════════════════════════════════════

function GuildTracker:OnEvent(event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_PREFIX and channel == "GUILD" then
            self:HandleMessage(message, sender)
        end
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function()
            if IsInGuild() and IsEnabled() then
                self:BroadcastPosition(true)
            end
        end)
        
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        -- Bei Zonenwechsel sofort senden (wichtig für Map-Wechsel)
        C_Timer.After(1, function()
            if IsInGuild() and IsEnabled() then
                self:BroadcastPosition(true)
            end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════
-- POSITION SENDEN (Mit Delta-Check)
-- ══════════════════════════════════════════════════════════════

function GuildTracker:BroadcastPosition(forceSend)
    if not IsInGuild() or not IsEnabled() then return end
    
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId then return end
    
    local position = C_Map.GetPlayerMapPosition(mapId, "player")
    if not position then return end
    
    local x, y = position:GetXY()
    if not x or not y then return end
    
    -- Delta-Check: Nur senden wenn Position sich ändert (außer Force)
    if not forceSend then
        local dx = math.abs(x - lastSentPosition.x)
        local dy = math.abs(y - lastSentPosition.y)
        local mapChanged = (mapId ~= lastSentPosition.mapId)
        
        -- Nichts geändert? Heartbeat nur alle HEARTBEAT_INTERVAL Sekunden
        if not mapChanged and dx < MOVEMENT_THRESHOLD and dy < MOVEMENT_THRESHOLD then
            local timeSinceLast = GetTime() - lastSentPosition.timestamp
            if timeSinceLast < HEARTBEAT_INTERVAL then
                return  -- Skip diesen Broadcast
            end
        end
    end
    
    -- Klassen-ID und Level holen
    local _, _, classId = UnitClass("player")
    local level = UnitLevel("player")
    
    -- Format: mapId|x|y|classId|level (kompakt, < 255 Bytes)
    local data = string.format("%d|%.4f|%.4f|%d|%d", 
        mapId, x, y, classId or 0, level or 0)
    
    -- Senden über GUILD-Channel
    local success = C_ChatInfo.SendAddonMessage(ADDON_PREFIX, data, "GUILD")
    
    if success then
        lastSentPosition.mapId = mapId
        lastSentPosition.x = x
        lastSentPosition.y = y
        lastSentPosition.timestamp = GetTime()
    end
end

-- ══════════════════════════════════════════════════════════════
-- POSITION EMPFANGEN
-- ══════════════════════════════════════════════════════════════

function GuildTracker:HandleMessage(message, sender)
    -- Eigene Nachrichten ignorieren
    local senderName = strsplit("-", sender)
    if senderName == GDL.playerName then return end
    
    -- Parse: mapId|x|y|classId|level
    local parts = {strsplit("|", message)}
    local mapId = tonumber(parts[1])
    local x = tonumber(parts[2])
    local y = tonumber(parts[3])
    local classId = tonumber(parts[4]) or 0
    local level = tonumber(parts[5]) or 0
    
    if not mapId or not x or not y then return end
    
    local now = GetTime()
    local existing = guildPositions[senderName]
    
    if existing and existing.mapId == mapId then
        -- Gleiche Map: Interpolation
        existing.startX = existing.currentX or existing.x
        existing.startY = existing.currentY or existing.y
        existing.targetX = x
        existing.targetY = y
        existing.interpStart = now
        existing.interpDuration = INTERPOLATION_DURATION
        existing.timestamp = now
        existing.level = level
    else
        -- Neue Map oder erster Eintrag
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
            interpStart = now,
            interpDuration = 0,
            classId = classId,
            level = level,
            timestamp = now
        }
    end
    
    -- Pins aktualisieren wenn Karte offen
    if WorldMapFrame and WorldMapFrame:IsShown() then
        self:UpdatePins()
    end
end

-- ══════════════════════════════════════════════════════════════
-- PIN-UPDATE MIT INTERPOLATION
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
    
    for name, pos in pairs(guildPositions) do
        if pos.mapId == currentMapId and (now - pos.timestamp) < STALE_TIMEOUT then
            local pin = mapPins[name]
            if pin and pin:IsShown() then
                -- Interpolation berechnen
                local progress = 1
                if pos.interpDuration > 0 then
                    local elapsed = now - pos.interpStart
                    progress = math.min(elapsed / pos.interpDuration, 1)
                    progress = HermiteInterpolate(progress)
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

-- ══════════════════════════════════════════════════════════════
-- PIN MANAGEMENT
-- ══════════════════════════════════════════════════════════════

function GuildTracker:UpdatePins()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    if not IsEnabled() then return end
    
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
    
    -- Alle Pins verstecken
    for _, pin in pairs(mapPins) do
        pin:Hide()
    end
    
    -- Pins für aktive Spieler anzeigen
    for name, pos in pairs(guildPositions) do
        if pos.mapId == currentMapId and (now - pos.timestamp) < STALE_TIMEOUT then
            local pin = self:GetOrCreatePin(canvas, name)
            
            local displayX = pos.currentX or pos.x
            local displayY = pos.currentY or pos.y
            
            pin:ClearAllPoints()
            local px = displayX * canvasWidth
            local py = -displayY * canvasHeight
            pin:SetPoint("CENTER", canvas, "TOPLEFT", px, py)
            
            -- Klassenfarbe
            local col = self:GetClassColor(pos.classId)
            pin.icon:SetVertexColor(col[1], col[2], col[3])
            pin.nameText:SetTextColor(col[1], col[2], col[3])
            if pin.glow then
                pin.glow:SetVertexColor(col[1], col[2], col[3])
            end
            
            -- Level-Anzeige
            if pin.levelText and pos.level and pos.level > 0 then
                pin.levelText:SetText(pos.level)
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

-- ══════════════════════════════════════════════════════════════
-- PIN ERSTELLUNG
-- ══════════════════════════════════════════════════════════════

function GuildTracker:CreatePin(canvas, name)
    local pin = CreateFrame("Frame", nil, canvas)
    pin:SetSize(36, 36)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(110)
    
    -- Pulsierender Glow-Ring
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(32, 32)
    glow:SetPoint("CENTER", 0, 0)
    glow:SetTexture("Interface\\BUTTONS\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.6)
    pin.glow = glow
    
    -- Hauptsymbol: Punkt
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(10, 10)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    pin.icon = icon
    
    -- Level-Anzeige
    local levelText = pin:CreateFontString(nil, "OVERLAY")
    levelText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    levelText:SetPoint("BOTTOMRIGHT", icon, "TOPRIGHT", 6, -2)
    levelText:SetTextColor(1, 1, 1)
    pin.levelText = levelText
    
    -- Name (nur bei Hover)
    local nameText = pin:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    nameText:SetPoint("TOP", icon, "BOTTOM", 0, -3)
    nameText:SetText(name)
    nameText:Hide()
    pin.nameText = nameText
    
    -- Pulsierender Glow Animation
    local pulseTime = 0
    pin:SetScript("OnUpdate", function(self, elapsed)
        pulseTime = pulseTime + elapsed
        local pulse = 0.4 + 0.3 * math.sin(pulseTime * 2)
        glow:SetAlpha(pulse)
        local glowSize = 26 + 8 * math.sin(pulseTime * 2)
        glow:SetSize(glowSize, glowSize)
    end)
    
    -- Hover-Effekte
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
            
            if pos.level and pos.level > 0 then
                GameTooltip:AddLine("Level " .. pos.level, 0.8, 0.8, 0.8)
            end
            
            local ago = GetTime() - pos.timestamp
            local status
            if ago < 5 then
                status = "|cff00FF00● LIVE|r"
            elseif ago < 30 then
                status = "|cffFFFF00● vor " .. math.floor(ago) .. "s|r"
            else
                status = "|cffFF8800● vor " .. math.floor(ago) .. "s|r"
            end
            GameTooltip:AddLine(status, 1, 1, 1)
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
-- STALE CLEANUP
-- ══════════════════════════════════════════════════════════════

function GuildTracker:CleanupStalePositions()
    local now = GetTime()
    local removedCount = 0
    
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) > STALE_TIMEOUT then
            guildPositions[name] = nil
            if mapPins[name] then
                mapPins[name]:Hide()
            end
            removedCount = removedCount + 1
        end
    end
    
    if removedCount > 0 and WorldMapFrame and WorldMapFrame:IsShown() then
        self:UpdatePins()
    end
end

-- ══════════════════════════════════════════════════════════════
-- KLASSENFARBEN
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

-- ══════════════════════════════════════════════════════════════
-- PUBLIC API
-- ══════════════════════════════════════════════════════════════

function GuildTracker:Toggle()
    if not GuildDeathLogDB.settings then 
        GuildDeathLogDB.settings = {} 
    end
    
    local newState = not IsEnabled()
    GuildDeathLogDB.settings.guildTracker = newState
    
    if newState then
        GDL:Print("|cff00FF00Gilden-Karte aktiviert|r")
        self:BroadcastPosition(true)
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
    local now = GetTime()
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) < STALE_TIMEOUT then
            count = count + 1
        end
    end
    return count
end

function GuildTracker:GetOnlinePlayers()
    local players = {}
    local now = GetTime()
    for name, pos in pairs(guildPositions) do
        if (now - pos.timestamp) < STALE_TIMEOUT then
            table.insert(players, {
                name = name,
                mapId = pos.mapId,
                classId = pos.classId,
                level = pos.level,
                lastSeen = math.floor(now - pos.timestamp)
            })
        end
    end
    table.sort(players, function(a, b) return a.name < b.name end)
    return players
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG / STATUS
-- ══════════════════════════════════════════════════════════════

function GuildTracker:PrintStatus()
    local count = self:GetOnlineCount()
    GDL:Print("═══════════════════════════════════════")
    GDL:Print("|cff00AAFFGuildTracker v2.0|r Status")
    GDL:Print("═══════════════════════════════════════")
    GDL:Print("Aktiviert: " .. (IsEnabled() and "|cff00FF00Ja|r" or "|cffFF0000Nein|r"))
    GDL:Print("Broadcast: |cff00FFFF" .. BROADCAST_INTERVAL_MOVING .. "s|r (Bewegung) / |cff00FFFF" .. BROADCAST_INTERVAL_STATIC .. "s|r (Still)")
    GDL:Print("Stale-Timeout: |cffFFD100" .. STALE_TIMEOUT .. "s|r")
    GDL:Print("Spieler online: |cffFFD100" .. count .. "|r")
    
    if count > 0 then
        local now = GetTime()
        GDL:Print("───────────────────────────────────────")
        for name, pos in pairs(guildPositions) do
            local ago = math.floor(now - pos.timestamp)
            if ago < STALE_TIMEOUT then
                local mapInfo = C_Map.GetMapInfo(pos.mapId)
                local mapName = mapInfo and mapInfo.name or "?"
                local status
                if ago < 5 then
                    status = "|cff00FF00● LIVE|r"
                elseif ago < 30 then
                    status = "|cffFFFF00● " .. ago .. "s|r"
                else
                    status = "|cffFF8800● " .. ago .. "s|r"
                end
                local lvl = pos.level and pos.level > 0 and (" Lv" .. pos.level) or ""
                GDL:Print("  " .. name .. lvl .. " - " .. mapName .. " " .. status)
            end
        end
    else
        GDL:Print("|cff888888Keine Gildenmitglieder mit Addon online.|r")
        GDL:Print("|cff888888Andere brauchen v4.8.0+|r")
    end
    GDL:Print("═══════════════════════════════════════")
end

function GuildTracker:ForceBroadcast()
    self:BroadcastPosition(true)
    GDL:Print("|cff00AAFFGuildTracker:|r Position gesendet (Force)")
end

-- ══════════════════════════════════════════════════════════════
-- MODULE INITIALIZATION
-- ══════════════════════════════════════════════════════════════

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
