#!/usr/bin/env bash
# Compile every Luau source, execute CLI tests, and build the Roblox place.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tools_dir="${COLOR_CHAOS_TOOLS_DIR:-"$repo_dir/.tools"}"
cd "$repo_dir"

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
done < <(find src tests release -type f \( -name '*.luau' -o -name '*.lua' \) -print0)

if [[ "$source_count" -eq 0 ]]; then
  printf '%s\n' 'No Luau sources found.' >&2
  exit 1
fi
printf 'Compiled %s Luau sources.\n' "$source_count"

test_count=0
while IFS= read -r -d '' test_file; do
  "$tools_dir/luau" "$test_file"
  test_count=$((test_count + 1))
done < <(find tests -maxdepth 1 -type f -name '*.spec.luau' -print0)

if [[ "$test_count" -eq 0 ]]; then
  printf '%s\n' 'No CLI tests found.' >&2
  exit 1
fi

# Exercise the real server orchestration with mocks. This cannot validate
# Roblox physics, networking, rendering or production DataStore availability.
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-server.py
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-client.py
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-bootstrap.py
LUAU_BIN="$tools_dir/luau" python3 tools/simulate-prisma-portraits.py
LUAU_BIN="$tools_dir/luau" python3 tools/test-installer.py

mkdir -p build
"$tools_dir/rojo" build default.project.json --output build/ColorChaos.rbxlx
printf '%s\n' 'Place built: build/ColorChaos.rbxlx'
printf '%s\n' 'Studio playtesting is still required; CLI checks do not run the Roblox engine.'
