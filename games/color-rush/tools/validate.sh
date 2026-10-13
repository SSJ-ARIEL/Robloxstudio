#!/usr/bin/env bash
# Validate this game independently without changing Color Chaos.
set -euo pipefail

game_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tools_dir="${COLOR_RUSH_TOOLS_DIR:-${COLOR_CHAOS_TOOLS_DIR:-"$game_dir/.tools"}}"
cd "$game_dir"
for executable in rojo luau luau-compile; do
  [[ -x "$tools_dir/$executable" ]] || {
    printf 'Missing %s. Run bash tools/setup.sh first.\n' "$executable" >&2
    exit 1
  }
done

source_count=0
while IFS= read -r -d '' source_file; do
  "$tools_dir/luau-compile" "$source_file" >/dev/null
  source_count=$((source_count + 1))
done < <(find src tests -type f \( -name '*.luau' -o -name '*.lua' \) -print0)
[[ "$source_count" -gt 0 ]] || { printf '%s\n' 'No Luau sources found.' >&2; exit 1; }
printf 'Compiled %s Color Rush Luau sources.\n' "$source_count"

test_count=0
while IFS= read -r -d '' test_file; do
  "$tools_dir/luau" "$test_file"
  test_count=$((test_count + 1))
done < <(find tests -maxdepth 1 -type f -name '*.spec.luau' -print0)
[[ "$test_count" -gt 0 ]] || { printf '%s\n' 'No CLI tests found.' >&2; exit 1; }
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-server.py
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-client.py
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-portraits.py

mkdir -p build
"$tools_dir/rojo" build default.project.json --output build/ColorRush.rbxlx
printf '%s\n' 'Place built: build/ColorRush.rbxlx'
printf '%s\n' 'Mocks do not execute the Roblox engine or real purchases.'
