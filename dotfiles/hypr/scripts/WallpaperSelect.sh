#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="$HOME/Pictures/wallpaper"
rofi_config="$HOME/.config/rofi/config-wallpaper.rasi"
selector="$HOME/.config/hypr/scripts/apply-wallpaper.sh"
[[ -d "$wallpaper_dir" ]] || exit 0

mapfile -d '' files < <(find "$wallpaper_dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -printf '%f\0' | sort -z)
((${#files[@]})) || exit 0

entries=''
for name in "${files[@]}"; do
  entries+="${name}"$'\0icon\x1f'"thumbnail://${wallpaper_dir}/${name}"$'\n'
done
choice="$(printf '%s' "$entries" | rofi -dmenu -i -show-icons -p 'Wallpaper' -config "$rofi_config")" || exit 0
[[ -n "$choice" && -f "$wallpaper_dir/$choice" ]] || exit 0
"$selector" "$wallpaper_dir/$choice"
notify-send 'Wallpaper' "$choice"

