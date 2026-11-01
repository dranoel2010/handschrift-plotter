// Stifthalter v4 für den Artillery Genius Pro (Handschrift-Plotter)
//
// Form nach Konzeptbild des Nutzers (proben/WhatsApp Image 2026-11-01 at 20.44.52.jpeg):
//   - zwei getrennte Arme, je einer an den 2 kleinen Schrauben des blauen Metallwinkels über
//     dem blauen Kasten ("Gruppe 2"), gehen nach vorn über den Kasten und dann davor nach unten
//   - unten ein Becher; der Stift steht mit seiner Spitzen-Verjüngung auf dem Absatz,
//     die Mine schaut unten durch das kleine Loch heraus
//   - oben offen: Stift einfach nach oben herausziehen (durch den Führungsring auf halber Höhe)
//   - KEINE Feder: der Stift liegt durch sein Eigengewicht auf ("schwimmend"). Drückt das Papier,
//     hebt er sich an. Z0 wird vor dem Start von Hand auf Papier gesetzt (G92 Z0), daher muss die
//     Spitzenhöhe nicht genau stimmen – nur tiefer als die Düse.
//   - vorn am Becher eine Öse für eine M3-Schraube nach unten ("Haken") für die Trägerplatte
//     (traegerplatte.scad, verschiebe_test.gcode); Abstand zur Stiftachse = becher_r + 5 = 12,65 mm
// Montage: immer nur EINE Schraube lösen, Arm dahinter, wieder fest, dann die zweite.
//
// Koordinaten: X = nach vorn (weg vom Winkel), Y = waagerecht entlang des Winkels,
//   Z = senkrecht, Ursprung = Mitte zwischen den beiden Schrauben auf der Winkelfläche.

/* [Gemessen] */
schraube_abstand = 13;    // 01.11. nach Probedruck: Löcher weiter nach außen (vorher 10)
langloch         = 1.5;
schraube_d       = 3.4;   // M3 angenommen
kopf_d           = 6;
duese_unten      = 75;    // vom Foto (~75 mm); unkritisch
kasten_vor       = 63;    // gemessen 01.11.: Kasten-Vorderseite → Schraubenköpfe 60 mm, + ~3 mm Kopfhöhe
stift_d          = 10;    // gemessen
spitze_d         = 6;     // Loch unten: Mine/Spitzenkonus muss durchpassen, Schaft nicht

/* [Konstruktion] */
gesamt_hoehe = 85;    // Wunsch Nutzer 01.11.: Oberkante Arm bis Unterkante Becher
staerke      = 4;     // Materialstärke der Arme (wie im Konzeptbild)
arm_tief     = 6;     // Tiefe der senkrechten Arme (X)
luft         = 2;     // Abstand Arme ↔ Kasten
lasche_unten = 4;    // 01.11. nach Probedruck: Lasche nur so hoch wie der Arm (8 mm), Loch mittig; darunter ist am Drucker kein Platz
oben         = 4;     // Oberkante von Lasche und Arm über Schraubenmitte (vorher 9; Form unverändert, nur Löcher 5 mm höher)
arm_hoehe    = 8;     // Höhe des waagerechten Teils (lange Auskragung → steifer)
spiel        = 0.5;
wand         = 2.4;
becher_h     = 16;
boden        = 3;
becher_ueber_duese = 8;   // (nicht mehr benutzt, Höhe kommt aus gesamt_hoehe)
ring_z       = -25;  // Höhe des oberen Führungsrings (Unterkante)
$fn = 64;

bohr_r     = (stift_d + spiel) / 2;
becher_r   = bohr_r + wand;
achse_x    = kasten_vor + luft + becher_r;    // Stiftachse
z_unten    = oben - gesamt_hoehe;                 // Unterkante Becher
arm_innen  = bohr_r + 0.5;                    // Arme laufen außen am Stift vorbei
arm_aussen = arm_innen + staerke;
haken_x    = achse_x + becher_r + 5;            // Haken-Schraube: so weit VOR der Stiftachse
lasche_y   = max(arm_aussen, schraube_abstand / 2 + langloch + kopf_d / 2 + 1);

module zyl_x(d, l) { rotate([0, 90, 0]) cylinder(d = d, h = l); }

module arm(s) {   // s = +1 / -1 (Seite)
    y0 = s > 0 ? arm_innen : -arm_aussen;
    difference() {
        union() {
            // Lasche an der Schraube (liegt flach an der Winkelfläche)
            translate([0, s > 0 ? 1 : -lasche_y, -lasche_unten]) cube([staerke, lasche_y - 1, lasche_unten + oben]);
            // waagerecht nach vorn über den Kasten
            translate([0, y0, oben - arm_hoehe]) cube([achse_x + arm_tief / 2, staerke, arm_hoehe]);
            // senkrecht nach unten vor dem Kasten bis zum Becher
            translate([achse_x - arm_tief / 2, y0, z_unten]) cube([arm_tief, staerke, oben - z_unten]);
        }
        hull() for (v = [-langloch, langloch])
            translate([-1, s * schraube_abstand / 2 + v, 0]) zyl_x(schraube_d, staerke + 2);
    }
}

module halter() {
    difference() {
        union() {
            arm(1); arm(-1);
            // durchgehende Platte zwischen den Armen über dem Kasten, endet hinter dem Stift
            translate([staerke, -arm_aussen, oben - 4]) cube([achse_x - becher_r - 2 - staerke, 2 * arm_aussen, 4]);
            translate([achse_x, 0, z_unten]) cylinder(r = becher_r, h = becher_h);
            // Führungsring oben: versteift die Arme, Stift bleibt nach oben herausziehbar
            translate([achse_x, 0, ring_z]) cylinder(r = becher_r, h = 5);
            // Öse für die "Haken"-Schraube (M3, nach unten) zum Verschieben der Trägerplatte.
            // Schräg (45°), damit sie kopfüber ohne Stützen druckbar ist.
            hull() {
                translate([achse_x + becher_r - 2, -4, z_unten]) cube([12, 8, 4]);
                translate([achse_x + becher_r - 2, -4, z_unten + 14]) cube([1, 8, 0.01]);
            }
        }
        // M3 direkt ins PLA schrauben (Ø 2,8); Mutter von unten kontert
        translate([haken_x, 0, z_unten - 1]) cylinder(d = 2.8, h = 20);
        // Becher: Schaft-Bohrung oben, kleines Loch unten für die Mine, kegeliger Absatz dazwischen
        translate([achse_x, 0, z_unten + boden]) cylinder(r = bohr_r, h = 200);
        translate([achse_x, 0, z_unten - 1]) cylinder(d = spitze_d, h = boden + 2);
        translate([achse_x, 0, z_unten + boden - 1.5]) cylinder(d1 = spitze_d, d2 = 2 * bohr_r, h = 1.51);
    }
}

// Druckanordnung: kopfüber (Oberseite der Arme liegt auf dem Bett), keine Stützen nötig
druck = true;
if (druck) translate([0, 0, oben]) rotate([180, 0, 0]) halter();
else halter();
