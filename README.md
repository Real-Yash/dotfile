# yash-rice

Reproducible Arch Linux Hyprland rice for a laptop with optional Acer Nitro monitor behavior. It includes Hyprland, Waybar, Rofi, SwayNC, Wlogout, Ghostty, Hyprpaper, AGS TaskPopup, static wallpapers, and an SDDM theme.

## Screenshots

Screenshots placeholder: add sanitized desktop and login-screen screenshots before publishing.

## Requirements

- Arch Linux on an already-installed system. This is not a disk installer.
- A regular user account. `install.sh` refuses root.
- Network access when AUR installation is confirmed. The installer prefers an existing `paru`, then `yay`; if neither is installed, it lists the required AUR packages and asks before bootstrapping `yay`.
- Review the package lists in `packages/` before installation.

## Install

```bash
git clone https://github.com/Real-Yash/yash-rice.git
cd yash-rice
./install.sh --dry-run
./install.sh
```

For the source machine's optional monitor layout and SDDM output mapping:

```bash
./install.sh --profile acer-nitro
```

The installer asks separately before official packages, AUR packages, SDDM deployment, and enabling `NetworkManager`/`sddm`. If no AUR helper is available, it first asks whether to bootstrap `yay`; the AUR build runs as the normal user, never root. `sudo` is used only for pacman and system installation steps. It never removes packages, edits bootloader settings, changes kernel parameters, formats disks, or reboots.

`--backup-dir PATH` selects a backup location. Default backups are timestamped under `~/.local/state/yash-rice/backups/`; each contains a manifest mapping every replaced target to its backup.

## Components

- **Waybar:** one startup path, `exec-once = waybar` in Hyprland. `style.css` is a symlink to a file in `~/.config/waybar/style/`. `Super+W` runs the Rofi picker and changes only that symlink before signalling Waybar to reload.
- **Wallpaper:** `Super+Space` opens a thumbnail Rofi picker. Static JPEG wallpapers are deployed to `~/Pictures/wallpaper`; the helper applies the selection to every monitor reported by Hyprland. Hyprpaper's generated config uses the target user's home, never the source machine path.
- **AGS TaskPopup:** AGS is required for the current Taskwarrior popup. Waybar displays pending task count and toggles `TaskPopup`; task data remains in the user's own Taskwarrior storage and is never copied.
- **Wlogout:** lock, reboot, shutdown, logout, and suspend only. Lock uses `hyprlock`; hibernate is intentionally omitted.
- **SDDM:** `simple_sddm_2` is copied without upstream git metadata. Generic Xsetup chooses a connected external display and disables an internal panel when present, otherwise uses the internal panel. It does not assume connector names or refresh rates.

## Profiles

`generic-laptop` uses Hyprland preferred modes and automatic monitor placement. `acer-nitro` preserves the observed HDMI-A-1/eDP-1 layout, modes, workspace placement, and SDDM Xorg connectors. It documents but does not automatically install `acer-wmi-battery-dkms`.

## Keybinds

`Super+Return` Ghostty, `Super+E` Thunar, `Super+D` Rofi, `Super+X` power menu, `Super+P` toggle internal monitor, `Super+W` Waybar themes, and `Super+Space` wallpapers. Existing workspace, navigation, screenshot, brightness, and volume bindings are retained in `dotfiles/hypr/hyprland.conf`.

## Rollback and Uninstall

`./uninstall.sh` is a restore tool. It lists backups, restores the latest only after confirmation, and moves the deployed files into that backup's `displaced-by-restore` directory. It does not remove packages, services, or unrelated configuration. If no manifest exists, it refuses cleanup.

## Validation

Run `./validate.sh`. It checks repository paths, Bash syntax, JSON, scripts, symlinks, packaged themes/wallpapers, AGS dependencies, source-machine paths, stale actions, copied SDDM git metadata, duplicate Waybar startup, and common secret markers. ShellCheck is used when installed.

## Attribution and License

Retained Waybar, Rofi, SwayNC, Wlogout, and Ghostty-derived files preserve their embedded JaKooLit and other upstream notices. The SDDM theme identifies Keyitdev's `sddm-astronaut-theme`, based on MarianArlt's `sddm-sugar-dark`, and includes its GPL-3.0-or-later license. This repository's original glue scripts are MIT-licensed; third-party files retain their own terms.

## Known Limitations

- AGS is AUR-supplied and coupled to AGS 3 GTK4/Astal APIs.
- Generic monitor detection cannot infer every dock/GPU routing preference; use or extend a hardware profile where needed.
- No dynamic Wallust/Matugen generation is included.
- SDDM display policy is X11/Xrandr based, matching the current SDDM configuration.
