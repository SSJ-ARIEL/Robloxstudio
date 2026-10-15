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
config = (root / "src/shared/Config.luau").read_text()
insertions = {
    "-- @CLIENT_MODULES@": f"local Config = (function()\n{config}\nend)()\n"
    "local function require(object)\n"
    " assert(object.Name == 'Config', 'Unexpected client module: ' .. object.Name)\n"
    " return Config\nend\n",
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
