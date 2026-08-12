#!/usr/bin/env bash
set -euo pipefail

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/yash-rice/backups"
target_home="$HOME"
target_root=/
backup_dir=""
yes=false
system_only=false

usage() { echo 'Usage: ./uninstall.sh [--backup-dir PATH] [--target-home PATH] [--target-root PATH] [--yes]'; }
while (($#)); do
  case "$1" in
    --backup-dir) backup_dir="$2"; shift ;;
    --target-home) target_home="$2"; shift ;;
    --target-root) target_root="$2"; shift ;;
    --yes) yes=true ;;
    --system-only) system_only=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ -z "$backup_dir" ]]; then
  mapfile -t backups < <(find "$state_root" -mindepth 1 -maxdepth 1 -type d -name '20*' -printf '%p\n' 2>/dev/null | sort)
  ((${#backups[@]})) || { echo "No yash-rice backups found in $state_root; refusing to remove anything."; exit 1; }
  printf 'Available backups:\n'; printf '  %s\n' "${backups[@]}"
  backup_dir="${backups[${#backups[@]}-1]}"
fi
manifest="$backup_dir/manifest.tsv"
[[ -f "$manifest" ]] || { echo "Missing manifest: $manifest" >&2; exit 1; }

confirm() { $yes || { read -r -p "$1 [y/N] " answer; [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; }; }
under_root() { [[ "$1" == "${target_root%/}"/* ]]; }
hold_target() {
  local original="$1" scope="$2" base relative hold
  [[ -e "$original" || -L "$original" ]] || return 0
  if [[ "$scope" == user ]]; then base="$target_home"; else base="${target_root%/}"; fi
  relative="${original#"$base"/}"
  hold="$backup_dir/displaced-by-restore/$scope/$relative"
  mkdir -p "$(dirname "$hold")"
  mv "$original" "$hold"
}
restore_record() {
  local type="$1" original="$2" backup="$3" deployed="$4" scope="$5"
  [[ "$scope" == user && "$original" == "$target_home"/* ]] || [[ "$scope" == system && "$original" == "${target_root%/}"/* ]] || return 0
  case "$type" in
    USER_BACKUP|SYSTEM_BACKUP)
      [[ -e "$backup" || -L "$backup" ]] || { echo "Skipping missing backup: $backup" >&2; return 1; }
      hold_target "$original" "$scope"
      mkdir -p "$(dirname "$original")"
      mv "$backup" "$original"
      printf 'Restored %s\n' "$original"
      ;;
    NEW_USER_FILE|NEW_SYSTEM_FILE)
      # A manifest record proves this target was created by this install.
      hold_target "$original" "$scope"
      printf 'Removed deployed target from active location: %s\n' "$original"
      ;;
    *) echo "Unknown manifest record type: $type" >&2; return 1 ;;
  esac
}

if ! $system_only; then
  if confirm "Restore user configuration from $backup_dir?"; then
    while IFS=$'\t' read -r type original backup deployed; do restore_record "$type" "$original" "$backup" "$deployed" user; done < "$manifest"
  fi
fi

mapfile -t system_records < <(awk -F '\t' '$1 ~ /^SYSTEM_BACKUP$|^NEW_SYSTEM_FILE$/ {print}' "$manifest")
if ((${#system_records[@]})); then
  printf 'System files recorded for restore:\n%s\n' "${system_records[*]}"
  if ! $system_only && ! confirm 'Restore these system SDDM files? This requires sudo and changes only recorded paths.'; then
    echo 'System restore skipped.'
  elif [[ "$target_root" == / && $EUID -ne 0 ]]; then
    exec sudo --preserve-env=HOME "$0" --system-only --yes --backup-dir "$backup_dir" --target-home "$target_home" --target-root /
  else
    while IFS=$'\t' read -r type original backup deployed; do restore_record "$type" "$original" "$backup" "$deployed" system; done < "$manifest"
  fi
fi
echo 'Restore complete. No packages or services were changed.'
