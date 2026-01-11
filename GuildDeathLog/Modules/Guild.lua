-- ══════════════════════════════════════════════════════════════
-- MODUL: Guild - Gildenverwaltung
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Guild = {}

local lastMemberUpdate = 0

function Guild:Initialize()
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- WICHTIG!
    self.eventFrame:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
    
    -- Initiales Laden nach kurzer Verzoegerung
    C_Timer.After(3, function()
        if IsInGuild() then 
            GuildRoster()  -- Roster anfordern
            self:UpdateGuildInfo()
            C_Timer.After(1, function()
                self:UpdateMembers()
            end)
        end
    end)
end

function Guild:OnEvent(event)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Beim Login: Gilde laden
        C_Timer.After(2, function()
            if IsInGuild() then 
                GuildRoster()
                self:UpdateGuildInfo()
            end
        end)
    elseif event == "GUILD_ROSTER_UPDATE" then
        self:UpdateGuildInfo()
        self:UpdateMembers()
    elseif event == "PLAYER_GUILD_UPDATE" then
        C_Timer.After(1, function()
            if IsInGuild() then GuildRoster() end
            self:UpdateGuildInfo()
        end)
    end
end

function Guild:UpdateGuildInfo()
    local oldGuild = GDL.currentGuildName
    
    if IsInGuild() then
        local guildName = GetGuildInfo("player")
        if guildName and guildName ~= "" then
            GDL.currentGuildName = guildName
            if oldGuild and oldGuild ~= GDL.currentGuildName then
                GDL:Print(string.format(GDL:L("GUILD_CHANGED"), GDL.currentGuildName))
            end
        end
    else
        if oldGuild then GDL:Print(GDL:L("GUILD_LEFT")) end
        GDL.currentGuildName = nil
    end
    
    local UI = GDL:GetModule("UI")
    if UI and UI.mainFrame and UI.mainFrame:IsShown() then UI:UpdateChronicle() end
end

function Guild:UpdateMembers()
    if not IsInGuild() then return end
    if time() - lastMemberUpdate < 5 then return end  -- Reduziert von 10 auf 5
    lastMemberUpdate = time()
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    guildData.members = guildData.members or {}
    
    local count = 0
    local numMembers = GetNumGuildMembers()
    
    for i = 1, numMembers do
        local name = GetGuildRosterInfo(i)
        if name then 
            local cleanName = strsplit("-", name)
            if cleanName then
                guildData.members[cleanName:lower()] = true
                count = count + 1
            end
        end
    end
    
    GDL:Debug("Guild: " .. count .. " Mitglieder geladen")
end

function Guild:IsMember(name)
    if not name then return false end
    
    local guildData = GDL:GetGuildData()
    
    -- Falls Members nicht geladen, nochmal versuchen
    if not guildData or not guildData.members or not next(guildData.members) then
        GDL:Debug("Guild:IsMember - Members leer, lade neu...")
        self:UpdateMembers()
        guildData = GDL:GetGuildData()
    end
    
    if not guildData or not guildData.members then 
        GDL:Debug("Guild:IsMember - Keine Gildendaten!")
        return false 
    end
    
    local cleanName = strsplit("-", name)
    local result = guildData.members[cleanName:lower()] ~= nil
    
    GDL:Debug("Guild:IsMember('" .. name .. "') = " .. tostring(result))
    return result
end

-- Hilfsfunktion: Anzahl Mitglieder
function Guild:GetMemberCount()
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.members then return 0 end
    
    local count = 0
    for _ in pairs(guildData.members) do count = count + 1 end
    return count
end

GDL:RegisterModule("Guild", Guild)
