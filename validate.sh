#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
failures=0
pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
warn() { printf 'WARN: %s\n' "$1"; }
require_file() { [[ -f "$2" ]] && pass "$1" || fail "$1"; }
require_executable() { [[ -x "$2" ]] && pass "$1" || fail "$1"; }
contains() { grep -Eq "$2" "$3" && pass "$1" || fail "$1"; }
lacks() { grep -REq "$2" "${@:3}" && fail "$1" || pass "$1"; }
declares_package() { grep -Fxq "$2" "$repo_root/packages/pacman.txt" && pass "$1" || fail "$1"; }

required=(install.sh uninstall.sh AUDIT.md README.md LICENSE packages/pacman.txt packages/aur.txt dotfiles/hypr/hyprland.conf dotfiles/hyprpaper/hyprpaper.conf.in dotfiles/waybar/config dotfiles/ags/app.tsx sddm/simple_sddm_2/theme.conf sddm/Xsetup)
for file in "${required[@]}"; do require_file "$file exists" "$repo_root/$file"; done

while IFS= read -r -d '' script; do
  if bash -n "$script"; then pass "bash syntax: ${script#$repo_root/}"; else fail "bash syntax: ${script#$repo_root/}"; fi
done < <(find "$repo_root" -type f -name '*.sh' -print0)

if command -v shellcheck >/dev/null 2>&1; then
  while IFS= read -r -d '' script; do shellcheck "$script" || fail "shellcheck: ${script#$repo_root/}"; done < <(find "$repo_root" -type f -name '*.sh' -print0)
else
  warn 'shellcheck is not installed; Bash syntax checks were run.'
fi

if command -v jq >/dev/null 2>&1; then
  for json in dotfiles/waybar/{config,Modules,ModulesWorkspaces,ModulesCustom,ModulesGroups,UserModules} dotfiles/swaync/config.json; do
    if jq empty "$repo_root/$json"; then pass "JSON parses: $json"; else fail "JSON parses: $json"; fi
  done
else
  warn 'jq is not installed; JSON parse checks were not run.'
fi

require_file 'default wallpaper exists' "$repo_root/wallpapers/wallpaper1.jpg"
require_executable 'wallpaper helper is executable' "$repo_root/dotfiles/hypr/scripts/apply-wallpaper.sh"
declares_package 'jq declared for wallpaper helper' jq
contains 'wallpaper helper enumerates active outputs' 'hyprctl monitors -j' "$repo_root/dotfiles/hypr/scripts/apply-wallpaper.sh"
lacks 'generic wallpaper logic has no hard-coded connector names' '(HDMI-A-1|eDP-1|HDMI-1-0)' "$repo_root/dotfiles/hypr/scripts/apply-wallpaper.sh" "$repo_root/dotfiles/hyprpaper/hyprpaper.conf.in"
contains 'generated hyprpaper config applies wallpaper to all outputs' '^wallpaper = ,@WALLPAPER@$' "$repo_root/dotfiles/hyprpaper/hyprpaper.conf.in"

expected_waybar_themes=(
  '[Black & White] Monochrome.css'
  '[Catppuccin] Mocha.css'
  '[Colored] Translucent.css'
  '[Dark] Golden Noir.css'
  '[Dark] Half-Moon.css'
  '[Dark] Purpl.css'
  '[Extra] Mauve.css'
  '[Extra] Modern-Combined - Transparent.css'
  '[Extra] Rose Pine.css'
  '[Transparent] Crystal Clear.css'
)
for theme in "${expected_waybar_themes[@]}"; do
  require_file "retained Waybar theme exists: $theme" "$repo_root/dotfiles/waybar/style/$theme"
done
mapfile -d '' packaged_waybar_themes < <(find "$repo_root/dotfiles/waybar/style" -maxdepth 1 -type f -name '*.css' -printf '%f\0' | sort -z)
[[ ${#packaged_waybar_themes[@]} == ${#expected_waybar_themes[@]} ]] && pass 'exact retained Waybar theme count' || fail 'exact retained Waybar theme count'
require_file 'default Waybar style target exists' "$repo_root/dotfiles/waybar/style/[Dark] Half-Moon.css"
contains 'AGS TaskPopup exists' 'name="TaskPopup"' "$repo_root/dotfiles/ags/app.tsx"
lacks 'AGS resolves task via PATH' '/usr/bin/(task|jq)' "$repo_root/dotfiles/ags/app.tsx"

if find "$repo_root/sddm/simple_sddm_2" -type d -name .git -print -quit | grep -q .; then fail 'no copied SDDM .git directory'; else pass 'no copied SDDM .git directory'; fi
if find "$repo_root" \( -name .taskrc -o -name .task \) -print -quit | grep -q .; then fail 'no Taskwarrior config or database'; else pass 'no Taskwarrior config or database'; fi
if find "$repo_root" -xtype l -print -quit | grep -q .; then fail 'no dangling repository symlinks'; else pass 'no dangling repository symlinks'; fi
if find "$repo_root" -type f \( -name my-waybar.service -o -name waybar-custom.service \) -print -quit | grep -q .; then fail 'no duplicate Waybar user units'; else pass 'no duplicate Waybar user units'; fi
lacks 'generic config has no source-machine home path' '/home/yash' "$repo_root/dotfiles" "$repo_root/sddm"
lacks 'Acer-only connector names confined to profiles' '(HDMI-A-1|eDP-1|HDMI-1-0)' "$repo_root/dotfiles" "$repo_root/sddm"
lacks 'no hibernate actions' 'systemctl hibernate' "$repo_root/dotfiles"
lacks 'no missing legacy action scripts referenced' '(Wlogout|LockScreen|AirplaneMode)\.sh' "$repo_root/dotfiles"
contains 'theme picker exposes packaged themes only' 'find .*style_dir.*-maxdepth 1' "$repo_root/dotfiles/hypr/scripts/WaybarStyles.sh"
contains 'theme picker safely quotes selected theme path' '"\$style_dir/\$choice"' "$repo_root/dotfiles/hypr/scripts/WaybarStyles.sh"

for package in qt6-declarative qt6-multimedia qt6-5compat qt6-svg qt6-virtualkeyboard; do
  declares_package "SDDM QML runtime package declared: $package" "$package"
done
contains 'SDDM theme imports QtMultimedia' '^import QtMultimedia$' "$repo_root/sddm/simple_sddm_2/Main.qml"
contains 'SDDM theme imports Qt5Compat GraphicalEffects' '^import Qt5Compat.GraphicalEffects$' "$repo_root/sddm/simple_sddm_2/Components/UserList.qml"
contains 'SDDM theme imports QtQuick VirtualKeyboard' '^import QtQuick.VirtualKeyboard' "$repo_root/sddm/simple_sddm_2/Components/VirtualKeyboard.qml"
starts="$(grep -Ec '^exec-once = waybar$' "$repo_root/dotfiles/hypr/hyprland.conf" || true)"
[[ "$starts" == 1 ]] && pass 'one Waybar startup declaration' || fail 'one Waybar startup declaration'

if find "$repo_root" -type f \( -name .env -o -name '.env.*' -o -name id_rsa -o -name '*.pem' -o -name '*.key' \) -print -quit | grep -q .; then fail 'no prohibited sensitive filenames'; else pass 'no prohibited sensitive filenames'; fi
if grep -RInE '(api[_-]?key|authorization:|bearer[[:space:]]+|BEGIN (OPENSSH )?PRIVATE KEY)' "$repo_root" --exclude=AUDIT.md --exclude=LICENSE --exclude=validate.sh --exclude-dir=simple_sddm_2 >/dev/null 2>&1; then fail 'no secret markers'; else pass 'no secret markers'; fi

((failures == 0)) || { printf '%d validation failure(s).\n' "$failures" >&2; exit 1; }
printf 'Validation succeeded.\n'
