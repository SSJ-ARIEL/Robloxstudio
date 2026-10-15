#!/usr/bin/env python3
"""Execute actual server source against limited Luau orchestration mocks."""
from pathlib import Path
import json
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]


def luau_value(value, property_name=None):
    """Represent only scene data; game logic remains the actual Luau source."""
    if isinstance(value, dict):
        if "UDim2" in value:
            axes = value["UDim2"]
            return f"UDim2.new({', '.join(str(component) for axis in axes for component in axis)})"
        for dimension in ("UDim", "Vector3", "Color3"):
            if dimension in value:
                return f"{dimension}.new({', '.join(map(str, value[dimension]))})"
        raise ValueError(f"Unsupported serialized scene property {property_name}: {value!r}")
    if property_name in {"Position", "Size", "StudsOffset"}:
        return f"Vector3.new({', '.join(map(str, value))})"
    if property_name in {"Color", "Ambient", "OutdoorAmbient"}:
        return f"Color3.new({', '.join(map(str, value))})"
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return str(value).lower()
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, list):
        return "{" + ", ".join(luau_value(child) for child in value) + "}"
    raise ValueError(f"Unsupported serialized scene property {property_name}: {value!r}")


def serialized_world():
    """Seed the mock with precisely the saved scene that Rojo includes."""
    project = json.loads((root / "default.project.json").read_text())
    node = project["tree"]["Workspace"]["ColorChaosWorld"]
    lines, objects = ["local savedSceneObjects = {}"], 0

    def add_node(data, name, parent, directory):
        nonlocal objects
        if "$path" in data:
            path = directory / data["$path"]
            external = json.loads(path.read_text())
            data = {**external.get("tree", external), **{k: v for k, v in data.items() if k != "$path"}}
            directory = path.parent
        objects += 1
        reference = f"savedSceneObjects[{objects}]"
        lines.append(f"{reference} = Instance.new({luau_value(data.get('$className', 'Folder'))})")
        lines.append(f"{reference}.Name = {luau_value(name)}")
        for key, value in data.get("$properties", {}).items():
            lines.append(f"{reference}[{luau_value(key)}] = {luau_value(value, key)}")
        lines.append(f"{reference}.Parent = {parent}")
        for key, value in data.get("$attributes", {}).items():
            lines.append(f"{reference}:SetAttribute({luau_value(key)}, {luau_value(value)})")
        for key, value in data.items():
            if not key.startswith("$"):
                add_node(value, key, reference, directory)

    add_node(node, "ColorChaosWorld", "workspace", root)
    return "\n".join(lines)


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
template = (root / "tests/server-harness.luau").read_text().replace("-- @MODULES_AND_SERVER@", insertion)
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-simulation-") as directory:
    scene = serialized_world()
    for scenario in ("normal", "datastore-unavailable", "fallback-world", "preparation-fall", "lava-contact", "legacy-config", "r6-lava-contact"):
        harness = template.replace("-- @SCENARIO@", f"local scenario = {luau_value(scenario)}")
        harness = harness.replace("-- @STATIC_WORLD@", "" if scenario == "fallback-world" else scene)
        generated = Path(directory) / f"server-{scenario}.luau"
        generated.write_text(harness)
        result = subprocess.run([cli, str(generated)], cwd=root)
        if result.returncode:
            raise SystemExit(result.returncode)
