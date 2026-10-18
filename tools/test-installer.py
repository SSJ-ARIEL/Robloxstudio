#!/usr/bin/env python3
"""Run the actual Studio installer with limited object/service mocks."""
from pathlib import Path
import json
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / "release/Installer.luau").read_text()
harness = (root / "release/installer-harness.luau").read_text()


def safety_scene() -> dict:
    """Use actual released geometry, not independent hand-authored coordinates."""
    scene = json.loads((root / "scene/color-chaos-world.project.json").read_text())["tree"]
    selected = {"$className": scene["$className"]}
    for name in ("LobbySpawn", "Plaza del reactor"):
        selected[name] = scene[name]
    stages = {"$className": scene["Stages"]["$className"]}
    for number in range(1, 9):
        name = f"Stage{number:02}"
        stage = scene["Stages"][name]
        subset = {"$className": stage["$className"], "ReferenceAnchor": stage["ReferenceAnchor"]}
        gates = {"$className": stage["Gates"]["$className"]}
        for lane in range(1, 6):
            gate_name = f"Gate{lane}"
            gate = stage["Gates"][gate_name]
            gates[gate_name] = {"$className": gate["$className"]}
            for part_name in ("Barrier", "ChoicePad", "PortraitAnchor"):
                gates[gate_name][part_name] = gate[part_name]
        subset["Gates"] = gates
        stages[name] = subset
    selected["Stages"] = stages
    return selected


def lua_literal(value) -> str:
    if isinstance(value, dict):
        return "{" + ",".join("[" + json.dumps(key) + "]=" + lua_literal(child) for key, child in value.items()) + "}"
    if isinstance(value, list):
        return "{" + ",".join(lua_literal(child) for child in value) + "}"
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "nil"
    return json.dumps(value, ensure_ascii=False)


generated = harness.replace("-- @SCENE@", "local sceneSpec = " + lua_literal(safety_scene()))
generated = generated.replace("-- @INSTALLER@", "local Installer = (function()\n" + source + "\nend)()\n")
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-installer-") as directory:
    path = Path(directory) / "installer-spec.luau"
    path.write_text(generated)
    result = subprocess.run([cli, str(path)], cwd=root)
raise SystemExit(result.returncode)
