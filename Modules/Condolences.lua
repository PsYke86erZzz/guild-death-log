-- ══════════════════════════════════════════════════════════════
-- MODUL: Condolences v2.0 - EPISCHE TODESNACHRICHTEN
-- NUR würdevolle, trauernde, epische Nachrichten
-- Hardcore-Tod verdient Respekt, keine Witze.
-- 
-- System: [INTRO] + [CORE] + [OUTRO] = Einzigartige Nachricht
-- ══════════════════════════════════════════════════════════════

local addonName, addon = ...
local GDL = _G["GuildDeathLog"]
local Condolences = {}

-- ══════════════════════════════════════════════════════════════
-- INTROS - Epische, würdevolle Einleitungen
-- ══════════════════════════════════════════════════════════════

local INTROS = {
    -- Glocken & Signale
    "Die Glocken von Sturmwind läuten... ",
    "Die Glocken von Orgrimmar verstummen... ",
    "Ein Hornstoß hallt durch die Berge... ",
    "Die Totenglocken erklingen... ",
    "Ein Trauermarsch beginnt... ",
    
    -- Natur & Elemente
    "Ein Schatten fällt über Azeroth. ",
    "Der Wind trägt traurige Kunde... ",
    "Die Sterne weinen heute Nacht. ",
    "Der Himmel verdunkelt sich. ",
    "Die Erde bebt vor Trauer. ",
    "Ein kalter Wind weht durch die Hallen... ",
    "Die Flammen der Hoffnung erlöschen. ",
    "Selbst die Sonne scheint heute matter. ",
    
    -- Geister & Ahnen
    "Die Geister flüstern einen Namen... ",
    "Die Ahnen rufen einen der Ihren heim... ",
    "Die Seelen der Gefallenen heißen einen neuen willkommen... ",
    "Die Geister der Vergangenheit erheben sich... ",
    "Ein Ruf aus dem Jenseits... ",
    
    -- Bücher & Chroniken
    "Das Buch der Gefallenen öffnet sich... ",
    "Die Chroniken verzeichnen einen Verlust. ",
    "Ein neuer Name wird in Stein gemeißelt. ",
    "Die Geschichte schreibt ein trauriges Kapitel. ",
    "Die Annalen Azeroths verzeichnen... ",
    
    -- Dramatisch
    "Heute ist ein dunkler Tag. ",
    "Eine Legende endet heute. ",
    "Das Schicksal hat zugeschlagen. ",
    "Die Nachricht erreicht uns schweren Herzens. ",
    "Mit tiefem Bedauern... ",
    "Wir haben einen der Unseren verloren. ",
    "Ein Held ist von uns gegangen. ",
    
    -- Helden & Legenden
    "Hört her, Helden von Azeroth! ",
    "Lasst die Banner auf Halbmast sinken. ",
    "Versammelt euch, Brüder und Schwestern... ",
    "Senkt eure Häupter... ",
    "Haltet inne und gedenket... ",
    
    -- Licht & Dunkelheit
    "Das Licht flackert und erlischt... ",
    "Die Dunkelheit hat einen weiteren verschlungen. ",
    "Ein Licht in der Finsternis ist erloschen. ",
    "Die Schatten breiten sich aus... ",
    
    -- Englisch - Episch
    "The bells of Stormwind toll... ",
    "A shadow falls over Azeroth. ",
    "The spirits whisper a name... ",
    "The wind carries sorrowful tidings... ",
    "A legend ends today. ",
    "Hear ye, heroes of Azeroth! ",
    "The chronicles record a great loss. ",
    "Let the banners fly at half-mast. ",
    "The ancestors call one of their own home... ",
    "Darkness claims another soul... ",
}

-- ══════════════════════════════════════════════════════════════
-- CORES - Würdevolle Hauptaussagen (%s = Name)
-- ══════════════════════════════════════════════════════════════

local CORES = {
    -- Gefallen / Tod
    "%s ist gefallen",
    "%s ist von uns gegangen",
    "%s hat uns verlassen",
    "%s weilt nicht mehr unter uns",
    "%s hat den letzten Atemzug getan",
    "%s hat die Augen für immer geschlossen",
    "%s ist in die ewige Ruhe eingegangen",
    "%s hat das Zeitliche gesegnet",
    
    -- Kampf & Ehre
    "%s hat seinen letzten Kampf verloren",
    "%s fiel im Kampf",
    "%s starb wie ein wahrer Held",
    "%s gab sein Leben für Azeroth",
    "%s kämpfte bis zum bitteren Ende",
    "%s fand einen ehrenvollen Tod",
    "%s starb mit der Waffe in der Hand",
    "%s hat den ultimativen Preis gezahlt",
    
    -- Reise & Jenseits
    "%s hat die letzte Reise angetreten",
    "%s ist in die ewigen Jagdgründe eingegangen",
    "%s wurde zu den Ahnen gerufen",
    "%s wandelt nun unter den Sternen",
    "%s hat Azeroth für immer verlassen",
    "%s ist heimgekehrt zu den Vorfahren",
    
    -- Hallen & Ehrenplätze
    "%s wurde in die Hallen der Tapferen aufgenommen",
    "%s kämpft nun an Uther's Seite",
    "%s ruht nun bei den Titanen",
    "%s hat seinen Platz unter den Legenden eingenommen",
    "%s wacht nun über uns von oben",
    
    -- Licht & Geist
    "%s ist nun eins mit dem Licht",
    "%s's Seele ist aufgestiegen",
    "%s's Geist hat Frieden gefunden",
    "%s wurde vom Licht heimgerufen",
    "%s ist in den Nether eingegangen",
    
    -- Tragisch
    "%s wurde uns genommen",
    "%s wurde der Welt entrissen",
    "%s hat aufgehört zu existieren",
    "%s's Flamme ist erloschen",
    "%s's Herz hat aufgehört zu schlagen",
    
    -- Englisch
    "%s has fallen",
    "%s has left us",
    "%s walks among us no more",
    "%s has begun the final journey",
    "%s fell in glorious battle",
    "%s died a true hero's death",
    "%s has been called to the ancestors",
    "%s now rests among the Titans",
    "%s's spirit has ascended",
    "%s paid the ultimate price",
    "%s has joined the Hall of the Brave",
}

-- ══════════════════════════════════════════════════════════════
-- OUTROS - Würdevolle Abschlüsse
-- ══════════════════════════════════════════════════════════════

local OUTROS = {
    -- Frieden & Ruhe
    ". Ruhe in Frieden.",
    ". Möge die Seele Frieden finden.",
    ". Ruhe sanft, tapferer Held.",
    ". Finde Frieden in der Ewigkeit.",
    ". Mögest du in Frieden ruhen.",
    ". Ewige Ruhe sei dir gewährt.",
    
    -- Erinnerung & Vermächtnis
    ". Für immer in unseren Herzen.",
    ". Niemals vergessen.",
    ". Dein Name wird ewig leben.",
    ". Wir werden dich nie vergessen.",
    ". Dein Vermächtnis lebt weiter.",
    ". Dein Andenken bleibt unsterblich.",
    ". Du lebst in unseren Erinnerungen weiter.",
    ". Dein Name ist in unsere Herzen gebrannt.",
    
    -- Ehre & Respekt
    ". Ehre seinem Andenken.",
    ". Ehre sei dir, tapferer Held.",
    ". Möge man sich deiner würdig erinnern.",
    ". Dein Opfer war nicht umsonst.",
    ". Du hast mit Ehre gelebt und bist mit Ehre gestorben.",
    ". Salut, Kamerad.",
    
    -- Trauer & Gilde
    ". Die Gilde trauert.",
    ". Wir trauern um dich.",
    ". Die Gilde wird dich vermissen.",
    ". Wir senken unsere Häupter.",
    ". Unser Herz ist schwer.",
    ". Ein Verlust für uns alle.",
    
    -- Abschied
    ". Auf Wiedersehen, Freund.",
    ". Bis wir uns wiedersehen.",
    ". Leb wohl, Held.",
    ". Mögen wir uns eines Tages wiedersehen.",
    ". Bis zum nächsten Leben.",
    
    -- Götter & Höhere Mächte
    ". Mögen die Titanen über dich wachen.",
    ". Das Licht wird dich führen.",
    ". Mögen die Götter dich empfangen.",
    ". Die Ahnen heißen dich willkommen.",
    ". Möge Elune über dich wachen.",
    ". Die Erdenmutter nimmt dich auf.",
    
    -- Kriegerisch / Horde-Allianz
    ". Lok'tar ogar - Sieg oder Tod.",
    ". Für die Allianz. Für immer.",
    ". Für die Horde. Für immer.",
    ". Ein Krieger bis zum Ende.",
    
    -- Englisch
    ". Rest in peace.",
    ". May your soul find peace.",
    ". Forever in our hearts.",
    ". Never forgotten.",
    ". Honor to your memory.",
    ". The guild mourns your loss.",
    ". Your sacrifice will not be forgotten.",
    ". Until we meet again.",
    ". May the Titans watch over you.",
    ". Farewell, brave hero.",
}

-- ══════════════════════════════════════════════════════════════
-- KOMPLETTE SPEZIAL-NACHRICHTEN (Eigenständig, sehr episch)
-- ══════════════════════════════════════════════════════════════

local SPECIALS = {
    -- Chroniken & Legenden
    "Die Chroniken berichten: %s, einst ein Held, nun eine Legende. Ruhe in Frieden.",
    "Und so endet die Geschichte von %s... Doch Legenden sterben nie.",
    "%s hat bewiesen, dass wahre Helden unsterblich sind - in unseren Herzen.",
    "Von Nordend bis Kalimdor wird man sich an %s erinnern.",
    "%s - Ein Name, der in die Geschichte eingeht.",
    "Die Sänger werden Lieder über %s singen, bis ans Ende der Zeit.",
    "%s's Taten werden von Generation zu Generation weitererzählt.",
    "In den Hallen der Helden wird ein neuer Platz bereitet: für %s.",
    
    -- Licht & Dunkelheit
    "Das Licht hat heute einen seiner treuesten Diener verloren: %s.",
    "%s's Licht mag erloschen sein, doch es erhellt noch immer unsere Erinnerungen.",
    "Die Dunkelheit mag %s genommen haben, aber sein Geist leuchtet ewig.",
    "Ein Stern am Himmel Azeroths ist erloschen. Ruhe in Frieden, %s.",
    "Das Licht weint heute. %s ist heimgekehrt.",
    
    -- Kampf & Ehre
    "%s kämpfte wie ein Löwe und fiel wie ein Held. Ewige Ehre.",
    "Die Welt ist ein dunklerer Ort ohne %s.",
    "%s hat sein Blut für Azeroth vergossen. Dieses Opfer vergessen wir nie.",
    "Mit %s verlieren wir nicht nur einen Kameraden, sondern einen wahren Helden.",
    "%s starb so, wie er lebte: Mit Ehre, Mut und unerschütterlichem Willen.",
    "Selbst im Angesicht des Todes zeigte %s keine Furcht. Ein wahrer Held.",
    
    -- Gilde & Gemeinschaft
    "Die Gilde hat heute ein Mitglied verloren, aber einen ewigen Kameraden gewonnen. %s.",
    "Jeder in der Gilde senkt den Kopf für %s. Du wirst vermisst.",
    "Die Gilde wird nie dieselbe sein ohne %s. Ruhe in Frieden, Freund.",
    "In unserer Gilde vergessen wir keinen. %s, du lebst in uns weiter.",
    "Wir stehen vereint in der Trauer um %s. Du warst einer von uns.",
    "%s war mehr als ein Gildenmitglied. %s war Familie.",
    
    -- Philosophisch & Tiefgründig
    "Der Tod ist nicht das Ende. %s lebt weiter - in jedem von uns.",
    "Manche sagen, %s sei gestorben. Wir sagen, %s wurde unsterblich.",
    "%s hat uns gelehrt, dass jeder Moment kostbar ist. Danke, Freund.",
    "Die Zeit mit %s war ein Geschenk. Wir werden es für immer schätzen.",
    "%s's Reise in dieser Welt endet, doch eine neue beginnt.",
    "Der Körper mag vergehen, doch %s's Geist wird ewig über Azeroth wachen.",
    
    -- Dramatisch & Emotional
    "Heute weint ganz Azeroth. %s ist nicht mehr.",
    "Die Nachricht trifft uns wie ein Schlag: %s hat uns verlassen.",
    "Worte können nicht ausdrücken, was wir empfinden. %s, du fehlst uns.",
    "Ein Stück von uns ist mit %s gegangen. Ruhe in Frieden.",
    "Unsere Herzen sind schwer. %s, mögest du Frieden finden.",
    "%s... Wir hätten noch so viel Zeit gebraucht. Leb wohl.",
    
    -- Ahnen & Jenseits
    "Die Ahnen haben %s zu sich gerufen. Mögen sie ihn würdig empfangen.",
    "%s wandelt nun auf den Pfaden der Ewigkeit. Wir werden folgen, wenn die Zeit kommt.",
    "Die Geister unserer Vorfahren heißen %s willkommen. Sei gesegnet.",
    "%s's Seele steigt auf zu den Sternen. Schau auf uns herab, Freund.",
    
    -- Englisch - Episch
    "The chronicles record: %s, once a hero, now a legend. Rest in peace.",
    "And so ends the story of %s... But legends never truly die.",
    "From Northrend to Kalimdor, %s will be remembered for all time.",
    "%s fought like a lion and fell like a hero. Eternal honor.",
    "The world is a darker place without %s. We shall carry the light forward.",
    "The guild has lost a member today, but gained an eternal guardian. %s.",
    "We stand united in grief for %s. You were one of us. Always.",
    "The ancestors have called %s home. May they receive them with honor.",
    "Today, all of Azeroth weeps. %s is no more.",
    "%s's journey in this world ends, but a new one begins among the stars.",
}

-- ══════════════════════════════════════════════════════════════
-- KLASSEN-SPEZIFISCHE NACHRICHTEN (Würdevoll)
-- ══════════════════════════════════════════════════════════════

local CLASS_MESSAGES = {
    ["WARRIOR"] = {
        "%s's Schwert ist verstummt. Der Krieger ruht in Ehren.",
        "Ein Krieger ist gefallen. %s kämpfte bis zum letzten Atemzug.",
        "%s: Einst unaufhaltsam im Kampf, nun in ewiger Ruhe. Ehre sei dir.",
        "Die Schlachtfelder werden %s vermissen. Ein wahrer Krieger ist gegangen.",
        "%s hat sein Schild zum letzten Mal niedergelegt. Ruhe in Frieden, Krieger.",
    },
    ["PALADIN"] = {
        "Das Licht weint um %s. Ein Paladin ist heimgekehrt.",
        "%s's heiliges Licht ist erloschen. Mögen die Naaru über dich wachen.",
        "Uther hat einen neuen Gefährten in den Hallen des Lichts: %s.",
        "%s diente dem Licht bis zum Ende. Nun wird das Licht ihn für immer umhüllen.",
        "Ein Verteidiger des Glaubens ist gefallen. %s, das Licht sei mit dir.",
    },
    ["HUNTER"] = {
        "%s's Bogen ist verstummt. Der Jäger jagt nun in den ewigen Wäldern.",
        "%s und sein treuer Begleiter sind vereint im Jenseits.",
        "Die Wildnis trauert um %s. Ein Meister der Jagd ist gegangen.",
        "%s's letzte Spur führt in die Ewigkeit. Mögest du Wild im Überfluss finden.",
        "Der Wind trägt %s's Namen durch die Wälder. Niemals vergessen.",
    },
    ["ROGUE"] = {
        "%s ist in die tiefsten Schatten verschwunden. Für immer.",
        "Selbst die Schatten trauern um %s. Ein Meister ist gegangen.",
        "%s's Klingen sind verstummt. Der Schatten ruht nun in Frieden.",
        "Lautlos kam %s, lautlos ging er. Doch sein Vermächtnis hallt nach.",
        "%s hat seinen letzten Auftrag erfüllt. Ruhe in den Schatten, Freund.",
    },
    ["PRIEST"] = {
        "%s's heilende Hände ruhen nun. Das Licht empfängt seinen Diener.",
        "Der Heiler ist gefallen. %s, möge nun jemand anderes über dich wachen.",
        "%s hat so viele Leben gerettet. Nun ist es Zeit, selbst Frieden zu finden.",
        "Das Licht hat %s heimgerufen. Ein treuer Diener kehrt heim.",
        "%s's Gebete sind verstummt, doch sein Glaube lebt in uns weiter.",
    },
    ["SHAMAN"] = {
        "Die Elemente weinen um %s. Ein Schamane kehrt zur Erde zurück.",
        "%s's Totems sind erloschen. Die Geister nehmen ihn in ihre Mitte auf.",
        "Der Wind, das Wasser, die Erde, das Feuer - alle trauern um %s.",
        "%s ist nun eins mit den Elementen. Für immer.",
        "Die Ahnen haben %s zu sich gerufen. Mögen die Elemente dich tragen.",
    },
    ["MAGE"] = {
        "%s's arkane Macht ist verblasst. Der Magier ruht nun in Frieden.",
        "Die Magie Azeroths hat einen Meister verloren. %s, ruhe in Frieden.",
        "%s's Zauber sind verklungen. Doch seine Weisheit bleibt.",
        "Die Sterne über Dalaran leuchten heute matter. %s ist gegangen.",
        "%s hat das letzte Portal durchschritten. Möge es zu Frieden führen.",
    },
    ["WARLOCK"] = {
        "%s's Dämonen verstummen. Der Hexenmeister hat Frieden gefunden.",
        "Die Leere gibt %s frei. Möge die Seele nun Ruhe finden.",
        "%s hat den letzten Pakt geschlossen - den mit der Ewigkeit.",
        "Selbst die Schatten des Nethers verneigen sich vor %s.",
        "%s's dunkle Künste sind erloschen. Nun wartet das Licht.",
    },
    ["DRUID"] = {
        "%s kehrt zum großen Kreislauf zurück. Der Druide ist eins mit der Natur.",
        "Der Smaragdgrüne Traum empfängt %s mit offenen Armen.",
        "Cenarius begrüßt %s in den ewigen Wäldern.",
        "%s's Verwandlungen sind vorbei. Nun nimmt die Natur ihn ganz auf.",
        "Die Bäume flüstern %s's Namen. Er ist nun Teil von ihnen.",
    },
}

-- ══════════════════════════════════════════════════════════════
-- LEVEL-BASIERTE NACHRICHTEN (Würdevoll)
-- ══════════════════════════════════════════════════════════════

local LEVEL_MESSAGES = {
    -- Low Level (1-19)
    low = {
        "%s (Level %d) - So jung, so tragisch. Ruhe in Frieden, junger Held.",
        "Die Reise von %s (Level %d) endete viel zu früh. Mögest du Frieden finden.",
        "%s hatte gerade erst begonnen. Level %d war das letzte Kapitel. Ruhe sanft.",
        "Ein junger Held fällt: %s, Level %d. Dein Mut wird nicht vergessen.",
    },
    -- Mid Level (20-39)
    mid = {
        "%s (Level %d) - Auf halbem Weg zur Legende, doch das Schicksal hatte andere Pläne.",
        "Level %d Held %s ist gefallen. So nah am Ziel, und doch so fern. Ruhe in Frieden.",
        "%s kämpfte sich bis Level %d. Möge die Reise im Jenseits weitergehen.",
        "Die Geschichte von %s (Level %d) endet hier. Doch Legenden leben ewig.",
    },
    -- High Level (40-59)
    high = {
        "%s (Level %d) - So kurz vor dem Gipfel. Ein tragischer Verlust für uns alle.",
        "Level %d! %s war so nah an der Spitze. Dein Opfer wird nicht vergessen.",
        "%s (Level %d) - Ein erfahrener Held fällt. Die Gilde trauert.",
        "Die Gilde verliert einen Level %d Veteranen: %s. Ruhe in Ehren.",
    },
    -- Max Level (60)
    max = {
        "%s (Level 60) - Ein wahrer Champion ist gefallen. Ewige Ehre sei dir.",
        "Level 60 Legende %s hat den ultimativen Preis gezahlt. Ruhe in Frieden, Held.",
        "%s - Level 60, der Gipfel erreicht, und doch vom Schicksal genommen. Niemals vergessen.",
        "Unser Level 60 Held %s ist gefallen. Die Gilde wird seine Größe nie vergessen.",
        "%s (Level 60) - Du hast alles erreicht. Nun ruhe in ewigem Ruhm.",
    },
}

-- ══════════════════════════════════════════════════════════════
-- NACHRICHTEN-GENERATOR
-- ══════════════════════════════════════════════════════════════

function Condolences:GenerateEpicMessage(name, level, className, killer, zone)
    local roll = math.random(100)
    
    -- 20% Chance auf Spezial-Nachricht
    if roll <= 20 then
        local msg = SPECIALS[math.random(#SPECIALS)]
        return string.format(msg, name, name) -- Manche haben 2x %s
    end
    
    -- 15% Chance auf Klassen-spezifische Nachricht
    if roll <= 35 and className then
        local classMsg = self:GetClassMessage(name, className)
        if classMsg then return classMsg end
    end
    
    -- 15% Chance auf Level-basierte Nachricht
    if roll <= 50 and level and level > 0 then
        local levelMsg = self:GetLevelMessage(name, level)
        if levelMsg then return levelMsg end
    end
    
    -- 50% Chance auf modulare Nachricht (INTRO + CORE + OUTRO)
    return self:BuildModularMessage(name)
end

-- Baut eine modulare Nachricht zusammen
function Condolences:BuildModularMessage(name)
    local parts = {}
    
    -- 50% Chance auf Intro
    if math.random(100) <= 50 then
        table.insert(parts, INTROS[math.random(#INTROS)])
    end
    
    -- Core (immer)
    local core = CORES[math.random(#CORES)]
    table.insert(parts, string.format(core, name))
    
    -- Outro (immer)
    table.insert(parts, OUTROS[math.random(#OUTROS)])
    
    return table.concat(parts, "")
end

-- Klassen-spezifische Nachricht
function Condolences:GetClassMessage(name, className)
    local classUpper = string.upper(className or "")
    
    -- Deutsche Klassennamen zu Englisch
    local classMap = {
        ["KRIEGER"] = "WARRIOR",
        ["PALADIN"] = "PALADIN",
        ["JÄGER"] = "HUNTER",
        ["JAEGER"] = "HUNTER",
        ["SCHURKE"] = "ROGUE",
        ["PRIESTER"] = "PRIEST",
        ["SCHAMANE"] = "SHAMAN",
        ["MAGIER"] = "MAGE",
        ["HEXENMEISTER"] = "WARLOCK",
        ["DRUIDE"] = "DRUID",
    }
    
    local classKey = classMap[classUpper] or classUpper
    
    if CLASS_MESSAGES[classKey] then
        local messages = CLASS_MESSAGES[classKey]
        return string.format(messages[math.random(#messages)], name)
    end
    
    return nil
end

-- Level-basierte Nachricht
function Condolences:GetLevelMessage(name, level)
    level = tonumber(level) or 0
    
    local category
    if level >= 60 then
        category = LEVEL_MESSAGES.max
    elseif level >= 40 then
        category = LEVEL_MESSAGES.high
    elseif level >= 20 then
        category = LEVEL_MESSAGES.mid
    else
        category = LEVEL_MESSAGES.low
    end
    
    local msg = category[math.random(#category)]
    return string.format(msg, name, level)
end

-- ══════════════════════════════════════════════════════════════
-- LEGACY FUNKTIONEN (Kompatibilität)
-- ══════════════════════════════════════════════════════════════

function Condolences:Initialize()
    GuildDeathLogDB.condolences = GuildDeathLogDB.condolences or {
        enabled = true,
        lastMessage = 0,
        cooldown = 30,
    }
end

function Condolences:GetRandomCondolence(name)
    return self:GenerateEpicMessage(name, nil, nil, nil, nil)
end

function Condolences:GetDeathAnnouncement(name, level, className, killer, zone)
    return self:GenerateEpicMessage(name, level, className, killer, zone)
end

function Condolences:SendCondolence(name, channel, level, className, killer, zone)
    local settings = GuildDeathLogDB.condolences
    if not settings or not settings.enabled then return false end
    
    if time() - (settings.lastMessage or 0) < (settings.cooldown or 30) then
        return false
    end
    
    local message = self:GenerateEpicMessage(name, level, className, killer, zone)
    
    channel = channel or "GUILD"
    if channel == "GUILD" and IsInGuild() then
        SendChatMessage(message, "GUILD")
        settings.lastMessage = time()
        return true
    end
    
    return false
end

function Condolences:SendToChannel(name, level, className, channelName, killer, zone)
    if not channelName or channelName == "" then return false end
    
    local channelId = GetChannelName(channelName)
    if not channelId or channelId == 0 then return false end
    
    local message = self:GenerateEpicMessage(name, level, className, killer, zone)
    SendChatMessage(message, "CHANNEL", nil, channelId)
    return true
end

-- Einstellungen
function Condolences:SetEnabled(enabled)
    GuildDeathLogDB.condolences.enabled = enabled
end

function Condolences:SetCooldown(seconds)
    GuildDeathLogDB.condolences.cooldown = seconds
end

function Condolences:GetSettings()
    return GuildDeathLogDB.condolences
end

-- ══════════════════════════════════════════════════════════════
-- DEBUG / TEST
-- ══════════════════════════════════════════════════════════════

function Condolences:TestMessages(count)
    count = count or 10
    GDL:Print("═══════════════════════════════════════")
    GDL:Print("|cffFFD100Epische Todesnachrichten - " .. count .. " Beispiele:|r")
    GDL:Print("═══════════════════════════════════════")
    
    local testNames = {"Valorian", "Shadowbane", "Lightbringer", "Ironforge", "Stormwind"}
    local testClasses = {"Warrior", "Paladin", "Mage", "Rogue", "Priest", "Hunter", "Shaman", "Warlock", "Druid"}
    local testLevels = {8, 15, 28, 45, 58, 60}
    
    for i = 1, count do
        local name = testNames[math.random(#testNames)]
        local class = testClasses[math.random(#testClasses)]
        local level = testLevels[math.random(#testLevels)]
        
        local msg = self:GenerateEpicMessage(name, level, class, nil, nil)
        GDL:Print("|cff888888" .. i .. ")|r " .. msg)
    end
    
    GDL:Print("═══════════════════════════════════════")
end

function Condolences:GetStats()
    local stats = {
        intros = #INTROS,
        cores = #CORES,
        outros = #OUTROS,
        specials = #SPECIALS,
        classMessages = 0,
        levelCategories = 4,
    }
    
    for _, msgs in pairs(CLASS_MESSAGES) do
        stats.classMessages = stats.classMessages + #msgs
    end
    
    stats.levelMessages = 4 + 4 + 4 + 5  -- low, mid, high, max
    stats.modularCombinations = stats.intros * stats.cores * stats.outros
    stats.totalPossible = stats.specials + stats.classMessages + stats.levelMessages + stats.modularCombinations
    
    return stats
end

function Condolences:PrintStats()
    local s = self:GetStats()
    GDL:Print("═══════════════════════════════════════")
    GDL:Print("|cffFFD100Epische Nachrichten - Statistiken:|r")
    GDL:Print("═══════════════════════════════════════")
    GDL:Print("Intros: |cff00FF00" .. s.intros .. "|r")
    GDL:Print("Cores: |cff00FF00" .. s.cores .. "|r")
    GDL:Print("Outros: |cff00FF00" .. s.outros .. "|r")
    GDL:Print("Spezial-Nachrichten: |cff00FF00" .. s.specials .. "|r")
    GDL:Print("Klassen-Nachrichten: |cff00FF00" .. s.classMessages .. "|r")
    GDL:Print("Level-Nachrichten: |cff00FF00" .. s.levelMessages .. "|r")
    GDL:Print("───────────────────────────────────────")
    GDL:Print("Modulare Kombinationen: |cffFFD100" .. s.modularCombinations .. "|r")
    GDL:Print("|cff00FFFFGesamt mögliche Nachrichten: " .. s.totalPossible .. "+|r")
    GDL:Print("═══════════════════════════════════════")
end

GDL:RegisterModule("Condolences", Condolences)
