#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Real-Yash/dotfile.git"
INSTALL_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/yash-rice-installer"

echo "====================================="
echo "       Yash Arch Rice Installer"
echo "====================================="
echo

if [[ $EUID -eq 0 ]]; then
    echo "ERROR: Do not run this installer as root."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    echo "ERROR: This installer supports Arch Linux only."
    exit 1
fi

ask() {
    local prompt="$1" answer

    if [[ ! -r /dev/tty || ! -w /dev/tty ]]; then
        echo "ERROR: Cannot prompt for confirmation: /dev/tty is unavailable." >&2
        return 1
    fi

    printf '%s [Y/n] ' "$prompt" > /dev/tty
    IFS= read -r answer < /dev/tty || return 1
    [[ -z "$answer" || "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

if ! command -v git >/dev/null 2>&1; then
    echo "Git is required."
    echo

    if ask "Install git using pacman?"; then
        sudo pacman -S --needed git
    else
        echo "Cannot continue without git."
        exit 1
    fi
fi

echo
echo "Repository:"
echo "  $REPO_URL"
echo
echo "Install directory:"
echo "  $INSTALL_DIR"
echo

if ! ask "Continue?"; then
    echo "Cancelled."
    exit 0
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo
    echo "Existing installer checkout found."
    echo "Updating repository..."

    git -C "$INSTALL_DIR" fetch --quiet origin
    git -C "$INSTALL_DIR" reset --hard origin/main
else
    echo
    echo "Downloading rice..."

    rm -rf "$INSTALL_DIR"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

echo
echo "Starting installer..."
echo

exec ./install.sh "$@"
