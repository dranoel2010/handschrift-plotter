; Handschrift-Plotter – Testdatei für Artillery Genius Pro (Marlin)
; Zeichnet: Quadrat 60x60 mm, beide Diagonalen, Kreis (r=25) – Mitte bei X110 Y110.
;
; VORHER (am Display, Papier liegt festgeklemmt auf dem Bett):
;   1. Druckkopf so fahren, dass der Stift über dem Papier steht.
;   2. Z langsam absenken, bis die Stiftspitze das Papier GERADE berührt.
;   3. Diese Datei starten. Die aktuelle Höhe wird als Z0 (= Stift unten) übernommen.
; NICHT vorher "Home All" oder Auto-Leveling – sonst stimmt Z nicht mehr.

M104 S0          ; Düse aus
M140 S0          ; Bett aus
M107             ; Lüfter aus
G21              ; Millimeter
G90              ; absolute Koordinaten
G92 Z0           ; aktuelle Höhe = Stift auf Papier
G1 Z5 F600       ; Stift hoch
G28 X Y          ; nur X und Y referenzieren

; --- Quadrat ---
G0 X80 Y80 F6000
G1 Z0 F600       ; Stift runter
G1 X140 Y80 F2000
G1 X140 Y140
G1 X80 Y140
G1 X80 Y80
G1 Z3 F600       ; Stift hoch

; --- Diagonalen ---
G0 X80 Y80 F6000
G1 Z0 F600
G1 X140 Y140 F2000
G1 Z3 F600
G0 X140 Y80 F6000
G1 Z0 F600
G1 X80 Y140 F2000
G1 Z3 F600

; --- Kreis r=25 um (110,110) ---
G0 X135 Y110 F6000
G1 Z0 F600
G2 X135 Y110 I-25 J0 F2000
G1 Z3 F600

; --- Ende ---
G1 Z20 F600      ; Stift weit hoch
G0 X0 Y200 F6000 ; Bett nach vorn
M84              ; Motoren aus
