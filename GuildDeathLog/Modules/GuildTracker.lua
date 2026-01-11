-- ══════════════════════════════════════════════════════════════
-- MODUL: GuildTracker v2.0 - LIVE Gilden-Tracking auf der Zonenkarte
-- Basierend auf GuildMap/MapMate Best Practices
-- 
-- FEATURES:
--   • Adaptive Broadcast: 3s bei Bewegung, 15s bei Stillstand
--   • 60s Stale-Timeout für stabiles Tracking ohne Flackern
--   • Delta-basiertes Senden (nur bei Positionsänderung)
--   • Robustes Cleanup-System
--   • Smooth Hermite-Interpolation für flüssige Pin-Bewegung
--
-- HINWEIS: Kontinent/Weltkarten-Anzeige deaktiviert (instabil in Classic)
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
    
    GDL:Print("|cff00AAFFGuildTracker v2.2:|r |cff00FF00Live-Sync|r aktiv (Gilden-intern)")
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
    
    -- NUR gleiche Map - stabil ohne Flackern
    for name, pos in pairs(guildPositions) do
        if pos.mapId == currentMapId and (now - pos.timestamp) < STALE_TIMEOUT then
            local pin = mapPins[name]
            if pin and pin:IsShown() then
                -- Interpolation berechnen
                local progress = 1
                if pos.interpDuration and pos.interpDuration > 0 then
                    local elapsed = now - (pos.interpStart or now)
                    progress = math.min(elapsed / pos.interpDuration, 1)
                    progress = HermiteInterpolate(progress)
                end
                
                -- Aktuelle Position berechnen
                local currentX = (pos.startX or pos.x) + ((pos.targetX or pos.x) - (pos.startX or pos.x)) * progress
                local currentY = (pos.startY or pos.y) + ((pos.targetY or pos.y) - (pos.startY or pos.y)) * progress
                
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
    
    -- Pins NUR für Spieler auf der GLEICHEN Map anzeigen (stabil!)
    for name, pos in pairs(guildPositions) do
        if pos.mapId == currentMapId and (now - pos.timestamp) < STALE_TIMEOUT then
            local pin = self:GetOrCreatePin(canvas, name)
            
            local displayX = pos.currentX or pos.x
            local displayY = pos.currentY or pos.y
            
            pin:ClearAllPoints()
            local px = displayX * canvasWidth
            local py = -displayY * canvasHeight
            pin:SetPoint("CENTER", canvas, "TOPLEFT", px, py)
            
            -- Klassenicon setzen
            self:SetPinClassIcon(pin, pos.classId)
            
            -- Glow und Name in Klassenfarbe
            local col = self:GetClassColor(pos.classId)
            if pin.nameText then
                pin.nameText:SetTextColor(col[1], col[2], col[3])
            end
            if pin.glow then
                pin.glow:SetVertexColor(col[1], col[2], col[3])
            end
            
            pin:Show()
        end
    end
end

-- Transformiert Koordinaten - DEAKTIVIERT wegen Instabilität in Classic
function GuildTracker:TransformCoordinates(sourceMapId, x, y, targetMapId)
    -- Kontinent/Weltkarten-Transformation verursacht Flackern
    -- Daher deaktiviert - nur gleiche Map wird angezeigt
    return nil, nil
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
-- PIN ERSTELLUNG - Mit Klassenicons!
-- ══════════════════════════════════════════════════════════════

-- Klassenicon TexCoords für das Spritesheet
local CLASS_ICON_TCOORDS = {
    [1]  = {0, 0.25, 0, 0.25},        -- Warrior
    [2]  = {0, 0.25, 0.5, 0.75},      -- Paladin
    [3]  = {0, 0.25, 0.25, 0.5},      -- Hunter
    [4]  = {0.5, 0.75, 0, 0.25},      -- Rogue
    [5]  = {0.5, 0.75, 0.25, 0.5},    -- Priest
    [6]  = {0.25, 0.5, 0.5, 0.75},    -- Death Knight
    [7]  = {0.25, 0.5, 0.25, 0.5},    -- Shaman
    [8]  = {0.25, 0.5, 0, 0.25},      -- Mage
    [9]  = {0.75, 1, 0.25, 0.5},      -- Warlock
    [10] = {0.5, 0.75, 0.5, 0.75},    -- Monk
    [11] = {0.75, 1, 0, 0.25},        -- Druid
}

function GuildTracker:CreatePin(canvas, name)
    local pin = CreateFrame("Frame", nil, canvas)
    pin:SetSize(18, 18)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(110)
    
    -- NUR das Klassenicon - sonst nichts!
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    icon:SetTexCoord(0, 0.25, 0, 0.25)
    pin.icon = icon
    
    -- Ganz dezenter Glow (nur als Highlight)
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetSize(18, 18)
    glow:SetPoint("CENTER", 0, 0)
    glow:SetTexture("Interface\\BUTTONS\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.3)
    pin.glow = glow
    
    -- Name (nur bei Hover)
    local nameText = pin:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    nameText:SetPoint("TOP", icon, "BOTTOM", 0, -2)
    nameText:SetText(name)
    nameText:Hide()
    pin.nameText = nameText
    
    -- Sanftes Pulsieren
    local pulseTime = 0
    pin:SetScript("OnUpdate", function(self, elapsed)
        pulseTime = pulseTime + elapsed
        local pulse = 0.25 + 0.2 * math.sin(pulseTime * 1.5)
        glow:SetAlpha(pulse)
    end)
    
    -- Hover
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        nameText:Show()
        icon:SetSize(18, 18)
        glow:SetAlpha(0.7)
        glow:SetSize(24, 24)
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(name, 1, 0.85, 0.5)
        
        local pos = guildPositions[name]
        if pos then
            local className = GuildTracker:GetClassNameById(pos.classId)
            if className then
                local col = GuildTracker:GetClassColor(pos.classId)
                GameTooltip:AddLine(className, col[1], col[2], col[3])
            end
            
            local mapInfo = C_Map.GetMapInfo(pos.mapId)
            local mapName = mapInfo and mapInfo.name or "Unbekannt"
            GameTooltip:AddLine(mapName, 0.3, 0.8, 0.3)
            
            if pos.level and pos.level > 0 then
                GameTooltip:AddLine("Level " .. pos.level, 0.8, 0.8, 0.8)
            end
            
            local ago = GetTime() - pos.timestamp
            if ago < 5 then
                GameTooltip:AddLine("LIVE", 0, 1, 0)
            elseif ago < 30 then
                GameTooltip:AddLine("vor " .. math.floor(ago) .. "s", 1, 1, 0)
            else
                GameTooltip:AddLine("vor " .. math.floor(ago) .. "s", 1, 0.5, 0)
            end
        end
        GameTooltip:Show()
    end)
    
    pin:SetScript("OnLeave", function()
        nameText:Hide()
        icon:SetSize(14, 14)
        glow:SetSize(18, 18)
        GameTooltip:Hide()
    end)
    
    return pin
end
-- Setzt das richtige Klassenicon auf einen Pin
function GuildTracker:SetPinClassIcon(pin, classId)
    if not pin or not pin.icon then return end
    
    local coords = CLASS_ICON_TCOORDS[classId]
    if coords then
        pin.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        -- Fallback: Warrior
        pin.icon:SetTexCoord(0, 0.25, 0, 0.25)
    end
end

-- Klassennamen für Tooltip
function GuildTracker:GetClassNameById(classId)
    local classNames = {
        [1] = "Krieger",
        [2] = "Paladin",
        [3] = "Jäger",
        [4] = "Schurke",
        [5] = "Priester",
        [6] = "Todesritter",
        [7] = "Schamane",
        [8] = "Magier",
        [9] = "Hexenmeister",
        [10] = "Mönch",
        [11] = "Druide",
    }
    return classNames[classId]
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
    GDL:Print("===========================================")
    GDL:Print("|cff00AAFFGuildTracker v2.2|r Status")
    GDL:Print("===========================================")
    GDL:Print("Gilde Live auf Karte: |cffFFD100" .. count .. "|r Spieler")
    
    if count > 0 then
        local now = GetTime()
        GDL:Print("-------------------------------------------")
        for name, pos in pairs(guildPositions) do
            local ago = math.floor(now - pos.timestamp)
            if ago < STALE_TIMEOUT then
                local mapInfo = C_Map.GetMapInfo(pos.mapId)
                local mapName = mapInfo and mapInfo.name or "?"
                local status
                if ago < 5 then
                    status = "|cff00FF00[LIVE]|r"
                elseif ago < 30 then
                    status = "|cffFFFF00[" .. ago .. "s]|r"
                else
                    status = "|cffFF8800[" .. ago .. "s]|r"
                end
                local lvl = pos.level and pos.level > 0 and (" Lv" .. pos.level) or ""
                GDL:Print("  " .. name .. lvl .. " - " .. mapName .. " " .. status)
            end
        end
    end
    GDL:Print("===========================================")
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
