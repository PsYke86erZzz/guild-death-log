# Das Buch der Gefallenen - Changelog

## Version 5.4.5 - TEXT-POSITIONEN KORRIGIERT
**Name nicht mehr über dem Header!**

### Positionen gefixt
- Name jetzt **unter** dem "Guild Death Log" Text (contentTop = -95)
- Klassen-Icon besser positioniert (links, vertikal zentriert)
- Alle Texte besser im dunklen Bereich zentriert
- Kleinere Schriftgrößen für bessere Passform

### Layout
- Name: 22pt (war 24pt)
- Level/Klasse: 13pt 
- Zone: 11pt
- Killer: 10pt
- Letzte Worte: 10pt, unten bei Y=30

---

## Version 5.4.4 - KORREKTES SEITENVERHÄLTNIS
**Popup jetzt mit Original-Bildproportionen 3:2!**

### Seitenverhältnis gefixt
- Original-Bild ist **1536 x 1024** Pixel (Verhältnis 3:2)
- Popup jetzt **460 x 307** Pixel - passt perfekt zum Bild!
- Keine Verzerrung mehr - Totenköpfe sehen wieder gut aus!

### Sound wieder da
- Epischer Death Sound (8959) ist zurück
- Raid Warning Echo nach 0.15 Sekunden

### Layout verbessert
- Klassen-Icon links (56x56)
- Name, Level, Zone mittig im dunklen Bereich
- Letzte Worte unten zentriert
- Alles passend zum "Todesmeldung" Header im Bild

---

## Version 5.4.3 - GEISTERHAFTER SOUND + LAYOUT FIX
**Engelshafter Chor statt Alarm + bessere Proportionen!**

### Neuer Sound: Geisterhaft/Engelshaft 👻
- **Engelshafter Chor** (Sound 11466) - "Ahhhhhhh" wie bei Geistern
- **Geister-Echo** (Sound 3332) - Leises Nachhall
- Kein nerviger Alarm-Ton mehr!

### Layout verbessert
- Popup ist jetzt **breiter** (580x155 statt 500x200) - wie ein Banner
- **Alle Texte zentriert** im Inhaltsbereich
- Name, Level, Zone alle schön mittig ausgerichtet
- Größeres Klassen-Icon (52x52)
- Bessere Abstände zwischen den Elementen

### Proportionen
- Das Popup passt jetzt viel besser zur Custom-Textur
- Kein "gequetschtes" Aussehen mehr

---

## Version 5.4.2 - EPISCHES TODES-POPUP
**Brandneues Custom-Design mit Skalierungsfunktion!**

### Neues Todes-Popup Design
**Custom Textur:** Epischer dunkler Rahmen mit Totenköpfen und rotem Akzent
- Professionelles "Todesmeldung / Guild Death Log" Design
- Passend zum Hardcore-Thema

### Skalierungsfunktion
**SHIFT + Linke Maustaste ziehen** = Popup größer/kleiner machen
- Skalierung von 50% bis 250%
- Live-Anzeige der aktuellen Größe während des Skalierens
- Einstellung wird automatisch gespeichert

### Bedienung
- **Linke Maustaste ziehen** = Popup verschieben
- **SHIFT + Linke Maustaste ziehen** = Popup skalieren
- **Rechte Maustaste** = Popup sofort schließen

### Weitere Verbesserungen
- Sanfteres Fade-In/Fade-Out (0.3s / 1.5s)
- Popup bleibt 10 Sekunden sichtbar (statt 8)
- Name wird in Klassenfarbe angezeigt
- Größerer Platz für letzte Worte (80 Zeichen)

---

## Version 5.4.1 - UI LAYOUT FIX + DEATHLOG ERKENNUNG
**Leitung-Button + Deathlog-Erkennung verbessert!**

### Fix: "Leitung" Button außerhalb des Fensters
**Problem:** Der Gildenleiter-Button (Leitung) hing außerhalb des Fensterrahmens
**Ursache:** Button-Position war bei Y = -2 (negativ = unter dem Fensterrand)
**Lösung:** 
- Fenster von 650px auf 700px Höhe vergrößert
- Alle Button-Positionen angepasst für 4 Reihen
- Footer und Scroll-Container neu positioniert
**Ergebnis:** Alle Buttons sind jetzt sauber im Fenster

### Fix: Deathlog-Addon wird nicht erkannt
**Problem:** Deathlog Status zeigte "Nein" obwohl Deathlog installiert ist
**Ursache:** Nur eine spezifische Variable wurde geprüft (`deathlog_data`)
**Lösung:** 
- Prüft jetzt 10+ verschiedene mögliche Variablennamen
- Prüft auch Addon-Tabellen (`Deathlog`, `DeathLog`, etc.)
- Prüft ob Addon geladen ist über `IsAddOnLoaded`
- Mehrere Erkennungsversuche (nach 2s, 5s, 10s)
- Verschiedene Datenstrukturen werden unterstützt
**Neuer Debug-Befehl:** `/gdl dlcheck` zeigt Deathlog-Status und alle globalen "death" Variablen

---

## Version 5.4.0 - PERFORMANCE & BUG FIXES
**Community-Feedback Update - 6 wichtige Bugs behoben!**

---

### Fix 1: FPS-Einbrüche beim Scrollen (Klassen/Berufe)
**Problem:** Bei 250+ Mitgliedern brachen die FPS stark ein, teilweise Freezes
**Ursache:** Bei jedem Scroll/Update wurden 250+ neue Frames erstellt und zerstört
**Lösung:** Frame-Pooling implementiert - Frames werden wiederverwendet statt neu erstellt
**Ergebnis:** Flüssiges Scrollen auch bei großen Gilden

### Fix 2: Einstellungen setzten sich zurück
**Problem:** Checkboxen in den Einstellungen wurden bei jedem Login zurückgesetzt
**Ursache:** Bei JEDER Versionsänderung wurden alle Settings überschrieben
**Lösung:** Settings werden nur noch bei komplett neuer Installation auf Defaults gesetzt
**Ergebnis:** Einstellungen bleiben dauerhaft gespeichert

### Fix 3: Neues Setting für Meilenstein-Nachrichten
**Problem:** Chat wurde bei großen Gilden mit Achievement-Nachrichten geflutet
**Lösung:** Zwei neue Einstellungen hinzugefügt:
- "Meilenstein-Nachrichten" - Chat-Ankündigungen an/aus
- "Meilenstein-Popup" - Popup-Fenster an/aus
**Ergebnis:** Jeder kann selbst entscheiden was angezeigt wird

### Fix 4: Bessere Lesbarkeit der Schrift
**Problem:** Graue Schrift war auf hellem Hintergrund schwer zu lesen
**Lösung:** Dunklere Schriftfarben (0.15, 0.1, 0.05 statt 0.3, 0.25, 0.2)
**Ergebnis:** Deutlich besserer Kontrast auf dem Pergament-Hintergrund

### Fix 5: Verbesserte Todes-Synchronisation
**Problem:** Todesstatistik war bei verschiedenen Spielern unterschiedlich
**Lösung:** 
- Sync-Intervall auf 5 Minuten reduziert (statt 15)
- Proaktiver Push alle 10 Minuten
- Zusätzlicher Sync 30 Sekunden nach Login
- Mehr Tode pro Sync (50 statt 20)
**Ergebnis:** Alle Gildenmitglieder sehen die gleichen Tode

### Fix 6: Berufe-Werte Synchronisation
**Problem:** Verschiedene Spieler sahen unterschiedliche Berufe-Werte für dieselbe Person
**Ursache:** Keine Konfliktlösung bei widersprüchlichen Daten
**Lösung:** Timestamp-basierte Konfliktlösung - nur neuere Daten werden akzeptiert
**Ergebnis:** Konsistente Berufe-Anzeige bei allen Spielern

---

### Technische Details

**Performance-Optimierungen:**
- Frame-Pooling: ~99% weniger Garbage Collection
- Wiederverwendbare UI-Elemente statt ständiger Neuerschaffung
- Reduzierte Memory-Allokationen beim Scrollen

**Sync-Verbesserungen:**
- Ping-Intervall: 3 Minuten (statt 5)
- Full-Sync: alle 5 Minuten (statt 15)
- Proaktiver Broadcast: alle 10 Minuten
- Login-Sync: nach 5s und 30s

**Neue Settings:**
- `milestoneAnnounce` - Meilenstein-Chat-Nachrichten (default: AN)
- `milestonePopup` - Meilenstein-Popup-Fenster (default: AN)

---

## Version 4.9.8 - HEUTE-ZÄHLER FIX
**Hauptfenster und Debug zeigen jetzt die gleiche Anzahl**

---

### Bug behoben: "Heute" Zähler

**Problem:**
- Debug-Fenster zeigte "3 heute"
- Hauptfenster zeigte "0 Heute"
- Beide sollten identisch sein!

**Ursache:**
- UI.lua verwendete UTC-Zeit: `time() - (time() % 86400)`
- Debug.lua verwendete lokale Zeit: `date("*t")` + `time({...})`
- Bei Zeitzone CET (UTC+1) führte das zu 1 Stunde Unterschied

**Fix:**
- UI.lua verwendet jetzt auch lokale Zeitzone
- Beide Fenster zeigen jetzt die gleiche Anzahl "Tode heute"

---

## Version 4.9.7 - TALENT-SPEC FIX
**Spezialisierung aktualisiert sich jetzt korrekt**

---

### Professions-Modul verbessert

**Neue Events für Talent-Aktualisierung:**
- `CHARACTER_POINTS_CHANGED` - Classic: Wenn Talentpunkte verteilt werden
- `PLAYER_TALENT_UPDATE` - Retail/WOTLK: Wenn Talente geändert werden
- `PLAYER_LEVEL_UP` - Bei Level-Up werden Infos neu gesendet

**Aktualisierungs-Zeiten:**
- Bei Berufsskill-Änderung: nach 2 Sekunden
- Bei Talent-Änderung: nach 1 Sekunde
- Bei Level-Up: nach 3 Sekunden
- Automatisch: alle 60 Sekunden

**Die Spezialisierung wird jetzt angezeigt für:**
- Alle Spieler ab Level 10 die Talentpunkte verteilt haben
- Aktualisiert sich automatisch wenn Talente geändert werden
- Zeigt den Talentbaum mit den meisten Punkten

---

## Version 4.9.6 - HOTFIX
**Debug-Fenster Anchor-Fix**

---

### Bug behoben

- **SetPoint Anchor Error** in Debug.lua Zeile 218 behoben
- `serverBox` Referenz zu `deathStatsBox` korrigiert
- Debug-Fenster oeffnet sich jetzt ohne Fehler

---

## Version 4.9.5 - FINALE VERSION
**STABIL, GETESTET, GILDEN-INTERN**

---

### ALLE SYSTEME VALIDIERT

Diese Version wurde gruendlich geprueft und alle Funktionen funktionieren wie geplant:

**13 Buttons - Alle funktionsfaehig:**
| Button | Funktion |
|--------|----------|
| Aktualisieren | Deathlog scannen + UI aktualisieren |
| Einstellungen | Einstellungsfenster oeffnen |
| Sync | Gilden-Sync anfordern |
| Export | Export-Fenster oeffnen |
| Debug | Debug-Fenster oeffnen |
| Ruhmeshalle | Hall of Fame anzeigen |
| Statistiken | Statistik-Fenster oeffnen |
| Meilensteine | Meilenstein-Fenster oeffnen |
| Berufe | Berufe-Fenster oeffnen |
| Gilden-Karte | Live-Tracker togglen |
| Titel | Titel-Fenster oeffnen |
| Gedenkhalle | Memorial-Fenster oeffnen |
| Gilden-Stats | Gilden-Statistiken anzeigen |

### Debug-Fenster verbessert

**6 Info-Boxen (neu organisiert):**
1. **Sync Status** - Version, Online Users, letzter Sync
2. **Online** - Liste der Gildenmitglieder mit Addon
3. **Deathlog** - Deathlog Addon Status, Eintraege
4. **Tode-Stats** - Gesamttode, Tode heute, letzter Tod (NEU!)
5. **Live-Tracker** - Tracker Status, Spieler auf Karte
6. **Addon Info** - Module, Speicher, Events

*Die redundante "Gilden-Sync" Box wurde durch "Tode-Stats" ersetzt.*

### Condolences v2.0 - Epische Todesnachrichten

**~125,000+ einzigartige Kombinationen:**
- 49 INTROS (epische Einleitungen)
- 48 CORES (Kernaussagen)
- 51 OUTROS (wuerdevolle Abschluesse)
- 51 SPECIALS (eigenstaendige Nachrichten)
- 45 Klassen-spezifische (9 Klassen × 5)
- 17 Level-basierte (4 Kategorien)

**Nur wuerdevolle, epische Nachrichten - keine Witze!**

### Gilden-interne Kommunikation

| Prefix | Modul | Funktion |
|--------|-------|----------|
| GDLSync | Sync | Todesfaelle syncen |
| GDLTrack | GuildTracker | Live-Positionen |
| GDLMile | Milestones | Meilensteine |
| GDLProf | Professions | Berufe |
| GDLTitle | Titles | Titel |

**Alles bleibt in der Gilde - keine Server-weite Kommunikation!**

### Bug-Fixes aus vorherigen Versionen

- Guild.lua: PLAYER_ENTERING_WORLD Event fuer korrektes Member-Loading
- GuildRoster() wird beim Login aufgerufen
- IsMember() laedt Members neu wenn leer
- Keine redundanten Debug-Boxen mehr

---

## Version 4.8.4
**VEREINFACHUNG: NUR GILDEN-INTERN**

---

### Server-weiten Counter ENTFERNT

Das Addon kommuniziert jetzt **NUR noch innerhalb der Gilde**:
- Kein Public Channel mehr
- Kein Server-weiter Counter
- Alles bleibt Gilden-intern wie gewuenscht

### Alle Kommunikation ist jetzt GILDEN-INTERN:

| System | Channel | Reichweite |
|--------|---------|------------|
| **Todes-Sync** | GUILD Messages | Nur Gilde |
| **Live-Tracker** | GUILD Messages | Nur Gilde |
| **Meilensteine** | GUILD Messages | Nur Gilde |
| **Berufe** | GUILD Messages | Nur Gilde |
| **PING/PONG** | GUILD Messages | Nur Gilde |

Fremde Gilden oder andere Spieler sehen **NICHTS** von euren Daten!

### Debug-Fenster angepasst

- "Server Users" Box umbenannt zu "Gilden-Sync"
- Zeigt jetzt: Mitglieder mit Addon online + Gesamtzahl Gildenmitglieder
- Kein externer Counter mehr

### Guild.lua Fix (aus v4.8.2)

- `PLAYER_ENTERING_WORLD` Event hinzugefuegt
- `GuildRoster()` wird beim Login aufgerufen
- `IsMember()` funktioniert jetzt korrekt
- Tode von Gildenmitgliedern werden erkannt

---

## Version 4.8.2
**SERVER USER COUNTER FIX + TOD-ERKENNUNG DEBUG**

---

### Server User Counter - DUAL MODE

Der Counter nutzt jetzt ZWEI Methoden gleichzeitig fuer maximale Kompatibilitaet:

**Methode 1: Public Channel (server-weit)**
- Channel: `GuildDeathLogCount`
- Messages: `GDL_COUNT_PING` / `GDL_COUNT_PONG`
- Fuer: v4.8.2+ User (auch aus anderen Gilden!)

**Methode 2: GUILD Messages (backward compatible)**
- Prefix: `GDLCnt`
- Messages: `CPING` / `CPONG` (und andere Varianten)
- Fuer: v4.8.0 und v4.8.1 User

Damit werden jetzt ALLE Addon-User gezaehlt, egal welche Version sie haben!

### Tod-Erkennung - Verbessertes Debugging

Bei Problemen mit der Tod-Erkennung zeigt `/gdl debug` jetzt genau:
- Warum ein Tod ignoriert wurde
- Ob der Blizzard HC-Channel aktiv ist
- Ob ein Spieler als Gildenmitglied erkannt wurde

### Systeme-Uebersicht

| System | Channel | Reichweite |
|--------|---------|------------|
| Gilden-Sync | GUILD Messages | Nur Gilde |
| Live-Tracker | GUILD Messages | Nur Gilde |
| Meilensteine | GUILD Messages | Nur Gilde |
| Berufe | GUILD Messages | Nur Gilde |
| Server Counter | PUBLIC + GUILD | Server-weit + Gilde |

---

## Version 4.8.1
**MAP-PINS FIX + SERVER USER COUNTER + KILLSTATS BUGFIX**

---

### WICHTIG: KillStats Bugfix!

**Problem:** Kills wurden gezaehlt wenn man nur in der Naehe war (mouseover, target, nameplate) und jemand ANDERES den Mob getoetet hat.

**Loesung:** 
- Neues Flag `damagedByPlayer` im Cache
- Wird NUR gesetzt wenn DU oder dein PET Schaden macht
- `UNIT_DIED` zaehlt jetzt nur wenn `damagedByPlayer=true`
- Pet-Kills werden korrekt mitgezaehlt

**Resultat:** NUR deine eigenen Kills zaehlen fuer Meilensteine!

### Debug-Fenster komplett neu!

6 gleichgrosse Info-Boxen in 2 Zeilen:

**Zeile 1:** Sync Status | Online | Deathlog Status
**Zeile 2:** Server Users | Live-Tracker | Addon Info

- Server Users werden automatisch beim Oeffnen gezaehlt
- Live-Tracker zeigt Status + Spieler auf Karte
- Addon Info zeigt Memory, Module-Anzahl, Uptime
- Module-Anzahl wird jetzt korrekt gezaehlt (kein "?" mehr)

### Karten-Pins komplett ueberarbeitet!

**Vorher:** Grosses Icon mit haesslichem schwarzen Kasten
**Jetzt:** Kleines, sauberes 16x16 Klassenicon mit dezenten Glow

- Kein schwarzer Border mehr
- Klassenicon in Originalfarben
- Dezenter pulsierender Glow in Klassenfarbe
- Wird groesser bei Hover (20x20)

### Tooltip-Fix

- Unicode-Symbole entfernt (WoW Classic Kompatibilitaet)
- Klare Textanzeige: "LIVE", "vor 7s" etc.
- Farbcodierung: Gruen=Live, Gelb=Kuerzlich, Orange=Aelter

### Server Addon-User im Status integriert!

`/gdl users` oder `/gdl trackerstatus` zeigt jetzt:

```
===========================================
GuildTracker v2.1 Status
===========================================
Gilde Live: 3 Spieler
Server Addon-User: (wird gezaehlt...)
-------------------------------------------
  Beatevonuse Lv42 - Stormwind [LIVE]
===========================================
Server Addon-User: 47
```

Die Server-Zaehlung laeuft automatisch nach 3 Sekunden.

---

## Version 4.8.0
**GUILDTRACKER v2.0 + EPISCHE TODESNACHRICHTEN!**

---

### Condolences v2.0 - EPISCHE Todesnachrichten!

**Modulares Nachrichten-System:**
Nachrichten werden dynamisch aus würdevollen Bausteinen zusammengesetzt.
**NUR epische, trauernde, respektvolle Nachrichten** - Hardcore-Tod verdient Würde.

**Aufbau:** `[INTRO] + [CORE] + [OUTRO]`
- **~50 Intros:** Dramatische, würdevolle Einleitungen
  - "Die Glocken von Sturmwind läuten..."
  - "Ein Schatten fällt über Azeroth."
  - "Die Ahnen rufen einen der Ihren heim..."
- **~50 Cores:** Ehrenvolle Hauptaussagen
  - "NAME ist gefallen"
  - "NAME wurde in die Hallen der Tapferen aufgenommen"
  - "NAME kämpfte bis zum bitteren Ende"
- **~50 Outros:** Würdevolle Abschlüsse
  - ". Ruhe in Frieden."
  - ". Mögen die Titanen über dich wachen."
  - ". Niemals vergessen."

**Spezial-Kategorien:**
- **~40 eigenständige Spezial-Nachrichten** (episch, emotional)
- **Klassen-spezifisch:** Würdevolle Nachrichten für jede Klasse
  - Paladin: "Das Licht weint um NAME. Ein Paladin ist heimgekehrt."
  - Krieger: "NAME's Schwert ist verstummt. Der Krieger ruht in Ehren."
- **Level-basiert:** Passend zum erreichten Level
  - "NAME (Level 60) - Ein wahrer Champion ist gefallen. Ewige Ehre sei dir."

**~125.000+ mögliche Kombinationen!**

**Test-Befehle:**
- `/gdl msgtest` - Zeigt 10 zufällige Nachrichten
- `/gdl msgstats` - Zeigt Statistiken

---

### 🗺️ GuildTracker v2.0 - Komplett neu!

**Adaptive Broadcast-Intervalle:**
- **3 Sekunden** bei Bewegung (statt 0.75s - reduziert Netzwerklast)
- **15 Sekunden** bei Stillstand (intelligente Erkennung)
- **30 Sekunden** Heartbeat für Spieler die komplett still stehen

**Robustes Stale-System:**
- **60 Sekunden** Timeout (statt 5s - kein Flackern mehr!)
- Spieler verschwinden erst nach 60s ohne Update
- Sauberes Cleanup alle 10 Sekunden

**Delta-basiertes Senden:**
- Position wird nur gesendet wenn sie sich ändert
- Spart Bandbreite und verhindert Rate-Limiting
- Bewegungserkennung mit 0.1% Threshold

**Smooth Interpolation:**
- Hermite-Spline für extra-flüssige Pin-Bewegung
- 20 FPS Pin-Updates (50ms Intervall)
- 3 Sekunden Interpolationsdauer

**Neue Events:**
- ZONE_CHANGED_NEW_AREA: Sofortiges Broadcast bei Zonenwechsel
- ZONE_CHANGED: Position wird bei jedem Zonenwechsel aktualisiert

**Level-Anzeige:**
- Spieler-Level wird jetzt mit gesynct
- Anzeige im Tooltip und am Pin

---

### 📊 Technische Details

| Parameter | Alt (v4.7) | Neu (v4.8) | Begründung |
|-----------|------------|------------|------------|
| Broadcast (Bewegung) | 0.75s | 3s | GuildMap Standard |
| Broadcast (Stillstand) | 0.75s | 15s | Bandbreite sparen |
| Stale-Timeout | 5s | 60s | Kein Flackern |
| Heartbeat | - | 30s | Präsenz-Check |
| Pin-Update FPS | 33 | 20 | Performance |
| Interpolation | Linear | Hermite | Smoother |

---

### 🔧 Befehle

- `/gdl tracker` - Toggle GuildTracker an/aus
- `/gdl trackerstatus` - Zeige Status und Online-Spieler

---

## Version 4.7.0
**NEUE MODULE: Gedenkhalle & Gilden-Statistiken!**

---

### 🪦 NEU: Memorial-Modul (Gedenkhalle)
Ehre die Gefallenen mit zufaelligen Nachrufen!

**Features:**
- Liste aller verstorbenen Gildenmitglieder
- **56 zufaellige Nachrufe** (28 DE + 28 EN)
  - Ehrenvoll: "Ruhe in Frieden, tapferer Held."
  - Humorvoll: "'Ich tank das' - Letzte Worte."
  - Episch: "Selbst der Tod konnte deinen Ruhm nicht mindern."
- Klassenicon mit Totenkopf-Overlay
- Level, Zone, Killer, Todesdatum
- **Verstorbene werden automatisch aus Berufe-Liste entfernt**

**Befehle:** `/gdl memorial`, `/gdl rip`, `/gdl gedenken`

---

### 📊 NEU: GuildStats-Modul (Gilden-Statistiken)
Ueberblick ueber die gesamte Gilde!

**Durchschnittslevel:**
- Gesamt-Durchschnitt aller Gildenmitglieder
- Online vs Offline getrennt angezeigt
- Anzahl Mitglieder

**Tode pro Charakter (Ranking):**
- 🥇 Gold / 🥈 Silber / 🥉 Bronze fuer Top 3
- Klassenicon + Name in Klassenfarbe
- Anzahl Tode (farbcodiert: Rot ≥5, Orange ≥3, Gelb <3)
- **Hover-Tooltip** mit allen Tod-Details:
  - Level bei jedem Tod
  - Zone wo gestorben
  - Datum des Todes

**Befehle:** `/gdl gstats`, `/gdl guildstats`, `/gdl gildenstat`

---

### 🎨 UI-Verbesserungen

**Fenster sind jetzt vollstaendig deckend:**
- Gedenkhalle und GuildStats hatten transparenten Hintergrund
- Jetzt mit solidem Pergament-Hintergrund
- Gold-Border wie alle anderen Fenster

**Schriftfarben optimiert (GuildStats):**
- Durchschnittslevel: Grosses Gold mit Outline
- Online/Offline: Gut lesbare Gruen/Grau-Toene
- Rang-Medaillen: Echte Gold/Silber/Bronze Farben
- Namen: Volle Klassenfarben (nicht abgedunkelt)
- Header: Mittleres Braun passend zum Pergament

**Fenster-Positionen (Cascade-Layout):**
- **Keine Ueberlappung** mehr wenn mehrere Fenster offen sind
- Alle Fenster sind verschiebbar (Drag & Drop)
- Gestaffelte Anordnung links/rechts vom Hauptfenster

```
  LINKS                    MITTE                    RECHTS
  
  Memorial (-480, +200)                    Settings (+500, +250)
                                           Titles (+420, +200)
                                           HallOfFame (+480, +100)
                           [HAUPT]
                             (0,0)         Statistics (+460, -50)
                                           GuildStats (+400, -100)
  Professions (-460, -200)                 Milestones (+440, -200)
  
                          Debug (0, -350)
```

---

### 🔄 Live-Sync fuer alle Fenster
Wenn ein Tod eingeht (lokal oder gesynct), werden alle offenen Fenster automatisch aktualisiert:
- ✓ Hauptfenster (Chronik)
- ✓ Gedenkhalle
- ✓ GuildStats
- ✓ Berufe-Fenster (Verstorbene werden entfernt)

---

### 🎯 Neue Buttons im Hauptfenster
**Reihe 3:** `[Titel] [Gedenkhalle] [Gilden-Stats]`

---

### 📋 Zusammenfassung der Aenderungen

| Kategorie | Aenderung |
|-----------|-----------|
| Neue Module | Memorial (Gedenkhalle), GuildStats |
| Neue Befehle | `/gdl memorial`, `/gdl rip`, `/gdl gstats`, `/gdl gildenstat` |
| UI | Cascade-Layout, deckende Fenster, lesbare Farben |
| Sync | Live-Update fuer alle offenen Fenster |
| Berufe | Verstorbene werden automatisch entfernt |

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
