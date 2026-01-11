-- ══════════════════════════════════════════════════════════════
-- MODUL: MinimapButton - Buch-Icon für schnellen Zugriff
-- Frei beweglich, neues schönes Buch-Design
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local MinimapButton = {}

local button = nil

function MinimapButton:Initialize()
    self:CreateButton()
end

function MinimapButton:CreateButton()
    local btn = CreateFrame("Button", "GDLMinimapButton", UIParent)
    btn:SetSize(36, 36)
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
    
    -- Buch-Icon als Haupttextur
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\AddOns\\GuildDeathLog\\Textures\\MinimapIcon")
    btn.icon = icon
    
    -- Dezenter Highlight-Rand beim Hover
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 0.8, 0.4, 0.2)
    
    -- Hover-Effekt
    btn:SetScript("OnEnter", function(self)
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
        icon:SetAlpha(0.9)
        GameTooltip:Hide()
    end)
    
    -- Klick-Handler
    btn:SetScript("OnClick", function(self, mouseBtn)
        if mouseBtn == "LeftButton" then
            if IsShiftKeyDown() then
                local Sync = GDL:GetModule("Sync")
                if Sync then Sync:RequestFullSync() end
            else
                -- BookUI verwenden statt altes UI
                local BookUI = _G["GDLBookUI"]
                if BookUI then
                    BookUI:Toggle()
                else
                    -- Fallback auf altes UI
                    local UI = GDL:GetModule("UI")
                    if UI then
                        if UI.mainFrame and UI.mainFrame:IsShown() then
                            UI:HideBook()
                        else
                            UI:ShowBook()
                        end
                    end
                end
            end
        elseif mouseBtn == "RightButton" then
            -- Rechtsklick: Settings-Kapitel öffnen
            local BookUI = _G["GDLBookUI"]
            if BookUI then
                BookUI:Show()
                BookUI:LoadChapter(9)  -- Settings ist Kapitel 9
            end
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
    
    icon:SetAlpha(0.9)
    button = btn
end

function MinimapButton:Show()
    if button then button:Show() end
end

function MinimapButton:Hide()
    if button then button:Hide() end
end

GDL:RegisterModule("MinimapButton", MinimapButton)

-- Auto-Initialize
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            MinimapButton:Initialize()
        end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
