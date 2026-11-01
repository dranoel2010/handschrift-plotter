"""Buchstaben aus Heftfotos ausschneiden – halbautomatisch.

Schritt 1 (schneiden):  zerlegt Seiten in zusammenhängende Tintenstücke, ordnet sie Zeilen zu
                        und erzeugt nummerierte Übersichtsbilder zum Beschriften.
    python glyphen_schneiden.py schneiden SEITEN.json ARBEITSORDNER

    SEITEN.json: [{"name": "91", "bild": "...jpg", "ausschnitt": [x0,y0,x1,y1], "schwelle": 0.72}, ...]

Schritt 2 (von Hand/KI): ARBEITSORDNER/labels.json  {"91-17": "a", "91-18": "",  ...}
                        Leer oder fehlend = unbrauchbar (verbundene Buchstaben, Krümel).

Schritt 3 (bauen):      Pfade der beschrifteten Stücke → glyphen.json
    python glyphen_schneiden.py bauen ARBEITSORDNER

glyphen.json: {"a": [ {"quelle": "91-17", "pfade": [[[x,y],...],...], "breite": w}, ...], ...}
  Koordinaten in "x-Höhen": Grundlinie y=0, Oberkante kleiner Buchstaben y=1, y wächst nach oben,
  x=0 am linken Rand des Stücks.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from skimage import measure, morphology

sys.path.insert(0, os.path.dirname(__file__))
from foto_zu_linien import skelett_pfade, tinte_maske  # noqa: E402

KLEIN_OHNE_OBERLAENGE = set("acemnorsuvwxz")


def seite_laden(s):
    im = Image.open(s["bild"]).convert("RGB")
    w, h = im.size
    x0, y0, x1, y1 = s.get("ausschnitt", [0, 0, 1, 1])
    im = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
    return im, tinte_maske(np.asarray(im), s.get("schwelle", 0.72))


def stuecke(maske):
    lab = measure.label(maske, connectivity=2)
    props = [p for p in measure.regionprops(lab) if p.area >= 8]
    # kleine Teile (i-Punkte, Striche über ä/ö/ü) dem darunterliegenden Stück zuordnen
    gross = [p for p in props if max(p.bbox[2] - p.bbox[0], p.bbox[3] - p.bbox[1]) > 12]
    klein = [p for p in props if p not in gross]
    gruppen = {p.label: [p.label] for p in gross}
    for k in klein:
        ky, kx = k.centroid
        beste, abst = None, 1e9
        for g in gross:
            y0, x0, y1, x1 = g.bbox
            if x0 - 4 <= kx <= x1 + 4 and ky < y0 + (y1 - y0) * 0.4:
                d = y0 - ky
                if -5 < d < 35 and d < abst:
                    beste, abst = g, d
        if beste is not None:
            gruppen[beste.label].append(k.label)
    erg = []
    for haupt, labels in gruppen.items():
        m = np.isin(lab, labels)
        ys, xs = np.nonzero(m)
        erg.append({"labels": labels, "bbox": [int(ys.min()), int(xs.min()), int(ys.max()) + 1, int(xs.max()) + 1]})
    return lab, erg


def zeilen_zuordnen(teile):
    """Teile nach vertikaler Mitte zu Zeilen gruppieren, Grundlinie je Zeile schätzen."""
    teile.sort(key=lambda t: (t["bbox"][0] + t["bbox"][2]) / 2)
    hoehen = sorted(t["bbox"][2] - t["bbox"][0] for t in teile)
    typ_h = hoehen[len(hoehen) // 2]
    zeilen, akt, mitte = [], [], None
    for t in teile:
        m = (t["bbox"][0] + t["bbox"][2]) / 2
        if mitte is not None and abs(m - mitte) > typ_h * 0.9:
            zeilen.append(akt)
            akt = []
        akt.append(t)
        mitte = np.median([(u["bbox"][0] + u["bbox"][2]) / 2 for u in akt])
    zeilen.append(akt)
    for z in zeilen:
        unten = sorted(t["bbox"][2] for t in z)
        grund = unten[len(unten) // 2]
        xh = np.median([t["bbox"][2] - t["bbox"][0] for t in z]) * 0.8
        for t in z:
            t["grundlinie"] = float(grund)
            t["xhoehe"] = float(max(xh, 6))
        z.sort(key=lambda t: t["bbox"][1])
    return [t for z in zeilen for t in z]


def schneiden(seiten_datei, ordner):
    seiten = json.load(open(seiten_datei))
    os.makedirs(ordner, exist_ok=True)
    alle = []
    for s in seiten:
        im, maske = seite_laden(s)
        _, teile = stuecke(maske)
        teile = zeilen_zuordnen(teile)
        for i, t in enumerate(teile):
            t["id"] = f'{s["name"]}-{i}'
            t["seite"] = s["name"]
        alle += teile
        # Übersichtsbild: Kacheln mit Nummer
        kacheln = []
        for t in teile:
            y0, x0, y1, x1 = t["bbox"]
            k = im.crop((x0 - 3, y0 - 3, x1 + 3, y1 + 3))
            k.thumbnail((110, 80))
            kacheln.append((t["id"], k))
        spalten, kb, kh = 10, 120, 105
        for blatt in range(0, len(kacheln), 80):
            teil = kacheln[blatt:blatt + 80]
            zeilen_n = (len(teil) + spalten - 1) // spalten
            bild = Image.new("RGB", (spalten * kb, zeilen_n * kh), "white")
            d = ImageDraw.Draw(bild)
            for j, (tid, k) in enumerate(teil):
                x, y = (j % spalten) * kb, (j // spalten) * kh
                bild.paste(k, (x + 5, y + 20))
                d.text((x + 5, y + 4), tid, fill="red")
                d.rectangle((x, y, x + kb - 1, y + kh - 1), outline="#ccc")
            bild.save(os.path.join(ordner, f'uebersicht_{s["name"]}_{blatt // 80}.png'))
    json.dump({"seiten": seiten, "teile": alle}, open(os.path.join(ordner, "teile.json"), "w"), indent=1)
    lp = os.path.join(ordner, "labels.json")
    if not os.path.exists(lp):
        json.dump({t["id"]: "" for t in alle}, open(lp, "w"), indent=0, ensure_ascii=False)
    print(f"{len(alle)} Teile aus {len(seiten)} Seiten → {ordner}")


def bauen(ordner):
    daten = json.load(open(os.path.join(ordner, "teile.json")))
    labels = json.load(open(os.path.join(ordner, "labels.json")))
    seiten = {s["name"]: s for s in daten["seiten"]}
    cache = {}
    glyphen = {}
    for t in daten["teile"]:
        z = labels.get(t["id"], "")
        if not z:
            continue
        if t["seite"] not in cache:
            _, maske = seite_laden(seiten[t["seite"]])
            lab, _ = stuecke(maske)
            cache[t["seite"]] = lab
        lab = cache[t["seite"]]
        y0, x0, y1, x1 = t["bbox"]
        m = np.isin(lab[y0:y1, x0:x1], t["labels"])
        m = np.pad(m, 2)
        pfade = skelett_pfade(m)
        xh = t["xhoehe"]
        grund = t["grundlinie"] - y0 + 2
        norm = [[[round((x - 2) / xh, 3), round((grund - y) / xh, 3)] for y, x in p] for p in pfade]
        glyphen.setdefault(z, []).append({"quelle": t["id"], "pfade": norm, "breite": round((x1 - x0) / xh, 3)})
    json.dump(glyphen, open(os.path.join(ordner, "glyphen.json"), "w"), ensure_ascii=False)
    print(f"{sum(len(v) for v in glyphen.values())} Glyphen, {len(glyphen)} Zeichen: "
          + " ".join(f"{k}×{len(v)}" for k, v in sorted(glyphen.items())))
    vorschau(glyphen, os.path.join(ordner, "glyphen_vorschau.png"))


def vorschau(glyphen, datei, s=40):
    zeichen = sorted(glyphen)
    maxn = max(len(v) for v in glyphen.values())
    bild = Image.new("RGB", (60 + maxn * (s * 2), len(zeichen) * int(s * 2.4)), "white")
    d = ImageDraw.Draw(bild)
    for r, z in enumerate(zeichen):
        y0 = r * int(s * 2.4) + int(s * 1.6)
        d.text((10, y0 - s // 2), z, fill="red")
        d.line((50, y0, bild.width, y0), fill="#ddd")
        for c, g in enumerate(glyphen[z]):
            x0 = 60 + c * s * 2
            for p in g["pfade"]:
                pts = [(x0 + x * s, y0 - y * s) for x, y in p]
                if len(pts) > 1:
                    d.line(pts, fill="black", width=2)
    bild.save(datei)


if __name__ == "__main__":
    if sys.argv[1] == "schneiden":
        schneiden(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "bauen":
        bauen(sys.argv[2])
    else:
        print(__doc__)
