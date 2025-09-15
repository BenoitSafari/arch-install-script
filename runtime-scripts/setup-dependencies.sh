#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

echo "Updating package database and upgrading system..."
pacman -Syu --noconfirm

echo "Installing media/office apps packages..."
flatpak install flathub com.discordapp.Discord

echo "Installing additional web browsers..."
yay -S --noconfirm chromium google-chrome

bash ./setup-dependencies.sh