#!/usr/bin/env python3
"""Execute the actual 250 portrait constructors with limited Roblox value mocks.

Checks construction, model geometry, target-color isolation and mount lifecycle.
This does not execute the Roblox renderer, lighting, camera projection or physics.
"""
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
harness = (root / "tests/prisma-portrait-harness.luau").read_text()
portrait_source = (root / "src/shared/Portrait.luau").read_text()
require_line = "local Characters = require(script.Parent.Characters)"
if portrait_source.count(require_line) != 1:
    raise RuntimeError("The portrait module must require the actual Characters module once")
portrait_source = portrait_source.replace(require_line, "local Characters = catalogModule")
insertions = {
    "-- @CHARACTERS_SOURCE@": (root / "src/shared/Characters.luau").read_text(),
    "-- @PORTRAIT_SOURCE@": portrait_source,
    "-- @CATALOG_SOURCE@": (root / "src/shared/Catalog.luau").read_text(),
    "-- @CONFIG_SOURCE@": (root / "src/shared/Config.luau").read_text(),
    "-- @COSMETICS_SOURCE@": (root / "src/server/Cosmetics.luau").read_text()
        .replace("local Config = require(ReplicatedStorage.ColorChaos.Config)", "local Config = configModule")
        .replace("local Catalog = require(ReplicatedStorage.ColorChaos.Catalog)", "local Catalog = cosmeticsCatalog"),
}
for marker, content in insertions.items():
    if harness.count(marker) != 1:
        raise RuntimeError(f"Expected exactly one insertion marker: {marker}")
    harness = harness.replace(marker, content)

cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-prisma-portrait-") as directory:
    generated = Path(directory) / "portrait-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
