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
| Bauraum | 220 × 220 mm Fahrweg (X × Y); die Druckplatte selbst ist 230 × 230 mm (vom Nutzer gemessen) |
| Bewegung | Kopf fährt in X, **Bett fährt in Y** |
| Stift heben/senken | über die **Z-Achse** (kein Servo). `Z0` = Stift auf Papier, `Z3` = Stift hoch, `Z20` = weit hoch |
| Papier | A5 passt komplett, A4 **nicht ganz** |
| Befestigung Halter | Werte vom 01.11. (70 mm zur Düse, Schraube 14 mm/Kopf Ø 6, Abstand 33 mm) sind **unklar zugeordnet** – vor Verwendung für Gruppe 2 neu messen |
| Stifthalter | `hardware/stifthalter.scad/.stl` v4 (01.11., ungedruckt; Form nach Konzeptbild `proben/…20.44.52.jpeg`): zwei getrennte Arme an den 2 kleinen Schrauben des blauen Metallwinkels („Gruppe 2“, Langlöcher), nach vorn über den Kasten (Vorderseite → Schraubenköpfe 60 mm gemessen, im Modell 63 mm ab Winkelfläche), davor nach unten; oberer Teil 8 mm hoch mit Platte zwischen den Armen; Führungsring auf halber Höhe + Becher unten mit Absatz. **Keine Feder: Stift schwimmt mit Eigengewicht**, oben herausziehbar. Stift-Ø 10 mm, Spitzenloch 6 mm, M3 angenommen |
| Versatz Stift ↔ Düse | **noch nicht gemessen**. Bis dahin keine absoluten Koordinaten als „exakt“ annehmen. |

## G-Code-Regeln (unbedingt einhalten)

1. **Kein `G28` ohne Achsangabe und kein `G28 Z`.** Nur `G28 X Y`. Ein Z-Homing würde den Stift ins Bett drücken bzw. den Nullpunkt zerstören.
2. **Kein Auto-Bed-Leveling** (`G29`) und kein `M420`.
3. Am Anfang immer: **Filament-Sensor aus (`M412 S0`)** – ohne Filament pausiert der Drucker sonst und piept. Heizungen praktisch aus (`M104 S10`, `M140 S10`; heizt bei Raumtemperatur nie), Lüfter aus (`M107`), `G21`, `G90`, `G92 Z0`, dann **zuerst Stift hoch** (`G1 Z5`) und erst danach `G28 X Y`.
4. Stift **immer anheben**, bevor eine Leerfahrt (`G0`) kommt. Keine Leerfahrt mit `Z0`.
5. Koordinaten müssen im Bereich **0–220** für X und Y bleiben. Am besten prüft das Skript es selbst und bricht sonst ab.
6. Vorschübe: Zeichnen `F1000` (F2000 war im ersten Schrifttest zu schnell, Linien rissen ab), Leerfahrt `F6000`, Z `F600`, Hub zwischen Linien 5 mm. Ändern nur nach Test mit dem Nutzer.
7. Am Ende: `G1 Z20`, Bett nach vorn (`G0 X0 Y200`), `M84`.
8. Kommentare im G-Code auf Deutsch, mit `;`.

Vorlage für Kopf und Ende: `test.gcode`.

## Dateien

- `README.md`: Kurzbeschreibung für Menschen
- `test.gcode`: Probelauf (Quadrat 60 × 60 mm, Diagonalen, Kreis r = 25 um X110 Y110). Bisher **nicht auf dem Drucker getestet**.
- `proben/` (**git-ignoriert**, Repo ist öffentlich): `proben/schulapp/` = 18 Heftseiten-Fotos aus der Schulapp (1200×1600, Karopapier) als Stilreferenz. Nie committen.
- `werkzeuge/foto_zu_linien.py`: Foto → Tinte vom Karo trennen → Skelett → Linienzüge (SVG, Vergleichsbild, optional G-Code). Braucht `werkzeuge/requirements.txt`; auf dem NAS liegt die venv in `~/.venvs/plotter` (außerhalb von Drive). Ausgaben mit echter Handschrift nur nach `proben/vorschau/`.
- `werkzeuge/glyphen_schneiden.py`: halbautomatisch Buchstaben ausschneiden (schneiden → `labels.json` beschriften → bauen → `glyphen.json`, Einheit x-Höhe, Grundlinie y=0). Arbeitsordner `proben/glyphen/` (privat).
- `pause_test.gcode`: Test für A4 in zwei Abschnitten – Kreuz zeichnen, Pause (`M0`), Blatt 100 mm nach hinten schieben, Kreuz erneut. Prüft, ob das Display `M0` kann und wie genau verschoben wird. **Noch nicht getestet.** Annahme: Drucker-Y+ = Richtung Rückseite des Betts.
- `hardware/papierfuehrung.scad` → `papierfuehrung.stl`: Leiste zum Aufkleben links auf dem Bett, Lippe für die linke Blattkante, zwei Kerben im Abstand 100 mm für die Blatt-Oberkante (Abschnitt 1/2).
- **A4 „Weg A“ (beschlossen 01.11., ungetestet):** Blatt auf gedruckter `hardware/traegerplatte_1/2.stl` (218 × 304 × 2 mm, 2 Hälften mit Schwalbenschwänzen, linker Randstreifen 8 mm + hintere Leiste als Papier-Anschlag, Buchse Ø 4 auf dem Streifen bei v = 139 mm). Platte liegt lose auf dem Bett. Zum Verschieben senkt der Kopf eine M3-Schraube („Haken“, Öse vorn am Stifthalter, 12,65 mm vor der Stiftachse) in die Buchse, Bett fährt +100 mm in Y, Platte bleibt hängen → Papierpunkte liegen danach bei Y + 100. Haken-Unterkante 6 mm über der Stiftspitze. `verschiebe_test.gcode` nutzt **Papier = Z10** (G92 Z10), Haken greift bei Z5, sicher Z25; Platte wird in 30 s Wartezeit (G4) unter den Haken geschoben; M204 P300 T300 gegen Rutschen.
- Geplant (noch nicht vorhanden): Python-Skript Text → G-Code (A4: Text **zwischen zwei Zeilen** in Abschnitte teilen, Versatz 100 mm, `M0`-Pause bzw. zwei Dateien, falls `M0` nicht geht), saubere Glyphen-Proben, OpenSCAD-Datei für den Stifthalter

## Offene Entscheidungen – nicht eigenmächtig festlegen

- **Format der Schriftproben**: z. B. SVG-Pfade pro Glyphe oder JSON mit Strichlisten aus Tablet und Stylus. Vorschläge machen, aber den Nutzer entscheiden lassen.
- Wie Buchstaben verbunden werden (Schreibschrift oder Druckschrift)
- Maße des Druckkopfs für den Stifthalter (müssen gemessen werden)

## OpenSCAD auf dem NAS

`~/bin/openscad` (Snapshot 2026.10.31, entpacktes AppImage in `~/opt/openscad`, fehlende Grafik-Libs aus Debian bookworm in `~/opt/openscad/libs`). Headless: `~/bin/openscad --backend=manifold -o teil.stl teil.scad`. STL nach jeder SCAD-Änderung neu erzeugen und mitcommitten. PNG-Vorschau geht headless nicht (kein OpenGL) → `werkzeuge/stl_vorschau.py`.

## Arbeitsweise

- Sprache: **Deutsch** (Code-Bezeichner dürfen Englisch sein, Kommentare und Commit-Messages auf Deutsch)
- Python 3, möglichst **ohne schwere Abhängigkeiten** (Standardbibliothek bevorzugt)
- Kleine, nachvollziehbare Commits. Nicht pushen, ohne dass der Nutzer es will.
- Vor jeder G-Code-Änderung prüfen: Gibt es eine Leerfahrt mit gesenktem Stift? Bleibt alles im Bauraum? Fehlt irgendwo ein `G28 Z`?
- Möglichst jede erzeugte Datei auch als **Vorschau** ausgeben (z. B. SVG/PNG der Stiftbahnen), bevor sie auf den Drucker geht

## Kontext außerhalb des Repos

Dieses Repo liegt als Arbeitskopie im Wiki des Nutzers unter `topics/vibe-coding/code/handschrift-plotter/`. Der Steckbrief mit dem aktuellen Stand und den offenen Punkten liegt unter `topics/vibe-coding/wiki/topics/handschrift-plotter.md`. Nach größeren Schritten sollte man ihn aktualisieren, wenn das Wiki erreichbar ist.
