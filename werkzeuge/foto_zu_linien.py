"""Foto einer Handschrift → Linienzüge (Stiftbahnen) als SVG.

Testwerkzeug, um zu sehen, ob sich aus Heftfotos Plotter-Linien gewinnen lassen.
Braucht numpy, scikit-image und Pillow (venv: ~/.venvs/plotter).

Ablauf:
  1. Graustufen, Beleuchtung ausgleichen (durch weichgezeichneten Hintergrund teilen)
  2. Tinte vom Karopapier trennen: Tinte ist dunkler und weniger blau als die Kästchen
  3. Lange gerade Linien (Karo, Rand) und Krümel entfernen
  4. Skelett (1 px breit) → Pfade verfolgen → mit Douglas-Peucker vereinfachen
  5. SVG mit den Linienzügen + Vergleichsbild (Original | Maske | Linien)

Aufruf:
  python foto_zu_linien.py BILD AUSGABE_PRÄFIX [--ausschnitt x0,y0,x1,y1] [--schwelle 0.72] [--gcode-breite 150]
  (Ausschnitt in Anteilen 0..1 des Bildes)
"""
import argparse

import numpy as np
from PIL import Image, ImageDraw
from skimage import filters, measure, morphology


def tinte_maske(rgb, schwelle):
    rgb = rgb.astype(float) / 255
    grau = rgb.mean(axis=2)
    hintergrund = filters.gaussian(grau, sigma=25)
    norm = np.clip(grau / np.maximum(hintergrund, 1e-3), 0, 1.2)
    # Karo ist bläulich/hellgrau, Tinte dunkel → Dunkelheit plus wenig Blau-Überschuss
    blau_ueber = rgb[..., 2] - rgb[..., :2].mean(axis=2)
    maske = (norm < schwelle) & (blau_ueber < 0.08)
    # Karo-Linien: lange waagerechte/senkrechte Strukturen herausrechnen
    lang = max(25, rgb.shape[1] // 30)
    waag = morphology.binary_opening(maske, np.ones((1, lang), bool))
    senk = morphology.binary_opening(maske, np.ones((lang, 1), bool))
    maske &= ~(waag | senk)
    maske = morphology.binary_closing(maske, morphology.disk(1))
    maske = morphology.remove_small_objects(maske, 8)
    return maske


NACHBARN = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def skelett_pfade(maske):
    sk = morphology.skeletonize(maske)
    pkt = set(zip(*np.nonzero(sk)))

    def nb(p):
        return [(p[0] + dy, p[1] + dx) for dy, dx in NACHBARN if (p[0] + dy, p[1] + dx) in pkt]

    besucht_kante = set()
    pfade = []
    # Start bei Enden (Grad 1) und Knoten (Grad ≥ 3), danach Restschleifen
    grad = {p: len(nb(p)) for p in pkt}
    starts = [p for p in pkt if grad[p] != 2] + [p for p in pkt if grad[p] == 2]
    for s in starts:
        for n in nb(s):
            if frozenset((s, n)) in besucht_kante:
                continue
            pfad = [s, n]
            besucht_kante.add(frozenset((s, n)))
            akt, vor = n, s
            while grad[akt] == 2:
                weiter = [q for q in nb(akt) if q != vor and frozenset((akt, q)) not in besucht_kante]
                if not weiter:
                    break
                vor, akt = akt, weiter[0]
                besucht_kante.add(frozenset((vor, akt)))
                pfad.append(akt)
            pfade.append(np.array(pfad, float))
    # vereinfachen, sehr kurze Stummel weg
    raus = []
    for p in pfade:
        if len(p) < 2:
            continue
        raus.append(measure.approximate_polygon(p, tolerance=0.8))
    # Punkte (i-Punkt, Satzpunkt) haben im Skelett oft nur 1 Pixel → als kurzer Strich
    for y, x in pkt:
        if not nb((y, x)):
            raus.append(np.array([[y - 0.5, x], [y + 0.5, x]]))
    return raus


def gcode(pfade, b, h, datei, breite_mm, x0=20.0, y0=20.0):
    """Linienzüge als Marlin-G-Code. Bildbreite → breite_mm, links unten bei (x0, y0).
    Regeln wie in AGENTS.md: nur G28 X Y, Stift vor jeder Leerfahrt hoch, Bauraum prüfen."""
    s = breite_mm / b

    def xy(y, x):
        return x0 + x * s, y0 + (h - y) * s  # Bild-y zeigt nach unten, Drucker-Y nach hinten

    for p in pfade:
        for y, x in p:
            gx, gy = xy(y, x)
            if not (0 <= gx <= 220 and 0 <= gy <= 220):
                raise SystemExit(f"Außerhalb des Bauraums: X{gx:.1f} Y{gy:.1f}")
    z = ["; Handschrift-Plotter – erzeugt von werkzeuge/foto_zu_linien.py",
         f"; {len(pfade)} Linienzüge, Breite {breite_mm} mm, Start bei X{x0} Y{y0}",
         "; VORHER: Stift von Hand auf Papier absenken (Z), dann starten. Kein Home All!",
         "M412 S0", "M104 S10", "M140 S10", "M107", "G21", "G90", "G92 Z0", "G1 Z5 F600", "G28 X Y"]
    for p in pfade:
        gx, gy = xy(*p[0])
        z += [f"G0 X{gx:.2f} Y{gy:.2f} F6000", "G1 Z0 F600"]
        for y, x in p[1:]:
            gx, gy = xy(y, x)
            z.append(f"G1 X{gx:.2f} Y{gy:.2f} F2000")
        z.append("G1 Z3 F600")
    z += ["G1 Z20 F600", "G0 X0 Y200 F6000", "M84"]
    open(datei, "w").write("\n".join(z) + "\n")


def svg(pfade, b, h, datei):
    teile = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {b} {h}" width="{b}" height="{h}">',
             '<rect width="100%" height="100%" fill="white"/>']
    for p in pfade:
        d = " ".join(f"{x:.1f},{y:.1f}" for y, x in p)
        teile.append(f'<polyline points="{d}" fill="none" stroke="black" stroke-width="1.2" '
                     'stroke-linecap="round" stroke-linejoin="round"/>')
    teile.append("</svg>")
    open(datei, "w").write("\n".join(teile))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("bild")
    ap.add_argument("praefix")
    ap.add_argument("--ausschnitt", default="0,0,1,1")
    ap.add_argument("--schwelle", type=float, default=0.72)
    ap.add_argument("--gcode-breite", type=float, default=0, help="Breite in mm; >0 → zusätzlich .gcode")
    a = ap.parse_args()

    im = Image.open(a.bild).convert("RGB")
    w, h = im.size
    x0, y0, x1, y1 = (float(v) for v in a.ausschnitt.split(","))
    im = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    rgb = np.asarray(im)

    maske = tinte_maske(rgb, a.schwelle)
    pfade = skelett_pfade(maske)
    b, hh = im.size
    svg(pfade, b, hh, a.praefix + ".svg")
    if a.gcode_breite > 0:
        gcode(pfade, b, hh, a.praefix + ".gcode", a.gcode_breite)

    # Vergleichsbild: Original | Maske | Linien
    linien = Image.new("RGB", (b, hh), "white")
    d = ImageDraw.Draw(linien)
    for p in pfade:
        d.line([(x, y) for y, x in p], fill="black", width=2)
    m = Image.fromarray(np.where(maske, 0, 255).astype(np.uint8)).convert("RGB")
    vgl = Image.new("RGB", (b, hh * 3), "white")
    for i, teil in enumerate((im, m, linien)):
        vgl.paste(teil, (0, i * hh))
    vgl.save(a.praefix + "_vergleich.png")

    punkte = sum(len(p) for p in pfade)
    print(f"{len(pfade)} Linienzüge, {punkte} Punkte → {a.praefix}.svg")


if __name__ == "__main__":
    main()
