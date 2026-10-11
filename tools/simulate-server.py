#!/usr/bin/env python3
"""Execute actual server source against limited Luau orchestration mocks."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
config = (root / "src/shared/Config.luau").read_text()
rules = (root / "src/shared/Rules.luau").read_text()
server = (root / "src/server/Main.server.luau").read_text()
server = server.replace("local Config = require(ReplicatedStorage.ColorChaos.Config)\n", "")
server = server.replace("local Rules = require(ReplicatedStorage.ColorChaos.Rules)\n", "")
insertion = f"local Config = (function()\n{config}\nend)()\nlocal Rules = (function()\n{rules}\nend)()\nlocal function serverMain()\n{server}\nend\n"
harness = (root / "tests/server-harness.luau").read_text().replace("-- @MODULES_AND_SERVER@", insertion)
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-simulation-") as directory:
    generated = Path(directory) / "server-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
