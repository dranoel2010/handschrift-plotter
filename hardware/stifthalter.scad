// Stifthalter v3 für den Artillery Genius Pro (Handschrift-Plotter)
//
// Form nach Vorlagebild des Nutzers (proben/WhatsApp Image 2026-11-01 at 20.08.11.jpeg):
// an den 2 kleinen Schrauben des blauen Metallwinkels über dem blauen Kasten ("Gruppe 2")
// festschrauben → Brücke mit Loch geht nach vorn über den Kasten → zwei schmale Streben links
// und rechts vom Stift dicht vor dem Kasten nach unten → Hülse unten, Spitze schaut heraus.
//
// Der Stift läuft durch zwei Führungen: Loch in der Brücke (oben) und Hülse (unten).
// Feder: Gummiband vom Klemmring am Stift zu den Haken unten an der Hülse. Der Ring liegt auf
//   der Hülse auf = tiefste Stiftposition; drückt das Papier den Stift hoch, hebt der Ring ab.
// Höhe einstellen: Ring auf dem Stift verschieben, bis die Spitze 2–3 mm unter der Düse steht.
// Montage: immer nur EINE Schraube lösen, Halter dazwischen, wieder fest, dann die zweite.
//
// Koordinaten: X = nach vorn (weg vom Winkel), Y = waagerecht entlang des Winkels,
//   Z = senkrecht, Ursprung = Mitte zwischen den beiden Schrauben auf der Winkelfläche.
//
// !!! Alle mit "SCHÄTZUNG" markierten Werte sind noch nicht gemessen !!!

/* [Gemessen / zu messen] */
schraube_abstand = 12;    // SCHÄTZUNG: Mitte–Mitte der beiden Schrauben
schraube_d       = 3.4;   // SCHÄTZUNG: M3 + Spiel
kopf_d           = 6;     // Kopf-Ø (für Freiraum)
duese_unten      = 70;    // SCHÄTZUNG: Schrauben → Düsenspitze, senkrecht
kasten_vor       = 25;    // SCHÄTZUNG: wie weit der blaue Kasten vor die Schraubenfläche ragt
stift_d          = 11;    // SCHÄTZUNG: Stift-Ø am Schaft

/* [Konstruktion] */
dicke     = 4;      // Lasche und Arm
abstand   = 3;      // Luft zwischen Kasten und Halter
spiel     = 0.4;
wand      = 2.2;
huelse_h  = 18;
strebe_b  = 4;      // Breite einer Strebe (Y)
strebe_t  = 6;      // Tiefe einer Strebe (X)
huelse_ab_bett = 20;   // Unterkante Hülse über Düsenspitze
ring_h    = 8;
$fn = 64;

huelse_r = stift_d / 2 + spiel / 2 + wand;
achse_x  = kasten_vor + abstand + huelse_r;            // Stiftachse vor der Schraubenfläche
z_unten  = -duese_unten + huelse_ab_bett;                // Unterkante Hülse
z_oben   = z_unten + huelse_h;                           // Oberkante Hülse
strebe_y = stift_d / 2 + spiel + 1 + strebe_b / 2;      // Mitte der Streben neben dem Stift
breite   = max(schraube_abstand + kopf_d + 6, 2 * (strebe_y + strebe_b / 2));

module zyl_x(d, l) { rotate([0, 90, 0]) cylinder(d = d, h = l); }

module haken(seite) {   // sitzt außen an der Strebe, Gummiband läuft an der Strebe entlang
    translate([achse_x, seite * (strebe_y + strebe_b / 2 - 0.5), z_unten + 4])
        rotate([seite * -90, 0, 0]) {
            cylinder(d = 3, h = 5.5);
            translate([0, 0, 5.5]) cylinder(d1 = 3, d2 = 5, h = 1.2);
        }
}

module halter() {
    difference() {
        union() {
            // Lasche an den Schrauben (liegt an der Winkelfläche an)
            translate([0, -breite / 2, -kopf_d / 2 - 3]) cube([dicke, breite, kopf_d + 6]);
            // Arm gerade nach vorn (oberhalb des Kastens)
            translate([0, -breite / 2, kopf_d / 2 + 3 - dicke]) cube([achse_x + huelse_r + 2, breite, dicke]);
            // zwei Streben links und rechts vom Stift nach unten (vor dem Kasten)
            for (s = [1, -1])
                translate([achse_x - strebe_t / 2, s * strebe_y - strebe_b / 2, z_unten])
                    cube([strebe_t, strebe_b, kopf_d / 2 + 3 - z_unten]);
            // Hülse
            translate([achse_x, 0, z_unten]) cylinder(r = huelse_r, h = huelse_h);
            haken(1); haken(-1);
        }
        // Stift: durch Hülse und Arm
        translate([achse_x, 0, z_unten - 1]) cylinder(d = stift_d + spiel, h = 300);
        // Schraubenlöcher
        for (s = [1, -1]) translate([-1, s * schraube_abstand / 2, 0]) zyl_x(schraube_d, dicke + 2);
    }
}

module ring() {
    difference() {
        union() {
            cylinder(d = stift_d + 7, h = ring_h);
            for (s = [1, -1]) translate([0, 0, ring_h / 2]) rotate([s * -90, 0, 0]) {
                cylinder(d = 3, h = stift_d / 2 + 3.5 + 4);
                translate([0, 0, stift_d / 2 + 3.5 + 4]) cylinder(d1 = 3, d2 = 5, h = 1.2);
            }
        }
        translate([0, 0, -1]) cylinder(d = stift_d - 0.2, h = ring_h + 2);
        translate([0, -0.75, -1]) cube([stift_d, 1.5, ring_h + 2]);
    }
}

// Druckanordnung: Halter kopfüber (Oberseite des Arms liegt auf dem Bett, Hülse zeigt nach oben),
// Ring daneben. Keine Stützen nötig.
druck = true;
if (druck) {
    translate([0, 0, kopf_d / 2 + 3]) rotate([180, 0, 0]) halter();
    translate([-22, 0, 0]) ring();
} else halter();
