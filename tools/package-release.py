#!/usr/bin/env python3
"""Build first-game places and a dormant, configuration-preserving Studio update."""
from __future__ import annotations

import argparse
import copy
import json
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
        target = build / f"ColorChaos.{suffix}"
        subprocess.run([str(rojo), "build", str(ROOT / "default.project.json"), "--output", str(target)], check=True, cwd=ROOT)
        shutil.copyfile(target, downloads / target.name)
    for suffix in ("rbxmx", "rbxm"):
        target = build / f"ColorChaosUpdate.{suffix}"
        subprocess.run([str(rojo), "build", str(release / "update.project.json"), "--output", str(target)], check=True, cwd=ROOT)
        shutil.copyfile(target, downloads / target.name)
    verify_dormant_model(downloads / "ColorChaosUpdate.rbxmx")
    archive = downloads / "ColorChaos-lobby-completo.zip"
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
    included.extend(downloads / f"ColorChaos.{suffix}" for suffix in ("rbxlx", "rbxl"))
    included.extend(downloads / f"ColorChaosUpdate.{suffix}" for suffix in ("rbxmx", "rbxm"))
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for path in sorted(set(included)):
            output.write(path, "ColorChaos/" + path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(archive) as output:
        if output.testzip() is not None:
            raise RuntimeError("Release archive did not pass CRC validation")
        count = len(output.infolist())
    print(f"Release packaged: {archive.relative_to(ROOT)} ({count} files, {archive.stat().st_size} bytes).")
    print("No Roblox engine, publishing, or purchase API was invoked.")


if __name__ == "__main__":
    main()
