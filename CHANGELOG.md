# Das Buch der Gefallenen - Changelog

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
