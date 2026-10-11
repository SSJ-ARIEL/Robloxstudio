#!/usr/bin/env python3
"""Execute actual server source against limited Luau orchestration mocks."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
server = (root / "src/server/Main.server.luau").read_text()
modules = {
    "Config": ("src/shared/Config.luau", "ReplicatedStorage.ColorChaos.Config"),
    "Rules": ("src/shared/Rules.luau", "ReplicatedStorage.ColorChaos.Rules"),
    "Progression": ("src/shared/Progression.luau", "ReplicatedStorage.ColorChaos.Progression"),
    "Ledger": ("src/shared/ProfileLedger.luau", "ReplicatedStorage.ColorChaos.ProfileLedger"),
    "Commerce": ("src/server/Commerce.luau", "script.Parent.Commerce"),
}
module_bodies = []
for name, (path, instance_path) in modules.items():
    declaration = f"local {name} = require({instance_path})\n"
    if server.count(declaration) != 1:
        raise RuntimeError(f"Expected exactly one server import for {name}")
    server = server.replace(declaration, "")
    source = (root / path).read_text()
    module_bodies.append(f"local {name} = (function()\n{source}\nend)()\n")
insertion = "".join(module_bodies) + f"local function serverMain()\n{server}\nend\n"
harness = (root / "tests/server-harness.luau").read_text().replace("-- @MODULES_AND_SERVER@", insertion)
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-simulation-") as directory:
    generated = Path(directory) / "server-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
