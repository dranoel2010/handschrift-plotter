// Papierführung für A4 in zwei Abschnitten (Handschrift-Plotter, Artillery Genius Pro)
//
// Eine Leiste, die mit Klebeband links auf das Bett geklebt wird (parallel zur Y-Richtung).
// Das Blatt liegt mit der linken Kante an der Lippe → X bleibt beim Verschieben gleich.
// Zwei Kerben markieren, wo die OBERKANTE des Blatts liegt:
//   Kerbe 1 = Abschnitt 1 (obere Blatthälfte wird geschrieben)
//   Kerbe 2 = Abschnitt 2, genau `versatz` mm weiter hinten
//
// Ausrichtung beim Aufkleben: Kerbe 1 zeigt nach vorn (zum Display), Kerbe 2 nach hinten.
// Druck: flach, Lippe nach oben, PLA, 0,2 mm Schicht, keine Stützen.

laenge     = 225;   // passt auf die 230-mm-Platte
breite     = 14;    // Auflagefläche (wird aufgeklebt)
dicke      = 1.2;   // flach, damit der Stift nicht anstößt
lippe_h    = 2.0;   // Höhe der Anschlaglippe über der Auflage (Papier ~0,1 mm)
lippe_b    = 2.4;
versatz    = 100;   // muss zum Versatz im G-Code passen (pause_test.gcode: 100 mm)
kerbe_1    = 50;    // Abstand der ersten Kerbe vom vorderen Ende
kerbe_b    = 1.0;   // Breite der Kerbe
kerbe_t    = 1.2;   // Tiefe der Kerbe in die Lippe

module kerbe(y) {
    // Schlitz durch die Lippe + Strich quer über die Auflage
    translate([breite - lippe_b - 0.1, y - kerbe_b / 2, dicke + lippe_h - kerbe_t])
        cube([lippe_b + 0.2, kerbe_b, kerbe_t + 0.1]);
    translate([2, y - 0.4, dicke - 0.4])
        cube([breite - lippe_b - 3, 0.8, 0.5]);
}

module ziffer(t, y) {
    translate([3, y + 2, dicke - 0.4])
        linear_extrude(0.5) text(t, size = 5, halign = "left");
}

difference() {
    union() {
        cube([breite, laenge, dicke]);                                  // Auflage
        translate([breite - lippe_b, 0, 0]) cube([lippe_b, laenge, dicke + lippe_h]); // Lippe rechts → Blatt liegt rechts davon
    }
    kerbe(kerbe_1);
    kerbe(kerbe_1 + versatz);
    ziffer("1", kerbe_1);
    ziffer("2", kerbe_1 + versatz);
}
