-- ══════════════════════════════════════════════════════════════
-- COMPATIBILITY LAYER
-- Ensures addon works across WoW versions
-- ══════════════════════════════════════════════════════════════

local addonName, GDL = ...

-- Version Detection
GDL.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
GDL.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
GDL.tocVersion = select(4, GetBuildInfo())

-- GuildRoster compatibility
GDL.GuildRoster = function()
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end

-- SendAddonMessage compatibility
GDL.SendAddonMessage = function(prefix, message, channel, target)
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        return C_ChatInfo.SendAddonMessage(prefix, message, channel, target)
    elseif SendAddonMessage then
        return SendAddonMessage(prefix, message, channel, target)
    end
end

-- RegisterAddonMessagePrefix compatibility
GDL.RegisterAddonMessagePrefix = function(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix)
    elseif RegisterAddonMessagePrefix then
        return RegisterAddonMessagePrefix(prefix)
    end
end

-- GetPlayerMapPosition compatibility
GDL.GetPlayerPosition = function()
    if C_Map and C_Map.GetBestMapForUnit then
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            local pos = C_Map.GetPlayerMapPosition(mapID, "player")
            if pos then
                return pos:GetXY()
            end
        end
    end
    return nil, nil
end

-- GetSpellInfo compatibility (Retail 11.0+ changed this)
GDL.GetSpellInfo = function(spellID)
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info then
            return info.name, nil, info.iconID
        end
    elseif GetSpellInfo then
        return GetSpellInfo(spellID)
    end
    return nil
end

-- Print version info on load
C_Timer.After(1, function()
    if GDL.tocVersion then
        -- Silent - nur für Debug
        -- print("|cffAAAAAACompat: Interface " .. GDL.tocVersion .. "|r")
    end
end)
