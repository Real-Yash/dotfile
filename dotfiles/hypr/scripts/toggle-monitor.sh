#!/usr/bin/env bash
set -euo pipefail

internal="$(hyprctl monitors -j | jq -r '[.[] | select(.name | test("^(eDP|LVDS)")) | .name][0] // empty')"
[[ -n "$internal" ]] || { notify-send 'Monitor' 'No internal panel detected'; exit 0; }

if hyprctl monitors -j | jq -e --arg name "$internal" '.[] | select(.name == $name)' >/dev/null; then
  hyprctl keyword monitor "$internal,disable"
else
  hyprctl keyword monitor "$internal,preferred,auto,1"
fi

