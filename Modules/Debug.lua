-- ══════════════════════════════════════════════════════════════
-- MODUL: Debug - Debug-Fenster und Logging
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Debug = {}

local debugLog = {}

function Debug:Initialize()
    -- Nix spezielles nötig
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
end

function Debug:CreateWindow()
    local f = CreateFrame("Frame", "GDLDebugFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(560, 480)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -350)  -- Unten-mitte (cascade)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(150)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    f.TitleText:SetText(GDL:L("DEBUG_TITLE"))
    
    -- Sync Status Box (kleiner, nur Text)
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
    
    -- ONLINE USER BOX mit Scroll!
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
    
    -- Scroll fuer Online-Liste
    local onlineScroll = CreateFrame("ScrollFrame", nil, onlineBox, "UIPanelScrollFrameTemplate")
    onlineScroll:SetPoint("TOPLEFT", 8, -24)
    onlineScroll:SetPoint("BOTTOMRIGHT", -28, 6)
    
    local onlineChild = CreateFrame("Frame", nil, onlineScroll)
    onlineChild:SetSize(130, 1)
    onlineScroll:SetScrollChild(onlineChild)
    f.onlineChild = onlineChild
    
    -- Deathlog Status Box
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
    
    -- Log Title
    local logTitle = f:CreateFontString(nil, "OVERLAY")
    logTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    logTitle:SetPoint("TOPLEFT", syncBox, "BOTTOMLEFT", 0, -10)
    logTitle:SetText("|cffFFD100" .. GDL:L("DEBUG_LOG") .. "|r")
    
    -- Scroll Frame fuer Log
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
    
    -- Test PING Button
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
    
    -- Auto-Update Ticker
    C_Timer.NewTicker(2, function() 
        if self.frame and self.frame:IsShown() then 
            self:UpdateWindow() 
        end 
    end)
end

function Debug:UpdateWindow()
    if not self.frame or not self.frame:IsShown() then return end
    local f = self.frame
    
    -- Sync Info (mit eigener Version!)
    local Sync = GDL:GetModule("Sync")
    local syncText = ""
    local onlineUsers = {}
    
    -- EIGENE VERSION anzeigen
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
    
    -- Online User Liste (scrollbar)
    f.onlineCount:SetText("(" .. #onlineUsers .. ")")
    
    -- Clear old entries
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
    
    -- Deathlog Info
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
    
    -- Log aktualisieren
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
