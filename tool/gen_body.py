#!/usr/bin/env python3
"""Genera la geometría de las siluetas de HOPE.

Salida: assets/config/body_geometry.json (lo lee la app) y, opcionalmente,
una vista previa SVG para revisar el dibujo:

    python3 tool/gen_body.py                 # solo JSON
    python3 tool/gen_body.py --preview out.svg

Sistema de coordenadas: caja de 200 x 520 unidades, origen arriba a la izquierda,
eje vertical central en x = 100. Se define el lado izquierdo de la figura
(x < 100) y se refleja para obtener el derecho.
"""
import json
import math
import os
import sys

W, H = 200, 520


# ---------------------------------------------------------------- utilidades
def catmull(points, n=8):
    """Curva Catmull-Rom que pasa por todos los puntos (devuelve puntos)."""
    if len(points) < 3:
        return list(points)
    pts = [points[0]] + list(points) + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for s in range(n):
            t = s / n
            t2, t3 = t * t, t * t * t
            x = 0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t
                       + (2 * p0[0] - 5 * p1[0] + 4 * p2[0] - p3[0]) * t2
                       + (-p0[0] + 3 * p1[0] - 3 * p2[0] + p3[0]) * t3)
            y = 0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t
                       + (2 * p0[1] - 5 * p1[1] + 4 * p2[1] - p3[1]) * t2
                       + (-p0[1] + 3 * p1[1] - 3 * p2[1] + p3[1]) * t3)
            out.append((x, y))
    out.append(points[-1])
    return out


def ellipse(cx, cy, rx, ry, n=48):
    return [(cx + rx * math.cos(2 * math.pi * i / n),
             cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n)]


def clip_y(poly, y0, keep_below):
    """Recorta un polígono convexo por la recta horizontal y = y0."""
    out = []
    n = len(poly)
    for i in range(n):
        a, b = poly[i], poly[(i + 1) % n]
        ina = (a[1] >= y0) if keep_below else (a[1] <= y0)
        inb = (b[1] >= y0) if keep_below else (b[1] <= y0)
        if ina:
            out.append(a)
        if ina != inb:
            t = (y0 - a[1]) / (b[1] - a[1])
            out.append((a[0] + t * (b[0] - a[0]), y0))
    return out


def mirror(poly):
    return [(W - x, y) for x, y in poly]


def rev(pts):
    return list(reversed(pts))


def dedupe(poly):
    out = []
    for p in poly:
        if not out or abs(out[-1][0] - p[0]) > 1e-6 or abs(out[-1][1] - p[1]) > 1e-6:
            out.append(p)
    if len(out) > 1 and abs(out[0][0] - out[-1][0]) < 1e-6 and abs(out[0][1] - out[-1][1]) < 1e-6:
        out.pop()
    return out


def lerp_table(table, y):
    if y <= table[0][0]:
        return table[0][1]
    for (y0, k0), (y1, k1) in zip(table, table[1:]):
        if y <= y1:
            return k0 + (k1 - k0) * (y - y0) / (y1 - y0)
    return table[-1][1]


# Factores de anchura de la silueta de mujer respecto a la de hombre.
FEMALE_TORSO = [(0, 0.88), (172, 0.88), (228, 0.86), (270, 1.10),
                (310, 1.08), (395, 1.0), (470, 1.0), (520, 0.95)]
FEMALE_ARMS = 0.88


def female_torso(poly):
    return [(100 + (x - 100) * lerp_table(FEMALE_TORSO, y), y) for x, y in poly]


def female_arms(poly):
    return [(100 + (x - 100) * FEMALE_ARMS, y) for x, y in poly]


# ------------------------------------------------------------ puntos clave
# Lado izquierdo de la figura (hombre). Los puntos compartidos entre zonas
# vecinas son idénticos para que no queden huecos.
N0 = (90, 80)      # base del cuello
S0 = (76, 84)      # inicio del hombro
S1 = (62, 97)
AX = (57, 124)     # axila
AO = (32, 124)     # parte exterior del hombro
W0 = (16, 288)     # muñeca exterior
W1 = (32, 290)     # muñeca interior
C1 = (58, 172)     # límite pecho / abdomen
L1 = (60, 200)     # límite espalda / lumbar
H0 = (57, 266)     # cadera (inicio de la ingle)
G0 = (54, 305)     # pliegue del glúteo
K0 = (64, 395)     # rodilla exterior
K1 = (91, 395)     # rodilla interior
A0 = (70, 488)     # tobillo exterior
A1 = (84, 488)     # tobillo interior
P0 = (92, 286)     # perineo, esquina superior izquierda
P1 = (96, 297)
P2 = (100, 300)    # unión de los muslos

SHOULDER_OUT = catmull([S0, (60, 85), (47, 90), (38, 101), (33, 113), AO])
ARM_OUT = catmull([AO, (29, 150), (26, 180), (24, 205), (21, 235), (18, 262), W0])
ARM_IN = catmull([W1, (35, 262), (39, 235), (44, 205), (48, 180), (52, 150), AX])
HAND = catmull([W1, (34.5, 303), (33.5, 318), (29.5, 330), (22, 333),
                (15.5, 327), (12, 313), (12.5, 299), W0])

SIDE = catmull([AX, (57.5, 150), C1, L1, (63, 228), (60.5, 250), H0])
i_C1 = SIDE.index(C1)
i_L1 = SIDE.index(L1)
SIDE_CHEST = SIDE[:i_C1 + 1]          # axila -> límite pecho
SIDE_ABDO = SIDE[i_C1:]               # límite pecho -> cadera
SIDE_BACK = SIDE[:i_L1 + 1]           # axila -> límite lumbar
SIDE_LUMB = SIDE[i_L1:]               # límite lumbar -> cadera

INGUINAL = catmull([H0, (75, 276), P0], n=6)
THIGH_OUT = catmull([H0, (54.5, 285), G0, (57, 340), (61, 370), K0])
i_G0 = THIGH_OUT.index(G0)
THIGH_OUT_HIP = THIGH_OUT[:i_G0 + 1]  # cadera -> pliegue (lateral del glúteo)
THIGH_OUT_LOW = THIGH_OUT[i_G0:]      # pliegue -> rodilla
THIGH_IN = catmull([P2, (97, 312), (95, 340), (93, 370), K1])
THIGH_IN_LOW = THIGH_IN[1:]           # desde (97, 312)
CALF_OUT = catmull([K0, (61, 420), (61.5, 445), (66, 470), A0])
CALF_IN = catmull([K1, (91.5, 420), (89, 445), (86, 470), A1])
FOOT_FRONT = catmull([A1, (86.5, 499), (88, 508), (85, 513), (67, 513), (63, 508), (66.5, 499), A0])
FOOT_BACK = catmull([A1, (86, 500), (84.5, 510), (77, 513), (69.5, 510), (68, 500), A0])
FOLD = catmull([G0, (62, 313.5), (76, 316.5), (90, 315), (98, 310)], n=6)
HEAD_C, HEAD_RX, HEAD_RY = (100, 36), 23, 29
HEAD = ellipse(HEAD_C[0], HEAD_C[1], HEAD_RX, HEAD_RY)


def neck_polygon(T):
    """Cuello: desde la barbilla (borde inferior de la cabeza) hasta el pecho."""
    bl = T([(90, 80)])[0]
    br = T([(110, 80)])[0]
    x0 = 100 - (100 - bl[0]) * 0.92
    x1 = 100 + (br[0] - 100) * 0.92
    top = []
    for i in range(9):
        x = x0 + (x1 - x0) * i / 8
        k = max(0.0, 1 - ((x - HEAD_C[0]) / HEAD_RX) ** 2)
        top.append((x, HEAD_C[1] + HEAD_RY * math.sqrt(k)))
    return top + [br, bl]


def sym(left):
    """Une el lado izquierdo con su reflejo para formar una zona central."""
    return dedupe(left + rev(mirror(left)))


def pair(left):
    left = dedupe(left)
    return [left, mirror(left)]


# Zonas pares: cada lado es una zona propia. Izquierda y derecha son las del
# paciente: en la vista frontal la figura está de cara, así que su lado
# derecho queda a la izquierda de la pantalla; en la posterior coinciden.
def add_sides(zones, zone_id, polys, f, view):
    screen_left, screen_right = [f(p) for p in polys]
    if view == "front":
        zones[zone_id + "_izq"] = [screen_right]
        zones[zone_id + "_der"] = [screen_left]
    else:
        zones[zone_id + "_izq"] = [screen_left]
        zones[zone_id + "_der"] = [screen_right]


def build(sex):
    T = female_torso if sex == "female" else (lambda p: p)
    A = female_arms if sex == "female" else (lambda p: p)

    shoulder = dedupe(SHOULDER_OUT + [AX, S1])
    arm = dedupe(ARM_OUT + ARM_IN)
    hand = dedupe(HAND)

    chest_left = [N0, S0, S1] + SIDE_CHEST
    chest = sym(chest_left)
    abdomen_left = SIDE_ABDO + INGUINAL[1:] + [(100, 286)]
    abdomen = dedupe(abdomen_left[:-1] + rev(mirror(abdomen_left[:-1])))
    perineum = dedupe([P0, mirror([P0])[0], mirror([P1])[0], P2, P1])
    # orden: ingle (de perineo a cadera) -> exterior -> rodilla -> interior
    thigh_front = dedupe(rev(INGUINAL) + THIGH_OUT[1:] + rev(THIGH_IN) + [P1])
    calf = dedupe(CALF_OUT + rev(CALF_IN))
    back_upper = sym([N0, S0, S1] + SIDE_BACK)
    lumbar_left = SIDE_LUMB + [(100, H0[1])]
    lumbar = dedupe(lumbar_left[:-1] + rev(mirror(lumbar_left[:-1])))
    glute = dedupe(THIGH_OUT_HIP + FOLD[1:] + [(100, 304), (100, H0[1])])
    thigh_back = dedupe(FOLD + THIGH_IN_LOW + rev(THIGH_OUT_LOW))

    head_cap = clip_y(HEAD, 24, keep_below=False)
    face = clip_y(HEAD, 24, keep_below=True)

    def tz(polys, f):
        return [f(p) for p in polys]

    neck = neck_polygon(T)

    fz = {}
    fz["cuello_delante"] = [neck]
    fz["cabeza"] = [head_cap]
    fz["cara"] = [face]
    add_sides(fz, "hombros", pair(shoulder), A, "front")
    fz["pecho"] = [T(chest)]
    fz["abdomen"] = [T(abdomen)]
    fz["perineo"] = [T(perineum)]
    add_sides(fz, "brazos", pair(arm), A, "front")
    add_sides(fz, "manos", pair(hand), A, "front")
    add_sides(fz, "muslos", pair(thigh_front), T, "front")
    add_sides(fz, "pantorrillas", pair(calf), T, "front")
    add_sides(fz, "pies", pair(FOOT_FRONT), T, "front")

    bz = {}
    bz["cuello_detras"] = [neck]
    bz["cabeza"] = [HEAD]
    add_sides(bz, "hombros", pair(shoulder), A, "back")
    bz["espalda"] = [T(back_upper)]
    bz["lumbar"] = [T(lumbar)]
    add_sides(bz, "gluteos", pair(glute), T, "back")
    add_sides(bz, "brazos", pair(arm), A, "back")
    add_sides(bz, "manos", pair(hand), A, "back")
    add_sides(bz, "muslos", pair(thigh_back), T, "back")
    add_sides(bz, "pantorrillas", pair(calf), T, "back")
    add_sides(bz, "pies", pair(FOOT_BACK), T, "back")

    front = {"base": [], "zones": fz, "decor": []}
    back = {"base": [], "zones": bz, "decor": []}

    # Detalles que distinguen la silueta: pecho / pectorales e ingles.
    if sex == "female":
        breast = catmull([(64, 128), (66, 152), (78, 164), (92, 160), (98, 150)], n=6)
    else:
        breast = catmull([(65, 140), (80, 151), (97, 147)], n=6)
    front["decor"] += [T(breast), T(mirror(breast))]
    front["decor"] += [T(INGUINAL), T(mirror(INGUINAL))]
    navel = ellipse(100, 230, 1.6, 2.2, n=12)
    front["decor"].append(T(navel + [navel[0]]))
    back["decor"].append(T([(100, 90), (100, 258)]))
    return {"front": front, "back": back}


def rounded(obj):
    if isinstance(obj, dict):
        return {k: rounded(v) for k, v in obj.items()}
    if isinstance(obj, list):
        if obj and isinstance(obj[0], tuple):
            flat = []
            for x, y in obj:
                flat += [round(x, 1), round(y, 1)]
            return flat
        return [rounded(v) for v in obj]
    return obj


# ------------------------------------------------------------ vista previa
def svg_preview(geo, path, highlight=("pecho", "manos_izq", "pies_izq", "pies_der", "lumbar",
                                      "muslos_der", "cuello_delante", "cuello_detras")):
    panels = [("female", "front"), ("female", "back"), ("male", "front"), ("male", "back")]
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W * 4 + 50} {H + 40}" '
             f'width="{(W * 4 + 50) * 2}" height="{(H + 40) * 2}">',
             f'<rect width="100%" height="100%" fill="#FAF8F5"/>']

    def pts(poly):
        return " ".join(f"{x:.1f},{y:.1f}" for x, y in poly)

    for i, (sex, view) in enumerate(panels):
        g = geo[sex][view]
        polys = g["base"] + [p for v in g["zones"].values() for p in v]
        parts.append(f'<g transform="translate({10 + i * (W + 10)},20)">')
        parts.append(f'<text x="100" y="-6" font-size="10" text-anchor="middle" '
                     f'font-family="sans-serif">{sex} / {view}</text>')
        left, right = ("D", "I") if view == "front" else ("I", "D")
        for x, letter in ((10, left), (190, right)):
            parts.append(f'<text x="{x}" y="44" font-size="14" text-anchor="middle" '
                         f'font-family="sans-serif" fill="#8A837C">{letter}</text>')
        for p in polys:
            parts.append(f'<polygon points="{pts(p)}" fill="none" stroke="#8A837C" '
                         f'stroke-width="2.6" stroke-linejoin="round"/>')
        for p in polys:
            parts.append(f'<polygon points="{pts(p)}" fill="#E9E4DE"/>')
        for z, ps in g["zones"].items():
            for p in ps:
                parts.append(f'<polygon points="{pts(p)}" fill="none" stroke="#FFFFFF" '
                             f'stroke-width="0.9" stroke-linejoin="round"/>')
        for z in highlight:
            for p in g["zones"].get(z, []):
                parts.append(f'<polygon points="{pts(p)}" fill="#D50000" fill-opacity="0.55" '
                             f'stroke="#B71C1C" stroke-width="0.8"/>')
        for d in g["decor"]:
            parts.append(f'<polyline points="{pts(d)}" fill="none" stroke="#B8B0A8" '
                         f'stroke-width="0.9" stroke-linecap="round"/>')
        parts.append("</g>")
    parts.append("</svg>")
    with open(path, "w") as f:
        f.write("\n".join(parts))


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    out = os.path.join(here, "..", "assets", "config", "body_geometry.json")
    geo = {"female": build("female"), "male": build("male")}
    data = {"viewBox": [W, H]}
    data.update(rounded(geo))
    with open(out, "w") as f:
        json.dump(data, f, separators=(",", ":"))
    print("Escrito", os.path.normpath(out))
    if "--preview" in sys.argv:
        svg_preview(geo, sys.argv[sys.argv.index("--preview") + 1])


if __name__ == "__main__":
    main()
