#!/usr/bin/env python3
"""Run the real Color Chaos client with explicit, limited Roblox API mocks.

This exercises UI state, camera selection and commerce boundaries. It does not
execute Roblox rendering, movement, device input, actual prices or purchases.
"""
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
harness = (root / "tests/client-harness.luau").read_text()
modules = [
    "local modules = {}\n",
    "local function require(object)\n",
    " assert(type(object) == 'table', 'Client modules must be Roblox module objects')\n",
    " return assert(modules[object.Name], 'Unexpected client module: ' .. object.Name)\n",
    "end\n",
    "local script = { Parent = shared }\n",
]
for name in ("Config", "Catalog", "GameSettings", "Characters", "Progression", "ProfileLedger", "Economy", "GameRules"):
    source = (root / "src/shared" / f"{name}.luau").read_text()
    modules.append(f"local {name} = (function()\n{source}\nend)()\nmodules.{name} = {name}\n")
modules.append(
    "local Portrait = { mount = function(viewport, character, rgb, hidden)\n"
    " local id = type(character) == 'table' and character.Id or character\n"
    " assert(Characters.get(id), 'Portrait references a real original character')\n"
    " for _, child in ipairs(viewport:GetChildren()) do if child.Name == 'PortraitCamera' or child.Name == 'PortraitWorld' then child:Destroy() end end\n"
    " table.insert(mounts, { Viewport = viewport, Id = id, RGB = rgb, Hidden = hidden })\n"
    " local camera = node('Camera', 'PortraitCamera', viewport)\n"
    " viewport.CurrentCamera = camera\n"
    " return node('WorldModel', 'PortraitWorld', viewport)\n"
    "end }\nmodules.Portrait = Portrait\n"
)
insertions = {
    "-- @CLIENT_MODULES@": "".join(modules),
    "-- @CLIENT_SOURCE@": (root / "src/client/Main.client.luau").read_text(),
}
for marker, content in insertions.items():
    if harness.count(marker) != 1:
        raise RuntimeError(f"Expected exactly one insertion marker: {marker}")
    harness = harness.replace(marker, content)

cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-client-simulation-") as directory:
    generated = Path(directory) / "client-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
