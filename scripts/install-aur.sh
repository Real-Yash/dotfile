#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $EUID -ne 0 ]] || { echo 'Refusing to build AUR packages as root.' >&2; exit 1; }

mapfile -t packages < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$repo_root/packages/aur.txt")
(( ${#packages[@]} )) || exit 0

ask_to_install_yay() {
  local answer

  if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    echo 'Cannot prompt to bootstrap yay: /dev/tty is unavailable.' >&2
    return 1
  fi

  printf 'No AUR helper found. Install yay? [y/N] ' > /dev/tty
  IFS= read -r answer < /dev/tty || return 1
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

helper=""
for candidate in paru yay; do
  if command -v "$candidate" >/dev/null 2>&1; then
    helper="$candidate"
    break
  fi
done

echo '[2/7] AUR helper'
if [[ -z "$helper" ]]; then
  echo 'This rice requires AUR packages.'
  echo 'Required AUR packages:'
  printf '  - %s\n' "${packages[@]}"

  if ! ask_to_install_yay; then
    echo 'AUR helper installation was declined; the rice installation is incomplete.' >&2
    exit 1
  fi

  echo 'Installing build dependencies for yay: base-devel git'
  sudo pacman -S --needed base-devel git

  build_dir="$(mktemp -d)"
  cleanup() {
    rm -rf -- "$build_dir"
  }
  trap cleanup EXIT

  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  (
    cd "$build_dir/yay"
    makepkg -si --needed
  )

  if ! command -v yay >/dev/null 2>&1; then
    echo 'yay installation completed without making yay available on PATH; aborting.' >&2
    exit 1
  fi
  helper=yay
fi

echo '[3/7] AUR packages'
echo "Installing AUR packages with $helper: ${packages[*]}"
"$helper" -S --needed "${packages[@]}"
