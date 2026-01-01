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
    self.eventFrame:SetScript("OnEvent", function(_, event) self:OnEvent(event) end)
end

function Guild:OnEvent(event)
    if event == "PLAYER_READY" then
        self:UpdateGuildInfo()
        if IsInGuild() then GuildRoster() end
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
    if not IsInGuild() or not GDL.currentGuildName then return end
    if time() - lastMemberUpdate < 10 then return end
    lastMemberUpdate = time()
    
    local guildData = GDL:GetGuildData()
    if not guildData then return end
    
    guildData.members = {}
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        if name then guildData.members[strsplit("-", name):lower()] = true end
    end
end

function Guild:IsMember(name)
    local guildData = GDL:GetGuildData()
    if not guildData or not guildData.members then return false end
    return guildData.members[strsplit("-", name):lower()] ~= nil
end

GDL:RegisterModule("Guild", Guild)
