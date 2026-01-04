-- ══════════════════════════════════════════════════════════════
-- MODUL: Deathlog - Integration mit Deathlog Addon
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Deathlog = {}

local deathlogAvailable = false
local deathlogEntryCount = 0
local deathlogGuildDeaths = 0
local lastScan = 0

function Deathlog:Initialize()
    C_Timer.After(2, function()
        self:SetupHooks()
        self:ScanData()
    end)
end

function Deathlog:OnEvent(event)
    if event == "PLAYER_READY" then
        C_Timer.After(5, function() self:ScanData() end)
    end
end

function Deathlog:SetupHooks()
    if _G["DeathNotificationLib_HookOnNewEntry"] then
        DeathNotificationLib_HookOnNewEntry(function(playerData, checksum, peerReport, inGuild)
            self:OnDeathNotification(playerData, inGuild)
        end)
        deathlogAvailable = true
        return
    end
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("HARDCORE_DEATHS")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "HARDCORE_DEATHS" then self:OnHardcoreDeathEvent(...) end
    end)
end

function Deathlog:OnDeathNotification(playerData, inGuild)
    GDL:Debug("DeathNotification erhalten: " .. (playerData and playerData.name or "nil"))
    
    if not playerData or not playerData.name or not GDL.currentGuildName then 
        GDL:Debug("DeathNotification: Daten unvollstaendig")
        return 
    end
    
    local isGuildDeath = inGuild or (playerData.guild and playerData.guild == GDL.currentGuildName)
    if not isGuildDeath then 
        GDL:Debug("DeathNotification: " .. playerData.name .. " nicht in unserer Gilde")
        return 
    end
    
    GDL:Debug("DeathNotification: " .. playerData.name .. " ist Gildenmitglied!")
    
    -- Koordinaten extrahieren (Vector2D hat .x und .y ODER [1] und [2])
    local posX, posY = 0, 0
    if playerData.map_pos then
        if playerData.map_pos.x then
            posX = playerData.map_pos.x
            posY = playerData.map_pos.y
        elseif playerData.map_pos[1] then
            posX = playerData.map_pos[1]
            posY = playerData.map_pos[2]
        end
    end
    
    local death = {
        name = playerData.name,
        level = playerData.level or 0,
        classId = playerData.class_id or 0,
        zone = self:GetZoneName(playerData.map_id),
        mapId = playerData.map_id or 0,
        posX = posX,
        posY = posY,
        lastWords = playerData.last_words or "",
        timestamp = playerData.date or time(),
    }
    
    local Sync = GDL:GetModule("Sync")
    if Sync then Sync:RecordLocalDeath(death) end
end

function Deathlog:OnHardcoreDeathEvent(name, level, classId, zoneName)
    if not name then return end
    
    local Guild = GDL:GetModule("Guild")
    if not Guild or not Guild:IsMember(name) then return end
    
    local death = {name = name, level = level or 0, classId = classId or 0, zone = zoneName or GDL:L("UNKNOWN"), timestamp = time()}
    
    local Sync = GDL:GetModule("Sync")
    if Sync then Sync:RecordLocalDeath(death) end
end

function Deathlog:ScanData()
    if time() - lastScan < 30 then return end
    lastScan = time()
    
    deathlogEntryCount = 0
    deathlogGuildDeaths = 0
    
    if not _G["deathlog_data"] or type(deathlog_data) ~= "table" then
        deathlogAvailable = false
        return
    end
    
    deathlogAvailable = true
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    local Sync = GDL:GetModule("Sync")
    
    for realmName, realmData in pairs(deathlog_data) do
        if type(realmData) == "table" then
            for playerKey, entry in pairs(realmData) do
                if type(entry) == "table" then
                    deathlogEntryCount = deathlogEntryCount + 1
                    
                    if GDL.currentGuildName and entry.guild and entry.guild == GDL.currentGuildName then
                        deathlogGuildDeaths = deathlogGuildDeaths + 1
                        
                        -- Koordinaten extrahieren
                        local posX, posY = 0, 0
                        if entry.map_pos then
                            if entry.map_pos.x then
                                posX = entry.map_pos.x
                                posY = entry.map_pos.y
                            elseif entry.map_pos[1] then
                                posX = entry.map_pos[1]
                                posY = entry.map_pos[2]
                            end
                        end
                        
                        local death = {
                            name = entry.name or playerKey:match("^([^%-]+)") or playerKey,
                            level = entry.level or 0,
                            classId = entry.class_id or 0,
                            zone = self:GetZoneName(entry.map_id),
                            mapId = entry.map_id or 0,
                            posX = posX,
                            posY = posY,
                            timestamp = entry.date or 0,
                            fromDeathlog = true,
                        }
                        
                        if Sync and not Sync:IsDuplicate(death) then
                            table.insert(guildData.deaths, death)
                        end
                    end
                end
            end
        end
    end
    
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
end

function Deathlog:GetZoneName(mapId)
    if not mapId or mapId == 0 then return GDL:L("UNKNOWN") end
    local mapInfo = C_Map.GetMapInfo(mapId)
    return mapInfo and mapInfo.name or GDL:L("UNKNOWN")
end

function Deathlog:IsAvailable() return deathlogAvailable end

function Deathlog:GetStats()
    return {available = deathlogAvailable, totalEntries = deathlogEntryCount, guildDeaths = deathlogGuildDeaths}
end

GDL:RegisterModule("Deathlog", Deathlog)
