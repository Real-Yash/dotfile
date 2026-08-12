#!/usr/bin/env bash
set -euo pipefail
echo "Enabling NetworkManager and sddm changes system service state."
systemctl enable NetworkManager.service sddm.service

