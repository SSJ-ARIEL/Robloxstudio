#!/usr/bin/env python3
"""Package Ciudad Prisma and its dormant, configuration-preserving Studio update."""
from __future__ import annotations

import argparse
import copy
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]


def source_tree(directory: Path) -> dict:
    result = {"$className": "Folder"}
    for path in sorted(directory.iterdir()):
        if path.is_dir():
            result[path.name] = source_tree(path)
        elif path.suffix in (".lua", ".luau"):
            stem = path.stem
            disabled = stem.endswith(".server") or stem.endswith(".client")
            name = stem.removesuffix(".server").removesuffix(".client")
            node = {"$path": os.path.relpath(path, ROOT / "release")}
            if disabled:
                node["$properties"] = {"Disabled": True}
            result[name] = node
    return result


def relocate_paths(node: dict) -> dict:
    result = copy.deepcopy(node)
    for key, value in result.items():
        if key == "$path":
            if isinstance(value, str):
                result[key] = os.path.relpath(ROOT / value, ROOT / "release")
            elif isinstance(value, list):
                result[key] = [os.path.relpath(ROOT / path, ROOT / "release") for path in value]
        elif isinstance(value, dict):
            result[key] = relocate_paths(value)
    return result


def update_project(project: dict) -> dict:
    world = project["tree"]["Workspace"].get("ColorChaosWorld")
    if not world:
        raise RuntimeError("The place must contain a serialized ColorChaosWorld before packaging")
    return {
        "name": "ColorChaosUpdate",
        "tree": {
            "$className": "Model",
            "Installer": {"$path": "Installer.luau"},
            "ReplicatedStorage": {"$className": "Folder", "ColorChaos": source_tree(ROOT / "src/shared")},
            "ServerScriptService": {"$className": "Folder", "ColorChaosServer": source_tree(ROOT / "src/server")},
            "StarterPlayerScripts": {"$className": "Folder", "ColorChaosClient": source_tree(ROOT / "src/client")},
            "Workspace": {"$className": "Folder", "ColorChaosWorld": relocate_paths(world)},
        },
    }


def verify_dormant_model(path: Path) -> None:
    tree = ET.parse(path)
    script_count = 0
    installer_count = 0
    for item in tree.iter("Item"):
        properties = item.find("Properties")
        if properties is None:
            continue
        if item.attrib.get("class") in ("Script", "LocalScript"):
            disabled = properties.find("bool[@name='Disabled']")
            if disabled is None or disabled.text != "true":
                raise RuntimeError("Update model contains an automatically enabled script")
            script_count += 1
        if item.attrib.get("class") == "ModuleScript":
            name = properties.find("string[@name='Name']")
            if name is not None and name.text == "Installer":
                installer_count += 1
    if script_count < 2 or installer_count != 1:
        raise RuntimeError("Update model is missing required scripts or its sole installer")
    print(f"Verified dormant update model: {script_count} disabled scripts, one ModuleScript installer.")


def named_child(parent: ET.Element, name: str) -> ET.Element:
    for item in parent.findall("Item"):
        actual = item.find("Properties/string[@name='Name']")
        if actual is not None and actual.text == name:
            return item
    raise RuntimeError(f"Release is missing the serialized object: {name}")


def verify_place(path: Path) -> None:
    """Inspect shipped XML, including a real floor and the final five gates."""
    document = ET.parse(path)
    root = document.getroot()
    world = named_child(named_child(root, "Workspace"), "ColorChaosWorld")
    spawn = named_child(world, "LobbySpawn")
    floor = named_child(world, "Plaza del reactor")
    if spawn.attrib.get("class") != "SpawnLocation" or floor.attrib.get("class") != "Part":
        raise RuntimeError("Place is missing the permanent spawn and floor")
    def vector(item: ET.Element, property_name: str, tag: str) -> tuple[float, float, float]:
        property_node = item.find(f"Properties/{tag}[@name='{property_name}']")
        if property_node is None:
            raise RuntimeError(f"Place contains a missing serialized {property_name}")
        result = tuple(float(property_node.findtext(axis, "nan")) for axis in ("X", "Y", "Z"))
        if not all(math.isfinite(coordinate) for coordinate in result):
            raise RuntimeError("Place contains invalid geometry coordinates")
        return result
    spawn_at = vector(spawn, "CFrame", "CoordinateFrame")
    floor_at = vector(floor, "CFrame", "CoordinateFrame")
    spawn_size = vector(spawn, "size", "Vector3")
    floor_size = vector(floor, "size", "Vector3")
    floor_top = floor_at[1] + floor_size[1] / 2
    if not 0 < spawn_at[1] - floor_top <= 8 or any(
        abs(spawn_at[index] - floor_at[index]) > (floor_size[index] - spawn_size[index]) / 2 for index in (0, 2)
    ):
        raise RuntimeError("Serialized spawn is not safely above the actual lobby floor")
    physical_classes = {"Part", "SpawnLocation", "WedgePart", "CornerWedgePart", "MeshPart", "TrussPart", "UnionOperation"}
    physical_parts = 0
    spawns = 0
    for item in world.iter("Item"):
        if item.attrib.get("class") in physical_classes:
            # Position is derived in Studio. Persist the native CFrame so the
            # engine does not need to reconstruct transforms from aliases.
            vector(item, "CFrame", "CoordinateFrame")
            if item.find("Properties/Vector3[@name='Position']") is not None:
                raise RuntimeError("Release must serialize CFrame instead of a derived Position alias")
            if item.findtext("Properties/bool[@name='Anchored']") != "true":
                raise RuntimeError("Permanent scene contains an unanchored physical part")
            physical_parts += 1
        if item.attrib.get("class") == "SpawnLocation":
            spawns += 1
    if spawns != 1:
        raise RuntimeError("Permanent scene must contain exactly one lobby spawn")
    stages = named_child(world, "Stages")
    for number in range(1, 9):
        stage = named_child(stages, f"Stage{number:02}")
        named_child(stage, "ReferenceAnchor")
        gates = named_child(stage, "Gates")
        for lane in range(1, 6):
            gate = named_child(gates, f"Gate{lane}")
            for name in ("Barrier", "ChoicePad", "PortraitAnchor"):
                named_child(gate, name)
    referents: set[str] = set()
    scripts = 0
    for item in document.iter("Item"):
        referent = item.attrib.get("referent")
        if referent in referents:
            raise RuntimeError("Release contains duplicated object references")
        if referent is not None:
            referents.add(referent)
        if item.attrib.get("class") in ("Script", "LocalScript", "ModuleScript"):
            sources = [node for node in item.findall("Properties/*") if node.attrib.get("name") == "Source"]
            if len(sources) != 1 or not (sources[0].text or "").strip():
                raise RuntimeError("Release contains an empty executable source")
            scripts += 1
    print(f"Verified place: {physical_parts} explicit CFrames, safe spawn, 8 sectors, 40 gates, {scripts} non-empty Luau sources.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tools-dir", default=os.environ.get("COLOR_CHAOS_TOOLS_DIR", str(ROOT / ".tools")))
    args = parser.parse_args()
    tool_dir = Path(args.tools_dir).resolve()
    rojo = tool_dir / "rojo"
    compiler = tool_dir / "luau-compile"
    for executable in (rojo, compiler):
        if not executable.is_file():
            raise RuntimeError(f"Missing tool: {executable}")
    release = ROOT / "release"
    build = ROOT / "build"
    downloads = ROOT / "downloads"
    build.mkdir(exist_ok=True)
    downloads.mkdir(exist_ok=True)
    project = json.loads((ROOT / "default.project.json").read_text())
    staged_project = update_project(project)
    (release / "update.project.json").write_text(json.dumps(staged_project, ensure_ascii=False, indent=2) + "\n")
    subprocess.run([str(compiler), str(release / "Installer.luau")], check=True, stdout=subprocess.DEVNULL)
    for suffix in ("rbxlx", "rbxl"):
        target = build / f"ColorChaos2.{suffix}"
        subprocess.run([str(rojo), "build", str(ROOT / "default.project.json"), "--output", str(target)], check=True, cwd=ROOT)
        shutil.copyfile(target, downloads / target.name)
        # Existing direct-place download URLs continue to receive the current
        # game. The new ZIP contains only the unambiguous version-2 filenames.
        shutil.copyfile(target, downloads / f"ColorChaos.{suffix}")
    verify_place(downloads / "ColorChaos2.rbxlx")
    for suffix in ("rbxmx", "rbxm"):
        target = build / f"ColorChaosUpdate.{suffix}"
        subprocess.run([str(rojo), "build", str(release / "update.project.json"), "--output", str(target)], check=True, cwd=ROOT)
        shutil.copyfile(target, downloads / target.name)
    verify_dormant_model(downloads / "ColorChaosUpdate.rbxmx")
    archive = downloads / "ColorChaos2-completo.zip"
    # Explicit first-game-only whitelist; never include caches, generated build
    # trees, another game's files, or the archive inside its own archive.
    included = []
    for directory in ("src", "scene", "docs", "assets", "release", "tools", "tests"):
        base = ROOT / directory
        if base.is_dir():
            included.extend(path for path in base.rglob("*") if path.is_file()
                            and "__pycache__" not in path.parts and path.suffix != ".pyc")
    for name in ("default.project.json", "README.md", "AGENTS.md", "PROJECT_NOTES.md", ".gitignore"):
        path = ROOT / name
        if path.is_file():
            included.append(path)
    included.extend(downloads / f"ColorChaos2.{suffix}" for suffix in ("rbxlx", "rbxl"))
    included.extend(downloads / f"ColorChaosUpdate.{suffix}" for suffix in ("rbxmx", "rbxm"))
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for path in sorted(set(included)):
            output.write(path, "ColorChaos2/" + path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(archive) as output:
        if output.testzip() is not None:
            raise RuntimeError("Release archive did not pass CRC validation")
        count = len(output.infolist())
    print(f"Release packaged: {archive.relative_to(ROOT)} ({count} files, {archive.stat().st_size} bytes).")
    print("No Roblox engine, publishing, or purchase API was invoked.")


if __name__ == "__main__":
    main()
