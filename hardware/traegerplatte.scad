// Trägerplatte für A4 (Handschrift-Plotter, "Weg A": der Drucker verschiebt die Platte selbst)
//
// Idee: Das Blatt liegt fest auf dieser Platte, die Platte liegt lose auf dem Bett.
// Zum Weiterschieben senkt der Druckkopf eine M3-Schraube (am Stifthalter) in die Buchse,
// dann fährt das Bett 100 mm. Die Platte wird festgehalten, das Bett gleitet darunter weg.
//
// Aufbau (u = quer / Drucker-X, v = längs / Drucker-Y, v = 0 ist die VORDERKANTE):
//   - Platte 218 × 304 × 2 mm, aus 2 Hälften (je 218 × 152) mit Schwalbenschwänzen
//   - links ein 8 mm breiter, 1,5 mm hoher Randstreifen = Anschlag für die linke Blattkante;
//     auf ihm sitzt die Buchse (hier wird nie geschrieben)
//   - hinten eine 1,5 mm hohe Leiste = Anschlag für die Oberkante des Blatts
//   - Blatt (210 × 297) liegt mit Oberkante an der hinteren Leiste, linker Kante am Streifen
//
// Export:  openscad -D teil=1 -o traegerplatte_1.stl traegerplatte.scad   (vordere Hälfte, mit Buchse)
//          openscad -D teil=2 -o traegerplatte_2.stl traegerplatte.scad   (hintere Hälfte)
// Druck: flach, glatte Unterseite aufs Bett (die wird später auf dem Druckbett gleiten), PLA,
//        0,2 mm, 100 % Infill ist bei 2 mm egal; KEIN Brim (Teil ist 218 mm breit).

teil = 1;            // 1 = vorne (mit Buchse), 2 = hinten, 0 = beide zusammengesetzt (Ansicht)

breite   = 218;
laenge   = 304;
dicke    = 2;
streifen = 8;        // linker Randstreifen
anschlag_h = 1.5;    // Höhe von Streifen und hinterer Leiste über der Platte
leiste   = 3.5;      // Tiefe der hinteren Leiste
teilung  = laenge / 2;

buchse_v = 139;      // Lage der Buchse ab Vorderkante (passt zu verschiebe_test.gcode)
buchse_d = 8;
buchse_h = 5;        // Höhe über der Platte
buchse_loch = 4;     // M3-Schraube Ø 3 + Spiel

// Schwalbenschwänze an der Teilung
sw_n     = 4;
sw_breit = 14;       // schmale Seite
sw_spreiz = 4;       // pro Seite breiter am Ende
sw_tief  = 10;
sw_spiel = 0.2;

$fn = 48;

module schwalbe(s = 0) {   // ein Zapfen, s = Spiel (für die Aussparung)
    linear_extrude(dicke + 0.02)
        polygon([[-sw_breit / 2 - s, -0.01], [sw_breit / 2 + s, -0.01],
                 [sw_breit / 2 + sw_spreiz + s, sw_tief + s], [-sw_breit / 2 - sw_spreiz - s, sw_tief + s]]);
}

function sw_u(i) = streifen + (breite - streifen) * (i + 0.5) / sw_n;

module platte_ganz() {
    cube([breite, laenge, dicke]);
    translate([0, 0, dicke - 0.01]) cube([streifen, laenge, anschlag_h + 0.01]);           // linker Streifen
    translate([0, laenge - leiste, dicke - 0.01]) cube([breite, leiste, anschlag_h + 0.01]); // hintere Leiste
}

module buchse() {
    translate([streifen / 2, buchse_v, dicke])
        difference() {
            cylinder(d = buchse_d, h = buchse_h);
            translate([0, 0, 0.8]) cylinder(d = buchse_loch, h = buchse_h);
        }
}

module vorne() {   // v = 0 … teilung, plus Zapfen nach hinten
    difference() {
        intersection() { platte_ganz(); translate([-1, -1, -1]) cube([breite + 2, teilung + 1, 20]); }
    }
    for (i = [0 : sw_n - 1]) translate([sw_u(i), teilung - 0.01, 0]) schwalbe();
    if (buchse_v < teilung - buchse_d) buchse();
}

module hinten() {
    difference() {
        intersection() { platte_ganz(); translate([-1, teilung, -1]) cube([breite + 2, laenge, 20]); }
        for (i = [0 : sw_n - 1]) translate([sw_u(i), teilung - 0.01, -0.01]) schwalbe(sw_spiel);
    }
    if (buchse_v >= teilung + buchse_d) buchse();
}

if (teil == 1) vorne();
else if (teil == 2) translate([0, -teilung, 0]) hinten();
else { vorne(); hinten(); }
