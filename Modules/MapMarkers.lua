-- ══════════════════════════════════════════════════════════════
-- MODUL: MapMarkers - Todesmarker auf der Weltkarte
-- Classic Era kompatibel
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local MapMarkers = {}

local MARKER_DURATION = 30 * 24 * 60 * 60 -- 30 Tage
local mapPins = {}
local pinPool = {}

function MapMarkers:Initialize()
    -- Hook WorldMapFrame
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function() 
            C_Timer.After(0.1, function() self:UpdateMarkers() end)
        end)
        
        -- Classic Era verwendet andere Map Change Detection
        if WorldMapFrame.ScrollContainer then
            hooksecurefunc(WorldMapFrame.ScrollContainer, "SetMapID", function()
                C_Timer.After(0.1, function() self:UpdateMarkers() end)
            end)
        end
    end
    
    -- Eigenen Tod erfassen für Koordinaten
    self:SetupSelfDeathTracking()
end

function MapMarkers:SetupSelfDeathTracking()
    local deathFrame = CreateFrame("Frame")
    deathFrame:RegisterEvent("PLAYER_DEAD")
    deathFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_DEAD" then
            self:CaptureOwnDeathLocation()
        end
    end)
end

function MapMarkers:CaptureOwnDeathLocation()
    -- Koordinaten des eigenen Todes erfassen
    local mapId = C_Map.GetBestMapForUnit("player")
    if not mapId then return end
    
    local position = C_Map.GetPlayerMapPosition(mapId, "player")
    if not position then return end
    
    local posX, posY = position:GetXY()
    
    -- Speichere die letzte bekannte Position für den Sync
    GDL.lastDeathLocation = {
        mapId = mapId,
        posX = posX,
        posY = posY,
        timestamp = time()
    }
    
    if GuildDeathLogDB.settings.debugPrint then
        GDL:Print(string.format("Todesort erfasst: Map %d @ %.2f, %.2f", mapId, posX * 100, posY * 100))
    end
end

function MapMarkers:GetLastDeathLocation()
    return GDL.lastDeathLocation
end

function MapMarkers:OnEvent(event)
    if event == "PLAYER_READY" then
        C_Timer.After(3, function() self:UpdateMarkers() end)
    end
end

function MapMarkers:UpdateMarkers()
    -- Alle Pins verstecken
    for _, pin in pairs(mapPins) do 
        pin:Hide() 
    end
    
    if not GuildDeathLogDB.settings.mapMarkers then return end
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    -- Aktuelle Map ID ermitteln
    local currentMapId = nil
    if WorldMapFrame.GetMapID then
        currentMapId = WorldMapFrame:GetMapID()
    elseif WorldMapFrame.mapID then
        currentMapId = WorldMapFrame.mapID
    end
    if not currentMapId then return end
    
    -- Canvas finden (Classic Era vs Retail unterschiedlich)
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
    
    local now = time()
    local Sync = GDL:GetModule("Sync")
    local pinCount = 0
    
    for _, death in ipairs(guildData.deaths or {}) do
        -- Nur Tode auf dieser Map mit gültigen Koordinaten
        if death.mapId and death.mapId == currentMapId and
           death.posX and death.posX > 0 and death.posX < 1 and
           death.posY and death.posY > 0 and death.posY < 1 and
           (now - (death.timestamp or 0)) < MARKER_DURATION then
            
            local key = Sync and Sync:GetDeathKey(death.name, death.timestamp) or (death.name .. (death.timestamp or 0))
            local pin = mapPins[key]
            
            if not pin then
                pin = self:GetOrCreatePin(canvas, death)
                mapPins[key] = pin
            end
            
            pin.deathData = death
            pin:SetParent(canvas)
            pin:ClearAllPoints()
            
            -- Position berechnen
            local x = death.posX * canvasWidth
            local y = -death.posY * canvasHeight
            pin:SetPoint("CENTER", canvas, "TOPLEFT", x, y)
            
            -- Klassenfarbe
            local col = GDL:GetModule("UI"):GetClassColor(death.classId)
            if pin.icon and col then
                pin.icon:SetVertexColor(col[1], col[2], col[3], 1)
            end
            
            pin:Show()
            pinCount = pinCount + 1
        end
    end
    
    if GuildDeathLogDB.settings.debugPrint and pinCount > 0 then
        GDL:Print(string.format("Map %d: %d Todesmarker angezeigt", currentMapId, pinCount))
    end
end

function MapMarkers:GetOrCreatePin(parent, death)
    -- Aus Pool holen oder neu erstellen
    local pin = table.remove(pinPool)
    if not pin then
        pin = self:CreatePin(parent)
    end
    return pin
end

function MapMarkers:CreatePin(parent)
    local pin = CreateFrame("Frame", nil, parent)
    pin:SetSize(24, 24)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(100)
    
    -- Hintergrund-Glow
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Cooldown\\star4")
    glow:SetBlendMode("ADD")
    glow:SetSize(32, 32)
    glow:SetPoint("CENTER")
    glow:SetAlpha(0.5)
    glow:SetVertexColor(0.8, 0.2, 0.2, 1)
    pin.glow = glow
    
    -- Totenkopf Icon
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    pin.icon = icon
    
    -- Interaktiv
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        local d = self.deathData
        if not d then return end
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        
        -- Name mit Klassenfarbe
        local col = GDL:GetModule("UI"):GetClassColor(d.classId)
        if col then
            GameTooltip:AddLine(d.name, col[1], col[2], col[3])
        else
            GameTooltip:AddLine(d.name, 1, 0.84, 0)
        end
        
        -- Details
        GameTooltip:AddLine(GDL:L("LEVEL") .. " " .. (d.level or "?") .. " " .. GDL:GetClassName(d.classId), 0.8, 0.8, 0.8)
        
        if d.zone and d.zone ~= "" then
            GameTooltip:AddLine(d.zone, 0.6, 0.6, 0.6)
        end
        
        if d.timestamp and d.timestamp > 0 then
            local timeAgo = time() - d.timestamp
            local timeStr
            if timeAgo < 3600 then
                timeStr = string.format("vor %d Minuten", math.floor(timeAgo / 60))
            elseif timeAgo < 86400 then
                timeStr = string.format("vor %d Stunden", math.floor(timeAgo / 3600))
            else
                timeStr = date("%d.%m.%Y %H:%M", d.timestamp)
            end
            GameTooltip:AddLine("† " .. timeStr, 0.5, 0.5, 0.5)
        end
        
        -- Koordinaten
        if d.posX and d.posY then
            GameTooltip:AddLine(string.format("Koordinaten: %.1f, %.1f", d.posX * 100, d.posY * 100), 0.4, 0.4, 0.4)
        end
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff888888Klick für Details|r", 0.5, 0.5, 0.5)
        
        GameTooltip:Show()
        
        -- Glow Animation
        if self.glow then
            self.glow:SetAlpha(0.8)
        end
    end)
    
    pin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.glow then
            self.glow:SetAlpha(0.5)
        end
    end)
    
    pin:SetScript("OnClick", function(self)
        local d = self.deathData
        if d then
            local UI = GDL:GetModule("UI")
            if UI then UI:ShowOverlay(d, d.syncedFrom ~= nil) end
        end
    end)
    
    return pin
end

function MapMarkers:RecyclePin(pin)
    pin:Hide()
    pin:ClearAllPoints()
    table.insert(pinPool, pin)
end

-- Anzahl der Marker mit Koordinaten
function MapMarkers:GetMarkerCount()
    local guildData = GDL:GetGuildData()
    if not guildData then return 0, 0 end
    
    local total = 0
    local withCoords = 0
    
    for _, death in ipairs(guildData.deaths or {}) do
        total = total + 1
        if death.posX and death.posX > 0 and death.posY and death.posY > 0 then
            withCoords = withCoords + 1
        end
    end
    
    return total, withCoords
end

GDL:RegisterModule("MapMarkers", MapMarkers)
