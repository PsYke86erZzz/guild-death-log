# Changelog - Das Buch der Gefallenen / The Book of the Fallen

---

## v5.9.7 - KRITISCHE BUGFIXES (11.01.2026)

### 🇩🇪 Deutsch

#### 🐛 KRITISCHE FIXES
1. **Gildendaten werden nicht mehr ohne Gilde angezeigt**
   - `GetGuildData()` gibt jetzt `nil` zurück wenn man NICHT in einer Gilde ist
   - Vorher wurden alte Gildendaten weiterhin angezeigt nach Gildenaustritt
   - FIX: IsInGuild() Prüfung hinzugefügt

2. **Titel sind jetzt character-spezifisch**
   - Titel wurden vorher GLOBAL für alle Characters gespeichert
   - Neue Character haben jetzt KEINE Titel vom Haupt-Char mehr
   - FIX: Character-Key System implementiert (wie bei Milestones)
   - Migration: Alte globale Titel werden automatisch migriert

#### 📋 Technische Details
- Titel-Speicherung: `GuildDeathLogDB.titles["CharName-Realm"]`
- Automatische Migration beim ersten Login nach Update
- Meilensteine waren bereits korrekt (character-spezifisch)

---

### 🇬🇧 English

#### 🐛 CRITICAL FIXES
1. **Guild data no longer shown without guild**
   - `GetGuildData()` now returns `nil` when NOT in a guild
   - Previously old guild data was still shown after leaving guild
   - FIX: Added IsInGuild() check

2. **Titles are now character-specific**
   - Titles were previously stored GLOBALLY for all characters
   - New characters no longer inherit titles from main character
   - FIX: Implemented character-key system (like Milestones)
   - Migration: Old global titles automatically migrated

#### 📋 Technical Details
- Title storage: `GuildDeathLogDB.titles["CharName-Realm"]`
- Automatic migration on first login after update
- Milestones were already correct (character-specific)

---

### 🇷🇺 Русский

#### 🐛 КРИТИЧЕСКИЕ ИСПРАВЛЕНИЯ
1. **Данные гильдии больше не показываются без гильдии**
   - `GetGuildData()` теперь возвращает `nil`, когда НЕ в гильдии
   - Раньше старые данные гильдии отображались после выхода из гильдии
   - ИСПРАВЛЕНИЕ: Добавлена проверка IsInGuild()

2. **Титулы теперь индивидуальны для персонажа**
   - Титулы ранее сохранялись ГЛОБАЛЬНО для всех персонажей
   - Новые персонажи больше не наследуют титулы от основного персонажа
   - ИСПРАВЛЕНИЕ: Реализована система ключей персонажа (как у Вех)
   - Миграция: Старые глобальные титулы автоматически мигрируются

#### 📋 Технические детали
- Хранение титулов: `GuildDeathLogDB.titles["ИмяПерсонажа-Сервер"]`
- Автоматическая миграция при первом входе после обновления
- Вехи уже были правильными (индивидуальными для персонажа)

---

## v5.9.6 - MapMarkers Fix & Russische Lokalisierung (11.01.2026)

### 🇩🇪 Deutsch

#### 🐛 KRITISCHER FIX
- **MapMarkers.lua Syntax-Fehler behoben**: `'<eof>' expected near 'end'` in Zeile 47 und 90
- Zwei zusätzliche `end` Statements entfernt, die die Datei nicht kompilierbar machten

#### 🌍 NEUE SPRACHE: RUSSISCH (ruRU)
- **Vollständige russische Übersetzung** hinzugefügt (Translator: ZamestoTV)
- Auto-Erkennung über `GetLocale()`
- Alle UI-Elemente, Meldungen und Texte auf Russisch verfügbar
- TOC-Datei mit russischen Titel und Beschreibung aktualisiert

#### 📋 Details
- Unterstützte Sprachen: Deutsch (deDE), Englisch (enUS/enGB), Russisch (ruRU)
- Russische Klassennamen: Воин, Паладин, Охотник, etc.
- Russischer Addon-Titel: "Книга Павших"

---

### 🇬🇧 English

#### 🐛 CRITICAL FIX
- **MapMarkers.lua syntax error fixed**: `'<eof>' expected near 'end'` at lines 47 and 90
- Removed two extra `end` statements that prevented the file from compiling

#### 🌍 NEW LANGUAGE: RUSSIAN (ruRU)
- **Full Russian translation** added (Translator: ZamestoTV)
- Auto-detection via `GetLocale()`
- All UI elements, messages and texts available in Russian
- TOC file updated with Russian title and description

#### 📋 Details
- Supported languages: German (deDE), English (enUS/enGB), Russian (ruRU)
- Russian class names: Воин, Паладин, Охотник, etc.
- Russian addon title: "Книга Павших"

---

### 🇷🇺 Русский

#### 🐛 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ
- **Исправлена синтаксическая ошибка MapMarkers.lua**: `'<eof>' expected near 'end'` в строках 47 и 90
- Удалены два лишних оператора `end`, которые не позволяли компилировать файл

#### 🌍 НОВЫЙ ЯЗЫК: РУССКИЙ (ruRU)
- **Добавлен полный русский перевод** (Переводчик: ZamestoTV)
- Автоматическое определение через `GetLocale()`
- Все элементы интерфейса, сообщения и тексты доступны на русском языке
- TOC-файл обновлен с русским названием и описанием

#### 📋 Детали
- Поддерживаемые языки: Немецкий (deDE), Английский (enUS/enGB), Русский (ruRU)
- Русские названия классов: Воин, Паладин, Охотник и т.д.
- Русское название аддона: "Книга Павших"

---

## v5.9.3 - Stabilität & Meilenstein-Marker (10.01.2026)

### 🇩🇪 Deutsch

#### 🐛 KRITISCHE FIXES
- **ALLE Module haben jetzt Auto-Initialize!** Vorher fehlte bei vielen Modulen die Initialisierung
- Betroffene Module: MinimapButton, LastWords, KillerTracker, Deathlog, Condolences, GuildRules, MapMarkers
- Das war der Grund warum viele Features nicht funktionierten!

#### 🗺️ Meilenstein-Marker auf der Karte
- Freigeschaltete Meilensteine werden jetzt auf der Weltkarte angezeigt (gelbe Sterne ⭐)
- Position wird beim Freischalten gespeichert
- **FILTER**: Dungeon- und Raid-Meilensteine werden NICHT auf der Karte angezeigt (macht keinen Sinn)
- Tooltip zeigt Name, Beschreibung, Freischalt-Datum und Zone

#### 🎨 Grabstein-Icon korrigiert
- Icon um 180° gedreht (stand vorher auf dem Kopf)
- Größerer roter Glow für bessere Sichtbarkeit

#### 🛠️ Neue Funktion
- `Milestones:GetMilestoneById()` für externen Zugriff auf Meilenstein-Daten

---

### 🇬🇧 English

#### 🐛 CRITICAL FIXES
- **ALL modules now have Auto-Initialize!** Previously many modules were missing initialization
- Affected modules: MinimapButton, LastWords, KillerTracker, Deathlog, Condolences, GuildRules, MapMarkers
- This was the reason why many features didn't work!

#### 🗺️ Milestone Markers on Map
- Unlocked milestones now show on the world map (yellow stars ⭐)
- Position is saved when unlocking
- **FILTER**: Dungeon and Raid milestones are NOT shown on the map (doesn't make sense)
- Tooltip shows name, description, unlock date and zone

#### 🎨 Gravestone Icon Fixed
- Icon rotated 180° (was upside down before)
- Larger red glow for better visibility

#### 🛠️ New Function
- `Milestones:GetMilestoneById()` for external access to milestone data

---

## v5.9.2 - MapMarkers Fix (10.01.2026)

### 🇩🇪 Deutsch

#### 🐛 KRITISCHER BUG BEHOBEN
- **MapMarkers wurde nie initialisiert!** Das Modul war registriert aber `Initialize()` wurde nie aufgerufen
- Tode werden jetzt wieder auf der Weltkarte angezeigt

#### 🎨 Neues Grabstein-Icon
- Schönes neues Grabstein-Icon mit Kreuz und Schädel ersetzt den Standard-Totenkopf
- Custom Textur: `Textures/DeathMarker.tga`
- Größere Icons (24x24) für bessere Sichtbarkeit
- Stärkerer roter Glow-Effekt

#### 🛠️ Verbesserungen
- `/gdl coords` zeigt jetzt auch das Marker-Setting (AN/AUS)
- Bessere Debug-Ausgabe mit MapID

---

### 🇬🇧 English

#### 🐛 CRITICAL BUG FIXED
- **MapMarkers was never initialized!** Module was registered but `Initialize()` was never called
- Deaths are now displayed on the world map again

#### 🎨 New Gravestone Icon
- Beautiful new gravestone icon with cross and skull replaces the standard skull
- Custom texture: `Textures/DeathMarker.tga`
- Larger icons (24x24) for better visibility
- Stronger red glow effect

#### 🛠️ Improvements
- `/gdl coords` now also shows the marker setting (ON/OFF)
- Better debug output with MapID

---

## v5.9.1 - Sync-Optimierung (10.01.2026)

### 🇩🇪 Deutsch

#### 🔄 Sync-System komplett überarbeitet
- **Message Queue**: Alle Nachrichten werden jetzt gequeued statt direkt gesendet
- **Throttling**: Automatische Rate-Limitierung (2 Nachrichten/Sekunde, 5 Burst)
- **Login-Delay**: 6 Sekunden Verzögerung nach Login (Server-Stabilität)
- **Prioritäten**: PING/PONG/DEATH haben Priorität 1, SYNCREQ Priorität 2, Bulk-Daten Priorität 3
- **255-Byte-Limit**: Automatische Prüfung und Kürzung zu langer Nachrichten
- **NULL-Byte-Filter**: Entfernt Zeichen die Parsing brechen

#### 🛠️ Neue Debug-Befehle
- `/gdl syncstatus` oder `/gdl ss` - Zeigt Sync-Status (Queue, Burst, Online Users)
- `/gdl clearqueue` oder `/gdl cq` - Leert die Message-Queue

#### 🐛 Bug-Fixes
- Alle Module nutzen jetzt konsistenten Login-Delay (6-10 Sekunden)
- Race-Conditions bei Gilden-Roster nach Zonenwechsel behoben
- SavedVariables Backup-System hinzugefügt

---

### 🇬🇧 English

#### 🔄 Sync System completely rewritten
- **Message Queue**: All messages are now queued instead of sent directly
- **Throttling**: Automatic rate limiting (2 messages/second, 5 burst)
- **Login Delay**: 6 second delay after login (server stability)
- **Priorities**: PING/PONG/DEATH have priority 1, SYNCREQ priority 2, bulk data priority 3
- **255-Byte Limit**: Automatic check and truncation of messages
- **NULL-Byte Filter**: Removes characters that break parsing

#### 🛠️ New Debug Commands
- `/gdl syncstatus` or `/gdl ss` - Shows sync status (Queue, Burst, Online Users)
- `/gdl clearqueue` or `/gdl cq` - Clears the message queue

#### 🐛 Bug Fixes
- All modules now use consistent login delay (6-10 seconds)
- Race conditions on guild roster after zone change fixed
- SavedVariables backup system added

---

## v5.9.0 - Finale Release (10.01.2026)

### 🇩🇪 Deutsch

#### ✨ Neue Features
- **⚔️ Hardcore Duell-System**: Trackt Duelle auf Leben und Tod!
  - 4 neue Meilensteine: 1, 3, 10, 25 Siege
  - 4 neue epische Titel: "Der Unvergessliche", "Blutrichter", "Der Unsterbliche Gladiator", "Hand des Schicksals"
  - Gildenchat-Ankündigung bei Duell-Siegen
  - Befehle: `/gdl dueltest`, `/gdl duelstats`, `/gdl duelreset`

- **📅 Kalender mit 3 Monaten**: Zeigt aktuellen + 2 folgende Monate
- **💬 Event-Chat-Benachrichtigung**: Gildenchat wenn Events erstellt werden
- **🎨 Fortschrittsfarben**: Rot → Gelb → Grün je nach Fortschritt

#### 🛠️ Verbesserungen
- **Gedenkseite**: Besseres Layout, größere Icons (56px), mehr Abstand
- **Titel-Farben**: Automatisch gedämpft für Pergament-Lesbarkeit
- **Content-Offset**: 48px für mehr Platz unter Titeln
- **Icons**: Alle auf Classic 1.15.8 kompatibel (keine Achievement_* mehr)

#### 🐛 Bug-Fixes
- `HasMilestone` Fehler bei Duell-Meilensteinen behoben
- Ragnaros Icon (war nicht Classic-kompatibel)
- "Ein Monat Hardcore" Icon gefixt
- Doppelte Funktion `KillStats:RecheckAllMilestones` entfernt
- Berufe-Meilensteine korrigiert (realistisch für Classic: max 2 Hauptberufe)

---

### 🇬🇧 English

#### ✨ New Features
- **⚔️ Hardcore Duel System**: Tracks Duels to the Death!
  - 4 new milestones: 1, 3, 10, 25 victories
  - 4 new epic titles: "The Unforgotten", "Blood Judge", "The Immortal Gladiator", "Hand of Fate"
  - Guild chat announcement on duel wins
  - Commands: `/gdl dueltest`, `/gdl duelstats`, `/gdl duelreset`

- **📅 Calendar with 3 months**: Shows current + 2 following months
- **💬 Event chat notification**: Guild chat when events are created
- **🎨 Progress colors**: Red → Yellow → Green based on progress

#### 🛠️ Improvements
- **Memorial page**: Better layout, larger icons (56px), more spacing
- **Title colors**: Automatically dampened for parchment readability
- **Content offset**: 48px for more space under titles
- **Icons**: All compatible with Classic 1.15.8 (no Achievement_* anymore)

#### 🐛 Bug Fixes
- `HasMilestone` error on duel milestones fixed
- Ragnaros icon (was not Classic-compatible)
- "One Month Hardcore" icon fixed
- Duplicate function `KillStats:RecheckAllMilestones` removed
- Profession milestones corrected (realistic for Classic: max 2 main professions)

---

## v5.8.x - Buch-UI Überarbeitung / Book UI Overhaul

### 🇩🇪 Deutsch
- Komplett neues Buch-Interface mit Quest-Log-Textur
- 9 Kapitel: Chronik, Helden, Statistik, Meilensteine, Titel, Berufe, Regeln, Kalender, Einstellungen
- Immersives Design passend zu WoW Classic
- Klickbare Mitglieder-Liste mit Klassenfarben
- 2-Seiten-Layout wie ein echtes Buch

### 🇬🇧 English
- Completely new book interface with Quest-Log texture
- 9 chapters: Chronicle, Heroes, Statistics, Milestones, Titles, Professions, Rules, Calendar, Settings
- Immersive design fitting WoW Classic
- Clickable member list with class colors
- 2-page layout like a real book

---

## v5.7.x - Meilenstein-System / Milestone System

### 🇩🇪 Deutsch
- 100+ Meilensteine: Level, Bosse, Kills, Berufe, Spielzeit, Gold
- Creature Type Tracking: Humanoid, Beast, Undead, Demon, Dragonkin, etc.
- Geheime Meilensteine die entdeckt werden müssen
- Titel-System mit über 80 freischaltbaren Titeln
- Sync zwischen Gildenmitgliedern

### 🇬🇧 English
- 100+ milestones: Level, Bosses, Kills, Professions, Playtime, Gold
- Creature type tracking: Humanoid, Beast, Undead, Demon, Dragonkin, etc.
- Secret milestones to discover
- Title system with 80+ unlockable titles
- Sync between guild members

---

## Befehle / Commands

| Befehl / Command | Beschreibung / Description |
|------------------|---------------------------|
| `/gdl` oder `/buch` | Buch öffnen / Open book |
| `/gdl help` | Alle Befehle / All commands |
| `/gdl sync` | Sync mit Gilde / Sync with guild |
| `/gdl debug` | Debug-Fenster / Debug window |
| `/gdl dueltest` | Duell-Sieg simulieren / Simulate duel win |
| `/gdl duelstats` | Duell-Statistik / Duel statistics |
| `/gdl setpw <pw>` | Admin-Passwort setzen / Set admin password |

---

## Technische Informationen / Technical Information

- **Interface**: 11508, 11509, 11510, 30300, 30403, 40402
- **WoW Classic**: 1.15.8+
- **Addon-Prefix**: GDLSync, GDLTitle, GDLRules
- **SavedVariables**: GuildDeathLogDB

---

## Credits

- **Autor / Author**: PsYke86
- **Gilde / Guild**: Letzte Zuflucht (Soulseeker-EU)
- **Unterstützung / Support**: Discord

---

*Mögen die Gefallenen in Frieden ruhen.*
*May the fallen rest in peace.*
