#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${BACKUP_DIR:?BACKUP_DIR is required}"
target_root="${TARGET_ROOT:-/}"
profile="${PROFILE:-generic-laptop}"

system_path() { printf '%s/%s' "${target_root%/}" "${1#/}"; }
copy_file() { mkdir -p "$(dirname "$2")"; cp -a "$1" "$2"; }
backup_system() {
  local target="$1" relative backup
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    printf 'NEW_SYSTEM_FILE\t%s\t\t%s\n' "$target" "sddm" >> "$BACKUP_DIR/manifest.tsv"
    return 0
  fi
  relative="${target#"${target_root%/}"/}"
  backup="$BACKUP_DIR/system/$relative"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  printf 'SYSTEM_BACKUP\t%s\t%s\t%s\n' "$target" "$backup" "sddm" >> "$BACKUP_DIR/manifest.tsv"
}

if [[ "$target_root" == / && $EUID -ne 0 ]]; then
  echo "SDDM deployment changes /etc and /usr/share and requires sudo."
  exec sudo --preserve-env=BACKUP_DIR,PROFILE,TARGET_ROOT "$0"
fi

theme_target="$(system_path /usr/share/sddm/themes/simple_sddm_2)"
xsetup_target="$(system_path /usr/share/sddm/scripts/Xsetup)"
conf_target="$(system_path /etc/sddm.conf.d/20-yash-rice.conf)"
backup_system "$theme_target"
backup_system "$xsetup_target"
backup_system "$conf_target"
mkdir -p "$(dirname "$theme_target")" "$(dirname "$xsetup_target")" "$(dirname "$conf_target")"
cp -a "$repo_root/sddm/simple_sddm_2" "$theme_target"
copy_file "$repo_root/sddm/config/20-yash-rice.conf" "$conf_target"
if [[ "$profile" == acer-nitro ]]; then copy_file "$repo_root/profiles/acer-nitro.Xsetup" "$xsetup_target"; else copy_file "$repo_root/sddm/Xsetup" "$xsetup_target"; fi
chmod 0755 "$xsetup_target"
