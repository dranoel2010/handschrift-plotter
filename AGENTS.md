# AGENTS.md – Anleitung für KI-Agenten

Diese Datei richtet sich an KI-Agenten (Claude Code, Codex usw.), die in diesem Repo arbeiten. Für Menschen ist `README.md` gedacht.

## Ziel des Projekts

Ein alter 3D-Drucker **Artillery Genius Pro** wird zum **Stiftplotter** umgebaut. Ein Python-Skript soll beliebigen Text **in der Handschrift des Besitzers** als G-Code ausgeben:

- Für jeden Buchstaben gibt es **3–5 aufgenommene Varianten**. Pro Vorkommen wird eine davon zufällig gewählt.
- Leichte Zufallsabweichungen bei Neigung, Größe, Grundlinie und Buchstabenabstand, damit der Text nicht maschinell wirkt
- Die Ausgabe ist eine `.gcode`-Datei, die der Drucker von SD-Karte oder per USB abarbeitet.

## Hardware – feste Fakten

| Punkt | Wert |
|---|---|
| Drucker | Artillery Genius Pro, Firmware **Marlin** |
| Bauraum | 220 × 220 mm (X × Y) |
| Bewegung | Kopf fährt in X, **Bett fährt in Y** |
| Stift heben/senken | über die **Z-Achse** (kein Servo). `Z0` = Stift auf Papier, `Z3` = Stift hoch, `Z20` = weit hoch |
| Papier | A5 passt komplett, A4 **nicht ganz** |
| Stifthalter | noch offen (erst provisorisch mit Kabelbindern, später gefederter Eigenbau in OpenSCAD) |
| Versatz Stift ↔ Düse | **noch nicht gemessen**. Bis dahin keine absoluten Koordinaten als „exakt“ annehmen. |

## G-Code-Regeln (unbedingt einhalten)

1. **Kein `G28` ohne Achsangabe und kein `G28 Z`.** Nur `G28 X Y`. Ein Z-Homing würde den Stift ins Bett drücken bzw. den Nullpunkt zerstören.
2. **Kein Auto-Bed-Leveling** (`G29`) und kein `M420`.
3. Am Anfang immer: Heizungen und Lüfter aus (`M104 S0`, `M140 S0`, `M107`), `G21`, `G90`, `G92 Z0`, dann **zuerst Stift hoch** (`G1 Z5`) und erst danach `G28 X Y`.
4. Stift **immer anheben**, bevor eine Leerfahrt (`G0`) kommt. Keine Leerfahrt mit `Z0`.
5. Koordinaten müssen im Bereich **0–220** für X und Y bleiben. Am besten prüft das Skript es selbst und bricht sonst ab.
6. Vorschübe: Zeichnen `F2000`, Leerfahrt `F6000`, Z `F600`. Ändern nur, wenn der Nutzer es nach einem Test so will.
7. Am Ende: `G1 Z20`, Bett nach vorn (`G0 X0 Y200`), `M84`.
8. Kommentare im G-Code auf Deutsch, mit `;`.

Vorlage für Kopf und Ende: `test.gcode`.

## Dateien

- `README.md`: Kurzbeschreibung für Menschen
- `test.gcode`: Probelauf (Quadrat 60 × 60 mm, Diagonalen, Kreis r = 25 um X110 Y110). Bisher **nicht auf dem Drucker getestet**.
- `proben/` (**git-ignoriert**, Repo ist öffentlich): `proben/schulapp/` = 18 Heftseiten-Fotos aus der Schulapp (1200×1600, Karopapier) als Stilreferenz. Nie committen.
- Geplant (noch nicht vorhanden): Python-Skript Text → G-Code, saubere Glyphen-Proben, OpenSCAD-Datei für den Stifthalter

## Offene Entscheidungen – nicht eigenmächtig festlegen

- **Format der Schriftproben**: z. B. SVG-Pfade pro Glyphe oder JSON mit Strichlisten aus Tablet und Stylus. Vorschläge machen, aber den Nutzer entscheiden lassen.
- Wie Buchstaben verbunden werden (Schreibschrift oder Druckschrift)
- Maße des Druckkopfs für den Stifthalter (müssen gemessen werden)

## Arbeitsweise

- Sprache: **Deutsch** (Code-Bezeichner dürfen Englisch sein, Kommentare und Commit-Messages auf Deutsch)
- Python 3, möglichst **ohne schwere Abhängigkeiten** (Standardbibliothek bevorzugt)
- Kleine, nachvollziehbare Commits. Nicht pushen, ohne dass der Nutzer es will.
- Vor jeder G-Code-Änderung prüfen: Gibt es eine Leerfahrt mit gesenktem Stift? Bleibt alles im Bauraum? Fehlt irgendwo ein `G28 Z`?
- Möglichst jede erzeugte Datei auch als **Vorschau** ausgeben (z. B. SVG/PNG der Stiftbahnen), bevor sie auf den Drucker geht

## Kontext außerhalb des Repos

Dieses Repo liegt als Arbeitskopie im Wiki des Nutzers unter `topics/vibe-coding/code/handschrift-plotter/`. Der Steckbrief mit dem aktuellen Stand und den offenen Punkten liegt unter `topics/vibe-coding/wiki/topics/handschrift-plotter.md`. Nach größeren Schritten sollte man ihn aktualisieren, wenn das Wiki erreichbar ist.
