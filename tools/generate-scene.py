#!/usr/bin/env python3
"""Author Ciudad Prisma: original anchored geometry visible before any script.

The checked-in Rojo project is the scene source. Players and Studio need neither
Python nor downloaded models to see the lobby, eight sectors and neutral spawn.
"""
from __future__ import annotations

import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DESTINATION = ROOT / "scene" / "color-chaos-world.project.json"
INK = (28, 43, 72)
MIDNIGHT = (38, 57, 91)
STEEL = (76, 103, 129)
WHITE = (244, 244, 235)
PEARL = (219, 229, 230)
SKY = (78, 189, 236)
GOLD = (249, 205, 95)
MINT = (102, 220, 174)
CORAL = (245, 137, 151)
LILAC = (180, 151, 235)
GRASS = (112, 172, 142)
LANE_COLORS = (SKY, GOLD, MINT, CORAL, LILAC)
tree: dict = {"$className": "Folder"}


def rgb(color):
    return [round(channel / 255, 6) for channel in color]


def group(parent, name, model=False):
    node = {"$className": "Model" if model else "Folder"}
    parent[name] = node
    return node


def transform(position, orientation=None):
    """Use the native serialized transform, not derived Position/Orientation."""
    x, y, z = (math.radians(value) for value in (orientation or (0, 0, 0)))
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    matrix = [
        [cy * cz + sy * sx * sz, -cy * sz + sy * sx * cz, sy * cx],
        [cx * sz, cx * cz, -sx],
        [-sy * cz + cy * sx * sz, sy * sz + cy * sx * cz, cy * cx],
    ]
    return {"CFrame": {"position": list(position), "orientation": [
        [round(value, 10) for value in row] for row in matrix
    ]}}


def part(name, size, position, color=WHITE, material="SmoothPlastic", *,
         parent=None, collide=True, transparency=0, shape=None, orientation=None):
    properties = {
        "Anchored": True, "Size": list(size), "CFrame": transform(position, orientation),
        "Color": rgb(color), "Material": material,
        "CanCollide": collide, "CanTouch": collide, "CanQuery": collide,
        "Transparency": transparency, "TopSurface": "Smooth", "BottomSurface": "Smooth",
    }
    if shape:
        properties["Shape"] = shape
    node = {"$className": "Part", "$properties": properties}
    (tree if parent is None else parent)[name] = node
    return node


def disk(parent, name, diameter, height, position, color, material="SmoothPlastic", **kwargs):
    return part(name, (height, diameter, diameter), position, color, material,
                parent=parent, shape="Cylinder", orientation=(0, 0, 90), **kwargs)


def sign(parent, heading, body="", *, width=320, height=108, offset=(0, 0, 0),
         accent=SKY, distance=130):
    panel = {
        "$className": "Frame",
        "$properties": {
            "Size": {"UDim2": [[1, 0], [1, 0]]},
            "BackgroundColor3": rgb(INK), "BackgroundTransparency": 0.08, "BorderSizePixel": 0,
        },
        "Corners": {"$className": "UICorner", "$properties": {"CornerRadius": {"UDim": [0, 12]}}},
        "Outline": {"$className": "UIStroke", "$properties": {
            "Color": rgb(accent), "Thickness": 1.5, "Transparency": 0.15,
        }},
        "Heading": {"$className": "TextLabel", "$properties": {
            "Position": {"UDim2": [[0, 12], [0, 8]]},
            "Size": {"UDim2": [[1, -24], [0, 31 if body else height - 16]]},
            "BackgroundTransparency": 1, "Font": "GothamBold",
            "Text": heading, "TextColor3": rgb(accent), "TextScaled": True,
            "TextWrapped": True, "BorderSizePixel": 0,
        }},
    }
    if body:
        panel["Body"] = {"$className": "TextLabel", "$properties": {
            "Position": {"UDim2": [[0, 14], [0, 43]]},
            "Size": {"UDim2": [[1, -28], [1, -51]]},
            "BackgroundTransparency": 1, "Font": "GothamMedium",
            "Text": body, "TextColor3": rgb(WHITE), "TextScaled": True,
            "TextWrapped": True, "BorderSizePixel": 0,
        }}
    parent["StaticSign"] = {
        "$className": "BillboardGui",
        "$properties": {
            "Size": {"UDim2": [[0, width], [0, height]]},
            "StudsOffset": list(offset), "MaxDistance": distance,
            "AlwaysOnTop": False, "LightInfluence": 0,
        },
        "Panel": panel,
    }


def tree_planter(parent, name, x, z, accent=MINT, *, base=6, small=False):
    plant = group(parent, name, model=True)
    diameter = 9 if small else 13
    disk(plant, "Jardinera", diameter, 1.2, (x, base + 0.6, z), PEARL)
    disk(plant, "Musgo", diameter - 1.1, 0.28, (x, base + 1.32, z), GRASS, "Grass", collide=False)
    part("Tronco", (1.5, 7, 1.5), (x, base + 4.4, z), STEEL, "Wood", parent=plant)
    part("Copa baja", (7, 6, 7), (x, base + 9, z), accent, parent=plant, collide=False, shape="Ball")
    part("Copa alta", (4.8, 4.8, 4.8), (x + 1, base + 12, z), accent, parent=plant, collide=False, shape="Ball")


def crystal(parent, name, x, y, z, color, *, scale=1):
    crystals = group(parent, name, model=True)
    disk(crystals, "Soporte", 8 * scale, 1, (x, y, z), PEARL)
    part("Prisma", (2.8 * scale, 7 * scale, 2.8 * scale), (x, y + 4 * scale, z),
         color, "Glass", parent=crystals, collide=False, orientation=(0, 45, 9), transparency=0.16)
    part("Destello", (0.5 * scale, 5.5 * scale, 0.5 * scale), (x, y + 4 * scale, z),
         color, "Neon", parent=crystals, collide=False, orientation=(0, 45, 9))


# Permanent spawn surface and a second slab that catches falls near the lobby.
part("Plaza del reactor", (164, 4, 140), (0, 4, 120), PEARL)
part("SceneSpawnFloor", (184, 6, 160), (0, -7, 120), INK, "Slate")
part("Cimiento flotante", (160, 11, 136), (0, -3.5, 120), MIDNIGHT, "Slate")
tree["LobbySpawn"] = {"$className": "SpawnLocation", "$properties": {
    "Anchored": True, "Neutral": True, "Enabled": True, "Duration": 0,
    "AllowTeamChangeOnTouch": False, "Size": [8, 0.2, 8], "CFrame": transform((0, 8, 110)),
    "Color": rgb(SKY), "Material": "SmoothPlastic", "Transparency": 1,
    "CanCollide": False, "CanTouch": False, "CanQuery": False,
    "TopSurface": "Smooth", "BottomSurface": "Smooth",
}}

plaza = group(tree, "Ciudad Prisma", model=True)
part("Paseo principal", (30, 0.14, 126), (0, 6.08, 120), WHITE, parent=plaza)
disk(plaza, "Roseta exterior", 45, 0.16, (0, 6.13, 110), INK, "Marble", collide=False)
disk(plaza, "Roseta interior", 40, 0.18, (0, 6.2, 110), WHITE, "Marble", collide=False)
disk(plaza, "Roseta prisma", 10, 0.2, (0, 6.3, 110), SKY, "Neon", collide=False)
for side in (-1, 1):
    x = side * 81
    part(f"Baranda exterior {side}", (1.6, 3.5, 140), (x, 7.75, 120), WHITE, parent=plaza)
    part(f"Pasamanos exterior {side}", (1.7, 0.25, 140), (x, 9.65, 120), SKY, "Neon", parent=plaza, collide=False)
    part(f"Jardín largo {side}", (20, 0.25, 38), (side * 68, 6.2, 137), GRASS, "Grass", parent=plaza, collide=False)
    for z in (86, 137, 151):
        tree_planter(plaza, f"Árbol {side} {z}", side * 70, z, MINT if z != 86 else LILAC, small=True)
    for z in (72, 166):
        part(f"Lámpara {side} {z}", (1.2, 9, 1.2), (side * 76, 10.5, z), STEEL, "Metal", parent=plaza)
        part(f"Luz {side} {z}", (3, 1.5, 3), (side * 76, 15.4, z), GOLD, "Neon", parent=plaza, collide=False)
    for z in (126, 146):
        part(f"Banco {side} {z}", (13, 1, 4), (side * 39, 8, z), WHITE, "WoodPlanks", parent=plaza)
        part(f"Respaldo {side} {z}", (13, 3, 0.7), (side * 39, 9.5, z + 1.8), STEEL, parent=plaza)
part("Baranda trasera", (164, 3.5, 1.6), (0, 7.75, 189), WHITE, parent=plaza)
for side in (-1, 1):
    part(f"Baranda frontal {side}", (52, 3.5, 1.6), (side * 55, 7.75, 50), WHITE, parent=plaza)
for z in (72, 84, 96, 122, 134):
    part(f"Guía del paseo {z}", (3, 0.12, 5), (0, 6.19, z), SKY, "Neon", parent=plaza, collide=False)

# Panels retain a readable welcome if services are unavailable. The live board
# renderer may replace each StaticSign with its own table.
for key, x, heading, accent in (
    ("GlobalBoard", -48, "CLASIFICACIÓN GLOBAL", GOLD),
    ("RoomBoard", 48, "CLASIFICACIÓN DE SALA", MINT),
):
    board = part(key, (34, 19, 1.4), (x, 18, 171), INK)
    part(f"Marco {key}", (36, 21, 0.8), (x, 18, 172), accent, "Metal", parent=plaza)
    for dx in (-13, 13):
        part(f"Soporte {key} {dx}", (1.6, 7, 1.6), (x + dx, 8.8, 171), STEEL, "Metal", parent=plaza)
    sign(board, heading, "Victorias · Racha máxima · Nivel\nTu aventura comienza aquí.",
         width=300, height=170, accent=accent, distance=105)

podium = group(tree, "Podio", model=True)
for place, x, height, color in ((2, -12, 3, PEARL), (1, 0, 5, GOLD), (3, 12, 2, PEARL)):
    pedestal = part(f"Puesto {place}", (10, height, 10), (x, 6 + height / 2, 151), color, parent=podium)
    sign(pedestal, str(place), width=46, height=45, offset=(0, 1.6 + height / 2, 0), accent=color, distance=70)
    part(f"Línea {place}", (10, 0.15, 0.3), (x, 6 + height + 0.08, 146), SKY, "Neon", parent=podium, collide=False)

gift = part("GiftStand", (14, 4, 14), (-52, 8, 110), WHITE)
gift_art = group(tree, "Regalo del tiempo", model=True)
part("Caja", (8, 7, 8), (-52, 13.5, 110), CORAL, parent=gift_art)
part("Tapa", (8.8, 1.1, 8.8), (-52, 17.5, 110), CORAL, parent=gift_art)
part("Cinta vertical", (1.5, 8.2, 8.2), (-52, 14, 110), GOLD, parent=gift_art, collide=False)
part("Cinta cruzada", (8.9, 0.2, 1.5), (-52, 18.16, 110), GOLD, parent=gift_art, collide=False)
for side in (-1, 1):
    part(f"Lazo {side}", (3.8, 2.2, 2), (-52 + side * 1.6, 19.2, 110), GOLD,
         parent=gift_art, collide=False, shape="Ball", orientation=(0, 0, side * 28))
sign(gift, "REGALOS GRATIS", "Tiempo jugando + cinco aciertos\nCosméticos y monedas para descubrir.",
     offset=(0, 18, 0), accent=CORAL, width=280, height=112, distance=90)

shop = part("ShopStand", (14, 4, 14), (52, 8, 110), WHITE)
shop_art = group(tree, "Atelier Prisma", model=True)
for side in (-1, 1):
    part(f"Columna {side}", (1.4, 13, 1.4), (52 + side * 7, 13, 113), STEEL, "Metal", parent=shop_art)
part("Techo", (18, 1.2, 13), (52, 20, 110), LILAC, parent=shop_art)
part("Atelier luminoso", (16, 0.3, 0.5), (52, 19.25, 103.5), GOLD, "Neon", parent=shop_art, collide=False)
part("Cuerpo de maniquí", (4.5, 4, 2.2), (52, 13.4, 110), LILAC, parent=shop_art, collide=False)
part("Visor de maniquí", (3, 2.7, 2.7), (52, 16.8, 110), SKY, "Glass", parent=shop_art, collide=False, shape="Ball")
part("Destello de maniquí", (1, 1, 1), (52, 17, 108.6), GOLD, "Neon", parent=shop_art, collide=False, shape="Ball")
sign(shop, "ATELIER PRISMA", "Trajes · Emotes · Reacciones\nDescubre tu estilo.",
     offset=(0, 18, 0), accent=LILAC, width=280, height=105, distance=90)

ghost = part("GhostPortal", (12, 15, 1.2), (57, 14, 73), SKY, "Glass", transparency=0.55, collide=False)
portal_art = group(tree, "Portal del fantasma", model=True)
disk(portal_art, "Base", 19, 0.4, (57, 6.25, 73), INK, "Marble")
for side in (-1, 1):
    part(f"Pilar {side}", (2, 17, 3), (57 + side * 7.5, 14.5, 73), WHITE, parent=portal_art)
    part(f"Borde {side}", (0.3, 16, 0.3), (57 + side * 6.3, 14.5, 71.4), SKY, "Neon", parent=portal_art, collide=False)
part("Arco", (17, 2, 3), (57, 23.5, 73), WHITE, parent=portal_art)
crystal(portal_art, "Prisma del portal", 57, 25, 73, SKY, scale=0.55)
sign(ghost, "MODO FANTASMA", "Explora la ronda sin competir.\nLa siguiente partida te espera.",
     offset=(0, 19, 0), accent=SKY, width=280, height=107, distance=95)

instructions = part("Instrucciones", (1, 1, 1), (-47, 15, 73), transparency=1, collide=False)
sign(instructions, "RECUERDA. ELIGE. AVANZA.",
     "1. Mira el personaje durante dos segundos.\n2. Encuentra su color entre cinco puertas.\n3. Cruza y sigue hasta la meta.",
     accent=MINT, width=325, height=145, distance=100)
part("Atril de bienvenida", (14, 3, 9), (-47, 7.5, 73), WHITE, parent=plaza)
crystal(plaza, "Prisma de bienvenida", -47, 9.5, 73, MINT, scale=0.8)

# Five small sculpted mascots make the lobby explorable without external meshes.
gallery = group(tree, "Galería de criaturas", model=True)
for index, (name, color) in enumerate(zip(("Nimbo", "Brote", "Orbi", "Chispa", "Lumi"), LANE_COLORS)):
    x, z = -32 + index * 16, 183
    mascot = group(gallery, name, model=True)
    disk(mascot, "Pedestal", 10, 1.4, (x, 6.7, z), WHITE)
    part("Cuerpo", (5, 5.5, 4), (x, 10, z), color, parent=mascot, shape="Ball", collide=False)
    part("Cabeza", (5.4, 4.5, 4.5), (x, 14.6, z), color, parent=mascot, shape="Ball", collide=False)
    for side in (-1, 1):
        part(f"Ojo {side}", (0.65, 0.95, 0.45), (x + side * 1.15, 15, z - 2.05), INK, parent=mascot, collide=False, shape="Ball")
        if index % 2 == 0:
            part(f"Oreja {side}", (1.3, 3 + index * 0.35, 1.3), (x + side * 2.1, 18, z),
                 color, parent=mascot, collide=False, shape="Ball", orientation=(0, 0, side * -20))
        else:
            part(f"Aleta {side}", (1.4, 2.3, 3.4), (x + side * 3, 10.8, z), GOLD if index == 3 else MINT,
                 parent=mascot, collide=False, shape="Ball", orientation=(0, 0, side * 25))
    part("Insignia", (1.5, 1.5, 0.25), (x, 10.3, z - 2), WHITE, parent=mascot, collide=False, orientation=(0, 0, 45))

# This promenade overlaps the lobby and Stage01 by one stud at either end.
promenade = group(tree, "Paseo hacia la aventura", model=True)
part("Paseo", (56, 4, 76), (0, 4, 13), WHITE, parent=promenade)
for side in (-1, 1):
    part(f"Baranda {side}", (1.6, 3, 76), (side * 27.3, 7.5, 13), STEEL, "Metal", parent=promenade)
    part(f"Guía {side}", (0.4, 0.2, 74), (side * 24.5, 6.2, 13), MINT, "Neon", parent=promenade, collide=False)
    part(f"Columna de entrada {side}", (3, 22, 4), (side * 24.5, 17, 48), WHITE, parent=promenade)
part("Arco de entrada", (53, 3, 4), (0, 29, 48), WHITE, parent=promenade)
part("Corona luminosa", (50, 0.3, 0.4), (0, 30.7, 46), GOLD, "Neon", parent=promenade, collide=False)
title = part("Título", (1, 1, 1), (0, 28, 48), collide=False, transparency=1)
sign(title, "COLOR CHAOS", "CIUDAD PRISMA", width=390, height=100, accent=GOLD, distance=200)
for z in (-15, 0, 15, 30):
    part(f"Baldosa {z}", (8, 0.12, 2), (0, 6.17, z), SKY, "Neon", parent=promenade, collide=False)

stages = group(tree, "Stages")
themes = (
    ("JARDÍN DEL CIELO", MINT, (216, 232, 221)),
    ("TERRAZAS CORAL", CORAL, (235, 221, 220)),
    ("PUERTO DE NUBES", SKY, (215, 230, 236)),
    ("BOSQUE DE CRISTAL", LILAC, (225, 220, 236)),
    ("ÓRBITA DORADA", GOLD, (236, 229, 209)),
    ("JARDÍN LUNAR", MINT, (218, 233, 229)),
    ("GALERÍA AURORA", LILAC, (228, 223, 234)),
    ("OBSERVATORIO PRISMA", GOLD, (234, 230, 219)),
)
for index, (theme, accent, stone) in enumerate(themes, 1):
    start_z = -40 - (index - 1) * 112
    gate_z = start_z - 48
    stage = group(stages, f"Stage{index:02}", model=True)
    part("Floor", (120, 4, 112), (0, 4, start_z - 40), stone, parent=stage)
    decor = group(stage, "Architecture", model=True)
    part("FloatingFoundation", (116, 7, 108), (0, -1.5, start_z - 40), MIDNIGHT, "Slate", parent=decor)
    part("EntranceLanding", (106, 0.13, 18), (0, 6.1, start_z), WHITE, parent=decor)
    part("ExitLanding", (106, 0.13, 18), (0, 6.1, start_z - 82), WHITE, parent=decor)
    part("EntranceLine", (106, 0.16, 0.4), (0, 6.2, start_z + 8.5), accent, "Neon", parent=decor, collide=False)
    part("ExitLine", (106, 0.16, 0.4), (0, 6.2, start_z - 90.5), accent, "Neon", parent=decor, collide=False)
    for side in (-1, 1):
        # Twenty-two-stud walls stop ordinary jumping around the closed doors.
        part(f"Boundary{side}", (4, 22, 112), (side * 58, 17, start_z - 40),
             STEEL, "Glass", parent=stage, transparency=0.65)
        part(f"Crown{side}", (4.2, 0.6, 112), (side * 58, 28.3, start_z - 40), accent, "Metal", parent=decor)
        part(f"GhostWalk{side}", (16, 4, 112), (side * 70, 4, start_z - 40), INK, "Marble", parent=stage)
        part(f"GhostRail{side}", (1, 3, 112), (side * 78, 7.5, start_z - 40), accent, "Glass", parent=decor, transparency=0.4)
        part(f"GhostLine{side}", (0.3, 0.2, 108), (side * 73, 6.2, start_z - 40), accent, "Neon", parent=decor, collide=False)
        island = group(decor, f"FloatingGarden{side}", model=True)
        disk(island, "Island", 26, 7, (side * 98, -1, start_z - 52), MIDNIGHT, "Slate")
        disk(island, "Garden", 25, 1, (side * 98, 3, start_z - 52), stone)
        if index in (1, 2, 3, 6):
            tree_planter(island, "Canopy", side * 98, start_z - 52, accent, base=3.5)
        else:
            crystal(island, "ObservatoryCrystal", side * 98, 4, start_z - 52, accent, scale=1.65)
    for x in (-50, -30, -10, 10, 30, 50):
        part(f"Divider{x}", (4, 22, 40), (x, 17, gate_z), WHITE, parent=stage, transparency=0.12)
        part(f"DividerCrown{x}", (4.2, 0.25, 40), (x, 28.2, gate_z), accent, "Metal", parent=decor, collide=False)
    for side in (-1, 1):
        part(f"EndStop{side}", (8, 22, 4), (side * 54, 17, gate_z), WHITE, parent=stage)
    part("ReferenceAnchor", (1, 1, 1), (0, 31, start_z - 25), parent=stage, collide=False, transparency=1)
    for side in (-1, 1):
        part(f"DisplayPost{side}", (1.7, 28, 1.7), (side * 22, 20, start_z - 25), WHITE, "Metal", parent=decor)
    part("DisplayCrown", (46, 1.2, 2), (0, 42.5, start_z - 25), accent, "Metal", parent=decor)
    name_anchor = part("ThemeSign", (1, 1, 1), (0, 45, start_z - 25), parent=decor, collide=False, transparency=1)
    sign(name_anchor, f"{index:02}  /  {theme}", width=285, height=43, accent=accent, distance=110)
    gates = group(stage, "Gates")
    for lane, (x, lane_color) in enumerate(zip((-40, -20, 0, 20, 40), LANE_COLORS), 1):
        gate = group(gates, f"Gate{lane}", model=True)
        part("Barrier", (16, 16, 2), (x, 14, gate_z), lane_color, "Glass", parent=gate, transparency=0.33)
        part("ChoicePad", (16, 0.2, 12), (x, 6.15, gate_z + 10), lane_color, parent=gate, transparency=0.1)
        part("PortraitAnchor", (1, 1, 1), (x, 24, gate_z), parent=gate, collide=False, transparency=1)
        for side in (-1, 1):
            part(f"DoorPost{side}", (1.2, 20, 2.6), (x + side * 8.7, 16, gate_z), INK, "Metal", parent=gate)
            part(f"DoorLight{side}", (0.23, 18, 0.15), (x + side * 8.04, 16, gate_z + 1.4), lane_color,
                 "Neon", parent=gate, collide=False)
        # This lintel stays high above avatars when Barrier rises twenty studs.
        part("Lintel", (18.6, 1.4, 2.8), (x, 26.7, gate_z), INK, "Metal", parent=gate)
        part("PortraitBack", (15.8, 11, 0.3), (x, 29, gate_z - 0.7), INK, parent=gate, collide=False, transparency=0.75)
        route_label = part("RouteLabel", (1, 1, 1), (x, 36.5, gate_z), parent=gate, collide=False, transparency=1)
        sign(route_label, f"{chr(64 + lane)}  ·  {lane}", width=105, height=34, accent=lane_color, distance=75)

finish = group(tree, "Mirador de la victoria", model=True)
finish_z = -40 - 7 * 112 - 111
part("FinishFloor", (120, 4, 34), (0, 4, finish_z), WHITE, parent=finish)
part("FinishRearRail", (120, 3, 1.4), (0, 7.5, finish_z - 16), GOLD, parent=finish)
for side in (-1, 1):
    part(f"FinishSideRail{side}", (1.4, 3, 34), (side * 59, 7.5, finish_z), GOLD, parent=finish)
    crystal(finish, f"VictoryCrystal{side}", side * 43, 7, finish_z, LILAC, scale=1.3)
disk(finish, "VictoryMedallion", 29, 0.15, (0, 6.2, finish_z), GOLD, "Neon", collide=False)
finish_anchor = part("FinishSign", (1, 1, 1), (0, 19, finish_z - 7), parent=finish, collide=False, transparency=1)
sign(finish_anchor, "CADA COLOR ES UNA AVENTURA", "CIUDAD PRISMA", width=350, height=92, accent=GOLD, distance=120)


def count_parts(node):
    return int(node.get("$className") in ("Part", "SpawnLocation")) + sum(
        count_parts(value) for key, value in node.items()
        if not key.startswith("$") and isinstance(value, dict)
    )


if __name__ == "__main__":
    count = count_parts(tree)
    assert count <= 1050, f"Static world budget exceeded: {count} parts"
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    DESTINATION.write_text(json.dumps({"name": "ColorChaosWorld", "tree": tree}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {DESTINATION.relative_to(ROOT)}: {count} anchored parts, 8 sectors, 40 gates")
