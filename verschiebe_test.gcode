; Handschrift-Plotter – Test "Weg A": der Drucker verschiebt die Trägerplatte selbst um 100 mm
;
; Teile: hardware/stifthalter.stl (mit Öse vorn), hardware/traegerplatte_1.stl + _2.stl,
;        eine M3-Schraube (ca. 25–30 mm) + Mutter in der Öse = "Haken".
;
; VORHER EINSTELLEN (einmalig):
;   - Haken-Schraube so weit eindrehen/herausdrehen, dass ihre Unterkante ca. 6 mm ÜBER der
;     Stiftspitze steht (Stift hängt frei im Becher). Mit der Mutter kontern.
;   - Bett von Hand ganz nach vorn und ganz nach hinten schieben, mit aufgelegter Platte:
;     die Platte steht vorn ca. 8 cm und nach dem Verschieben hinten ca. 10 cm über –
;     prüfen, dass sie nirgends anstößt (Display, Kabel, Wand).
;   - Blatt auf die Platte: Oberkante an die hintere Leiste, linke Kante an den Randstreifen, mit
;     Klebeband fixieren. Platte mit der Buchse nach links-vorn auf das Bett legen.
;
; Z-BEZUG IN DIESER DATEI: Papier = Z10 (nicht Z0), damit nie negative Z-Werte nötig sind.
;   Stift über dem Papier absenken, bis er es gerade berührt, dann Datei starten.
;   Z15 = Stift 5 mm hoch, Z25 = sicher (Haken weit über der Buchse), Z5 = Haken in der Buchse.
;
; ABLAUF:
;   1. Kopf fährt so, dass der Haken über der Sollposition der Buchse steht (Stift bei X10 Y70).
;      Display zeigt "Platte ausrichten". 30 Sekunden Zeit: Platte so schieben, dass die
;      Buchse genau unter der Haken-Schraube liegt. Hände weg, wenn die Zeit um ist!
;      MIT SCHIENEN (hardware/schienen.stl) lässt sich die Platte nur vor/zurück schieben.
;      Steht der Haken dann seitlich NICHT über der Buchse: Test abbrechen, Kopf am Display
;      in X verschieben, bis er passt, den X-Wert ablesen und melden → X10 wird angepasst.
;   2. Zwei Kreuze bei Y100: links (X50) und rechts (X190).
;   3. Haken senkt sich in die Buchse, Bett fährt 100 mm, Haken hebt sich.
;   4. Dieselben zwei Kreuze bei Y200. Stimmt alles, liegen beide genau auf den ersten.
;      - beide gleich versetzt  → Verschiebung ungenau (Spiel in der Buchse, Rutschen)
;      - nur RECHTS versetzt    → Tablett hat sich GEDREHT → Führungsschiene links aufs Bett
;        (hardware/papierfuehrung.stl, Lippe 2 mm = Tablettdicke)

M412 S0          ; Filament-Sensor aus
M104 S10         ; Düse 10 °C (heizt praktisch nie)
M140 S10         ; Bett 10 °C
M107             ; Lüfter aus
G21              ; Millimeter
G90              ; absolute Koordinaten
G92 Z10          ; aktuelle Höhe = Stift auf Papier = Z10
G1 Z25 F600      ; sicher hoch
M204 P300 T300   ; sanft beschleunigen, damit die lose Platte beim Schreiben nicht rutscht
G28 X Y          ; nur X und Y referenzieren

; --- 1. Platte ausrichten ---
G0 X10 Y70 F6000
M400
M117 Platte ausrichten 30s
G4 S30           ; 30 Sekunden warten
M117 Test laeuft

; --- 2. Zwei Kreuze vor dem Verschieben (links X50, rechts X190, je Y100) ---
G0 X40 Y100 F6000
G1 Z10 F600
G1 X60 Y100 F1000
G1 Z15 F600
G0 X50 Y90 F6000
G1 Z10 F600
G1 X50 Y110 F1000
G1 Z15 F600
G0 X180 Y100 F6000
G1 Z10 F600
G1 X200 Y100 F1000
G1 Z15 F600
G0 X190 Y90 F6000
G1 Z10 F600
G1 X190 Y110 F1000
G1 Z15 F600

; --- 3. Verschieben ---
G1 Z25 F600
G0 X10 Y70 F6000 ; Haken über die Buchse
M400
G1 Z5 F300       ; Haken in die Buchse (Stift setzt auf dem Randstreifen auf und schwimmt hoch)
G1 Y170 F600     ; Bett fährt 100 mm, Platte bleibt am Haken hängen
G1 Z25 F300      ; Haken raus
M117 Verschoben

; --- 4. Dieselben Kreuze nach dem Verschieben (Y200) ---
G0 X40 Y200 F6000
G1 Z10 F600
G1 X60 Y200 F1000
G1 Z15 F600
G0 X50 Y190 F6000
G1 Z10 F600
G1 X50 Y210 F1000
G1 Z15 F600
G0 X180 Y200 F6000
G1 Z10 F600
G1 X200 Y200 F1000
G1 Z15 F600
G0 X190 Y190 F6000
G1 Z10 F600
G1 X190 Y210 F1000
G1 Z15 F600

; --- Ende ---
G1 Z30 F600
G0 X0 Y110 F6000 ; Bett mittig (Platte steht hinten über)
M84
M117 Fertig
