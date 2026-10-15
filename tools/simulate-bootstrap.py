#!/usr/bin/env python3
"""Exercise the actual independent welcome script with finite simulated time.

The shared UI mocks do not execute Roblox rendering, respawning or physics.
"""
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
harness = (root / "tests/bootstrap-harness.luau").read_text()
ui_harness = (root / "tests/client-harness.luau").read_text()
marker = "-- @CLIENT_MOCKS_END@"
if ui_harness.count(marker) != 1:
    raise RuntimeError(f"Expected exactly one shared-mock marker: {marker}")
insertions = {
    "-- @CLIENT_MOCKS@": ui_harness.split(marker, 1)[0],
    "-- @BOOTSTRAP_SOURCE@": (root / "src/client/Bootstrap.client.luau").read_text(),
}
for marker, content in insertions.items():
    if harness.count(marker) != 1:
        raise RuntimeError(f"Expected exactly one insertion marker: {marker}")
    harness = harness.replace(marker, content)

cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-bootstrap-simulation-") as directory:
    generated = Path(directory) / "bootstrap-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
