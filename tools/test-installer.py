#!/usr/bin/env python3
"""Run the actual Studio installer with limited object/service mocks."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "release/Installer.luau").read_text()
harness = (root / "release/installer-harness.luau").read_text()
generated = harness.replace("-- @INSTALLER@", "local Installer = (function()\n" + source + "\nend)()\n")
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-installer-") as directory:
    path = Path(directory) / "installer-spec.luau"
    path.write_text(generated)
    result = subprocess.run([cli, str(path)], cwd=root)
raise SystemExit(result.returncode)
