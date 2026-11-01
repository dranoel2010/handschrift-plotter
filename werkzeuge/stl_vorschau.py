"""STL → PNG-Vorschau ohne OpenGL (3 Ansichten, einfache Schattierung). Aufruf: python stl_vorschau.py teil.stl bild.png"""
import sys, numpy as np, trimesh
from PIL import Image, ImageDraw
def ansicht(stl, az, el, out, size=700):
    m = trimesh.load(stl); v = m.vertices - m.bounds.mean(0)
    a, e = np.radians(az), np.radians(el)
    Rz = np.array([[np.cos(a), -np.sin(a), 0], [np.sin(a), np.cos(a), 0], [0, 0, 1]])
    Rx = np.array([[1, 0, 0], [0, np.cos(e), -np.sin(e)], [0, np.sin(e), np.cos(e)]])
    p = v @ Rz.T @ Rx.T
    s = size * 0.85 / np.ptp(p[:, [0, 2]], 0).max()
    img = Image.new('RGB', (size, size), 'white'); d = ImageDraw.Draw(img)
    f = m.faces; tri = p[f]; n = np.cross(tri[:, 1] - tri[:, 0], tri[:, 2] - tri[:, 0])
    n /= np.linalg.norm(n, axis=1)[:, None] + 1e-9
    licht = np.array([0.4, -0.7, 0.6]); licht /= np.linalg.norm(licht)
    for i in np.argsort(tri[:, :, 1].mean(1))[::-1]:
        if n[i, 1] > 0: continue
        h = int(70 + 170 * max(0, n[i] @ licht))
        pts = [(size / 2 + q[0] * s, size / 2 - q[2] * s) for q in tri[i]]
        d.polygon(pts, fill=(h, int(h * 0.85), int(h * 0.55)))
    return img
bilder = [ansicht(sys.argv[1], az, el, None) for az, el in ((-35, 20), (55, 15), (180+35, 25))]
w = Image.new('RGB', (2100, 700), 'white')
for i, b in enumerate(bilder): w.paste(b, (i * 700, 0))
w.save(sys.argv[2])
