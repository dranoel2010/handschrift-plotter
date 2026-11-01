// Führungsschienen für die Trägerplatte (Handschrift-Plotter, A4 "Weg A")
//
// Zwei gleiche Schienen, links und rechts auf den Rand des Druckbetts geklebt (doppelseitiges
// Klebeband). Die Trägerplatte (218 mm breit) läuft dazwischen wie ein Schlitten: sie kann
// nur noch vor/zurück (Y), sich nicht drehen und nicht seitlich rutschen.
//
// Bett 230 mm breit → Kanal 219 mm (0,5 mm Luft je Seite) → je Schiene 5,5 mm.
// Querschnitt: flache Auflage außen + Lippe innen (2,5 mm hoch > Plattendicke 2 mm).
// Die zweite Schiene ist dasselbe Teil, um 180° gedreht aufgeklebt (Lippe zeigt nach innen).
//
// Druck: beide Schienen in einer Datei nebeneinander, flach, PLA, 0,2 mm, keine Stützen.

bett_breite   = 230;
platte_breite = 218;
luft          = 0.5;
laenge        = 215;     // passt gerade auf das 220er Druckbett
auflage_dicke = 1.0;
lippe_h       = 2.5;     // Höhe über dem Bett
lippe_b       = 2.0;

schiene_b = (bett_breite - platte_breite - 2 * luft) / 2;   // = 5,5 mm

module schiene() {
    cube([schiene_b, laenge, auflage_dicke]);                              // Auflage
    translate([schiene_b - lippe_b, 0, 0]) cube([lippe_b, laenge, lippe_h]); // Lippe (innen)
}

schiene();
translate([schiene_b + 8, 0, 0]) schiene();
echo(str("Schienenbreite: ", schiene_b, " mm"));
