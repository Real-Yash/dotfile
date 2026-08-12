#!/usr/bin/env bash
set -euo pipefail

wallpaper="${1:-$HOME/Pictures/wallpaper/wallpaper1.jpg}"
[[ -f "$wallpaper" ]] || exit 0

# Hyprpaper may start just before this helper; wait briefly for its IPC socket.
for _ in 1 2 3 4 5; do
  hyprctl hyprpaper listactive >/dev/null 2>&1 && break
  sleep 0.2
done

hyprctl hyprpaper preload "$wallpaper" >/dev/null 2>&1 || true
while IFS= read -r monitor; do
  [[ -n "$monitor" ]] || continue
  hyprctl hyprpaper wallpaper "$monitor,$wallpaper,cover" >/dev/null
done < <(hyprctl monitors -j | jq -r '.[].name')

