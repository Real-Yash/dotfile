#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mapfile -t packages < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$repo_root/packages/pacman.txt")
(( ${#packages[@]} )) || exit 0
echo "Installing official packages: ${packages[*]}"
pacman -S --needed "${packages[@]}"

