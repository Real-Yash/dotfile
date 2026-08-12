#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $EUID -ne 0 ]] || { echo 'Refusing to build AUR packages as root.' >&2; exit 1; }

mapfile -t packages < <(sed '/^[[:space:]]*#/d;/^[[:space:]]*$/d' "$repo_root/packages/aur.txt")
(( ${#packages[@]} )) || exit 0

choose_helper_to_install() {
  local answer

  if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    echo 'Cannot choose an AUR helper: /dev/tty is unavailable.' >&2
    return 1
  fi

  printf 'No AUR helper found. Install yay or paru? [yay/paru] (default: yay) ' > /dev/tty
  IFS= read -r answer < /dev/tty || return 1
  case "${answer,,}" in
    ''|yay|paru) printf '%s\n' "${answer,,}" ;;
    *) return 1 ;;
  esac
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

  if ! helper="$(choose_helper_to_install)"; then
    echo 'No AUR helper was selected; the rice installation is incomplete.' >&2
    exit 1
  fi
  helper="${helper:-yay}"

  echo "Installing build dependencies for $helper: base-devel git"
  sudo pacman -S --needed base-devel git

  build_dir="$(mktemp -d)"
  cleanup() {
    rm -rf -- "$build_dir"
  }
  trap cleanup EXIT

  git clone "https://aur.archlinux.org/$helper.git" "$build_dir/$helper"
  (
    cd "$build_dir/$helper"
    makepkg -si --needed
  )

  if ! command -v "$helper" >/dev/null 2>&1; then
    echo "$helper installation completed without making $helper available on PATH; aborting." >&2
    exit 1
  fi
fi

echo '[3/7] AUR packages'
echo "Installing AUR packages with $helper: ${packages[*]}"
"$helper" -S --needed "${packages[@]}"
