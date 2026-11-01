; Handschrift-Plotter – Pause-Test für A4 in zwei Abschnitten (Artillery Genius Pro, Marlin)
; Prüft zweierlei:
;   1. Zeigt das Display die Pause (M0) an und kann man danach weitermachen?
;   2. Wie genau trifft man beim Verschieben des Blatts um 100 mm?
;
; Ablauf:
;   - Teil 1 zeichnet ein Kreuz bei X110 Y40 und eine Linie links daneben.
;   - Pause: Bett fährt nach vorn, Stift weit oben. Display: "Blatt 100mm nach hinten".
;   - Blatt GENAU 100 mm Richtung Rückseite des Druckers schieben (gerade, nicht drehen).
;   - Am Display "Weiter"/"Resume" drücken.
;   - Teil 2 zeichnet dasselbe Kreuz bei Y140. Stimmt die Verschiebung, liegt es exakt
;     auf dem ersten Kreuz. Der Abstand zwischen beiden = Fehler beim Verschieben.
;   - Liegt das zweite Kreuz ganz woanders (ca. 20 cm daneben), ist die Richtung
;     falsch herum → dann muss das Blatt nach vorn statt nach hinten (bitte melden).
;
; VORHER: Stift von Hand auf Papier absenken (Z), wie bei test.gcode. Kein Home All!
; Das Blatt ragt nach dem Verschieben hinten über das Bett: prüfen, dass es nirgends anstößt.

M412 S0          ; Filament-Sensor aus
M104 S10         ; Düse 10 °C (heizt praktisch nie)
M140 S10         ; Bett 10 °C
M107             ; Lüfter aus
G21              ; Millimeter
G90              ; absolute Koordinaten
G92 Z0           ; aktuelle Höhe = Stift auf Papier
G1 Z5 F600       ; Stift hoch
G28 X Y          ; nur X und Y referenzieren

; --- Teil 1: Kreuz bei X110 Y40, Linie X20–80 auf Höhe Y40 ---
G0 X100 Y40 F6000
G1 Z0 F600
G1 X120 Y40 F1000
G1 Z5 F600
G0 X110 Y30 F6000
G1 Z0 F600
G1 X110 Y50 F1000
G1 Z5 F600
G0 X20 Y40 F6000
G1 Z0 F600
G1 X80 Y40 F1000
G1 Z5 F600

; --- Pause zum Verschieben ---
G1 Z20 F600              ; Stift weit hoch
G0 X0 Y200 F6000         ; Bett nach vorn, Blatt gut erreichbar
M400                     ; warten, bis alle Bewegungen fertig sind
M117 Blatt 100mm nach hinten
M0 Blatt 100mm nach hinten schieben, dann Weiter

; --- Teil 2: dasselbe Kreuz 100 mm weiter (Y140) ---
M117 Teil 2
G0 X100 Y140 F6000
G1 Z0 F600
G1 X120 Y140 F1000
G1 Z5 F600
G0 X110 Y130 F6000
G1 Z0 F600
G1 X110 Y150 F1000
G1 Z5 F600
G0 X20 Y140 F6000
G1 Z0 F600
G1 X80 Y140 F1000
G1 Z5 F600

; --- Ende ---
G1 Z20 F600
G0 X0 Y200 F6000
M84
