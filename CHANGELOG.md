# Das Buch der Gefallenen - Changelog

## Version 4.7.0
**NEUE MODULE: Gedenkhalle & Gilden-Statistiken!**

### 🪦 NEU: Memorial-Modul (Gedenkhalle)
Ehre die Gefallenen mit zufaelligen Nachrufen!

**Features:**
- Liste aller verstorbenen Gildenmitglieder
- **28 zufaellige Nachrufe** (ehrenvoll, humorvoll, episch)
- Klassenicon, Level, Zone, Killer, Datum
- **Verstorbene werden automatisch aus Berufe-Liste entfernt**

**Befehle:** `/gdl memorial` oder `/gdl rip`

**Nachruf-Beispiele:**
- "Ruhe in Frieden, tapferer Held."
- "'Ich tank das' - Letzte Worte."
- "Selbst der Tod konnte deinen Ruhm nicht mindern."

---

### 📊 NEU: GuildStats-Modul (Gilden-Statistiken)
Ueberblick ueber die gesamte Gilde!

**Durchschnittslevel:**
- Gesamt (alle Mitglieder)
- Online vs Offline getrennt
- Anzahl Mitglieder

**Tode pro Charakter:**
- Ranking mit Gold/Silber/Bronze fuer Top 3
- Anzahl Tode pro Spieler
- **Hover-Tooltip** mit Details (Level, Zone, Datum)
- Dunkle Schriftfarben passend zum Pergament-Design

**Befehle:** `/gdl gstats` oder `/gdl gildenstat`

---

### 🎨 UI-Verbesserungen

**Schriftfarben korrigiert:**
- Alle Fenster nutzen jetzt einheitlich dunkle Braun-Toene
- Passend zum Pergament-Hintergrund der Ruhmeshalle
- Bessere Lesbarkeit auf hellem Hintergrund

**Fenster-Positionen (Cascade-Layout):**
- **Keine Ueberlappung** mehr wenn mehrere Fenster offen sind
- Alle Fenster sind verschiebbar (Drag & Drop)
- Gestaffelte Anordnung links/rechts vom Hauptfenster

**Layout:**
```
        [Memorial]              [Titles]
              ↘                   ↙
    [Professions]  [HAUPT]  [HallOfFame]
                       ↘
                   [Statistics]
                        ↘
                    [Milestones]
                         ↘
                     [GuildStats]
```

---

### 🗺️ Gilden-Karte verbessert
- **Neues Pin-Design**: Kleiner Punkt + pulsierender Glow-Ring
- **Ultra-Echtzeit**: Updates alle 0.75 Sekunden (vorher 1.5s)
- **33 FPS**: Fluessigere Pin-Bewegung
- **Klassenfarben** auf Punkt und Glow

---

### 🔇 Sync-Spam behoben
- Nur **LIVE Tode** (< 30 Sekunden) zeigen Popup/Sound
- Historische Tode werden **still** importiert
- Weniger automatische Syncs

---

### 🎯 Neue Buttons im Hauptfenster
Reihe 3: `[Titel] [Gedenkhalle] [Gilden-Stats]`

---

## Version 4.6.0
**GROSSES UPDATE: Echtzeit Gilden-Karte, Kill-Meilensteine & Titel-System!**

### 🚨 KRITISCHER BUG-FIX
**Mehrere Module wurden nie initialisiert!** Das betrifft:
- `GuildTracker` - Spieler auf der Karte wurden nicht angezeigt
- `Sync` - Todes-Synchronisation funktionierte nicht richtig
- `Professions` - Berufe wurden nicht gesynct
- `Milestones` - Level-Tracking startete nicht

**Alle Gildenmitglieder muessen auf v4.6.0 updaten!**

---

### 🗺️ ECHTZEIT Gilden-Karte
Sieh deine Gildenmitglieder LIVE auf der Weltkarte!

**Features:**
- **Echtzeit-Tracking**: Positionen werden alle 1.5 Sekunden gesynct
- **Fluessige Bewegung**: Pins bewegen sich smooth durch Interpolation (20 FPS)
- **Dezentes Design**: Kleiner farbiger Punkt in Klassenfarbe
- **Name bei Hover**: Name erscheint nur beim Ueberfahren mit der Maus
- **Tooltip**: Zone und letztes Update werden angezeigt

**Technische Details:**
| Einstellung | Wert |
|-------------|------|
| Broadcast-Intervall | 1.5 Sekunden |
| Stale-Timeout | 10 Sekunden |
| Pin-Update | 50ms (20 FPS) |
| Interpolation | Smooth Easing |

---

### 🏆 Custom Titel-System
Verdiene Titel durch Meilensteine - sichtbar fuer alle Gildenmitglieder!

**31 Titel verfuegbar:**

**Leichte Titel (ab 10-25 Kills):**
| Titel | Anforderung |
|-------|-------------|
| Wegelagerer | 25 Humanoide |
| Jaeger | 25 Wildtiere |
| Grabschaender | 25 Untote |
| Daemonentoeter | 25 Daemonen |
| Elementarjaeger | 25 Elementare |
| Welpentoeter | 10 Drachkin |
| Riesentoeter | 10 Riesen |

**Mittlere Titel (100 Kills):**
| Titel | Anforderung |
|-------|-------------|
| Banditenjaeger | 100 Humanoide |
| Wildnisjaeger | 100 Wildtiere |
| Untotenjaeger | 100 Untote |
| Daemonenbekaempfer | 100 Daemonen |
| Funkensammler | 100 Elementare |

**Hohe Titel:**
- Seuchenreiniger (5.000 Untote)
- Drachenbane (1.000 Drachkin)
- Eredarbane (1.000 Daemonen)
- Bestienmeister (2.000 Wildtiere)
- Titanentoeter (250 Riesen)

**Raid-Titel:**
- Champion von Naxxramas (Kel'Thuzad)
- Bezwinger von C'Thun
- Drachentoeter (Nefarian)
- Bezwinger des Feuerlords (Ragnaros)

---

### ⚔️ KillStats Modul
Trackt automatisch getoetete Kreaturen nach Typ:

**27 Kill-Meilensteine** (vorher 21):
| Kreaturtyp | Stufen |
|------------|--------|
| Humanoide | 25, 100, 500, 2.000 |
| Wildtiere | 25, 100, 500, 2.000 |
| Untote | 25, 100, 500, 1.000, 5.000 |
| Daemonen | 25, 100, 500, 1.000 |
| Elementare | 25, 100, 500 |
| Drachkin | 10, 50, 250, 1.000 |
| Riesen | 10, 50, 250 |

---

### 📊 UI-Verbesserungen

**Fortschrittsbalken fuer Kill-Meilensteine:**
- Kompakte Leiste unter der Beschreibung
- Stoppt bei 100% (kein Ueberlauf mehr)
- Automatische Freischaltung wenn Ziel erreicht

**Bessere Lesbarkeit:**
- Charakter-Info in Gold statt Grau
- Kategorie-Header groesser und kontrastreicher
- Kill-Zeilen dynamisch hoeher fuer Progress-Platz

**Tooltip-Fix:**
- Titel erscheint nur noch einmal (nicht doppelt)

---

### 🔧 Neue Befehle

| Befehl | Funktion |
|--------|----------|
| `/gdl titles` | Titel-Auswahl oeffnen |
| `/gdl mytitles` | Eigene Titel anzeigen |
| `/gdl kills` | Kill-Statistiken |
| `/gdl killcheck` | Verpasste Meilensteine nachholen |
| `/gdl trackstatus` | GuildTracker Status (LIVE/offline) |

---

### 🔧 Technische Aenderungen

- **Module initialisieren jetzt korrekt** via PLAYER_ENTERING_WORLD
- **Doppelte Initialisierung verhindert** durch self.initialized Flag
- **Creature Type Caching** fuer Kill-Tracking (WoW gibt Typ nach Tod nicht)
- **Interpolation** fuer fluessige Kartenpin-Bewegung
- **OnUpdate Frame** fuer 20 FPS Pin-Updates

---

## Version 4.5.3
**Weniger Chat-Spam - Nur eine Startup-Meldung**

### Aenderungen
- **Nur noch eine Login-Meldung:** Buch der Gefallenen: Aktiv (v4.5.3)
- Entfernt: Alle Debug-Meldungen bei Login

---

# Guild Death Log - Changelog (English)

## Version 4.6.0
**MAJOR UPDATE: Real-Time Guild Map, Kill Milestones & Title System!**

### 🚨 CRITICAL BUG FIX
**Several modules were never initialized!** This affects:
- `GuildTracker` - Players on map weren't displayed
- `Sync` - Death synchronization didn't work properly
- `Professions` - Professions weren't synced
- `Milestones` - Level tracking didn't start

**All guild members must update to v4.6.0!**

---

### 🗺️ REAL-TIME Guild Map
See your guild members LIVE on the world map!

**Features:**
- **Real-time tracking**: Positions sync every 1.5 seconds
- **Smooth movement**: Pins move fluidly through interpolation (20 FPS)
- **Clean design**: Small colored dot in class color
- **Name on hover**: Name only appears when hovering with mouse
- **Tooltip**: Zone and last update shown

**Technical Details:**
| Setting | Value |
|---------|-------|
| Broadcast interval | 1.5 seconds |
| Stale timeout | 10 seconds |
| Pin update | 50ms (20 FPS) |
| Interpolation | Smooth Easing |

---

### 🏆 Custom Title System
Earn titles through milestones - visible to all guild members!

**31 titles available:**

**Easy Titles (10-25 kills):**
| Title | Requirement |
|-------|-------------|
| Highwayman | 25 Humanoids |
| Hunter | 25 Beasts |
| Grave Robber | 25 Undead |
| Demon Slayer | 25 Demons |
| Elemental Hunter | 25 Elementals |
| Whelp Slayer | 10 Dragonkin |
| Giant Slayer | 10 Giants |

**Medium Titles (100 kills):**
| Title | Requirement |
|-------|-------------|
| Bandit Hunter | 100 Humanoids |
| Wilderness Hunter | 100 Beasts |
| Undead Hunter | 100 Undead |
| Demon Fighter | 100 Demons |
| Spark Collector | 100 Elementals |

**High Titles:**
- Plague Cleanser (5,000 Undead)
- Dragonbane (1,000 Dragonkin)
- Eredarbane (1,000 Demons)
- Beastmaster (2,000 Beasts)
- Titan Slayer (250 Giants)

**Raid Titles:**
- Champion of Naxxramas (Kel'Thuzad)
- Slayer of C'Thun
- Dragonslayer (Nefarian)
- Firelord Slayer (Ragnaros)

---

### ⚔️ KillStats Module
Automatically tracks killed creatures by type:

**27 Kill Milestones** (previously 21):
| Creature Type | Tiers |
|---------------|-------|
| Humanoids | 25, 100, 500, 2,000 |
| Beasts | 25, 100, 500, 2,000 |
| Undead | 25, 100, 500, 1,000, 5,000 |
| Demons | 25, 100, 500, 1,000 |
| Elementals | 25, 100, 500 |
| Dragonkin | 10, 50, 250, 1,000 |
| Giants | 10, 50, 250 |

---

### 📊 UI Improvements

**Progress bars for kill milestones:**
- Compact bar below description
- Stops at 100% (no overflow)
- Auto-unlock when goal reached

**Better readability:**
- Character info in gold instead of gray
- Category headers larger and higher contrast
- Kill rows dynamically taller for progress bar

**Tooltip fix:**
- Title now appears only once (not duplicated)

---

### 🔧 New Commands

| Command | Function |
|---------|----------|
| `/gdl titles` | Open title selection |
| `/gdl mytitles` | Show your titles |
| `/gdl kills` | Kill statistics |
| `/gdl killcheck` | Catch up missed milestones |
| `/gdl trackstatus` | GuildTracker status (LIVE/offline) |

---

### 🔧 Technical Changes

- **Modules now initialize correctly** via PLAYER_ENTERING_WORLD
- **Double initialization prevented** through self.initialized flag
- **Creature type caching** for kill tracking (WoW doesn't provide type after death)
- **Interpolation** for smooth map pin movement
- **OnUpdate frame** for 20 FPS pin updates

---

## Version 4.5.3
**Less Chat Spam - Only One Startup Message**

### Changes
- **Only one login message:** Book of the Fallen: Active (v4.5.3)
- Removed: All debug messages at login
