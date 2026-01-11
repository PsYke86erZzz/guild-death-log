-- ============================================================══
-- MODUL: MapMarkers - Todes- und Meilenstein-Marker auf der Weltkarte
-- Classic Era kompatibel
-- ============================================================══

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local MapMarkers = {}

local MARKER_DURATION = 30 * 24 * 60 * 60 -- 30 Tage
local mapPins = {}

-- ══════════════════════════════════════════════════════════════
-- INITIALISIERUNG
-- ══════════════════════════════════════════════════════════════

function MapMarkers:Initialize()
    -- Schutz gegen doppelte Initialisierung
    if self.initialized then return end
    self.initialized = true
    
    GDL:Debug("MapMarkers: Starte Initialisierung...")
    
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
        
        GDL:Debug("MapMarkers: WorldMapFrame Hooks installiert")
    else
        GDL:Debug("MapMarkers: WARNUNG - WorldMapFrame nicht gefunden!")
    end
    
    -- Eigenen Tod erfassen für Koordinaten
    self:SetupSelfDeathTracking()
    
    GDL:Print("|cff00FF00MapMarkers:|r Todesmarker auf der Karte aktiviert")
end

function MapMarkers:SetupSelfDeathTracking()
    local deathFrame = CreateFrame("Frame")
    deathFrame:RegisterEvent("PLAYER_DEAD")
    deathFrame:RegisterEvent("PLAYER_ALIVE")  -- Für Debug
    deathFrame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_DEAD" then
            -- Mehrfach versuchen die Position zu erfassen
            self:CaptureOwnDeathLocation()
            -- Nochmal nach kurzer Verzögerung
            C_Timer.After(0.5, function() self:CaptureOwnDeathLocation() end)
        end
    end)
    GDL:Debug("MapMarkers: Death-Tracking aktiviert")
end

function MapMarkers:CaptureOwnDeathLocation()
    -- Koordinaten des eigenen Todes erfassen
    local mapId = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not mapId then 
        GDL:Debug("MapMarkers: Keine MapId gefunden")
        return 
    end
    
    local position = C_Map.GetPlayerMapPosition(mapId, "player")
    if not position then 
        GDL:Debug("MapMarkers: Keine Position gefunden")
        return 
    end
    
    local posX, posY = position:GetXY()
    
    -- Speichere die letzte bekannte Position für den Sync
    GDL.lastDeathLocation = {
        mapId = mapId,
        posX = posX,
        posY = posY,
        timestamp = time()
    }
    
    GDL:Debug(string.format("MapMarkers: Todesort erfasst - Map %d @ %.2f, %.2f", mapId, posX * 100, posY * 100))
end

function MapMarkers:GetLastDeathLocation()
    return GDL.lastDeathLocation
end

-- ══════════════════════════════════════════════════════════════
-- MARKER UPDATE - Hauptfunktion
-- ══════════════════════════════════════════════════════════════

function MapMarkers:UpdateMarkers()
    -- Alle Pins verstecken
    for _, pin in pairs(mapPins) do 
        pin:Hide() 
    end
    
    if not GuildDeathLogDB.settings.mapMarkers then return end
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end
    
    local guildData = GDL:GetGuildData()
    
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
    local pinCount = 0
    
    -- ═══════════════════════════════════════════════════════════
    -- 1. TODES-MARKER (Grabsteine)
    -- ═══════════════════════════════════════════════════════════
    if guildData and guildData.deaths then
        for _, death in ipairs(guildData.deaths) do
            -- Nur Tode auf dieser Map mit gültigen Koordinaten
            if death.mapId and death.mapId == currentMapId and
               death.posX and death.posX > 0 and death.posX < 1 and
               death.posY and death.posY > 0 and death.posY < 1 and
               (now - (death.timestamp or 0)) < MARKER_DURATION then
                
                local key = "death_" .. (death.name or "?") .. "_" .. (death.timestamp or 0)
                local pin = mapPins[key]
                
                if not pin then
                    pin = self:CreateDeathPin(canvas)
                    mapPins[key] = pin
                end
                
                pin.deathData = death
                pin.markerType = "death"
                pin:SetParent(canvas)
                pin:ClearAllPoints()
                
                -- Position berechnen
                local x = death.posX * canvasWidth
                local y = -death.posY * canvasHeight
                pin:SetPoint("CENTER", canvas, "TOPLEFT", x, y)
                
                -- Klassenfarbe für Glow
                local UI = GDL:GetModule("UI")
                if UI then
                    local col = UI:GetClassColor(death.classId)
                    if pin.glow and col then
                        pin.glow:SetVertexColor(col[1] * 0.8, col[2] * 0.3, col[3] * 0.3, 1)
                    end
                end
                
                pin:Show()
                pinCount = pinCount + 1
            end
        end
    end
    
    -- ═══════════════════════════════════════════════════════════
    -- 2. MEILENSTEIN-MARKER (Sterne)
    -- Nur eigene Meilensteine, KEINE Dungeon/Raid-Meilensteine
    -- ═══════════════════════════════════════════════════════════
    local Milestones = GDL:GetModule("Milestones")
    if Milestones and Milestones.GetCharacterKey and Milestones.GetCharacterData then
        local charKey = Milestones:GetCharacterKey()
        local charData = Milestones:GetCharacterData(charKey)
        
        if charData and charData.unlocked then
            for milestoneId, data in pairs(charData.unlocked) do
                -- Prüfe ob Meilenstein auf dieser Map mit Koordinaten
                if data.mapId and data.mapId == currentMapId and
                   data.posX and data.posX > 0 and data.posX < 1 and
                   data.posY and data.posY > 0 and data.posY < 1 then
                    
                    -- Hole Meilenstein-Definition
                    local milestone = nil
                    if Milestones.GetMilestoneById then
                        milestone = Milestones:GetMilestoneById(milestoneId)
                    end
                    
                    -- FILTER: Keine Dungeon oder Raid Meilensteine auf der Karte!
                    if milestone and milestone.category ~= "dungeon" and milestone.category ~= "raid" then
                        local key = "milestone_" .. milestoneId
                        local pin = mapPins[key]
                        
                        if not pin then
                            pin = self:CreateMilestonePin(canvas)
                            mapPins[key] = pin
                        end
                        
                        pin.milestoneData = {milestone = milestone, data = data}
                        pin.markerType = "milestone"
                        pin:SetParent(canvas)
                        pin:ClearAllPoints()
                        
                        -- Position berechnen
                        local x = data.posX * canvasWidth
                        local y = -data.posY * canvasHeight
                        pin:SetPoint("CENTER", canvas, "TOPLEFT", x, y)
                        
                        pin:Show()
                        pinCount = pinCount + 1
                    end
                end
            end
        end
    end
    
    if GuildDeathLogDB.settings.debugPrint and pinCount > 0 then
        GDL:Print(string.format("Map %d: %d Marker angezeigt", currentMapId, pinCount))
    end
end

-- ══════════════════════════════════════════════════════════════
-- TODES-PIN ERSTELLEN (Grabstein)
-- ══════════════════════════════════════════════════════════════

function MapMarkers:CreateDeathPin(parent)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(28, 28)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(100)
    
    -- Hintergrund-Glow (rötlich für Tod)
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Cooldown\\star4")
    glow:SetBlendMode("ADD")
    glow:SetSize(36, 36)
    glow:SetPoint("CENTER")
    glow:SetAlpha(0.6)
    glow:SetVertexColor(0.8, 0.1, 0.1, 1)
    pin.glow = glow
    
    -- Grabstein-Icon (Custom Texture mit Fallback)
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(26, 26)
    icon:SetPoint("CENTER")
    
    -- Versuche Custom Texture, Fallback auf WoW Totenkopf
    local customTexture = "Interface\\AddOns\\GuildDeathLog\\Textures\\DeathMarker"
    icon:SetTexture(customTexture)
    
    -- Wenn Custom Texture nicht lädt, nutze Fallback
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    end
    pin.icon = icon
    
    -- Interaktiv
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        local d = self.deathData
        if not d then return end
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("☠ " .. (d.name or "Unbekannt"), 1, 0.3, 0.3)
        
        -- Klasse und Level
        local className = GDL:GetClassName(d.classId)
        GameTooltip:AddLine("Level " .. (d.level or "?") .. " " .. className, 0.8, 0.8, 0.8)
        
        -- Zone
        if d.zone and d.zone ~= "" then
            GameTooltip:AddLine(d.zone, 0.6, 0.6, 0.6)
        end
        
        -- Todesursache
        if d.killerName and d.killerName ~= "" then
            GameTooltip:AddLine("Getötet von: " .. d.killerName, 0.9, 0.5, 0.5)
        end
        
        -- Zeitstempel
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
        
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff888888Linksklick für Details|r", 0.5, 0.5, 0.5)
        GameTooltip:Show()
        
        if self.glow then self.glow:SetAlpha(0.9) end
    end)
    
    pin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.glow then self.glow:SetAlpha(0.6) end
    end)
    
    pin:RegisterForClicks("LeftButtonUp")
    pin:SetScript("OnClick", function(self, button)
        local d = self.deathData
        if d and button == "LeftButton" then
            local UI = GDL:GetModule("UI")
            if UI and UI.ShowOverlay then 
                UI:ShowOverlay(d, d.syncedFrom ~= nil) 
            end
        end
    end)
    
    return pin
end

-- ══════════════════════════════════════════════════════════════
-- MEILENSTEIN-PIN ERSTELLEN (Gelber Stern)
-- ══════════════════════════════════════════════════════════════

function MapMarkers:CreateMilestonePin(parent)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(20, 20)
    pin:SetFrameStrata("HIGH")
    pin:SetFrameLevel(99)  -- Leicht unter Todes-Markern
    
    -- Goldener Glow
    local glow = pin:CreateTexture(nil, "BACKGROUND")
    glow:SetTexture("Interface\\Cooldown\\star4")
    glow:SetBlendMode("ADD")
    glow:SetSize(28, 28)
    glow:SetPoint("CENTER")
    glow:SetAlpha(0.5)
    glow:SetVertexColor(1, 0.8, 0, 1)  -- Gold
    pin.glow = glow
    
    -- Stern-Icon (WoW Standard Marker)
    local icon = pin:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    -- Gelber Stern (Raid Target Icon 1)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
    pin.icon = icon
    
    -- Interaktiv
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", function(self)
        local md = self.milestoneData
        if not md or not md.milestone then return end
        
        local m = md.milestone
        local d = md.data
        
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("⭐ " .. (m.name or "Meilenstein"), 1, 0.84, 0)
        
        if m.desc then
            GameTooltip:AddLine(m.desc, 0.8, 0.8, 0.8, true)
        end
        
        -- Wann freigeschaltet
        if d.timestamp and d.timestamp > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("Freigeschaltet: " .. date("%d.%m.%Y %H:%M", d.timestamp), 0.6, 0.8, 0.6)
        end
        
        -- Zone
        if d.zone and d.zone ~= "" then
            GameTooltip:AddLine("Zone: " .. d.zone, 0.5, 0.5, 0.5)
        end
        
        GameTooltip:Show()
        
        if self.glow then self.glow:SetAlpha(0.8) end
    end)
    
    pin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.glow then self.glow:SetAlpha(0.5) end
    end)
    
    return pin
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG / STATISTIK
-- ══════════════════════════════════════════════════════════════

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

function MapMarkers:PrintCoordDebug()
    local guildData = GDL:GetGuildData()
    if not guildData then 
        GDL:Print("|cffFF6666Keine Gildendaten gefunden!|r")
        return 
    end
    
    local total, withCoords = self:GetMarkerCount()
    
    GDL:Print("|cffFFD100=== Karten-Marker Debug ===|r")
    GDL:Print(string.format("Tode gesamt: %d", total))
    GDL:Print(string.format("Mit Koordinaten: |cff00FF00%d|r (%.0f%%)", withCoords, total > 0 and (withCoords/total*100) or 0))
    GDL:Print(string.format("Ohne Koordinaten: |cffFF6666%d|r", total - withCoords))
    GDL:Print(string.format("Marker-Setting: %s", GuildDeathLogDB.settings.mapMarkers and "|cff00FF00AN|r" or "|cffFF0000AUS|r"))
    
    -- Meilenstein-Statistik
    local Milestones = GDL:GetModule("Milestones")
    if Milestones and Milestones.GetCharacterKey then
        local charKey = Milestones:GetCharacterKey()
        local charData = Milestones:GetCharacterData(charKey)
        if charData and charData.unlocked then
            local msTotal, msWithCoords = 0, 0
            for _, data in pairs(charData.unlocked) do
                msTotal = msTotal + 1
                if data.posX and data.posX > 0 then
                    msWithCoords = msWithCoords + 1
                end
            end
            GDL:Print(string.format("Meilensteine: %d total, |cff00FF00%d|r mit Koordinaten", msTotal, msWithCoords))
        end
    end
    
    GDL:Print(" ")
    
    -- Zeige die letzten 5 Tode
    GDL:Print("|cffFFD100Letzte 5 Tode:|r")
    local count = 0
    for i = #(guildData.deaths or {}), 1, -1 do
        if count >= 5 then break end
        local d = guildData.deaths[i]
        local hasCoords = d.posX and d.posX > 0 and d.posY and d.posY > 0
        local coordStr = hasCoords 
            and string.format("|cff00FF00%.1f, %.1f|r (Map %d)", (d.posX or 0)*100, (d.posY or 0)*100, d.mapId or 0)
            or "|cffFF6666keine|r"
        GDL:Print(string.format("  %s - Coords: %s", d.name or "?", coordStr))
        count = count + 1
    end
end

-- ══════════════════════════════════════════════════════════════
-- AUTO-INITIALIZE
-- ══════════════════════════════════════════════════════════════
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            MapMarkers:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("MapMarkers", MapMarkers)
