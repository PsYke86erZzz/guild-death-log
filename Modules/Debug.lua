-- ══════════════════════════════════════════════════════════════
-- MODUL: Debug - Debug-Fenster und Logging
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Debug = {}

local debugLog = {}

function Debug:Initialize()
    -- Nix spezielles noetig
end

function Debug:Log(category, message, color)
    table.insert(debugLog, 1, {
        time = date("%H:%M:%S"), 
        timestamp = time(), 
        category = category or "INFO", 
        message = message or "", 
        color = color or "AAAAAA"
    })
    if #debugLog > 100 then table.remove(debugLog) end
    if self.frame and self.frame:IsShown() then self:UpdateWindow() end
end

function Debug:ShowWindow()
    if not self.frame then self:CreateWindow() end
    self.frame:Show()
    self:UpdateWindow()
    -- Tode-Stats aktualisieren
    C_Timer.After(0.5, function()
        self:UpdateDeathStats()
    end)
end

function Debug:CreateWindow()
    local f = CreateFrame("Frame", "GDLDebugFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(560, 560)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -350)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(150)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    f.TitleText:SetText(GDL:L("DEBUG_TITLE"))
    
    -- ═══════════════════════════════════════════════════════════
    -- ZEILE 1: Sync Status | Online | Deathlog Status
    -- ═══════════════════════════════════════════════════════════
    
    -- Box 1: Sync Status
    local syncBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    syncBox:SetPoint("TOPLEFT", 15, -35)
    syncBox:SetSize(170, 70)
    syncBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    syncBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    syncBox:SetBackdropBorderColor(0.3, 0.3, 0.3)
    
    local syncTitle = syncBox:CreateFontString(nil, "OVERLAY")
    syncTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    syncTitle:SetPoint("TOPLEFT", 8, -8)
    syncTitle:SetText("|cffFFD100" .. GDL:L("DEBUG_SYNC_STATUS") .. "|r")
    
    f.syncInfo = syncBox:CreateFontString(nil, "OVERLAY")
    f.syncInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.syncInfo:SetPoint("TOPLEFT", syncTitle, "BOTTOMLEFT", 0, -5)
    f.syncInfo:SetWidth(155)
    f.syncInfo:SetJustifyH("LEFT")
    
    -- Box 2: Online Users
    local onlineBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    onlineBox:SetPoint("TOPLEFT", syncBox, "TOPRIGHT", 8, 0)
    onlineBox:SetSize(170, 70)
    onlineBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    onlineBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    onlineBox:SetBackdropBorderColor(0.3, 0.5, 0.3)
    
    local onlineTitle = onlineBox:CreateFontString(nil, "OVERLAY")
    onlineTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    onlineTitle:SetPoint("TOPLEFT", 8, -8)
    onlineTitle:SetText("|cff00FF00Online:|r")
    
    f.onlineCount = onlineBox:CreateFontString(nil, "OVERLAY")
    f.onlineCount:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.onlineCount:SetPoint("LEFT", onlineTitle, "RIGHT", 5, 0)
    f.onlineCount:SetTextColor(0.7, 0.7, 0.7)
    
    local onlineScroll = CreateFrame("ScrollFrame", nil, onlineBox, "UIPanelScrollFrameTemplate")
    onlineScroll:SetPoint("TOPLEFT", 8, -24)
    onlineScroll:SetPoint("BOTTOMRIGHT", -28, 6)
    
    local onlineChild = CreateFrame("Frame", nil, onlineScroll)
    onlineChild:SetSize(130, 1)
    onlineScroll:SetScrollChild(onlineChild)
    f.onlineChild = onlineChild
    
    -- Box 3: Deathlog Status
    local dlBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    dlBox:SetPoint("TOPLEFT", onlineBox, "TOPRIGHT", 8, 0)
    dlBox:SetSize(170, 70)
    dlBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    dlBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    dlBox:SetBackdropBorderColor(0.3, 0.3, 0.3)
    
    local dlTitle = dlBox:CreateFontString(nil, "OVERLAY")
    dlTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    dlTitle:SetPoint("TOPLEFT", 8, -8)
    dlTitle:SetText("|cffFFD100" .. GDL:L("DEBUG_DEATHLOG") .. "|r")
    
    f.dlInfo = dlBox:CreateFontString(nil, "OVERLAY")
    f.dlInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.dlInfo:SetPoint("TOPLEFT", dlTitle, "BOTTOMLEFT", 0, -5)
    f.dlInfo:SetWidth(155)
    f.dlInfo:SetJustifyH("LEFT")
    
    -- ═══════════════════════════════════════════════════════════
    -- ZEILE 2: Tode-Stats | Live-Tracker | Addon Info
    -- ═══════════════════════════════════════════════════════════
    
    -- Box 4: Tode-Stats (Statistiken über Tode)
    local deathStatsBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    deathStatsBox:SetPoint("TOPLEFT", syncBox, "BOTTOMLEFT", 0, -8)
    deathStatsBox:SetSize(170, 70)
    deathStatsBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    deathStatsBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    deathStatsBox:SetBackdropBorderColor(0.5, 0.2, 0.2)
    
    local deathStatsTitle = deathStatsBox:CreateFontString(nil, "OVERLAY")
    deathStatsTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    deathStatsTitle:SetPoint("TOPLEFT", 8, -8)
    deathStatsTitle:SetText("|cffFF6666Tode-Stats|r")
    
    f.deathStatsInfo = deathStatsBox:CreateFontString(nil, "OVERLAY")
    f.deathStatsInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.deathStatsInfo:SetPoint("TOPLEFT", deathStatsTitle, "BOTTOMLEFT", 0, -5)
    f.deathStatsInfo:SetWidth(155)
    f.deathStatsInfo:SetJustifyH("LEFT")
    f.deathStatsInfo:SetText("|cff888888Wird geladen...|r")
    
    -- Box 5: Live-Tracker Status
    local trackerBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    trackerBox:SetPoint("TOPLEFT", deathStatsBox, "TOPRIGHT", 8, 0)
    trackerBox:SetSize(170, 70)
    trackerBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    trackerBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    trackerBox:SetBackdropBorderColor(0.4, 0.3, 0.5)
    
    local trackerTitle = trackerBox:CreateFontString(nil, "OVERLAY")
    trackerTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    trackerTitle:SetPoint("TOPLEFT", 8, -8)
    trackerTitle:SetText("|cffAA88FFLive-Tracker|r")
    
    f.trackerInfo = trackerBox:CreateFontString(nil, "OVERLAY")
    f.trackerInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.trackerInfo:SetPoint("TOPLEFT", trackerTitle, "BOTTOMLEFT", 0, -5)
    f.trackerInfo:SetWidth(155)
    f.trackerInfo:SetJustifyH("LEFT")
    
    -- Box 6: Addon Info
    local addonBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    addonBox:SetPoint("TOPLEFT", trackerBox, "TOPRIGHT", 8, 0)
    addonBox:SetSize(170, 70)
    addonBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8", 
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
        edgeSize = 12, 
        insets = {left=2, right=2, top=2, bottom=2}
    })
    addonBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    addonBox:SetBackdropBorderColor(0.5, 0.4, 0.2)
    
    local addonTitle = addonBox:CreateFontString(nil, "OVERLAY")
    addonTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    addonTitle:SetPoint("TOPLEFT", 8, -8)
    addonTitle:SetText("|cffFFAA00Addon Info|r")
    
    f.addonInfo = addonBox:CreateFontString(nil, "OVERLAY")
    f.addonInfo:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    f.addonInfo:SetPoint("TOPLEFT", addonTitle, "BOTTOMLEFT", 0, -5)
    f.addonInfo:SetWidth(155)
    f.addonInfo:SetJustifyH("LEFT")
    
    -- ═══════════════════════════════════════════════════════════
    -- LOG BEREICH
    -- ═══════════════════════════════════════════════════════════
    
    local logTitle = f:CreateFontString(nil, "OVERLAY")
    logTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    logTitle:SetPoint("TOPLEFT", deathStatsBox, "BOTTOMLEFT", 0, -10)
    logTitle:SetText("|cffFFD100" .. GDL:L("DEBUG_LOG") .. "|r")
    
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", logTitle, "BOTTOMLEFT", 0, -5)
    scroll:SetPoint("BOTTOMRIGHT", -35, 45)
    
    local logChild = CreateFrame("Frame", nil, scroll)
    logChild:SetSize(490, 1)
    scroll:SetScrollChild(logChild)
    f.logChild = logChild
    
    -- Buttons
    local clearBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    clearBtn:SetSize(80, 22)
    clearBtn:SetPoint("BOTTOMLEFT", 15, 10)
    clearBtn:SetText(GDL:L("DEBUG_CLEAR"))
    clearBtn:SetScript("OnClick", function() 
        debugLog = {} 
        self:UpdateWindow() 
    end)
    
    local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    scanBtn:SetSize(80, 22)
    scanBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    scanBtn:SetText("Rescan")
    scanBtn:SetScript("OnClick", function()
        local Deathlog = GDL:GetModule("Deathlog")
        if Deathlog then Deathlog:ScanData() end
    end)
    
    local syncBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    syncBtn:SetSize(80, 22)
    syncBtn:SetPoint("LEFT", scanBtn, "RIGHT", 5, 0)
    syncBtn:SetText("Sync")
    syncBtn:SetScript("OnClick", function()
        local Sync = GDL:GetModule("Sync")
        if Sync then 
            Sync:RequestFullSync() 
            self:Log("SYNC", "Sync angefordert", "FFAA00")
        end
    end)
    
    local pingBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    pingBtn:SetSize(80, 22)
    pingBtn:SetPoint("LEFT", syncBtn, "RIGHT", 5, 0)
    pingBtn:SetText("Test PING")
    pingBtn:SetScript("OnClick", function()
        local Sync = GDL:GetModule("Sync")
        if Sync then 
            Sync:SendPing()
            self:Log("PING", "PING gesendet - warte auf PONGs...", "00AAFF")
        end
    end)
    
    self.frame = f
    
    -- Auto-Update Ticker (alle 2 Sekunden)
    C_Timer.NewTicker(2, function() 
        if self.frame and self.frame:IsShown() then 
            self:UpdateWindow() 
        end 
    end)
    
    -- OnShow: Tode-Stats aktualisieren
    f:SetScript("OnShow", function()
        self:UpdateWindow()
        self:UpdateDeathStats()
    end)
end

-- Tode-Stats aktualisieren (zeigt Statistiken über Tode)
function Debug:UpdateDeathStats()
    if not self.frame or not self.frame.deathStatsInfo then return end
    
    local guildData = GDL:GetGuildData()
    local deaths = guildData and guildData.deaths or {}
    local totalDeaths = #deaths
    
    local text = "|cffFFFFFF" .. totalDeaths .. "|r Tode gesamt"
    
    -- Tode heute zählen
    local today = date("*t")
    local todayStart = time({year=today.year, month=today.month, day=today.day, hour=0, min=0, sec=0})
    local todayDeaths = 0
    local lastDeath = nil
    
    for _, death in ipairs(deaths) do
        if death.timestamp and death.timestamp >= todayStart then
            todayDeaths = todayDeaths + 1
        end
        if not lastDeath or (death.timestamp and death.timestamp > (lastDeath.timestamp or 0)) then
            lastDeath = death
        end
    end
    
    text = text .. "\n|cffFF8800" .. todayDeaths .. "|r heute"
    
    -- Letzter Tod
    if lastDeath then
        local ago = time() - (lastDeath.timestamp or 0)
        local agoText
        if ago < 60 then
            agoText = ago .. "s"
        elseif ago < 3600 then
            agoText = math.floor(ago/60) .. "m"
        elseif ago < 86400 then
            agoText = math.floor(ago/3600) .. "h"
        else
            agoText = math.floor(ago/86400) .. "d"
        end
        text = text .. "\n|cff888888Letzter: " .. (lastDeath.name or "?"):sub(1,10) .. " (" .. agoText .. ")|r"
    end
    
    self.frame.deathStatsInfo:SetText(text)
end

function Debug:UpdateWindow()
    if not self.frame or not self.frame:IsShown() then return end
    local f = self.frame
    
    -- ═══════════════════════════════════════════════════════════
    -- Box 1: Sync Info
    -- ═══════════════════════════════════════════════════════════
    local Sync = GDL:GetModule("Sync")
    local syncText = ""
    local onlineUsers = {}
    
    syncText = "|cff00FF00v" .. GDL.version .. "|r\n"
    
    if Sync then
        onlineUsers = Sync:GetOnlineUsers()
        syncText = syncText .. string.format(GDL:L("DEBUG_USERS"), #onlineUsers) .. "\n"
        local lastSync = Sync:GetLastSyncTime()
        if lastSync > 0 then
            local ago = time() - lastSync
            if ago < 60 then
                syncText = syncText .. string.format(GDL:L("DEBUG_LAST_SYNC"), ago .. "s")
            elseif ago < 3600 then
                syncText = syncText .. string.format(GDL:L("DEBUG_LAST_SYNC"), math.floor(ago/60) .. "m")
            else
                syncText = syncText .. string.format(GDL:L("DEBUG_LAST_SYNC"), date("%H:%M", lastSync))
            end
        else
            syncText = syncText .. string.format(GDL:L("DEBUG_LAST_SYNC"), GDL:L("DEBUG_NEVER"))
        end
    end
    f.syncInfo:SetText(syncText)
    
    -- ═══════════════════════════════════════════════════════════
    -- Box 2: Online Users
    -- ═══════════════════════════════════════════════════════════
    f.onlineCount:SetText("(" .. #onlineUsers .. ")")
    
    for _, c in ipairs({f.onlineChild:GetChildren()}) do 
        c:Hide() 
        c:SetParent(nil) 
    end
    
    local y = 0
    if #onlineUsers == 0 then
        local noUsers = f.onlineChild:CreateFontString(nil, "OVERLAY")
        noUsers:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        noUsers:SetPoint("TOPLEFT", 0, 0)
        noUsers:SetText("|cff666666(Niemand online)|r")
        y = -14
    else
        for _, user in ipairs(onlineUsers) do
            local row = CreateFrame("Frame", nil, f.onlineChild)
            row:SetSize(130, 13)
            row:SetPoint("TOPLEFT", 0, y)
            
            local text = row:CreateFontString(nil, "OVERLAY")
            text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
            text:SetPoint("LEFT")
            text:SetText("|cffAAFFAA" .. user.name .. "|r |cff888888v" .. (user.version or "?") .. "|r")
            
            y = y - 13
        end
    end
    f.onlineChild:SetHeight(math.max(math.abs(y) + 5, 40))
    
    -- ═══════════════════════════════════════════════════════════
    -- Box 3: Deathlog Info
    -- ═══════════════════════════════════════════════════════════
    local Deathlog = GDL:GetModule("Deathlog")
    local dlText = ""
    if Deathlog then
        local stats = Deathlog:GetStats()
        local foundText = stats.available and "|cff00FF00Ja|r" or "|cffFF6666Nein|r"
        dlText = string.format(GDL:L("DEBUG_FOUND"), foundText) .. "\n"
        dlText = dlText .. string.format(GDL:L("DEBUG_ENTRIES"), stats.totalEntries) .. "\n"
        dlText = dlText .. string.format(GDL:L("DEBUG_GUILD_DEATHS"), stats.guildDeaths)
    end
    local guildData = GDL:GetGuildData()
    dlText = dlText .. "\n|cffFFAA00Gesamt:|r " .. (guildData and #(guildData.deaths or {}) or 0)
    f.dlInfo:SetText(dlText)
    
    -- ═══════════════════════════════════════════════════════════
    -- Box 5: Live-Tracker Info
    -- ═══════════════════════════════════════════════════════════
    local GuildTracker = GDL:GetModule("GuildTracker")
    local trackerText = ""
    if GuildTracker then
        local trackerCount = GuildTracker:GetOnlineCount()
        local status = GuildTracker.initialized and "|cff00FF00Aktiv|r" or "|cffFF6666Inaktiv|r"
        trackerText = "Status: " .. status .. "\n"
        trackerText = trackerText .. "Auf Karte: |cff00FFFF" .. trackerCount .. "|r\n"
        trackerText = trackerText .. "Sync: |cff00FF00Aktiv|r"
    else
        trackerText = "|cffFF6666Nicht geladen|r"
    end
    f.trackerInfo:SetText(trackerText)
    
    -- ═══════════════════════════════════════════════════════════
    -- Box 6: Addon Info
    -- ═══════════════════════════════════════════════════════════
    local addonText = ""
    local mem = GetAddOnMemoryUsage("GuildDeathLog")
    addonText = "Memory: |cffFFFFFF" .. string.format("%.1f", mem) .. " KB|r\n"
    -- Module zaehlen
    local moduleCount = 0
    if GDL.modules then
        for _ in pairs(GDL.modules) do
            moduleCount = moduleCount + 1
        end
    end
    addonText = addonText .. "Module: |cffFFFFFF" .. moduleCount .. "|r\n"
    local uptime = GetTime()
    local mins = math.floor(uptime / 60)
    local hrs = math.floor(mins / 60)
    mins = mins % 60
    addonText = addonText .. "Uptime: |cffFFFFFF" .. hrs .. "h " .. mins .. "m|r"
    f.addonInfo:SetText(addonText)
    
    -- ═══════════════════════════════════════════════════════════
    -- Log aktualisieren
    -- ═══════════════════════════════════════════════════════════
    for _, c in ipairs({f.logChild:GetChildren()}) do 
        c:Hide() 
        c:SetParent(nil) 
    end
    
    local logY = 0
    for i, entry in ipairs(debugLog) do
        if i > 50 then break end
        local row = CreateFrame("Frame", nil, f.logChild)
        row:SetSize(490, 14)
        row:SetPoint("TOPLEFT", 0, logY)
        
        local text = row:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        text:SetPoint("LEFT")
        text:SetWidth(490)
        text:SetText(string.format("|cff666666%s|r |cff%s[%s]|r %s", 
            entry.time, entry.color, entry.category, entry.message))
        logY = logY - 14
    end
    f.logChild:SetHeight(math.max(math.abs(logY) + 10, 100))
end

GDL:RegisterModule("Debug", Debug)
