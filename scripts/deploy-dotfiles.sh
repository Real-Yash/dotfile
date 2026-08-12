#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${TARGET_HOME:?TARGET_HOME is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"
source "$repo_root/scripts/backup-existing.sh"

deploy_config() {
  local name="$1" source="$repo_root/dotfiles/$name" target="$TARGET_HOME/.config/$name"
  backup_target "$target" "dotfiles/$name"
  mkdir -p "$TARGET_HOME/.config"
  cp -a "$source" "$target"
}

for name in hypr waybar rofi swaync wlogout ghostty ags; do deploy_config "$name"; done

# Style selection has one source of truth: style.css is a symlink to a packaged file.
ln -s "style/[Dark] Half-Moon.css" "$TARGET_HOME/.config/waybar/style.css"

wallpaper_dir="$TARGET_HOME/Pictures/wallpaper"
backup_target "$wallpaper_dir" "wallpapers"
mkdir -p "$TARGET_HOME/Pictures"
cp -a "$repo_root/wallpapers" "$wallpaper_dir"

# Fresh installations need this directory before the screenshot keybind is used.
mkdir -p "$TARGET_HOME/Pictures/Screenshots"

hyprpaper_target="$TARGET_HOME/.config/hypr/hyprpaper.conf"
wallpaper="$wallpaper_dir/wallpaper1.jpg"
sed "s|@WALLPAPER@|$wallpaper|g" "$repo_root/dotfiles/hyprpaper/hyprpaper.conf.in" > "$hyprpaper_target"

profile="${PROFILE:-generic-laptop}"
cp "$repo_root/profiles/$profile.conf" "$TARGET_HOME/.config/hypr/profile.conf"
chmod 0755 "$TARGET_HOME/.config/hypr/scripts/"*.sh
