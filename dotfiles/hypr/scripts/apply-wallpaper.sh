#!/usr/bin/env bash
set -euo pipefail

wallpaper="${1:-$HOME/Pictures/wallpaper/wallpaper1.jpg}"
log() { printf '[apply-wallpaper] %s\n' "$*" >&2; }

if [[ ! -f "$wallpaper" ]]; then
  log "wallpaper does not exist: $wallpaper"
  exit 1
fi

# Hyprland starts exec-once commands asynchronously, so wait for hyprpaper's IPC
# rather than assuming it is ready immediately after its launch command.
ready=false
for _ in {1..20}; do
  if hyprctl hyprpaper listactive >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 0.25
done

if [[ "$ready" != true ]]; then
  if pgrep -x hyprpaper >/dev/null 2>&1; then
    log 'hyprpaper is running, but its IPC was not ready after 5 seconds'
  else
    log 'hyprpaper is not running; cannot apply wallpaper'
  fi
  exit 1
fi

# hyprpaper 0.8.x accepts wallpaper directly; preloading first is unnecessary.
if ! monitors="$(hyprctl monitors -j | jq -r '.[].name')"; then
  log 'failed to enumerate active Hyprland outputs'
  exit 1
fi

applied=0
while IFS= read -r monitor; do
  [[ -n "$monitor" ]] || continue
  if ! hyprctl hyprpaper wallpaper "$monitor,$wallpaper,cover" >/dev/null; then
    log "failed to apply wallpaper to output: $monitor"
    exit 1
  fi
  applied=$((applied + 1))
done <<< "$monitors"

if ((applied == 0)); then
  log 'Hyprland reported no active outputs'
  exit 1
fi
