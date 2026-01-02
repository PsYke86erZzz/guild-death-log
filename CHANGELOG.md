# Das Buch der Gefallenen - Changelog

## Version 4.2.0
**Duplikat-Schutz & Loesch-Funktion mit Passwort**

### Neue Features

**5-Minuten Duplikat-Schutz**
- Wenn ein Charakter mit dem gleichen Namen innerhalb von 5 Minuten stirbt, wird der zweite Tod NICHT geloggt
- Verhindert doppelte Eintraege durch Sync-Probleme oder Mehrfach-Meldungen

**Loesch-Funktion mit Passwort-Schutz**
- Sanfter X-Button (dezent, nur 30% sichtbar) bei jedem Todeseintrag
- X-Button erscheint nur wenn ein Admin-Passwort gesetzt ist
- Bei Klick auf X wird ein Passwort-Dialog angezeigt
- Nur mit korrektem Passwort kann ein Eintrag geloescht werden

### Neue Admin-Befehle (nur Gildenleiter/Offiziere)
- `/gdl setpw <passwort>` - Setzt das Admin-Passwort
- `/gdl clearpw` - Entfernt das Passwort (X-Buttons verschwinden)
- `/gdl haspw` - Zeigt ob ein Passwort gesetzt ist

### Technische Details
- `IsDuplicateByName()` - Neue Funktion fuer 5-Min-Namens-Check
- `VerifyPassword()` - Passwort-Verifizierung
- `DeleteDeath()` - Loescht einen Eintrag aus der Liste
- `ShowPasswordDialog()` - Passwort-Eingabe-Dialog
- Rang-Pruefung: Nur GM (Rang 0) und Offiziere (Rang 1-2) koennen Passwort setzen

---

## Version 4.1.2
**Debug-Tools für Meilensteine**

### Neue Befehle
- `/gdl mtest` - Zeigt detaillierten Meilenstein-Status
- `/gdl mcheck` - Prüft und holt Level-Meilensteine nach
- `/gdl mforce` - Erzwingt Freischaltung aller Level-Meilensteine

### Verbesserungen
- **Initialize zeigt jetzt Chat-Nachrichten** zur Bestätigung
- **CheckCurrentLevel** zeigt Nachrichten im Chat
- Mehr Debug-Output für Troubleshooting
- Level-Meilensteine werden bei Initialize automatisch geprüft

### Debug-Ausgaben
Bei `/gdl mtest` siehst du:
- Charaktername und Key
- Aktuelles Level
- Alle freigeschalteten Meilensteine
- Status aller Level-Meilensteine (✅/❌/⚠️)

---

## Version 4.1.1
**Level-Tracking Fix**

### Bug-Fix
- **Level-Tracking komplett überarbeitet** nach WoW_Hardcore Vorbild
- Event-Handler-System wie im WoW_Hardcore Addon implementiert
- `PLAYER_LEVEL_UP` Event wird jetzt korrekt verarbeitet
- `PLAYER_LOGIN` und `PLAYER_ENTERING_WORLD` Events für Level-Check beim Login
- Level wird jetzt aus dem Event-Parameter gelesen (nicht mehr aus `UnitLevel("player")` im Event-Handler)
- Debug-Ausgaben für besseres Troubleshooting

### Technische Änderungen
- Neues Event-Handler-Pattern: `self[event](self, ...)` 
- Separate Handler-Funktionen für jeden Event-Typ
- `CheckCurrentLevel()` Funktion für Login-Level-Check
- Mehr Debug-Ausgaben bei Level-Up und Login

---

## Version 4.1.0
**Meilenstein-System - Komplette Überarbeitung**

### BREAKING CHANGE: Achievements → Milestones
Das alte Achievement-System mit 46 generischen Erfolgen wurde komplett ersetzt durch ein neues **Meilenstein-System** mit echten Gameplay-Meilensteinen!

### Neues Meilenstein-System
- **100% Charakter-basiert** - Jeder Charakter hat seinen eigenen Fortschritt
- **Gilden-Synchronisation** - Meilensteine werden zwischen Gildenmitgliedern geteilt
- **Kein "NORMEN"-Bug mehr** - Korrekter Charaktername bei allen Events

### Meilenstein-Kategorien

**Level-Meilensteine (6)**
- Level 10, 20, 30, 40, 50, 60

**Dungeon-Bosse (24)**
- RFC, Deadmines, WC, SFK, BFD, Stocks
- Gnomeregan, alle SM-Flügel, RFK, RFD, Uldaman, ZF, Maraudon
- Sunken Temple, BRD, alle DM-Flügel, LBRS, UBRS, Scholomance, Stratholme

**Raid-Bosse (7)**
- Onyxia, Ragnaros (MC), Nefarian (BWL)
- Hakkar (ZG), Ossirian (AQ20), C'Thun (AQ40), Kel'Thuzad (Naxx)

**Berufe-Meilensteine (6)**
- Hauptberuf 150/225/300
- Angeln, Kochen, Erste Hilfe auf 300

### Neue UI
- **Kategorien-Navigation** mit Icons
- Übersichtliche Darstellung pro Kategorie
- Fortschrittsanzeige pro Charakter
- Datum & Level bei Freischaltung

### Entfernt
- Alle 46 alten Achievements
- Spielzeit-Tracking
- Gold-Tracking
- Quest-Tracking
- Feinde-getötet-Tracking
- Addon-Nutzungs-Tracking
- Buch-öffnen-Tracking
- Tode-beobachtet-Tracking

### Technisch
- Neues Modul: `Milestones.lua` (ersetzt `Achievements.lua`)
- Eigener Addon-Prefix `GDLMile` für Sync
- Boss-ID-Tracking via Combat Log
- Profession-Skill-Tracking via Classic API

---

## Version 4.0.3
**Minimap-Button & Debug-Verbesserungen**

### Neue Features
- **Minimap-Button** ☠️
  - Totenkopf-Icon, frei beweglich auf dem Bildschirm
  - Linksklick: Buch öffnen/schließen
  - Shift+Linksklick: Sync anfordern
  - Rechtsklick: Einstellungen öffnen
  - Position wird gespeichert

### Verbesserungen
- **Debug-Fenster komplett überarbeitet**
  - Online-Liste jetzt in eigener scrollbarer Box
  - 3 Boxen nebeneinander (Sync Status | Online | Deathlog)
  - Läuft nicht mehr aus dem Fenster raus
  - Fenster breiter (560px)

---

## Version 4.0.2
**Popup-Verbesserungen & Sync-Fixes**

### Popup-Overlay
- **Skalierbar** (50% - 200%) via Slider in Einstellungen
- **Frei verschiebbar** (Drag & Drop)
- **Position wird gespeichert**
- Rechtsklick schließt das Popup
- **Neues Design:**
  - Großer Totenkopf ☠️ als Hauptsymbol
  - Kleines Klassen-Icon am Totenkopf
  - Rote Linie oben als Todesmarkierung
  - Größere, besser lesbare Schrift (Name: 20pt)
  - Kompakteres Layout (340x110)
- Reset-Button in Einstellungen (setzt Position & Größe zurück)

### Sync-Fixes
- v1.2 Kompatibilität verbessert (Format wird zuerst gesendet)
- PLAYER_ENTERING_WORLD Event-Handling gefixt
- Mehr Debug-Ausgaben für Sync-Probleme
- `/gdl test` Befehl zum Testen der Sync-Funktion

---

## Version 4.0.1
**Statistik-Fenster Redesign & Settings-Migration**

### Statistik-Fenster
- **4 farbige Info-Boxen** mit Icons:
  - 📊 Zusammenfassung (Gold)
  - 🗺️ Gefährlichste Zonen (Pink)
  - ⚔️ Tödlichste Monster (Lila)
  - ⚔️ Klassen-Verteilung (Blau)
- Helle, gut lesbare Schrift
- Zweisprachige Labels (DE/EN)
- Side-by-Side Layout für Zonen/Monster
- Kompakteres Fenster (420x480)

### Bug-Fixes
- **Kritischer Fix:** Settings-Migration für bestehende User
- Alle Einstellungen werden bei Update automatisch aktiviert
- Verhindert dass Sync nach Update aus ist

---

## Version 4.0.0
**Großes Feature-Update**

### Neue Module (8 Stück)
- **LastWords** - Speichert letzte Chat-Nachrichten automatisch
- **KillerTracker** - Erfasst wer/was den Spieler getötet hat
- **Statistics** - Erweiterte Statistiken (Zonen, Level, Klassen, Killer)
- **Achievements** - 46 Überlebens-Erfolge mit Popup-System
- **HallOfFame** - Ruhmeshalle für Level 60 Überlebende
- **Condolences** - 15+ automatische Beileidsnachrichten
- **Export** - Text/Discord Export mit Custom-Channel
- **Debug** - Debug-Fenster mit Aktivitäts-Log

### Achievements (46 Stück)
Alle Erfolge basieren auf ÜBERLEBEN, nicht auf Toden anderer:
- Überlebenszeit (1 Stunde bis 30 Tage)
- Level-Meilensteine (10, 20, 30, 40, 50, 60)
- Zonen-Erkundung
- Gilden-Aktivität
- Spezial-Erfolge

### Sync-System
- Protokoll v4.0 (abwärtskompatibel zu v1.2)
- Online-User Tracking
- PING/PONG System
- Automatischer Sync bei Login

### UI-Verbesserungen
- Immersives Buch-Design (Pergament-Optik)
- Elegante Todes-Einträge mit Klassenfarben
- Statistik-Fenster
- Erfolge-Fenster
- Hall of Fame Fenster

---

## Version 1.2 (Original)
**Basis-Version von PsYke86**

- Gilden-Tode tracken
- Sync zwischen Gildenmitgliedern
- Gildenchat-Ankündigungen
- Sound bei Tod
- Popup-Overlay
- Deathlog-Integration
