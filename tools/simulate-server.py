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
        if "CFrame" in value:
            frame = value["CFrame"]
            components = frame["position"] + [component for axis in frame["orientation"] for component in axis]
            return f"CFrame.new({', '.join(map(str, components))})"
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
modules = {}
for section in ("shared", "server"):
    for path in sorted((root / "src" / section).glob("*.luau")):
        if path.name.endswith(".server.luau"):
            continue
        name = path.stem
        if name in modules:
            raise RuntimeError(f"Duplicate module name in simulation: {name}")
        modules[name] = (section, path.read_text())

chunks = ["local moduleInstances, moduleLoaders, moduleCache = {}, {}, {}\n"]
chunks.append("""
local function require(target)
    assert(type(target) == "table" and target.Name, "Expected mocked ModuleScript")
    local name = target.Name
    if scenario == "module-failure" and name == "Cosmetics" then error("Simulated secondary module startup failure") end
    if moduleCache[name] == nil then
        assert(moduleLoaders[name], "Module not supplied to harness: " .. name)
        moduleCache[name] = moduleLoaders[name]()
    end
    return moduleCache[name]
end
""")
for name, (section, source) in modules.items():
    folder = "shared" if section == "shared" else "serverFolder"
    chunks.append(
        f'moduleInstances["{name}"] = Instance.new("ModuleScript")\n'
        f'moduleInstances["{name}"].Name = "{name}"\n'
        f'moduleInstances["{name}"].Parent = {folder}\n'
        f'moduleLoaders["{name}"] = function()\n'
        f'local script = moduleInstances["{name}"]\n{source}\nend\n'
    )
chunks.append('local mainScript = Instance.new("Script")\nmainScript.Parent = serverFolder\n')
chunks.append(f"local function serverMain()\nlocal script = mainScript\n{server}\nend\n")
for name in ("Config", "GameSettings", "GameRules", "Characters", "Economy", "Catalog"):
    if name in modules:
        chunks.append(f'local {name} = require(moduleInstances["{name}"])\n')
insertion = "".join(chunks)
template = (root / "tests/server-harness.luau").read_text().replace("-- @MODULES_AND_SERVER@", insertion)
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-chaos-simulation-") as directory:
    scene = serialized_world()
    for scenario in ("journey", "solo", "datastore-unavailable", "ghosts", "recovery", "module-failure"):
        harness = template.replace("-- @SCENARIO@", f"local scenario = {luau_value(scenario)}")
        harness = harness.replace("-- @STATIC_WORLD@", "" if scenario == "fallback-world" else scene)
        generated = Path(directory) / f"server-{scenario}.luau"
        generated.write_text(harness)
        result = subprocess.run([cli, str(generated)], cwd=root)
        if result.returncode:
            raise SystemExit(result.returncode)
