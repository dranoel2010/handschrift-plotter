// Gefederter Stifthalter für den Artillery Genius Pro (Handschrift-Plotter)
//
// Montage: an die rechte blaue Abdeckung des Druckkopfs, mit deren 2 Schrauben (M3).
//   - Untere Schraube durch das runde Loch.
//   - Obere Schraube durch das Bogen-Langloch (Radius = Schraubenabstand um die untere).
//     → Platte lässt sich um die untere Schraube drehen: Stift senkrecht ausrichten, dann festziehen.
// Feder: Gummiband(er) vom Ring am Stift zu den Haken unten an der Hülse. Der Ring liegt
//   auf der Hülse auf (= tiefste Stiftposition). Drückt das Papier den Stift hoch, hebt der
//   Ring ab und das Gummi zieht ihn zurück.
// Höhe einstellen: Ring auf dem Stift so verschieben, dass die Spitze 2–3 mm unter der Düse steht.
//
// Koordinaten (Modell): X = von der Abdeckung nach außen, Y = waagerecht entlang der Abdeckung,
//   Z = senkrecht, Ursprung = Mitte der unteren Schraube auf der Abdeckung. Düsenspitze bei Z = -70.
// Druck: Datei ist schon gedreht (Rückseite der Platte liegt auf dem Bett), PLA, 0,2 mm,
//   3 Wände, 30 % Infill, keine Stützen nötig.

/* [Gemessen] */
schraube_abstand = 33;    // Mitte–Mitte, gemessen 01.11.
schraube_d       = 3.4;   // M3 + Spiel
stift_d          = 11;    // !!! noch messen (Schaft, wo Hülse und Ring sitzen)

/* [Konstruktion] */
platte_dicke  = 4;
bogen_winkel  = 25;       // ± Grad: deckt seitlichen Versatz bis ~14 mm ab
spiel         = 0.4;      // Hülse: Stift muss leicht gleiten
wand          = 2.2;
huelse_oben   = -18;      // Oberkante Hülse (Z); darüber Platz für Ring + Federweg
huelse_unten  = -50;      // Unterkante Hülse; Abstand zum Bett ~20 mm
achse_x       = 14;       // Stiftachse vor der Abdeckung (Stift läuft vor den Schraubenköpfen vorbei)
ring_h        = 8;
$fn = 64;

huelse_r = stift_d / 2 + spiel / 2 + wand;

module zyl_x(d, l) { rotate([0, 90, 0]) cylinder(d = d, h = l); }

module bogenloch() {
    for (a = [90 - bogen_winkel : 2 : 90 + bogen_winkel - 2])
        hull() for (b = [a, a + 2])
            translate([-1, schraube_abstand * cos(b), schraube_abstand * sin(b)])
                zyl_x(schraube_d, platte_dicke + 2);
}

module haken(seite) {   // Zapfen mit Kopf für das Gummiband
    translate([achse_x, seite * (huelse_r - 0.5), huelse_unten + 4])
        rotate([seite * -90, 0, 0]) {
            cylinder(d = 3, h = 5.5);
            translate([0, 0, 5.5]) cylinder(d1 = 3, d2 = 5, h = 1.2);
        }
}

module halter() {
    difference() {
        union() {
            // Montageplatte
            translate([0, -17, huelse_unten]) cube([platte_dicke, 34, schraube_abstand + 5 - huelse_unten]);
            // Steg zwischen Platte und Hülse
            translate([0, -9, huelse_unten]) cube([achse_x, 18, huelse_oben - huelse_unten]);
            // Hülse
            translate([achse_x, 0, huelse_unten]) cylinder(r = huelse_r, h = huelse_oben - huelse_unten);
            haken(1); haken(-1);
        }
        // Bohrung für den Stift
        translate([achse_x, 0, huelse_unten - 1]) cylinder(d = stift_d + spiel, h = 100);
        // Schraubenlöcher
        translate([-1, 0, 0]) zyl_x(schraube_d, platte_dicke + 2);
        bogenloch();
    }
}

module ring() {   // Klemmring auf dem Stift, mit Zapfen für das Gummiband
    difference() {
        union() {
            cylinder(d = stift_d + 7, h = ring_h);
            for (s = [1, -1]) translate([0, 0, ring_h / 2]) rotate([s * -90, 0, 0]) {
                cylinder(d = 3, h = stift_d / 2 + 3.5 + 4);
                translate([0, 0, stift_d / 2 + 3.5 + 4]) cylinder(d1 = 3, d2 = 5, h = 1.2);
            }
        }
        translate([0, 0, -1]) cylinder(d = stift_d - 0.2, h = ring_h + 2);   // klemmt leicht
        translate([0, -0.75, -1]) cube([stift_d, 1.5, ring_h + 2]);           // Schlitz zum Federn
    }
}

// Druckanordnung: Halter mit der Plattenrückseite (X = 0) nach unten, Ring daneben
rotate([0, -90, 0]) halter();
translate([0, 40, 0]) ring();
