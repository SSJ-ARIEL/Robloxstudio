#!/usr/bin/env bash
# Pinned Linux cloud tooling. The archives come from the projects' official
# GitHub HTTPS releases; SHA-256 pins protect subsequent installs.
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tools_dir="${COLOR_RUSH_TOOLS_DIR:-"$repo_dir/.tools"}"

if [[ "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  printf '%s\n' 'This installer supports Linux x86_64. For Studio on Windows/macOS, follow README.md.' >&2
  exit 1
fi

for required_command in curl unzip sha256sum; do
  command -v "$required_command" >/dev/null || {
    printf 'Missing prerequisite: %s\n' "$required_command" >&2
    exit 1
  }
done

mkdir -p "$tools_dir/.archives"

install_archive() {
  local archive_name="$1" archive_url="$2" expected_digest="$3"
  local archive_path="$tools_dir/.archives/$archive_name"
  if [[ ! -f "$archive_path" ]]; then
    curl --fail --location --proto '=https' --tlsv1.2 \
      --retry 2 --connect-timeout 20 --max-time 180 \
      "$archive_url" --output "$archive_path.part"
    mv -- "$archive_path.part" "$archive_path"
  fi
  printf '%s  %s\n' "$expected_digest" "$archive_path" | sha256sum --check --status || {
    printf 'Checksum mismatch: %s. Remove that archive and rerun; do not bypass this check.\n' "$archive_path" >&2
    exit 1
  }
  unzip -oq "$archive_path" -d "$tools_dir"
}

install_archive rojo-7.6.1-linux-x86_64.zip \
  https://github.com/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip \
  a9542a713036897fdbd0173e7a105ea409658333133c949025fcb6f1a7ca909d

install_archive luau-0.694-ubuntu.zip \
  https://github.com/luau-lang/luau/releases/download/0.694/luau-ubuntu.zip \
  d0c2593f5cdb650f46fc86899be251de2818a2612844ca8ec83c3164d30ad6eb

chmod +x "$tools_dir/rojo" "$tools_dir/luau" "$tools_dir/luau-compile" \
  "$tools_dir/luau-analyze" "$tools_dir/luau-ast"
"$tools_dir/rojo" --version
printf 'Luau 0.694 installed. Tools: %s\n' "$tools_dir"
printf 'Validate: COLOR_RUSH_TOOLS_DIR=%q bash tools/validate.sh\n' "$tools_dir"
