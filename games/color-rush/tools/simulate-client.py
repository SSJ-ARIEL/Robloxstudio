#!/usr/bin/env python3
"""Exercise the actual UI and catalog with explicit, limited service mocks.

This validates UI state and commerce boundaries, not Roblox rendering, physics,
device input, real prices, or actual purchases. Portrait rendering is mocked.
"""
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
harness = (root / "tests/client-harness.luau").read_text()
modules = []
for name in ("Config", "Characters", "Rules"):
    source = (root / "src/shared" / f"{name}.luau").read_text()
    modules.append(f"local {name} = (function()\n{source}\nend)()\n")
insertions = {
    "-- @CLIENT_MODULES@": "".join(modules),
    "-- @CLIENT_SOURCE@": (root / "src/client/Main.client.luau").read_text(),
}
for marker, content in insertions.items():
    if harness.count(marker) != 1:
        raise RuntimeError(f"Expected exactly one insertion marker: {marker}")
    harness = harness.replace(marker, content)

cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-rush-client-simulation-") as directory:
    generated = Path(directory) / "client-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
