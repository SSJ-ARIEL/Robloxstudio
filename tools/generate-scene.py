#!/usr/bin/env python3
"""Build the original, script-independent Color Chaos lobby from simple parts.

The checked-in project is the source loaded by Rojo. Run this script only when
changing this scene; building the game does not depend on Python or this script.
"""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
DESTINATION = ROOT / "scene" / "color-chaos-world.project.json"
DARK = (24, 29, 48)
SLATE = (39, 49, 75)
METAL = (65, 76, 99)
BLUE = (64, 181, 255)
YELLOW = (255, 218, 83)
GREEN = (80, 230, 164)
RED = (255, 100, 124)
PURPLE = (180, 126, 255)
WHITE = (231, 241, 255)
COLORS = (BLUE, YELLOW, GREEN, RED)
tree: dict = {"$className": "Folder"}


def rgb(color):
    return [round(channel / 255, 6) for channel in color]


def part(name, size, position, color=SLATE, material="SmoothPlastic", *,
         parent=None, collide=True, transparency=0, shape=None, orientation=None):
    properties = {
        "Anchored": True,
        "Size": list(size),
        "Position": list(position),
        "Color": rgb(color),
        "Material": material,
        "CanCollide": collide,
        "CanTouch": collide,
        "CanQuery": collide,
        "Transparency": transparency,
        "TopSurface": "Smooth",
        "BottomSurface": "Smooth",
    }
    if shape:
        properties["Shape"] = shape
    if orientation:
        properties["Orientation"] = list(orientation)
    node = {"$className": "Part", "$properties": properties}
    (tree if parent is None else parent)[name] = node
    return node


def sign(parent, heading, body="", *, width=330, height=112, offset=(0, 2.5, 0), accent=BLUE):
    gui = {
        "$className": "BillboardGui",
        "$properties": {
            "Size": {"UDim2": [[0, width], [0, height]]},
            "StudsOffset": list(offset),
            "MaxDistance": 180,
            "AlwaysOnTop": False,
            "LightInfluence": 0,
        },
        "Panel": {
            "$className": "Frame",
            "$properties": {
                "Size": {"UDim2": [[1, 0], [1, 0]]},
                "BackgroundColor3": rgb(DARK),
                "BackgroundTransparency": 0.13,
                "BorderSizePixel": 0,
            },
            "Corners": {"$className": "UICorner", "$properties": {"CornerRadius": {"UDim": [0, 14]}}},
            "Outline": {"$className": "UIStroke", "$properties": {
                "Color": rgb(accent), "Thickness": 2, "Transparency": 0.15,
            }},
            "Heading": {"$className": "TextLabel", "$properties": {
                "Position": {"UDim2": [[0, 12], [0, 10]]},
                "Size": {"UDim2": [[1, -24], [0, 35 if body else height - 20]]},
                "BackgroundTransparency": 1, "Font": "GothamBold",
                "Text": heading, "TextColor3": rgb(accent), "TextScaled": True,
                "TextWrapped": True, "BorderSizePixel": 0,
            }},
        },
    }
    if body:
        gui["Panel"]["Body"] = {"$className": "TextLabel", "$properties": {
            "Position": {"UDim2": [[0, 14], [0, 50]]}, "Size": {"UDim2": [[1, -28], [1, -60]]},
            "BackgroundTransparency": 1, "Font": "GothamMedium",
            "Text": body, "TextColor3": rgb(WHITE), "TextScaled": True,
            "TextWrapped": True, "BorderSizePixel": 0,
        }}
    parent["StaticSign"] = gui


# The floor and neutral spawn exist before any script or online service starts.
part("Cimiento del lobby", (114, 4, 84), (0, 2, 145), DARK, "Metal")
part("Plaza del reactor", (110, 3, 80), (0, 5, 145), SLATE, "SmoothPlastic")
tree["LobbySpawn"] = {"$className": "SpawnLocation", "$properties": {
    "Anchored": True, "Neutral": True, "Enabled": True, "Duration": 0,
    "AllowTeamChangeOnTouch": False, "Size": [10, 1, 10], "Position": [0, 7, 153],
    "Color": rgb(BLUE), "Material": "Neon", "Transparency": 0.18,
    "CanCollide": True, "CanTouch": True, "TopSurface": "Smooth", "BottomSurface": "Smooth",
}}

details = {"$className": "Folder"}
tree["Arquitectura del lobby"] = details
for x in (-46, 46):
    for z in (119, 173):
        part(f"Pilar {x} {z}", (7, 22, 7), (x, -6, z), METAL, "Metal", parent=details)
for x in (-54, 54):
    part(f"Baranda lateral {x}", (1.4, 3.6, 80), (x, 8.3, 145), METAL, "Metal", parent=details)
    part(f"Luz lateral {x}", (0.22, 0.35, 80), (x, 10.25, 145), BLUE, "Neon", parent=details, collide=False)
part("Baranda trasera", (110, 3.6, 1.4), (0, 8.3, 184), METAL, "Metal", parent=details)
part("Luz trasera", (110, 0.35, 0.22), (0, 10.25, 184), PURPLE, "Neon", parent=details, collide=False)
for x in (-34, 34):
    part(f"Baranda hacia arena {x}", (40, 3.6, 1.4), (x, 8.3, 106), METAL, "Metal", parent=details)
    part(f"Luz hacia arena {x}", (40, 0.35, 0.22), (x, 10.25, 106), GREEN, "Neon", parent=details, collide=False)
for x in (-49, 49):
    part(f"Borde del piso {x}", (0.28, 0.15, 65), (x, 6.58, 145), BLUE, "Neon", parent=details, collide=False)
for z in (112, 177):
    part(f"Borde del piso {z}", (98, 0.15, 0.28), (0, 6.58, z), PURPLE, "Neon", parent=details, collide=False)
for z in (114, 123, 132, 141, 150, 159, 168):
    part(f"Camino central {z}", (3.4, 0.16, 4.5), (0, 6.6, z), BLUE, "Neon", parent=details, collide=False, transparency=0.22)
for i, (name, color) in enumerate(zip(("A Azul", "B Amarillo", "C Verde", "D Rojo"), COLORS)):
    x = -36 + i * 24
    part(f"Base de color {name}", (11, 0.18, 7), (x, 6.64, 174), color, "Neon", parent=details, collide=False, transparency=0.34)
    post = part(f"Baliza {name}", (2, 5, 2), (x, 9, 175), METAL, "Metal", parent=details)
    part(f"Cristal {name}", (3, 2.5, 3), (x, 12.8, 175), color, "Neon", parent=details, collide=False, shape="Ball")
    sign(post, name.upper(), width=146, height=44, offset=(0, 6.5, 0), accent=color)

title = part("Título", (1, 1, 1), (0, 17, 168), BLUE, collide=False, transparency=1)
sign(title, "COLOR CHAOS", "Memoria · Reparación · Rescate\nUn equipo. Un reactor. Lava en ascenso.", width=430, height=118, offset=(0, 3, 0), accent=BLUE)
instructions = part("Instrucciones", (1, 1, 1), (-27, 9, 144), BLUE, collide=False, transparency=1)
sign(instructions, "¿CÓMO SE JUEGA?", "1. Espera aquí la siguiente ronda.\n2. Sigue las letras y los colores.\n3. Coopera para escapar de la lava.", height=145, offset=(0, 8, 0), accent=GREEN)
part("Mesa de instrucciones", (14, 2, 8), (-27, 7.5, 144), DARK, "Metal", parent=details)
part("Panel del taller", (12, 0.3, 6), (-27, 8.65, 144), GREEN, "Neon", parent=details, collide=False, transparency=0.25)
shop = part("Tienda de auras", (8, 4, 8), (27, 8, 144), PURPLE, "SmoothPlastic")
sign(shop, "TIENDA DE AURAS", "Cosméticos · Monedas · VIP\nAbre la tienda para ver tus opciones.", width=290, height=116, offset=(0, 7, 0), accent=PURPLE)
part("Pedestal de la tienda", (14, 0.3, 13), (27, 6.7, 144), PURPLE, "Neon", parent=details, collide=False, transparency=0.2)
for x in (21, 33):
    part(f"Columna de tienda {x}", (1.2, 9, 1.2), (x, 11, 146), METAL, "Metal", parent=details)
    part(f"Luz de tienda {x}", (0.4, 8, 0.4), (x, 11, 145.25), PURPLE, "Neon", parent=details, collide=False)
part("Techo de tienda", (14, 1, 8), (27, 16, 146), DARK, "Metal", parent=details)

# The accessible observation deck never overlaps playable round coordinates.
observation = {"$className": "Folder"}
tree["Mirador"] = observation
for step in range(1, 18):
    z = 110 - 1.5 * step
    top = 6.5 + step
    part(f"Escalón {step:02}", (22, step, 1.55), (0, 6.5 + step / 2, z), SLATE, "Metal", parent=observation)
    part(f"Frente luminoso {step:02}", (20, 0.16, 0.12), (0, top - 0.25, z - 0.73), BLUE, "Neon", parent=observation, collide=False)
    for x in (-12, 12):
        part(f"Baranda escalón {step:02} {x}", (1, 3, 1.55), (x, top + 1.5, z), METAL, "Metal", parent=observation)
part("Plataforma del mirador", (68, 3, 19), (0, 22, 78.5), SLATE, "Metal", parent=observation)
part("Borde del mirador", (68, 0.25, 0.4), (0, 23.65, 69.2), BLUE, "Neon", parent=observation, collide=False)
part("Baranda panorámica", (68, 3.3, 1), (0, 25.15, 69), METAL, "Metal", parent=observation)
part("Pasamanos panorámico", (68, 0.25, 1.1), (0, 26.9, 69), GREEN, "Neon", parent=observation, collide=False)
for x in (-33.5, 33.5):
    part(f"Baranda mirador {x}", (1, 3.3, 19), (x, 25.15, 78.5), METAL, "Metal", parent=observation)
    part(f"Soporte mirador {x}", (5, 33, 5), (x, 5.5, 79), DARK, "Metal", parent=observation)
for x in (-23, 23):
    part(f"Baranda trasera mirador {x}", (20, 3.3, 1), (x, 25.15, 87.5), METAL, "Metal", parent=observation)
lookout = part("Cartel del mirador", (1, 1, 1), (0, 29, 82), WHITE, parent=observation, collide=False, transparency=1)
sign(lookout, "MIRADOR", "Aquí esperas y observas la arena.\nLa siguiente ronda te llevará al desafío.", width=300, height=105, offset=(0, 4, 0), accent=GREEN)
for x, heading, text, color in (
    (-25, "MEMORIA", "Recuerda la secuencia.\nConstruye el camino.", BLUE),
    (25, "REACTOR", "Repara y rescata en equipo.\nLas plataformas te protegen.", YELLOW),
):
    kiosk = part(f"Panel de modo {heading}", (5, 3, 3), (x, 25, 81), DARK, "Metal", parent=observation)
    sign(kiosk, heading, text, width=225, height=94, offset=(0, 4, 0), accent=color)

# A visible basin gives every joiner a scene even when server startup fails.
basin = {"$className": "Folder"}
tree["Cuenca volcánica"] = basin
part("Cimiento de arena", (176, 6, 204), (0, -7, -15), DARK, "Slate", parent=basin)
for x in (-84, 84):
    part(f"Muro de cuenca {x}", (8, 12, 204), (x, 1, -15), METAL, "Slate", parent=basin)
    part(f"Borde ardiente {x}", (1, 0.4, 196), (x, 7.25, -15), (255, 140, 73), "Neon", parent=basin, collide=False)
for z in (-115, 85):
    part(f"Muro de cuenca {z}", (176, 12, 8), (0, 1, z), METAL, "Slate", parent=basin)
    part(f"Borde ardiente {z}", (168, 0.4, 1), (0, 7.25, z), (255, 140, 73), "Neon", parent=basin, collide=False)
lava = part("LavaSurface", (160, 0.8, 176), (0, 8, -22), (255, 91, 50), "Neon", collide=False, transparency=0.08)
lava["Glow"] = {"$className": "PointLight", "$properties": {
    "Color": rgb((255, 120, 66)), "Brightness": 0.65, "Range": 45, "Shadows": False,
}}
for x in (-77, 77):
    warning = part(f"Aviso de lava {x}", (1, 1, 1), (x, 15, -18), YELLOW, parent=basin, collide=False, transparency=1)
    sign(warning, "LAVA EN ASCENSO", "Coopera y quédate sobre las plataformas.", width=250, height=86, offset=(0, 3, 0), accent=YELLOW)

# Preview: purely decorative, so Main can hide it while a live arena is present.
preview = {"$className": "Model"}
tree["ArenaPreview"] = preview
part("Reactor en espera", (10, 12, 10), (0, 18, -15), METAL, "Metal", parent=preview, collide=False)
part("Núcleo en espera", (8, 8, 8), (0, 26, -15), BLUE, "Neon", parent=preview, collide=False, shape="Ball", transparency=0.1)
for i, color in enumerate(COLORS):
    x = -30 + i * 20
    part(f"Plataforma de muestra {i + 1}", (11, 2, 11), (x, 16, 8), DARK, "Metal", parent=preview, collide=False)
    part(f"Color de muestra {i + 1}", (10, 0.3, 10), (x, 17.2, 8), color, "Neon", parent=preview, collide=False, transparency=0.1)
anchor = part("Arena en espera", (1, 1, 1), (0, 32, -15), BLUE, parent=preview, collide=False, transparency=1)
sign(anchor, "LA ARENA TE ESPERA", "Las rondas comienzan desde el lobby.", width=340, height=94, offset=(0, 3, 0), accent=BLUE)

DESTINATION.parent.mkdir(parents=True, exist_ok=True)
DESTINATION.write_text(json.dumps({"name": "ColorChaosWorld", "tree": tree}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"Generated {DESTINATION.relative_to(ROOT)}")
