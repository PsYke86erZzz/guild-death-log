-- ══════════════════════════════════════════════════════════════
-- MODUL: Calendar v2.0 - Gilden-Kalender für Events
-- Mit Teilnahme-System (Ja/Nein/Vielleicht)
-- Sync über Addon-Channel, Quest-Log Style Design
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Calendar = {}

local CALENDAR_PREFIX = "GDLCal"
local locale = GetLocale()

-- ══════════════════════════════════════════════════════════════
-- LOKALISIERUNG
-- ══════════════════════════════════════════════════════════════

local L = {
    TITLE = locale == "deDE" and "Gilden-Kalender" or "Guild Calendar",
    ADD_EVENT = locale == "deDE" and "+ Neues Event" or "+ New Event",
    DELETE = locale == "deDE" and "Loeschen" or "Delete",
    DATE = locale == "deDE" and "Datum" or "Date",
    TIME = locale == "deDE" and "Uhrzeit" or "Time",
    EVENT_NAME = locale == "deDE" and "Event-Name" or "Event Name",
    DESCRIPTION = locale == "deDE" and "Beschreibung" or "Description",
    CREATED_BY = locale == "deDE" and "von" or "by",
    NO_EVENTS = locale == "deDE" and "Keine Events geplant.\n\nKlicke unten auf '+ Neues Event'\num ein Event zu erstellen!" or "No events scheduled.\n\nClick '+ New Event' below\nto create an event!",
    TODAY = locale == "deDE" and "HEUTE" or "TODAY",
    TOMORROW = locale == "deDE" and "MORGEN" or "TOMORROW",
    UPCOMING = locale == "deDE" and "Kommende Events" or "Upcoming Events",
    PAST = locale == "deDE" and "Vergangene Events" or "Past Events",
    SAVE = locale == "deDE" and "Speichern" or "Save",
    CANCEL = locale == "deDE" and "Abbrechen" or "Cancel",
    EVENT_ADDED = locale == "deDE" and "Event hinzugefuegt!" or "Event added!",
    EVENT_DELETED = locale == "deDE" and "Event geloescht!" or "Event deleted!",
    ATTENDING = locale == "deDE" and "Zusagen" or "Attending",
    NOT_ATTENDING = locale == "deDE" and "Absagen" or "Declined",
    MAYBE = locale == "deDE" and "Vielleicht" or "Maybe",
    YES = locale == "deDE" and "Ja" or "Yes",
    NO = locale == "deDE" and "Nein" or "No",
    WEEKDAYS = locale == "deDE" 
        and {"So", "Mo", "Di", "Mi", "Do", "Fr", "Sa"}
        or {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"},
    MONTHS = locale == "deDE"
        and {"Januar", "Februar", "Maerz", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"}
        or {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"},
}

-- Event-Typen mit passenden Icons und Farben
local EVENT_TYPES = {
    {id = "raid", name = locale == "deDE" and "Raid" or "Raid", icon = "Interface\\Icons\\INV_Helmet_06", color = {1, 0.5, 0}},
    {id = "dungeon", name = locale == "deDE" and "Dungeon" or "Dungeon", icon = "Interface\\Icons\\INV_Misc_Key_04", color = {0.4, 0.7, 1}},
    {id = "pvp", name = locale == "deDE" and "PvP" or "PvP", icon = "Interface\\Icons\\INV_Sword_04", color = {1, 0.2, 0.2}},
    {id = "social", name = locale == "deDE" and "Treffen" or "Meeting", icon = "Interface\\Icons\\INV_Drink_13", color = {0.4, 1, 0.4}},
    {id = "other", name = locale == "deDE" and "Sonstiges" or "Other", icon = "Interface\\Icons\\INV_Misc_Rune_01", color = {0.7, 0.7, 0.7}},
}

-- ══════════════════════════════════════════════════════════════
-- INITIALISIERUNG
-- ══════════════════════════════════════════════════════════════

function Calendar:Initialize()
    GuildDeathLogDB.calendar = GuildDeathLogDB.calendar or {
        events = {},
        lastSync = 0,
    }
    
    C_ChatInfo.RegisterAddonMessagePrefix(CALENDAR_PREFIX)
    
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:SetScript("OnEvent", function(_, event, prefix, message, channel, sender)
        if event == "CHAT_MSG_ADDON" and prefix == CALENDAR_PREFIX and channel == "GUILD" then
            self:HandleAddonMessage(message, sender)
        end
    end)
    
    C_Timer.After(10, function()
        if IsInGuild() then
            self:RequestEvents()
        end
    end)
    
    GDL:Debug("Calendar: Initialisiert")
end

-- ══════════════════════════════════════════════════════════════
-- DATEN-MANAGEMENT
-- ══════════════════════════════════════════════════════════════

function Calendar:GetEvents()
    return GuildDeathLogDB.calendar.events or {}
end

function Calendar:AddEvent(eventData)
    eventData.id = eventData.id or (time() .. "-" .. math.random(10000, 99999))
    eventData.createdBy = eventData.createdBy or UnitName("player")
    eventData.createdAt = eventData.createdAt or time()
    eventData.responses = eventData.responses or {}
    
    table.insert(GuildDeathLogDB.calendar.events, eventData)
    self:SortEvents()
    self:BroadcastEvent(eventData, "ADD")
    
    GDL:Print("|cff00FF00" .. L.EVENT_ADDED .. "|r")
    
    if self.frame and self.frame:IsShown() then
        self:UpdateEventList()
    end
    
    return eventData.id
end

function Calendar:DeleteEvent(eventId)
    local events = GuildDeathLogDB.calendar.events
    for i, event in ipairs(events) do
        if event.id == eventId then
            local myName = UnitName("player")
            if event.createdBy == myName or GDL:IsAdmin() then
                table.remove(events, i)
                self:BroadcastEvent({id = eventId}, "DELETE")
                GDL:Print("|cffFF6666" .. L.EVENT_DELETED .. "|r")
                
                if self.frame and self.frame:IsShown() then
                    self:UpdateEventList()
                end
                return true
            end
        end
    end
    return false
end

function Calendar:RespondToEvent(eventId, response)
    local myName = UnitName("player")
    for _, event in ipairs(GuildDeathLogDB.calendar.events) do
        if event.id == eventId then
            event.responses = event.responses or {}
            event.responses[myName] = response
            self:BroadcastResponse(eventId, myName, response)
            
            if self.frame and self.frame:IsShown() then
                self:UpdateEventList()
            end
            return true
        end
    end
    return false
end

function Calendar:GetMyResponse(eventId)
    local myName = UnitName("player")
    for _, event in ipairs(GuildDeathLogDB.calendar.events) do
        if event.id == eventId then
            return event.responses and event.responses[myName]
        end
    end
    return nil
end

function Calendar:GetResponseCounts(event)
    local counts = {yes = {}, no = {}, maybe = {}}
    if event.responses then
        for name, response in pairs(event.responses) do
            if response == "yes" then
                table.insert(counts.yes, name)
            elseif response == "no" then
                table.insert(counts.no, name)
            elseif response == "maybe" then
                table.insert(counts.maybe, name)
            end
        end
    end
    return counts
end

function Calendar:SortEvents()
    table.sort(GuildDeathLogDB.calendar.events, function(a, b)
        return (a.timestamp or 0) < (b.timestamp or 0)
    end)
end

function Calendar:GetUpcomingEvents()
    local now = time()
    local upcoming = {}
    for _, event in ipairs(self:GetEvents()) do
        if (event.timestamp or 0) >= now then
            table.insert(upcoming, event)
        end
    end
    return upcoming
end

function Calendar:GetPastEvents()
    local now = time()
    local past = {}
    for _, event in ipairs(self:GetEvents()) do
        if (event.timestamp or 0) < now then
            table.insert(past, event)
        end
    end
    table.sort(past, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)
    return past
end

-- ══════════════════════════════════════════════════════════════
-- SYNC ÜBER ADDON-CHANNEL
-- ══════════════════════════════════════════════════════════════

function Calendar:BroadcastEvent(eventData, action)
    if not IsInGuild() then return end
    local data = action .. "|" .. self:SerializeEvent(eventData)
    C_ChatInfo.SendAddonMessage(CALENDAR_PREFIX, data, "GUILD")
end

function Calendar:BroadcastResponse(eventId, playerName, response)
    if not IsInGuild() then return end
    local data = string.format("RESP|%s|%s|%s", eventId, playerName, response)
    C_ChatInfo.SendAddonMessage(CALENDAR_PREFIX, data, "GUILD")
end

function Calendar:RequestEvents()
    if not IsInGuild() then return end
    C_ChatInfo.SendAddonMessage(CALENDAR_PREFIX, "REQUEST", "GUILD")
end

function Calendar:SerializeEvent(event)
    local respStr = ""
    if event.responses then
        local parts = {}
        for name, resp in pairs(event.responses) do
            table.insert(parts, name .. ":" .. resp)
        end
        respStr = table.concat(parts, ",")
    end
    
    return string.format("%s;%d;%s;%s;%s;%s;%d;%s",
        event.id or "",
        event.timestamp or 0,
        event.eventType or "other",
        (event.name or ""):gsub(";", ","),
        (event.description or ""):gsub(";", ","),
        event.createdBy or "",
        event.createdAt or 0,
        respStr
    )
end

function Calendar:DeserializeEvent(data)
    local parts = {strsplit(";", data)}
    if #parts < 7 then return nil end
    
    local event = {
        id = parts[1],
        timestamp = tonumber(parts[2]) or 0,
        eventType = parts[3],
        name = parts[4],
        description = parts[5],
        createdBy = parts[6],
        createdAt = tonumber(parts[7]) or 0,
        responses = {},
    }
    
    if parts[8] and parts[8] ~= "" then
        for _, pair in ipairs({strsplit(",", parts[8])}) do
            local name, resp = strsplit(":", pair)
            if name and resp then
                event.responses[name] = resp
            end
        end
    end
    
    return event
end

function Calendar:HandleAddonMessage(message, sender)
    local senderName = strsplit("-", sender)
    local myName = UnitName("player")
    
    if senderName == myName and not message:match("^REQUEST") then return end
    
    local action, data = strsplit("|", message, 2)
    
    if action == "REQUEST" then
        C_Timer.After(math.random() * 3, function()
            for _, event in ipairs(self:GetEvents()) do
                local msg = "SYNC|" .. self:SerializeEvent(event)
                C_ChatInfo.SendAddonMessage(CALENDAR_PREFIX, msg, "GUILD")
            end
        end)
        
    elseif action == "ADD" or action == "SYNC" then
        local event = self:DeserializeEvent(data)
        if event and event.id then
            local found = false
            for i, e in ipairs(GuildDeathLogDB.calendar.events) do
                if e.id == event.id then
                    GuildDeathLogDB.calendar.events[i] = event
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(GuildDeathLogDB.calendar.events, event)
                self:SortEvents()
            end
            
            if self.frame and self.frame:IsShown() then
                self:UpdateEventList()
            end
        end
        
    elseif action == "DELETE" then
        local eventId = data
        for i, e in ipairs(GuildDeathLogDB.calendar.events) do
            if e.id == eventId then
                table.remove(GuildDeathLogDB.calendar.events, i)
                if self.frame and self.frame:IsShown() then
                    self:UpdateEventList()
                end
                break
            end
        end
        
    elseif action == "RESP" then
        local eventId, playerName, response = strsplit("|", data)
        for _, e in ipairs(GuildDeathLogDB.calendar.events) do
            if e.id == eventId then
                e.responses = e.responses or {}
                e.responses[playerName] = response
                if self.frame and self.frame:IsShown() then
                    self:UpdateEventList()
                end
                break
            end
        end
    end
end

-- ══════════════════════════════════════════════════════════════
-- UI - KALENDER-FENSTER
-- ══════════════════════════════════════════════════════════════

function Calendar:CreateFrame()
    if self.frame then return self.frame end
    
    local f = CreateFrame("Frame", "GDLCalendar", UIParent, "BackdropTemplate")
    f:SetSize(420, 500)
    f:SetPoint("CENTER", 200, 0)  -- Versetzt nach rechts um Überlappung zu vermeiden
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetScript("OnMouseDown", function(self) self:Raise() end)
    f:Hide()
    
    -- Schatten
    local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
    shadow:SetPoint("TOPLEFT", -5, 5)
    shadow:SetPoint("BOTTOMRIGHT", 5, -5)
    shadow:SetFrameLevel(f:GetFrameLevel() - 1)
    shadow:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
    shadow:SetBackdropColor(0, 0, 0, 0.5)
    
    -- Hintergrund - Quest-Log Style
    f:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 26,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    f:SetBackdropColor(1, 1, 1, 1)
    f:SetBackdropBorderColor(0.7, 0.6, 0.4, 1)
    
    -- Titel (dunkle Farbe für Lesbarkeit)
    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 22, "")
    title:SetPoint("TOP", 0, -18)
    title:SetText("|cff3a2510" .. L.TITLE .. "|r")
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)
    
    -- Event-Liste ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", "GDLCalendarScroll", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 55)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(350, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    f.scrollChild = scrollChild
    f.eventButtons = {}
    
    -- Add Event Button (unten, schön positioniert)
    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    addBtn:SetSize(160, 28)
    addBtn:SetPoint("BOTTOM", 0, 18)
    addBtn:SetText(L.ADD_EVENT)
    addBtn:SetScript("OnClick", function()
        self:ShowAddEventDialog()
    end)
    
    self.frame = f
    return f
end

function Calendar:Show()
    if not self.frame then
        self:CreateFrame()
    end
    self:UpdateEventList()
    self.frame:Show()
end

function Calendar:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Calendar:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- ══════════════════════════════════════════════════════════════
-- EVENT-LISTE ANZEIGEN
-- ══════════════════════════════════════════════════════════════

function Calendar:UpdateEventList()
    if not self.frame then return end
    
    local scrollChild = self.frame.scrollChild
    
    for _, btn in pairs(self.frame.eventButtons) do
        btn:Hide()
        btn:SetParent(nil)
    end
    self.frame.eventButtons = {}
    
    local y = 0
    local now = time()
    local today = date("*t")
    today.hour, today.min, today.sec = 0, 0, 0
    local todayStart = time(today)
    local tomorrowStart = todayStart + 86400
    
    local upcoming = self:GetUpcomingEvents()
    local past = self:GetPastEvents()
    
    -- Kommende Events Header
    if #upcoming > 0 then
        local header = scrollChild:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\MORPHEUS.TTF", 15, "")
        header:SetPoint("TOPLEFT", 5, y)
        header:SetText("|cff3a2510" .. L.UPCOMING .. "|r")
        table.insert(self.frame.eventButtons, header)
        y = y - 22
        
        for _, event in ipairs(upcoming) do
            local btn = self:CreateEventButton(scrollChild, event, y)
            y = y - btn:GetHeight() - 8
        end
    end
    
    -- Vergangene Events Header
    if #past > 0 then
        y = y - 15
        local header = scrollChild:CreateFontString(nil, "OVERLAY")
        header:SetFont("Fonts\\MORPHEUS.TTF", 13, "")
        header:SetPoint("TOPLEFT", 5, y)
        header:SetText("|cff666666" .. L.PAST .. "|r")
        table.insert(self.frame.eventButtons, header)
        y = y - 20
        
        for i, event in ipairs(past) do
            if i > 3 then break end
            local btn = self:CreateEventButton(scrollChild, event, y, true)
            y = y - btn:GetHeight() - 5
        end
    end
    
    -- Keine Events
    if #upcoming == 0 and #past == 0 then
        local noEvents = scrollChild:CreateFontString(nil, "OVERLAY")
        noEvents:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        noEvents:SetPoint("TOP", 0, -60)
        noEvents:SetText("|cff5a4530" .. L.NO_EVENTS .. "|r")
        noEvents:SetJustifyH("CENTER")
        table.insert(self.frame.eventButtons, noEvents)
    end
    
    scrollChild:SetHeight(math.abs(y) + 20)
end

function Calendar:CreateEventButton(parent, event, yOffset, isPast)
    local btn = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    btn:SetSize(350, 85)
    btn:SetPoint("TOPLEFT", 0, yOffset)
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    
    -- Event-Typ Farbe
    local eventTypeData = nil
    for _, et in ipairs(EVENT_TYPES) do
        if et.id == event.eventType then
            eventTypeData = et
            break
        end
    end
    eventTypeData = eventTypeData or EVENT_TYPES[5]
    
    local col = eventTypeData.color
    if isPast then
        btn:SetBackdropColor(0.25, 0.25, 0.25, 0.8)
        btn:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.5)
    else
        btn:SetBackdropColor(col[1] * 0.15, col[2] * 0.15, col[3] * 0.15, 0.9)
        btn:SetBackdropBorderColor(col[1] * 0.8, col[2] * 0.8, col[3] * 0.8, 0.8)
    end
    
    -- Icon
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", 8, -8)
    icon:SetTexture(eventTypeData.icon)
    
    -- Event-Name (dunkle Farbe!)
    local nameText = btn:CreateFontString(nil, "OVERLAY")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, 0)
    nameText:SetWidth(220)
    nameText:SetJustifyH("LEFT")
    if isPast then
        nameText:SetText("|cff666666" .. (event.name or "?") .. "|r")
    else
        nameText:SetText("|cffEEDDCC" .. (event.name or "?") .. "|r")
    end
    
    -- Datum & Uhrzeit
    local dateText = btn:CreateFontString(nil, "OVERLAY")
    dateText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    dateText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    
    local eventDate = date("*t", event.timestamp or 0)
    local dateStr = string.format("%02d.%02d.%04d  %02d:%02d Uhr", 
        eventDate.day, eventDate.month, eventDate.year,
        eventDate.hour, eventDate.min)
    
    -- Heute/Morgen Marker
    local today = date("*t")
    today.hour, today.min, today.sec = 0, 0, 0
    local todayStart = time(today)
    
    local prefix = ""
    if event.timestamp >= todayStart and event.timestamp < todayStart + 86400 then
        prefix = "|cff00FF00" .. L.TODAY .. "|r  "
    elseif event.timestamp >= todayStart + 86400 and event.timestamp < todayStart + 172800 then
        prefix = "|cffFFFF00" .. L.TOMORROW .. "|r  "
    end
    
    dateText:SetText("|cffAA9988" .. prefix .. dateStr .. "|r")
    
    -- Erstellt von
    local createdText = btn:CreateFontString(nil, "OVERLAY")
    createdText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    createdText:SetPoint("TOPLEFT", dateText, "BOTTOMLEFT", 0, -2)
    createdText:SetText("|cff888877" .. L.CREATED_BY .. " " .. (event.createdBy or "?") .. "|r")
    
    -- Response Buttons (nur für kommende Events)
    if not isPast then
        local myResponse = self:GetMyResponse(event.id)
        local btnY = -50
        local btnX = 50
        
        -- Ja Button
        local yesBtn = CreateFrame("Button", nil, btn)
        yesBtn:SetSize(50, 20)
        yesBtn:SetPoint("TOPLEFT", btnX, btnY)
        
        local yesBg = yesBtn:CreateTexture(nil, "BACKGROUND")
        yesBg:SetAllPoints()
        yesBg:SetColorTexture(0, 0.5, 0, myResponse == "yes" and 0.8 or 0.3)
        yesBtn.bg = yesBg
        
        local yesText = yesBtn:CreateFontString(nil, "OVERLAY")
        yesText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        yesText:SetPoint("CENTER")
        yesText:SetText("|cffFFFFFF" .. L.YES .. "|r")
        
        yesBtn:SetScript("OnClick", function()
            self:RespondToEvent(event.id, "yes")
        end)
        yesBtn:SetScript("OnEnter", function(self)
            yesBg:SetColorTexture(0, 0.7, 0, 0.8)
        end)
        yesBtn:SetScript("OnLeave", function(self)
            local resp = Calendar:GetMyResponse(event.id)
            yesBg:SetColorTexture(0, 0.5, 0, resp == "yes" and 0.8 or 0.3)
        end)
        
        -- Vielleicht Button
        local maybeBtn = CreateFrame("Button", nil, btn)
        maybeBtn:SetSize(70, 20)
        maybeBtn:SetPoint("LEFT", yesBtn, "RIGHT", 5, 0)
        
        local maybeBg = maybeBtn:CreateTexture(nil, "BACKGROUND")
        maybeBg:SetAllPoints()
        maybeBg:SetColorTexture(0.6, 0.6, 0, myResponse == "maybe" and 0.8 or 0.3)
        maybeBtn.bg = maybeBg
        
        local maybeText = maybeBtn:CreateFontString(nil, "OVERLAY")
        maybeText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        maybeText:SetPoint("CENTER")
        maybeText:SetText("|cffFFFFFF?|r")
        
        maybeBtn:SetScript("OnClick", function()
            self:RespondToEvent(event.id, "maybe")
        end)
        maybeBtn:SetScript("OnEnter", function(self)
            maybeBg:SetColorTexture(0.8, 0.8, 0, 0.8)
        end)
        maybeBtn:SetScript("OnLeave", function(self)
            local resp = Calendar:GetMyResponse(event.id)
            maybeBg:SetColorTexture(0.6, 0.6, 0, resp == "maybe" and 0.8 or 0.3)
        end)
        
        -- Nein Button
        local noBtn = CreateFrame("Button", nil, btn)
        noBtn:SetSize(50, 20)
        noBtn:SetPoint("LEFT", maybeBtn, "RIGHT", 5, 0)
        
        local noBg = noBtn:CreateTexture(nil, "BACKGROUND")
        noBg:SetAllPoints()
        noBg:SetColorTexture(0.5, 0, 0, myResponse == "no" and 0.8 or 0.3)
        noBtn.bg = noBg
        
        local noText = noBtn:CreateFontString(nil, "OVERLAY")
        noText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        noText:SetPoint("CENTER")
        noText:SetText("|cffFFFFFF" .. L.NO .. "|r")
        
        noBtn:SetScript("OnClick", function()
            self:RespondToEvent(event.id, "no")
        end)
        noBtn:SetScript("OnEnter", function(self)
            noBg:SetColorTexture(0.7, 0, 0, 0.8)
        end)
        noBtn:SetScript("OnLeave", function(self)
            local resp = Calendar:GetMyResponse(event.id)
            noBg:SetColorTexture(0.5, 0, 0, resp == "no" and 0.8 or 0.3)
        end)
        
        -- Response Counter
        local counts = self:GetResponseCounts(event)
        local countText = btn:CreateFontString(nil, "OVERLAY")
        countText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        countText:SetPoint("LEFT", noBtn, "RIGHT", 10, 0)
        countText:SetText(string.format("|cff00FF00%d|r / |cffFFFF00%d|r / |cffFF6666%d|r", 
            #counts.yes, #counts.maybe, #counts.no))
    end
    
    -- Delete Button
    local myName = UnitName("player")
    if event.createdBy == myName or GDL:IsAdmin() then
        local delBtn = CreateFrame("Button", nil, btn)
        delBtn:SetSize(16, 16)
        delBtn:SetPoint("TOPRIGHT", -5, -5)
        delBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        delBtn:SetHighlightTexture("Interface\\Buttons\\UI-StopButton")
        delBtn:GetHighlightTexture():SetVertexColor(1, 0, 0, 0.5)
        delBtn:SetAlpha(0.4)
        delBtn:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
        delBtn:SetScript("OnLeave", function(self) self:SetAlpha(0.4) end)
        delBtn:SetScript("OnClick", function()
            self:DeleteEvent(event.id)
        end)
    end
    
    -- Tooltip bei Hover (zeigt Teilnehmer)
    btn:EnableMouse(true)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(event.name or "Event", 1, 1, 1)
        
        if event.description and event.description ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(event.description, 0.8, 0.8, 0.7, true)
        end
        
        local counts = Calendar:GetResponseCounts(event)
        
        if #counts.yes > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff00FF00" .. L.ATTENDING .. ":|r", 0, 1, 0)
            for _, name in ipairs(counts.yes) do
                GameTooltip:AddLine("  " .. name, 0.7, 1, 0.7)
            end
        end
        
        if #counts.maybe > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFFFF00" .. L.MAYBE .. ":|r", 1, 1, 0)
            for _, name in ipairs(counts.maybe) do
                GameTooltip:AddLine("  " .. name, 1, 1, 0.7)
            end
        end
        
        if #counts.no > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cffFF6666" .. L.NOT_ATTENDING .. ":|r", 1, 0.4, 0.4)
            for _, name in ipairs(counts.no) do
                GameTooltip:AddLine("  " .. name, 1, 0.7, 0.7)
            end
        end
        
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    table.insert(self.frame.eventButtons, btn)
    return btn
end

-- ══════════════════════════════════════════════════════════════
-- EVENT HINZUFÜGEN DIALOG
-- ══════════════════════════════════════════════════════════════

function Calendar:ShowAddEventDialog()
    if self.addDialog then
        self.addDialog:Show()
        return
    end
    
    local d = CreateFrame("Frame", "GDLCalendarAdd", UIParent, "BackdropTemplate")
    d:SetSize(320, 300)
    d:SetPoint("CENTER", 0, 50)
    d:SetFrameStrata("DIALOG")
    d:SetFrameLevel(150)
    d:SetMovable(true)
    d:EnableMouse(true)
    d:RegisterForDrag("LeftButton")
    d:SetScript("OnDragStart", d.StartMoving)
    d:SetScript("OnDragStop", d.StopMovingOrSizing)
    
    d:SetBackdrop({
        bgFile = "Interface\\ACHIEVEMENTFRAME\\UI-Achievement-Parchment-Horizontal",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        edgeSize = 22,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    d:SetBackdropColor(1, 1, 1, 1)
    d:SetBackdropBorderColor(0.6, 0.5, 0.3, 1)
    
    -- Titel
    local title = d:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\MORPHEUS.TTF", 18, "")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cff3a2510" .. L.ADD_EVENT .. "|r")
    
    -- Close
    local closeBtn = CreateFrame("Button", nil, d, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    
    local y = -45
    
    -- Event-Typ Dropdown
    local typeLabel = d:CreateFontString(nil, "OVERLAY")
    typeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    typeLabel:SetPoint("TOPLEFT", 20, y)
    typeLabel:SetText("|cff4a3520Typ:|r")
    
    local selectedType = 1
    local typeButtons = {}
    local typeX = 55
    for i, et in ipairs(EVENT_TYPES) do
        local btn = CreateFrame("Button", nil, d)
        btn:SetSize(32, 32)
        btn:SetPoint("TOPLEFT", typeX, y + 8)
        
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(et.icon)
        
        local selected = btn:CreateTexture(nil, "OVERLAY")
        selected:SetSize(36, 36)
        selected:SetPoint("CENTER")
        selected:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        selected:SetBlendMode("ADD")
        selected:SetVertexColor(et.color[1], et.color[2], et.color[3])
        selected:Hide()
        btn.selected = selected
        
        btn:SetScript("OnClick", function()
            selectedType = i
            for _, b in ipairs(typeButtons) do
                b.selected:Hide()
            end
            selected:Show()
        end)
        
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(et.name)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        if i == 1 then selected:Show() end
        
        table.insert(typeButtons, btn)
        typeX = typeX + 40
    end
    
    y = y - 45
    
    -- Event Name
    local nameLabel = d:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    nameLabel:SetPoint("TOPLEFT", 20, y)
    nameLabel:SetText("|cff4a3520" .. L.EVENT_NAME .. ":|r")
    
    y = y - 18
    local nameInput = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    nameInput:SetSize(270, 22)
    nameInput:SetPoint("TOPLEFT", 25, y)
    nameInput:SetAutoFocus(false)
    nameInput:SetMaxLetters(50)
    
    y = y - 32
    
    -- Datum
    local dateLabel = d:CreateFontString(nil, "OVERLAY")
    dateLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    dateLabel:SetPoint("TOPLEFT", 20, y)
    dateLabel:SetText("|cff4a3520" .. L.DATE .. " (TT.MM.JJJJ):|r")
    
    y = y - 18
    local dateInput = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    dateInput:SetSize(90, 22)
    dateInput:SetPoint("TOPLEFT", 25, y)
    dateInput:SetAutoFocus(false)
    dateInput:SetMaxLetters(10)
    dateInput:SetText(date("%d.%m.%Y"))
    
    -- Uhrzeit
    local timeLabel = d:CreateFontString(nil, "OVERLAY")
    timeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    timeLabel:SetPoint("TOPLEFT", 140, y + 18)
    timeLabel:SetText("|cff4a3520" .. L.TIME .. ":|r")
    
    local timeInput = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    timeInput:SetSize(55, 22)
    timeInput:SetPoint("TOPLEFT", 145, y)
    timeInput:SetAutoFocus(false)
    timeInput:SetMaxLetters(5)
    timeInput:SetText("20:00")
    
    y = y - 32
    
    -- Beschreibung
    local descLabel = d:CreateFontString(nil, "OVERLAY")
    descLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    descLabel:SetPoint("TOPLEFT", 20, y)
    descLabel:SetText("|cff4a3520" .. L.DESCRIPTION .. " (optional):|r")
    
    y = y - 18
    local descInput = CreateFrame("EditBox", nil, d, "InputBoxTemplate")
    descInput:SetSize(270, 22)
    descInput:SetPoint("TOPLEFT", 25, y)
    descInput:SetAutoFocus(false)
    descInput:SetMaxLetters(200)
    
    -- Buttons
    local saveBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 24)
    saveBtn:SetPoint("BOTTOMLEFT", 50, 15)
    saveBtn:SetText(L.SAVE)
    saveBtn:SetScript("OnClick", function()
        local name = nameInput:GetText()
        if name == "" then return end
        
        local day, month, year = dateInput:GetText():match("(%d+)%.(%d+)%.(%d+)")
        local hour, min = timeInput:GetText():match("(%d+):(%d+)")
        
        day = tonumber(day) or 1
        month = tonumber(month) or 1
        year = tonumber(year) or 2025
        hour = tonumber(hour) or 20
        min = tonumber(min) or 0
        
        local timestamp = time({
            year = year, month = month, day = day,
            hour = hour, min = min, sec = 0
        })
        
        self:AddEvent({
            name = name,
            description = descInput:GetText(),
            eventType = EVENT_TYPES[selectedType].id,
            timestamp = timestamp,
        })
        
        nameInput:SetText("")
        descInput:SetText("")
        d:Hide()
    end)
    
    local cancelBtn = CreateFrame("Button", nil, d, "UIPanelButtonTemplate")
    cancelBtn:SetSize(100, 24)
    cancelBtn:SetPoint("BOTTOMRIGHT", -50, 15)
    cancelBtn:SetText(L.CANCEL)
    cancelBtn:SetScript("OnClick", function()
        d:Hide()
    end)
    
    self.addDialog = d
end

-- ══════════════════════════════════════════════════════════════
-- MODULE REGISTRATION
-- ══════════════════════════════════════════════════════════════

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(3, function() Calendar:Initialize() end)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

GDL:RegisterModule("Calendar", Calendar)
