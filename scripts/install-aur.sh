#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
helper=""
for candidate in paru yay; do command -v "$candidate" >/dev/null 2>&1 && { helper="$candidate"; break; }; done
if [[ -z "$helper" ]]; then
  echo "No supported AUR helper (paru or yay) is installed. AUR packages were not installed."
  echo "Install one manually, then rerun this installer. This repository does not bootstrap an AUR helper."
  exit 1
fi
mapfile -t packages < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$repo_root/packages/aur.txt")
(( ${#packages[@]} )) || exit 0
echo "Installing AUR packages with $helper: ${packages[*]}"
"$helper" -S --needed "${packages[@]}"

