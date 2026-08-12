#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dry_run=false
profile=generic-laptop
backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/yash-rice/backups/$(date +%Y-%m-%d_%H%M%S)"
target_home="$HOME"
target_root=/
yes=false
skip_packages=false
skip_sddm=false
skip_services=false

usage() { cat <<'EOF'
Usage: ./install.sh [--dry-run] [--profile generic-laptop|acer-nitro] [--backup-dir PATH]
                    [--yes] [--target-home PATH] [--target-root PATH] [--skip-packages]
The target options are for isolated test environments only.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) dry_run=true ;;
    --profile) profile="$2"; shift ;;
    --backup-dir) backup_dir="$2"; shift ;;
    --yes) yes=true ;;
    --target-home) target_home="$2"; shift ;;
    --target-root) target_root="$2"; shift ;;
    --skip-packages) skip_packages=true ;;
    --skip-sddm) skip_sddm=true ;;
    --skip-services) skip_services=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

[[ $EUID -ne 0 ]] || { echo 'Refusing to run as root.' >&2; exit 1; }
[[ -r /etc/arch-release ]] || { echo 'This installer supports Arch Linux only.' >&2; exit 1; }
[[ "$profile" == generic-laptop || "$profile" == acer-nitro ]] || { echo "Unknown profile: $profile" >&2; exit 2; }

log() { printf '[yash-rice] %s\n' "$*"; }
ask() {
  local prompt="$1" answer
  $yes && return 0
  if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
    echo 'Cannot prompt for confirmation: /dev/tty is unavailable.' >&2
    return 1
  fi
  printf '%s [y/N] ' "$prompt" > /dev/tty
  IFS= read -r answer < /dev/tty || return 1
  [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

log "Preflight: profile=$profile target_home=$target_home target_root=$target_root"
if $dry_run; then
  cat <<EOF
DRY RUN: would create backup $backup_dir
DRY RUN: would install official packages from packages/pacman.txt after confirmation
DRY RUN: would install AUR packages from packages/aur.txt after confirmation
DRY RUN: would back up and deploy Hyprland, Waybar, Rofi, SwayNC, Wlogout, Ghostty, AGS, and wallpapers to $target_home
DRY RUN: would offer SDDM theme/Xsetup installation under /usr/share and /etc after a separate confirmation
DRY RUN: would offer enabling NetworkManager and sddm after a separate confirmation
DRY RUN: would run validate.sh
EOF
  exit 0
fi

mkdir -p "$backup_dir"
printf 'type\toriginal\tbackup\tdeployed\n' > "$backup_dir/manifest.tsv"
log "Backup manifest: $backup_dir/manifest.tsv"

echo '[1/7] Official packages'
if ! $skip_packages && ask 'Install required official Arch packages?'; then
  log 'Official package installation requires sudo and changes the system.'
  sudo "$repo_root/scripts/install-packages.sh"
fi
if ! $skip_packages && ask 'Install required AUR packages?'; then
  log 'AUR package installation changes the system; yay will be offered only if no supported helper is installed.'
  if ! "$repo_root/scripts/install-aur.sh"; then
    echo 'AUR package installation failed; aborting before dotfiles, SDDM, and service setup.' >&2
    exit 1
  fi
fi

echo '[4/7] Dotfiles'
log 'Backing up conflicting user targets and deploying repository dotfiles.'
TARGET_HOME="$target_home" BACKUP_DIR="$backup_dir" PROFILE="$profile" "$repo_root/scripts/deploy-dotfiles.sh"

echo '[5/7] SDDM'
if ! $skip_sddm && ask 'Install the SDDM theme and display policy? This changes /usr/share and /etc.'; then
  if [[ "$target_root" == / ]]; then
    log 'SDDM deployment requires sudo and does not restart or enable SDDM.'
  else
    log "SDDM deployment uses the isolated target root: $target_root"
  fi
  BACKUP_DIR="$backup_dir" PROFILE="$profile" TARGET_ROOT="$target_root" "$repo_root/scripts/setup-sddm.sh"
fi
echo '[6/7] Services'
if ! $skip_services && ask 'Enable NetworkManager and sddm services? This changes service enablement.'; then
  log 'Service enablement requires sudo; no services will be restarted.'
  sudo "$repo_root/scripts/setup-services.sh"
fi

echo '[7/7] Validation'
log 'Validation.'
"$repo_root/validate.sh"
log 'Complete. No reboot was requested.'
