#!/usr/bin/env bash
set -euo pipefail

: "${TARGET_HOME:?TARGET_HOME is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"
manifest="$BACKUP_DIR/manifest.tsv"
mkdir -p "$BACKUP_DIR"
[[ -f "$manifest" ]] || printf 'type\toriginal\tbackup\tdeployed\n' > "$manifest"

record_manifest() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$manifest"
}

backup_target() {
  local target="$1" deployed="$2" relative backup
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    record_manifest NEW_USER_FILE "$target" '' "$deployed"
    return 0
  fi
  relative="${target#"$TARGET_HOME"/}"
  backup="$BACKUP_DIR/home/$relative"
  mkdir -p "$(dirname "$backup")"
  mv "$target" "$backup"
  record_manifest USER_BACKUP "$target" "$backup" "$deployed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  backup_target "$@"
fi
