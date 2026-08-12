# Yash Rice Audit

Audit date: 2026-08-13  
Scope: read-only inspection of the live Arch Linux configuration. No live configuration, service, package, or system file was modified.

## Active Rice Architecture

- Hyprland starts the session from `~/.config/hypr/hyprland.conf`.
- The active Hyprland configuration directly defines both monitors, workspaces, bindings, and autostart commands. `monitors.conf` and `workspaces.conf` exist but are empty and are not sourced.
- Hyprland autostarts Waybar, NetworkManager Applet, Blueman Applet, KDE Polkit agent, Hyprpaper, Udiskie, and AGS.
- Waybar is configured through symlinks:
  - `~/.config/waybar/config` -> `configs/[TOP] Minimal - Short`
  - `~/.config/waybar/style.css` -> `style/[Dark] Half-Moon.css`
  - `selected-theme.css` -> `style/[Colored] Translucent.css` but is not referenced by the active launcher/configuration.
- The active Waybar layout includes `Modules`, `ModulesWorkspaces`, `ModulesCustom`, `ModulesGroups`, and `UserModules`; it shows workspaces, clock, weather, tray, notifications, PulseAudio, battery, Taskwarrior count, and power.
- Rofi uses `config.rasi`, importing `0-shared-fonts.rasi` and selecting `themes/KooL_style-4.rasi`. Hyprland bindings use the dedicated Waybar-style and wallpaper Rofi configs.
- Hyprpaper reads `~/.config/hypr/hyprpaper.conf` and is expected to show the same wallpaper on both outputs.
- SDDM runs X11 (`DisplayServer=x11`), selects `simple_sddm_2`, and uses the modified `/usr/share/sddm/scripts/Xsetup` display command.

## Active Config Files

| Area | Active file(s) | Notes |
| --- | --- | --- |
| Hyprland | `~/.config/hypr/hyprland.conf` | Main source of truth; contains monitor/workspace rules and `exec-once` startup. |
| Hyprpaper | `~/.config/hypr/hyprpaper.conf` | Uses absolute `/home/yash/Pictures/wallpaper/wallpaper1.jpg`. |
| Hypr scripts | `toggle-monitor.sh`, `scripts/WaybarStyles.sh`, `scripts/WallpaperSelect.sh` | All are executable. |
| Waybar | `config` symlink and `style.css` symlink | Active targets above. Module banks are included by active config. |
| Rofi | `config.rasi`, `0-shared-fonts.rasi`, `themes/KooL_style-4.rasi`, `config-wallpaper.rasi`, `config-waybar-style.rasi` | Active selector dependencies. |
| SwayNC | `config.json`, `style.css`, `icons/`, `images/` | Backlight is hard-coded to `amdgpu_bl2`. |
| Wlogout | `layout`, `style.css`, `icons/` | Current layout includes hibernate. |
| Ghostty | `config`, `wallust.conf` | Optional `theme.conf` is referenced but absent. |
| SDDM | `/etc/sddm.conf`, `/etc/sddm.conf.d/10-monitor.conf`, `/etc/sddm.conf.d/kde_settings.conf`, `/usr/share/sddm/scripts/Xsetup`, `/usr/share/sddm/themes/simple_sddm_2/` | Theme is unpackaged/manual and has an upstream `.git` directory. |

## Required Packages

These are derived from the active session, visible Waybar modules, and active scripts rather than the full installed package set.

- `hyprland`, `waybar`, `rofi`, `swaync`, `wlogout`, `hyprpaper`, `ghostty`, `hyprlock`
- `wireplumber`, `pipewire`, `pipewire-pulse`, `pipewire-alsa`
- `networkmanager`, `network-manager-applet`, `blueman`, `udiskie`, `polkit-kde-agent`
- `grim`, `slurp`, `wl-clipboard`, `brightnessctl`, `pavucontrol`, `playerctl`, `task`, `thunar`, `libnotify`, `xorg-xrandr`
- `sddm`, plus its Qt/QML dependencies supplied by Arch package dependencies

`polkit-kde-agent` and `pamixer` require confirmation during Phase 2: the main config invokes `/usr/lib/polkit-kde-authentication-agent-1`, but this path was not owned by an installed package; `pamixer` is referenced by inherited Waybar modules but is absent.

## Optional Packages

- `ags` and an AGS configuration: autostarted, but `~/.config/ags/app.tsx` was not part of this audit scope and must not be silently assumed.
- `nvtop`, `btop`, `cava`, `ddcui`, `pavucontrol`, `playerctl`, `task`, `checkupdates` (`pacman-contrib`): referenced by retained/inherited Waybar module definitions; only `task` is in the active layout.
- `wallust`, `matugen`: retained generated color files exist, but the active rice does not require dynamic generation.
- `nwg-look`, `gnome-system-monitor`, `hyprpicker`: referenced by non-active inherited module definitions. `gnome-system-monitor` and `hyprpicker` are not installed.
- GPU drivers, firmware, and Acer battery behavior must remain outside the generic rice installer.

## AUR / Foreign Packages

Installed foreign packages relevant to the rice:

- `aylurs-gtk-shell-git` (provides `ags`; required only while the AGS autostart remains)
- `wlogout` (installed as foreign on this machine)
- `ddcui` (optional)
- `acer-wmi-battery-dkms` (optional Acer Nitro profile only; never force automatically)
- `yay` (AUR helper; installer must ask before installing/using a helper)

Other foreign packages found are not rice dependencies: `burpsuite`, `downgrade`, `obs-move-transition`, and `protonplus-bin`.

## Required Fonts

- `JetBrainsMono Nerd Font` (Waybar, Rofi, SwayNC); resolved by Fontconfig from `ttf-jetbrains-mono-nerd`.
- `FantasqueSansM Nerd Font Mono` (Ghostty); resolved from `ttf-fantasque-nerd`.
- SDDM bundles its own theme fonts in `simple_sddm_2/Fonts/`.

Archived/non-active Rofi themes also name Iosevka Nerd Font and Fira Code, neither of which resolved locally. Do not retain those themes unless their fonts are made optional dependencies.

## Scripts and Dependencies

| Script / action | State | Dependencies / issue |
| --- | --- | --- |
| `toggle-monitor.sh` | Present | Uses `hyprctl`; hard-codes `eDP-1`, 1920x1080@144, and position. Acer profile candidate. |
| `scripts/WaybarStyles.sh` | Present | Uses Bash, `find`, `sort`, `readlink`, Rofi, `pkill`, `notify-send`; changes live symlink only when invoked. Repo copy must use package-relative deployment paths. |
| `scripts/WallpaperSelect.sh` | Present | Uses Bash, `find`, `sort`, `hyprctl hyprpaper`, Rofi, `notify-send`; hard-codes both current monitor names and `$HOME/Pictures/wallpaper`. |
| `scripts/Wlogout.sh` | Missing | Active Waybar power control and SwayNC button are broken. |
| `scripts/LockScreen.sh` | Missing | SwayNC lock button is broken. Use `hyprlock` directly in repo copy. |
| `scripts/AirplaneMode.sh` | Missing | SwayNC airplane button is broken; omit or implement explicitly only after approval. |
| `~/.config/ags/app.tsx` | Not audited / not packaged | Hyprland autostarts it; Phase 2 must package AGS or remove that `exec-once` in the repo copy. |

The active Waybar `custom/weather` module has no `exec`, so it will render no useful weather data. The active `custom/tasks` module needs `task` and `ags` (`ags toggle TaskPopup`).

## Services and Launch Methods

- Hyprland configuration is the active declared launch method for `waybar`, `hyprpaper`, `nm-applet`, `blueman-applet`, KDE Polkit agent, `udiskie`, and AGS.
- Two additional user unit files declare Waybar: `~/.config/systemd/user/my-waybar.service` and `waybar-custom.service`.
- D-Bus access is restricted in this audit environment, so enabled/active states of these user units and system units could not be verified. `pgrep` similarly returned no visible Waybar process here; this is not evidence that Waybar is not running in the live session.
- SDDM, NetworkManager, PipeWire, and WirePlumber unit status could not be queried for the same environment limitation. Their installed configuration/package presence was verified.
- Phase 2 should retain **Hyprland `exec-once = waybar` only** and omit user Waybar service deployment, unless the user explicitly chooses a systemd-user strategy instead.

## Monitor and SDDM Behavior

- Hyprland hard-codes `HDMI-A-1` at 1920x1080@180 position `0x0` and `eDP-1` at 1920x1080@144 position `1920x0`.
- Workspaces 1-3 are bound to HDMI; workspaces 4-5 to eDP. The active Waybar workspace module contains the same machine-specific monitor names.
- `toggle-monitor.sh` controls only `eDP-1` with the same fixed mode/position.
- SDDM Xsetup hard-codes different Xorg connector names: internal `eDP`, external `HDMI-1-0`. If the external output is connected, it disables the internal panel and sets external 1920x1080@180 primary; otherwise it disables external and enables internal at 1920x1080@144.
- The generic profile must replace this with connected-output detection using Xrandr and avoid fixed connectors/rates. Exact Acer connector mappings and preferred modes belong in `profiles/acer-nitro.conf`.

## Wallpaper Behavior

- Active Hyprpaper config preloads and assigns `wallpaper1.jpg` to `eDP-1` and `HDMI-A-1`.
- `~/.config/hypr/.current_wallpaper` points to `wallpaper3.jpg`; this disagrees with static Hyprpaper config and should be treated as runtime state, not copied.
- The wallpaper selector supports JPG/JPEG/PNG/WebP and applies a chosen file to both hard-coded outputs. It excludes the two large video files.
- `~/Pictures/wallpaper/` contains four JPEGs plus `Red Dragon 4k Live Wallpaper.webm` and `.mp4` (about 20 MB each). Select only intentional static wallpapers for Phase 2; Hyprpaper does not use the video files.
- Rofi’s `.current_wallpaper` symlink points to a different, non-scoped location: `~/Pictures/wallpapers/Lofi - Anime Girl2.png`. It is stale and should not be copied.

## Broken or Stale References

- Missing active action scripts: `Wlogout.sh`, `LockScreen.sh`, `AirplaneMode.sh`.
- Missing `~/.config/ghostty/theme.conf`; optional include is harmless only if Ghostty supports optional includes as configured.
- Waybar `selected-theme.css` is not the active stylesheet path.
- Hyprpaper config (`wallpaper1.jpg`) and Hypr `.current_wallpaper` (`wallpaper3.jpg`) disagree.
- Rofi `.current_wallpaper` points to `~/Pictures/wallpapers/`, not the active `~/Pictures/wallpaper/` directory.
- `swaync` hard-codes backlight device `amdgpu_bl2`.
- Inherited Waybar definitions reference unavailable `pamixer`, `gnome-system-monitor`, and `hyprpicker`; they are not used by the active module list.
- `style-archive/`, the many unused Waybar layouts, and Hyprland `.save`/`pre-recovery` files are retained/dead material, not active rice inputs.

## Exclusions and Sensitive Material

Exclude from the repository:

- `~/.config/hypr/hyprland.conf.save*`, `hyprland.conf.pre-recovery-*`, `.initial_startup_done`, and `.current_wallpaper`.
- Waybar `style-archive/`, unused layouts, `wallust/` generated colors unless wallust becomes an explicit optional feature, and all deployment-created symlinks.
- Rofi `.current_wallpaper`, `online_music.list` unless manually reviewed, and generated wallust colors unless intentionally retained.
- `/usr/share/sddm/themes/simple_sddm_2/.git/` and any git metadata from upstream sources.
- All caches, histories, lockfiles, sockets, logs, screenshots, browser data, SSH/GPG material, `.env` files, tokens, credentials, and private keys.

No obvious secret/token/password content was found in the scoped rice configuration by pattern scan. The password-themed SDDM asset/config names are UI labels, not credentials. Manual review is still required before committing `online_music.list` and any non-text assets.

## Migration Risks and Recommendations

1. Convert Hyprland monitors/workspaces, Waybar persistent workspaces, and wallpaper selection to generic output-aware behavior; put the existing connector/mode values in the Acer profile.
2. Keep only a curated active Waybar config, its five include files, and intentionally retained styles. Do not package the broad archived JaKooLit collection by default.
3. Replace missing power/lock actions in the repo copy with direct valid commands: `wlogout --protocol layer-shell`, `hyprlock`, `systemctl reboot`, `systemctl poweroff`, `systemctl suspend`, and `hyprctl dispatch exit`. Omit hibernate.
4. Decide whether AGS is part of this rice. It is currently autostarted and used by Taskwarrior, but its configuration was not included in the requested directory list.
5. Package `simple_sddm_2` as a copied theme (without `.git`) and preserve `theme.conf`; install it only through a backup-first SDDM setup step in Phase 2.
6. Generic install should deploy configs to a test HOME first, use one Waybar startup method, and never install Acer battery DKMS or GPU tuning automatically.
7. Add a pre-commit secret scan and an explicit allowlist for wallpaper assets. Avoid committing live monitor/runtime symlinks.

## AGS Audit

### Scope and Required Files

- `~/.config/ags` contains exactly one configuration file: `app.tsx` (3,470 bytes). There are no imported local modules, manifests, lockfiles, symlinks, asset directories, or generated files within this configuration directory.
- `app.tsx` is the Hyprland autostart target: `ags run ~/.config/ags/app.tsx`.
- Therefore, the complete AGS configuration required for the current behavior is this single source file. Its runtime state is external and must not be copied: Taskwarrior uses `~/.taskrc` with `data.location=/home/yash/.task`.

### TaskPopup and Control Command

- `TaskPopup` exists in `app.tsx` as an AGS GTK4 layer-shell window with `name="TaskPopup"`, namespace `task-popup`, top-right anchoring, and initial `visible={false}`.
- The active Waybar `custom/tasks` module uses `ags toggle TaskPopup`, which matches the window name exactly. AGS 3.1.0 exposes the `toggle` command specifically for toggling a window's visibility.
- The popup lists pending Taskwarrior tasks, supports adding tasks, marks a task done, deletes a task without Taskwarrior confirmation, closes itself, and refreshes its data every five seconds.

### Dependencies

- Required for the current AGS feature: `aylurs-gtk-shell-git` (AUR, AGS 3.1.0), `task`, `jq`, and `bash`/`sh`.
- AGS package dependencies installed on this system: `gjs`, `gtk4-layer-shell`, `gobject-introspection`, `libastal`, `libastal-4`, and `npm`.
- The code calls `/usr/bin/task` and `/usr/bin/jq` explicitly. These paths are valid on this host but should become command lookups or documented Arch dependencies in a packaged copy.
- No network calls, API clients, private URLs, or additional user scripts are used.

### Security and Runtime Material

- Pattern and filename scans found no secrets, API keys, tokens, credentials, or private paths in `~/.config/ags/app.tsx`.
- `~/.taskrc` contains a machine-specific absolute data path and Taskwarrior's task database is personal data. Neither `~/.taskrc` nor `~/.task/` may enter the repository.
- The only AGS-related cache found is under `~/.cache/yay/aylurs-gtk-shell-git/`; it is build-cache material and must be excluded.

### Broken References and Risks

- No missing imports or missing locally referenced files were found; the AGS file is self-contained.
- `ags`, `task`, `jq`, and `/bin/sh` all exist and are package-owned.
- The TaskPopup's refresh command and task mutation commands are operationally coupled to the user's Taskwarrior data, but no Taskwarrior data was read or changed during this audit.
- The configuration relies on AGS 3 GTK4/Astal APIs and an AUR package, increasing installation complexity relative to the rest of the rice.

### Recommendation

Classification: **A. Include AGS as a required rice component** for a faithful reproduction of the current rice. It is actively autostarted and backs the visible active Waybar task control; removing it changes that workflow and leaves `custom/tasks` nonfunctional.

Phase 2 should package only `app.tsx`, list AGS as a required AUR dependency and `task`/`jq` as official dependencies, and exclude all Taskwarrior configuration/data. A later optional profile can replace this with a simpler Rofi/Taskwarrior popup, but that would not reproduce the current add/complete/delete behavior exactly.

## Audit Limitations

- `hyprctl` IPC and user/system D-Bus calls were denied by the execution environment. Live monitor state, active clients/binds, Hyprpaper activity, and unit enablement could not be verified here.
- No sudo was used. No packages, services, live configurations, or system files were changed.
