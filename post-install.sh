#!/bin/bash

user_apps=(
    brave-bin 
    google-chrome 
    walker
)
username=$(ls /home | grep -v "lost+found" | head -n 1)

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Install yay AUR helper."
echo "###############################################################"
su - "$username" -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si --noconfirm"

echo "###############################################################"
echo "[ARCH-INSTALL-SCRIPT] Installing pamac."
echo "###############################################################"
su - $username -c "yay -S --noconfirm libpamac-full pamac-cli pamac"

echo "###############################################################"
echo "[ARCH-INSTALL-SCRIPT] Cleaning up GNOME Software."
echo "###############################################################"
pacman -Rs --noconfirm gnome-software

echo "###############################################################"
echo "[ARCH-INSTALL-SCRIPT] Configuring Pamac features."
echo "###############################################################"
sed -i 's/#EnableAUR/EnableAUR/' /etc/pamac.conf
sed -i 's/#CheckAURUpdates/CheckAURUpdates/' /etc/pamac.conf
sed -i 's/#EnableSnap/EnableSnap/' /etc/pamac.conf
sed -i 's/#EnableFlatpak/EnableFlatpak/' /etc/pamac.conf

echo "###############################################################"
echo "[ARCH-INSTALL-SCRIPT] Installing user apps."
echo "###############################################################"
su - $username -c "yay -S --noconfirm ${user_apps[@]}"