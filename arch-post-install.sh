#!/bin/bash

user_apps=(
    brave-bin
    walker
    sourcegit
    vscodium
)
user_ext=(
    gnome-shell-extension-appindicator 
    gnome-shell-extension-blur-my-shell
)

username=$(ls /home | grep -v "lost+found" | head -n 1)

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Install yay AUR helper."
echo "###############################################################"
su - $username -c "cd /tmp && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -s --noconfirm"
pacman -U --noconfirm /tmp/yay/yay-*.pkg.tar.zst

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing pamac."
echo "###############################################################"
su - $username -c "yay -S --noconfirm libpamac-full pamac-cli pamac"

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Configuring Pamac features."
echo "###############################################################"
sed -i 's/#EnableAUR/EnableAUR/' /etc/pamac.conf
sed -i 's/#CheckAURUpdates/CheckAURUpdates/' /etc/pamac.conf
sed -i 's/#EnableSnap/EnableSnap/' /etc/pamac.conf
sed -i 's/#EnableFlatpak/EnableFlatpak/' /etc/pamac.conf

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing user desktop extensions."
echo "###############################################################"
su - $username -c "yay -S --noconfirm ${user_ext[@]}"
su - $username -c "dbus-launch gnome-extensions enable 'appindicatorsupport@rgcjonas.gmail.com'"
su - $username -c "dbus-launch gnome-extensions enable 'blur-my-shell@aunetx'"
su - $username -c "dbus-launch gnome-extensions enable 'system-monitor@gnome-shell-extensions.gcampax.github.com'"
su - $username -c "dbus-launch gnome-extensions enable 'launch-new-instance@gnome-shell-extensions.gcampax.github.com'"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.appindicator icon-size 16"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell hacks-level 1"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell settings-version 2"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder brightness 0.5"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder sigma 100"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.appfolder style-dialogs 1"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.applications blur true"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.applications enable-all true"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.applications sigma 35"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.panel blur true"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.panel brightness 0.6"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.panel sigma 100"
su - $username -c "dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell.panel override-background true"

BLUR_PIPELINES="{'pipeline_default': {'name': <'Default'>, 'effects': <[<{'type': <'monte_carlo_blur'>, 'id': <'effect_65482949569871'>, 'params': <@a{sv} {}>}>, <{'type': <'noise'>, 'id': <'effect_22455112089519'>, 'params': <@a{sv} {}>}>]>}, 'pipeline_default_rounded': {'name': <'Default rounded'>, 'effects': <@av []>}}"
sudo -u "$username" dbus-launch gsettings set org.gnome.shell.extensions.blur-my-shell pipelines "$BLUR_PIPELINES"

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing user apps."
echo "###############################################################"
su - $username -c "yay -S --noconfirm ${user_apps[@]}"
pacman -Syu --noconfirm qbittorrent podman podman-desktop