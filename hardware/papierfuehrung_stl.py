"""Papierführung als STL ohne OpenSCAD (nur Standardbibliothek).

Gleiche Maße wie papierfuehrung.scad, aber aus Quadern zusammengesetzt:
die Kerben sind Lücken in der Lippe, statt Ziffern gibt es 1 bzw. 2 kleine Noppen.
    python3 papierfuehrung_stl.py  →  papierfuehrung.stl
"""
import os
import struct

laenge, breite, dicke = 225.0, 14.0, 1.2
lippe_h, lippe_b = 2.0, 2.4
versatz, kerbe_1, kerbe_b = 100.0, 50.0, 1.0


def quader(x, y, z, dx, dy, dz):
    p = [(x + a * dx, y + b * dy, z + c * dz) for a in (0, 1) for b in (0, 1) for c in (0, 1)]
    # Indizes: (a,b,c) → a*4 + b*2 + c ; Dreiecke gegen den Uhrzeigersinn von außen gesehen
    flaechen = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    tris = []
    for a, b, c, d in flaechen:
        tris += [(p[a], p[b], p[c]), (p[a], p[c], p[d])]
    return tris


def normale(t):
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = t
    ux, uy, uz, vx, vy, vz = bx - ax, by - ay, bz - az, cx - ax, cy - ay, cz - az
    n = (uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx)
    l = sum(v * v for v in n) ** 0.5 or 1
    return tuple(v / l for v in n)


tris = quader(0, 0, 0, breite, laenge, dicke)                       # Auflage
k1, k2 = kerbe_1, kerbe_1 + versatz
lx = breite - lippe_b
grenzen = [0, k1 - kerbe_b / 2, k1 + kerbe_b / 2, k2 - kerbe_b / 2, k2 + kerbe_b / 2, laenge]
for i in (0, 2, 4):                                                 # Lippe mit 2 Lücken
    tris += quader(lx, grenzen[i], dicke, lippe_b, grenzen[i + 1] - grenzen[i], lippe_h)
for y, n in ((k1, 1), (k2, 2)):                                     # Noppen: 1 bzw. 2
    for j in range(n):
        tris += quader(3 + j * 3.5, y + 2.5, dicke, 2, 2, 0.6)

ziel = os.path.join(os.path.dirname(os.path.abspath(__file__)), "papierfuehrung.stl")
with open(ziel, "wb") as f:
    f.write(b"Papierfuehrung Handschrift-Plotter".ljust(80, b" "))
    f.write(struct.pack("<I", len(tris)))
    for t in tris:
        f.write(struct.pack("<3f", *normale(t)))
        for v in t:
            f.write(struct.pack("<3f", *v))
        f.write(b"\0\0")
print(f"{len(tris)} Dreiecke → {ziel}")
