// Führungsschienen für die Trägerplatte (Handschrift-Plotter, A4 "Weg A") – mit Magneten
//
// Zwei gleiche Schienen, links und rechts auf den Rand des Druckbetts gelegt. Sie halten mit
// Magneten (Nutzer will nicht kleben). Voraussetzung: die Druckplatte zieht Magnete an.
// Die Trägerplatte (218 mm breit) läuft dazwischen wie ein Schlitten: nur vor/zurück (Y),
// kein Drehen, kein seitliches Rutschen.
//
// Bett 230 mm breit → Kanal 219 mm (0,5 mm Luft je Seite) → je Schiene 5,5 mm.
// Querschnitt: einfacher Riegel 5,5 × 3 mm (höher als die 2 mm dicke Platte).
// Magnete: Scheiben Ø 4 × 2 mm (Neodym), von unten in Taschen gedrückt (Presssitz, kein Kleber).
//   Taschen-Ø = magnet_d + magnet_spiel; zu locker → magnet_spiel kleiner, zu stramm → größer.
//
// Druck: beide Schienen in einer Datei, flach (Taschen zeigen nach unten aufs Druckbett),
//        PLA, 0,2 mm, keine Stützen. Danach Magnete von unten eindrücken – alle mit DERSELBEN
//        Seite nach oben (sonst egal, sie halten am Stahl der Druckplatte, nicht aneinander).

bett_breite   = 230;
platte_breite = 218;
luft          = 0.5;
laenge        = 215;     // passt gerade auf das 220er Druckbett
hoehe         = 3.0;     // > Plattendicke 2 mm

magnet_d      = 4;
magnet_h      = 2;
magnet_spiel  = 0.15;    // Presssitz
magnet_n      = 5;       // pro Schiene

schiene_b = (bett_breite - platte_breite - 2 * luft) / 2;   // = 5,5 mm

$fn = 40;

module schiene() {
    difference() {
        cube([schiene_b, laenge, hoehe]);
        for (i = [0 : magnet_n - 1])
            translate([schiene_b / 2, 15 + i * (laenge - 30) / (magnet_n - 1), -0.01])
                cylinder(d = magnet_d + magnet_spiel, h = magnet_h + 0.1);
    }
}

schiene();
translate([schiene_b + 8, 0, 0]) schiene();
echo(str("Schienenbreite: ", schiene_b, " mm, Magnete pro Schiene: ", magnet_n, " (Ø ", magnet_d, " × ", magnet_h, ")"));
