#!/usr/bin/env python3
"""Run the real server and modules with explicit, limited Roblox service mocks.

This checks orchestration and authority boundaries, not Roblox physics, network
latency, rendering, device input, or real production payments.
"""
from pathlib import Path
import os
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
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
    )
    chunks.append(
        f'moduleLoaders["{name}"] = function()\n'
        f'local script = moduleInstances["{name}"]\n{source}\nend\n'
    )
chunks.append('local mainScript = Instance.new("Script")\nmainScript.Parent = serverFolder\n')
server = (root / "src/server/Main.server.luau").read_text()
chunks.append(f"local function serverMain()\nlocal script = mainScript\n{server}\nend\n")
for name in ("Config", "Rules", "Characters", "Ledger", "Progression"):
    if name in modules:
        chunks.append(f'local {name} = require(moduleInstances["{name}"])\n')

harness = (root / "tests/server-harness.luau").read_text()
if harness.count("-- @MODULES_AND_SERVER@") != 1:
    raise RuntimeError("The harness must contain exactly one source insertion marker")
harness = harness.replace("-- @MODULES_AND_SERVER@", "".join(chunks))
cli = os.environ.get("LUAU_BIN", "/workspace/.tools/color-chaos/luau")
with tempfile.TemporaryDirectory(prefix="color-rush-simulation-") as directory:
    generated = Path(directory) / "server-smoke.luau"
    generated.write_text(harness)
    result = subprocess.run([cli, str(generated)], cwd=root)
raise SystemExit(result.returncode)
