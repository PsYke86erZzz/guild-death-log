-- ══════════════════════════════════════════════════════════════
-- MODUL: Export - Daten exportieren für Discord/Custom Channel
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Export = {}

function Export:Initialize()
    -- SavedVariables für Export-Einstellungen
    GuildDeathLogDB.export = GuildDeathLogDB.export or {
        customChannel = "",
        announceToChannel = false,
        format = "detailed", -- "simple", "detailed", "discord"
    }
end

function Export:SetCustomChannel(channelName)
    GuildDeathLogDB.export.customChannel = channelName
    GDL:Print("Export Channel: " .. (channelName ~= "" and channelName or "disabled"))
end

function Export:GetCustomChannel()
    return GuildDeathLogDB.export.customChannel or ""
end

function Export:SetAnnounceToChannel(enabled)
    GuildDeathLogDB.export.announceToChannel = enabled
end

-- Export Tod zu Custom Channel
function Export:AnnounceToChannel(death)
    if not GuildDeathLogDB.export.announceToChannel then return end
    
    local channel = GuildDeathLogDB.export.customChannel
    if not channel or channel == "" then return end
    
    local channelId = GetChannelName(channel)
    if not channelId or channelId == 0 then return end
    
    local msg = self:FormatDeath(death, GuildDeathLogDB.export.format)
    SendChatMessage(msg, "CHANNEL", nil, channelId)
end

function Export:FormatDeath(death, format)
    format = format or "detailed"
    
    local name = death.name or "Unknown"
    local level = death.level or "?"
    local class = GDL:GetClassName(death.classId)
    local zone = death.zone or "Unknown"
    local killer = death.killerName or death.killer or ""
    local lastWords = death.lastWords or ""
    
    if format == "simple" then
        return string.format("[X] %s (Lvl %s %s) R.I.P.", name, level, class)
        
    elseif format == "discord" then
        -- Discord-freundliches Format
        local msg = string.format("**[X] %s** ist gefallen! / has fallen!", name)
        msg = msg .. string.format("\n> Level %s %s", level, class)
        msg = msg .. string.format("\n> Zone: %s", zone)
        if killer and killer ~= "" then
            msg = msg .. string.format("\n> Getötet von / Killed by: %s", killer)
        end
        if lastWords and lastWords ~= "" then
            msg = msg .. string.format("\n> Letzte Worte / Last words: \"%s\"", lastWords)
        end
        return msg
        
    else -- detailed
        local msg = string.format("[X] %s (Level %s %s) - %s", name, level, class, zone)
        if killer and killer ~= "" then
            msg = msg .. " | Killer: " .. killer
        end
        if lastWords and lastWords ~= "" then
            msg = msg .. " | \"" .. lastWords .. "\""
        end
        return msg
    end
end

-- Export alle Tode als Text (für Copy/Paste)
function Export:ExportAllDeaths()
    local guildData = GDL:GetGuildData()
    if not guildData then return "" end
    
    local lines = {}
    table.insert(lines, "=== Das Buch der Gefallenen / The Book of the Fallen ===")
    table.insert(lines, string.format("Guild: %s | Exported: %s", GDL.currentGuildName or "?", date("%Y-%m-%d %H:%M")))
    table.insert(lines, "")
    
    local deaths = guildData.deaths or {}
    table.sort(deaths, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    
    for i, death in ipairs(deaths) do
        local dateStr = death.timestamp and date("%Y-%m-%d %H:%M", death.timestamp) or "?"
        local line = string.format("[%s] %s - Level %s %s - %s",
            dateStr,
            death.name or "?",
            death.level or "?",
            GDL:GetClassName(death.classId),
            death.zone or "?"
        )
        if death.killerName or death.killer then
            line = line .. " | Killed by: " .. (death.killerName or death.killer)
        end
        if death.lastWords and death.lastWords ~= "" then
            line = line .. " | \"" .. death.lastWords .. "\""
        end
        table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
end

-- Export als CSV
function Export:ExportCSV()
    local guildData = GDL:GetGuildData()
    if not guildData then return "" end
    
    local lines = {}
    table.insert(lines, "Date,Name,Level,Class,Zone,Killer,LastWords")
    
    for _, death in ipairs(guildData.deaths or {}) do
        local dateStr = death.timestamp and date("%Y-%m-%d %H:%M", death.timestamp) or ""
        local line = string.format('"%s","%s",%d,"%s","%s","%s","%s"',
            dateStr,
            (death.name or ""):gsub('"', '""'),
            death.level or 0,
            GDL:GetClassName(death.classId),
            (death.zone or ""):gsub('"', '""'),
            (death.killerName or death.killer or ""):gsub('"', '""'),
            (death.lastWords or ""):gsub('"', '""')
        )
        table.insert(lines, line)
    end
    
    return table.concat(lines, "\n")
end

-- Statistik-Export
function Export:ExportStatistics()
    local Stats = GDL:GetModule("Statistics")
    if not Stats then return "" end
    
    local summary = Stats:GetSummary()
    local zones = Stats:GetDangerousZones(10)
    local killers = Stats:GetDeadliestKillers(10)
    local classStats = Stats:GetDeathsByClass()
    
    local lines = {}
    table.insert(lines, "=== GUILD DEATH STATISTICS ===")
    table.insert(lines, string.format("Guild: %s", GDL.currentGuildName or "?"))
    table.insert(lines, "")
    
    table.insert(lines, "--- SUMMARY ---")
    table.insert(lines, string.format("Total Deaths: %d", summary.total))
    table.insert(lines, string.format("Today: %d | This Week: %d", summary.today, summary.thisWeek))
    table.insert(lines, string.format("Avg Level: %.1f | Highest: %d | Lowest: %d", summary.avgLevel, summary.highestLevel, summary.lowestLevel))
    table.insert(lines, "")
    
    table.insert(lines, "--- DEADLIEST ZONES ---")
    for i, zone in ipairs(zones) do
        table.insert(lines, string.format("%d. %s - %d deaths (avg lvl %.1f)", i, zone.zone, zone.count, zone.avgLevel))
    end
    table.insert(lines, "")
    
    table.insert(lines, "--- DEADLIEST KILLERS ---")
    for i, killer in ipairs(killers) do
        table.insert(lines, string.format("%d. %s - %d kills", i, killer.name, killer.count))
    end
    table.insert(lines, "")
    
    table.insert(lines, "--- DEATHS BY CLASS ---")
    for _, class in ipairs(classStats) do
        table.insert(lines, string.format("%s: %d deaths (avg lvl %.1f)", class.name, class.count, class.avgLevel))
    end
    
    return table.concat(lines, "\n")
end

-- Export Fenster anzeigen
function Export:ShowExportWindow()
    if not self.exportFrame then
        self:CreateExportWindow()
    end
    
    self.exportFrame.editBox:SetText(self:ExportAllDeaths())
    self.exportFrame:Show()
end

function Export:CreateExportWindow()
    local f = CreateFrame("Frame", "GDLExportWindow", UIParent, "BackdropTemplate")
    f:SetSize(600, 400)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    f:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = {left = 5, right = 5, top = 5, bottom = 5}
    })
    f:SetBackdropColor(0.1, 0.08, 0.05, 0.95)
    f:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
    
    -- Title
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 16, "")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cffFFD100Export - Copy & Paste|r")
    
    -- Close
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    
    -- Scroll Frame
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 15, -45)
    scroll:SetPoint("BOTTOMRIGHT", -35, 80)
    
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scroll:GetWidth() - 20)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(editBox)
    f.editBox = editBox
    
    -- Buttons
    local btnAll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnAll:SetSize(100, 24)
    btnAll:SetPoint("BOTTOMLEFT", 15, 15)
    btnAll:SetText("All Deaths")
    btnAll:SetScript("OnClick", function()
        editBox:SetText(self:ExportAllDeaths())
        editBox:HighlightText()
    end)
    
    local btnCSV = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnCSV:SetSize(100, 24)
    btnCSV:SetPoint("LEFT", btnAll, "RIGHT", 10, 0)
    btnCSV:SetText("CSV")
    btnCSV:SetScript("OnClick", function()
        editBox:SetText(self:ExportCSV())
        editBox:HighlightText()
    end)
    
    local btnStats = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnStats:SetSize(100, 24)
    btnStats:SetPoint("LEFT", btnCSV, "RIGHT", 10, 0)
    btnStats:SetText("Statistics")
    btnStats:SetScript("OnClick", function()
        editBox:SetText(self:ExportStatistics())
        editBox:HighlightText()
    end)
    
    local btnSelect = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    btnSelect:SetSize(120, 24)
    btnSelect:SetPoint("BOTTOMRIGHT", -15, 15)
    btnSelect:SetText("Select All")
    btnSelect:SetScript("OnClick", function()
        editBox:HighlightText()
        editBox:SetFocus()
    end)
    
    -- Channel Settings
    local channelLabel = f:CreateFontString(nil, "OVERLAY")
    channelLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    channelLabel:SetPoint("BOTTOMLEFT", 15, 50)
    channelLabel:SetText("|cffAAAAAAAuto-Announce Channel:|r")
    
    local channelBox = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    channelBox:SetSize(150, 20)
    channelBox:SetPoint("LEFT", channelLabel, "RIGHT", 10, 0)
    channelBox:SetAutoFocus(false)
    channelBox:SetText(GuildDeathLogDB.export.customChannel or "")
    channelBox:SetScript("OnEnterPressed", function(self)
        Export:SetCustomChannel(self:GetText())
        self:ClearFocus()
    end)
    
    self.exportFrame = f
end

GDL:RegisterModule("Export", Export)
