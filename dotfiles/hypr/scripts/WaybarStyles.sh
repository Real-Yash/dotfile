#!/usr/bin/env bash
set -euo pipefail

style_dir="$HOME/.config/waybar/style"
active_link="$HOME/.config/waybar/style.css"
rofi_config="$HOME/.config/rofi/config-waybar-style.rasi"

mapfile -d '' themes < <(find "$style_dir" -maxdepth 1 -type f -name '*.css' -printf '%f\0' | sort -z)
((${#themes[@]})) || exit 0

choice="$(printf '%s\n' "${themes[@]}" | rofi -dmenu -i -p 'Waybar Theme' -config "$rofi_config")" || exit 0
[[ -n "$choice" && -f "$style_dir/$choice" ]] || exit 0

tmp_link="$active_link.tmp.$$"
ln -s "$style_dir/$choice" "$tmp_link"
mv -f "$tmp_link" "$active_link"
pkill -SIGUSR2 -x waybar 2>/dev/null || true
notify-send 'Waybar Theme' "${choice%.css}"

