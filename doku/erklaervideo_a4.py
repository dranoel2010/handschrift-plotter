"""Erklär-Animation "A4 mit dem Plotter" (Weg A) als GIF.

Ansicht von oben auf das Druckbett. Das Bett bleibt im Bild stehen; man sieht, wohin der Stift
kommt (grüne Zone), wie die obere Hälfte geschrieben wird, wie die Schraube ins Loch geht und
das Tablett 10 cm weiterrutscht, und wie danach die untere Hälfte drankommt.
    python3 erklaervideo_a4.py  →  a4_erklaerung.gif
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

FONT = os.path.expanduser("~/opt/openscad/squashfs-root/usr/share/openscad/fonts/Liberation-2.00.1/ttf/LiberationSans-Bold.ttf")
F_GROSS = ImageFont.truetype(FONT, 30)
F_KLEIN = ImageFont.truetype(FONT, 20)

W, H = 900, 1250
S = 1.45                      # Pixel pro mm
X0 = 300                      # Bildschirm-x von Bett-X = 0
Y_BASIS = 880                 # Bildschirm-y von Bett-Y = 0 (vorn = unten)


def bx(x):  # Bett-X (mm) → Bildschirm
    return X0 + x * S


def by(y):  # Bett-Y (mm, nach hinten) → Bildschirm (nach oben)
    return Y_BASIS - y * S


PLATTE_B, PLATTE_L = 218, 304
PAPIER_B, PAPIER_L = 210, 297
ZONE = (5, 225)               # in dieser Bett-Y-Spanne kommt der Stift hin
START_V = -82                 # Vorderkante Tablett (Bett-Y) am Anfang
BUCHSE = (4, 139)             # Buchse auf dem Tablett (u, v)

random.seed(3)


def zeile_punkte(breite_mm, n=60):
    """eine 'Handschrift'-Zeile als Wellenlinie (Tablett-u relativ, Höhe in mm)"""
    pts, phase = [], random.random() * 6
    for i in range(n + 1):
        t = i / n
        u = t * breite_mm
        h = 1.8 * math.sin(t * 38 + phase) + 0.8 * math.sin(t * 91 + phase * 2)
        pts.append((u, h))
    return pts


# Zeilen: Abstand von der Papier-Oberkante (mm)
ZEILEN_1 = [18 + 10 * i for i in range(19)]            # passt vor dem Verschieben (bis ~200)
ZEILEN_2 = [218 + 10 * i for i in range(7)]            # danach
LINIEN = {d: zeile_punkte(150 if d not in (18, 218) else 90) for d in ZEILEN_1 + ZEILEN_2}


def papier_punkt(versatz, u, d):
    """Papierpunkt (u ab linker Papierkante, d ab Papier-Oberkante) → Bett-Koordinaten"""
    v_oben = START_V + versatz + PLATTE_L - 3.5           # Oberkante Papier an der hinteren Leiste
    return 8 + u, v_oben - d


def bild(versatz, geschrieben, stift=None, haken_unten=False, text="", unter="", zone_blink=False,
         pfeil=False, rot=True):
    im = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(im, "RGBA")
    # Bett
    d.rectangle([bx(-0), by(230), bx(230), by(0)], fill=(70, 70, 75))
    d.text((bx(115), by(0) + 12), "vorne (Display-Seite)", font=F_KLEIN, fill="gray", anchor="mt")
    d.text((bx(115), by(230) - 10), "Druckbett", font=F_KLEIN, fill=(70, 70, 75), anchor="mb") if versatz < 50 else None
    # Tablett
    v0 = START_V + versatz
    d.rectangle([bx(0), by(v0 + PLATTE_L), bx(PLATTE_B), by(v0)], fill=(70, 130, 220), outline=(30, 70, 150), width=3)
    # Papier
    px0, py_oben = papier_punkt(versatz, 0, 0)
    d.rectangle([bx(px0), by(py_oben), bx(px0 + PAPIER_B), by(py_oben - PAPIER_L)], fill=(255, 255, 252), outline=(160, 160, 160))
    # Buchse
    bu = (BUCHSE[0], v0 + BUCHSE[1])
    d.ellipse([bx(bu[0]) - 9, by(bu[1]) - 9, bx(bu[0]) + 9, by(bu[1]) + 9], fill=(30, 70, 150), outline="white", width=2)
    # Bereich, den der Stift nicht erreicht (auf dem Papier)
    if rot:
        unten = py_oben - PAPIER_L
        if unten < ZONE[0]:
            d.rectangle([bx(px0), by(min(ZONE[0], py_oben)), bx(px0 + PAPIER_B), by(unten)], fill=(230, 40, 40, 90))
            d.text((bx(px0 + PAPIER_B / 2), by((ZONE[0] + unten) / 2)), "kommt der Stift\nNICHT hin", font=F_KLEIN,
                   fill=(180, 0, 0), anchor="mm", align="center")
    # Geschriebenes
    for zeile, anteil in geschrieben:
        pts = LINIEN[zeile]
        k = max(2, int(len(pts) * anteil))
        xy = []
        for u, h in pts[:k]:
            x, y = papier_punkt(versatz, 15 + u, zeile)
            xy.append((bx(x), by(y + h * 0.6)))
        d.line(xy, fill=(20, 20, 120), width=3)
    # grüne Zone
    a = 170 if zone_blink else 110
    d.rectangle([bx(-6), by(ZONE[1]), bx(236), by(ZONE[0])], outline=(0, 170, 0, a), width=5)
    d.text((bx(240), by(ZONE[1]) + 4), "Hier kommt\nder Stift hin\n(22 cm)", font=F_KLEIN, fill=(0, 140, 0))
    # Stift + Schraube
    if stift:
        sx, sy = stift
        d.ellipse([bx(sx) - 8, by(sy) - 8, bx(sx) + 8, by(sy) + 8], fill=(0, 0, 0))
        hx, hy = sx, sy - 12.65
        farbe = (220, 30, 30) if haken_unten else (240, 200, 0)
        d.rectangle([bx(hx) - 7, by(hy) - 7, bx(hx) + 7, by(hy) + 7], fill=farbe, outline="black", width=2)
        if haken_unten:
            box = d.textbbox((bx(hx) + 14, by(hy)), "Schraube steckt im Loch", font=F_KLEIN, anchor="lm")
            d.rectangle([box[0] - 4, box[1] - 3, box[2] + 4, box[3] + 3], fill="white", outline=(200, 0, 0))
            d.text((bx(hx) + 14, by(hy)), "Schraube steckt im Loch", font=F_KLEIN, fill=(200, 0, 0), anchor="lm")
    if pfeil:
        x = bx(-25)
        d.line([(x, by(40)), (x, by(150))], fill=(220, 30, 30), width=6)
        d.polygon([(x - 14, by(150)), (x + 14, by(150)), (x, by(165))], fill=(220, 30, 30))
        d.text((x - 12, by(100)), "Tablett\nrutscht\n10 cm", font=F_KLEIN, fill=(200, 0, 0), anchor="rm", align="right")
    # Legende + Text
    d.rectangle([0, 0, W, 150], fill=(245, 245, 245))
    d.multiline_text((30, 25), text, font=F_GROSS, fill="black", spacing=8)
    d.multiline_text((30, H - 110), unter, font=F_KLEIN, fill=(60, 60, 60), spacing=6)
    leg_y = H - 160
    d.rectangle([30, leg_y, 50, leg_y + 20], fill=(70, 130, 220)); d.text((58, leg_y), "Tablett (gedruckt)", font=F_KLEIN, fill="black")
    d.ellipse([260, leg_y, 280, leg_y + 20], fill="black"); d.text((288, leg_y), "Stift", font=F_KLEIN, fill="black")
    d.rectangle([360, leg_y, 380, leg_y + 20], fill=(240, 200, 0), outline="black"); d.text((388, leg_y), "Schraube (oben)", font=F_KLEIN, fill="black")
    d.rectangle([580, leg_y, 600, leg_y + 20], fill=(220, 30, 30), outline="black"); d.text((608, leg_y), "Schraube unten", font=F_KLEIN, fill="black")
    return im


frames, dauer = [], []


def add(im, ms):
    frames.append(im.convert("P", palette=Image.ADAPTIVE, colors=64)); dauer.append(ms)


# 1. Problem
for i in range(6):
    add(bild(0, [], text="1. Das Blatt liegt auf einem Tablett.\n    Das Tablett liegt LOSE auf dem Druckbett.",
             unter="Ansicht: von oben auf den Drucker.", zone_blink=i % 2 == 0), 700)
add(bild(0, [], text="2. Problem: Der Stift kommt nur 22 cm weit.\n    Das untere Stück des Blatts erreicht er nicht.",
         unter="Ein A4-Blatt ist 30 cm lang."), 3500)

# 2. obere Hälfte schreiben
geschr = []
for z in ZEILEN_1:
    for anteil in (0.35, 0.7, 1.0):
        x, y = papier_punkt(0, 15 + 150 * anteil, z)
        aktuell = geschr + [(z, anteil)]
        add(bild(0, aktuell, stift=(x, y), text="3. Der Drucker schreibt alles,\n    was in die grüne Zone passt."), 90)
    geschr.append((z, 1.0))
add(bild(0, geschr, text="3. Der Drucker schreibt alles,\n    was in die grüne Zone passt."), 1500)

# 3. Schraube ins Loch
ziel = (BUCHSE[0], START_V + BUCHSE[1] + 12.65)
for k in range(8):
    t = (k + 1) / 8
    x = 120 + (ziel[0] - 120) * t; y = 60 + (ziel[1] - 60) * t
    add(bild(0, geschr, stift=(x, y), text="4. Der Kopf fährt zum Loch\n    am Rand des Tabletts."), 120)
add(bild(0, geschr, stift=ziel, haken_unten=True, text="5. Die Schraube geht RUNTER\n    und steckt im Loch."), 2500)

# 4. Verschieben
for k in range(16):
    v = 100 * (k + 1) / 16
    add(bild(v, geschr, stift=(ziel[0], ziel[1] + v), haken_unten=True, pfeil=True,
             text="6. Das Bett fährt. Das Tablett hängt an der\n    Schraube fest und rutscht 10 cm weiter.",
             unter="Kein Motor nötig: der Drucker schiebt das Tablett selbst.", rot=False), 150)
add(bild(100, geschr, stift=(ziel[0], ziel[1] + 100), haken_unten=True, pfeil=True,
         text="6. Das Bett fährt. Das Tablett hängt an der\n    Schraube fest und rutscht 10 cm weiter.", rot=False), 2000)
add(bild(100, geschr, stift=(ziel[0], ziel[1] + 100), text="7. Schraube wieder hoch.\n    Jetzt ist der Rest des Blatts in der Zone!"), 3000)

# 5. untere Hälfte
for z in ZEILEN_2:
    for anteil in (0.35, 0.7, 1.0):
        x, y = papier_punkt(100, 15 + 150 * anteil, z)
        add(bild(100, geschr + [(z, anteil)], stift=(x, y), text="8. Der Drucker schreibt den Rest."), 90)
    geschr.append((z, 1.0))
add(bild(100, geschr, text="9. Fertig: das ganze A4-Blatt ist beschrieben.\n    Du hast nichts angefasst.",
         unter="Geteilt wird immer zwischen zwei Zeilen,\ndamit man vom Verschieben nichts sieht."), 5000)

ziel_datei = os.path.join(os.path.dirname(os.path.abspath(__file__)), "a4_erklaerung.gif")
frames[0].save(ziel_datei, save_all=True, append_images=frames[1:], duration=dauer, loop=0, optimize=True)
print(len(frames), "Bilder,", round(sum(dauer) / 1000, 1), "s →", ziel_datei)
