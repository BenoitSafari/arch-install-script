#!/bin/bash

# Install yay AUR helper
YAY_TMP_DIR="/tmp/yay"
rm -rf "$YAY_TMP_DIR"
git clone https://aur.archlinux.org/yay.git "$YAY_TMP_DIR"
cd "$YAY_TMP_DIR"

makepkg -si --noconfirm
cd ~
rm -rf "$YAY_TMP_DIR"

# Install packages from AUR
yay -S --noconfirm \
    brave-bin google-chrome walker \
