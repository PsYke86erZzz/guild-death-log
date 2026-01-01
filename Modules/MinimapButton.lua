-- ══════════════════════════════════════════════════════════════
-- MODUL: MinimapButton - Schnellzugriff auf das Buch
-- Frei beweglich, sauberes Design
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local MinimapButton = {}

local button = nil

function MinimapButton:Initialize()
    self:CreateButton()
end

function MinimapButton:CreateButton()
    local btn = CreateFrame("Button", "GDLMinimapButton", UIParent, "BackdropTemplate")
    btn:SetSize(28, 28)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(100)
    btn:EnableMouse(true)
    btn:SetMovable(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetClampedToScreen(true)
    
    -- Position laden oder Standard (neben Minimap)
    local pos = GuildDeathLogDB.settings.buttonPosition
    if pos and pos.point then
        btn:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        btn:SetPoint("TOPRIGHT", Minimap, "TOPLEFT", -5, 0)
    end
    
    -- Sauberer dunkler Hintergrund
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    btn:SetBackdropColor(0.1, 0.08, 0.05, 0.9)
    btn:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
    
    -- Totenkopf Icon (sauber, zentriert)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8")
    btn.icon = icon
    
    -- Hover-Effekt
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
        icon:SetAlpha(1)
        
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("|cffFFD100Das Buch der Gefallenen|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffAAAAAALinksklick:|r Buch oeffnen", 1, 1, 1)
        GameTooltip:AddLine("|cffAAAAAAShift+Links:|r Sync", 1, 1, 1)
        GameTooltip:AddLine("|cffAAAAAARechtsklick:|r Einstellungen", 1, 1, 1)
        GameTooltip:AddLine("|cffAAAAAAZiehen:|r Verschieben", 1, 1, 1)
        
        local guildData = GDL:GetGuildData()
        if guildData and guildData.deaths and #guildData.deaths > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFF6666" .. #guildData.deaths .. " Gefallene|r", 1, 1, 1)
        end
        
        GameTooltip:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.4, 0.35, 0.25, 1)
        icon:SetAlpha(0.85)
        GameTooltip:Hide()
    end)
    
    -- Klick-Handler
    btn:SetScript("OnClick", function(self, mouseBtn)
        if mouseBtn == "LeftButton" then
            if IsShiftKeyDown() then
                local Sync = GDL:GetModule("Sync")
                if Sync then Sync:RequestFullSync() end
            else
                local UI = GDL:GetModule("UI")
                if UI then
                    if UI.mainFrame and UI.mainFrame:IsShown() then
                        UI:HideBook()
                    else
                        UI:ShowBook()
                    end
                end
            end
        elseif mouseBtn == "RightButton" then
            local UI = GDL:GetModule("UI")
            if UI then UI:ShowSettings() end
        end
    end)
    
    -- Frei beweglich
    btn:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    
    btn:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        GuildDeathLogDB.settings.buttonPosition = {
            point = point,
            relPoint = relPoint,
            x = x,
            y = y
        }
    end)
    
    icon:SetAlpha(0.85)
    button = btn
end

function MinimapButton:Show()
    if button then button:Show() end
end

function MinimapButton:Hide()
    if button then button:Hide() end
end

GDL:RegisterModule("MinimapButton", MinimapButton)
