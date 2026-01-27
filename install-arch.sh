#!/bin/bash

country="France"
localdomains="dev.localhost.com dev.localhost.io dev.localhost.fr dev.localhost.de dev.localhost.ch dev.localhost.be dev.localhost.lu"

timedatectl set-ntp true

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Setup your partitions."
echo "###############################################################"
echo "This script is for French users and will configure the system locale accordingly."
echo "This script will format and mount your partitions for Arch Linux installation with the following Btrfs subvolumes:"
echo "  @ (root)"
echo "  @home (for /home)"
echo "  @snapshots (for /.snapshots)"
echo ""
echo "Create the following partitions before running this script:"
echo "  1. EFI System Partition (512M, type ef00)"
echo "  2. Linux Filesystem Partition (at least 50G, default type)"
echo "  3. Swap Partition (max 2x your RAM size, type 19)"
lsblk

disk=""
while [[ -z "$disk" ]]; do
    read -r -p "Enter the disk to partition (e.g., /dev/sda): " disk
    if [[ ! -b "$disk" ]]; then
        echo "Invalid disk. Please try again."
        disk=""
        continue
    fi
    
    echo "You have selected disk: $disk"
    read -r -p "Is this correct? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        disk=""
    fi
done

gdisk $disk

partswap=""
partroot=""
partefi=""
while [[ -z "$partroot" || -z "$partswap" || -z "$partefi" ]]; do
    read -r -p "Enter the root partition (e.g., /dev/sda2): " partroot
    if [[ ! -b "$partroot" ]]; then
        echo "Invalid partition. Please try again."
        partroot=""
    fi
    read -r -p "Enter the swap partition (e.g., /dev/sda3): " partswap
    if [[ ! -b "$partswap" ]]; then
        echo "Invalid partition. Please try again."
        partswap=""
    fi
    read -r -p "Enter the EFI partition (e.g., /dev/sda1): " partefi
    if [[ ! -b "$partefi" ]]; then
        echo "Invalid partition. Please try again."
        partefi=""
    fi

    echo "Setup will proceed with:"
    echo "  Root Partition: $partroot"
    echo "  Swap Partition: $partswap"
    echo "  EFI Partition: $partefi"
    read -r -p "Are these correct? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        partroot=""
        partswap=""
        partefi=""
    fi
done


shouldFormatEfi=0
echo "By default, the EFI partition will NOT be formatted, assuming it already contains a valid EFI System."
read -r -p "Do you need to format the EFI partition $partefi? (y/n): " formatEfi
if [[ "$formatEfi" == "y" ]]; then
    shouldFormatEfi=1
fi

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Will now format partitions."
echo "###############################################################"
mkswap "$partswap"
swapon "$partswap"
mkfs.btrfs -f "$partroot"

if [[ $shouldFormatEfi -eq 1 ]]; then
    mkfs.fat -F 32 "$partefi"
fi

echo "[ARCH-INSTALL-SCRIPT] Creating Btrfs subvolumes and mounting partitions."
mount "$partroot" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
umount -R /mnt

mount -o compress=zstd,subvol=@ "$partroot" /mnt
mkdir -p /mnt/{boot/efi,home,.snapshots}

mount -o compress=zstd,subvol=@home "$partroot" /mnt/home
mount -o compress=zstd,subvol=@snapshots "$partroot" /mnt/.snapshots
mount "$partefi" /mnt/boot/efi

echo "Partitions formatted and mounted successfully."

username=""
userpass=""

while [[ -z "$username" ]]; do
    read -r -p "Please enter the username to create: " username
    read -r -s -p "Please enter the password for $username: " userpass
    echo ""
    read -r -p "You entered username: $username. Is this correct? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        username=""
        userpass=""
    fi
done

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Arch Linux base installation will begin now."
echo "###############################################################"
pacstrap /mnt base base-devel linux linux-firmware intel-ucode amd-ucode sudo rsync reflector

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Generating fstab."
echo "###############################################################"
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Time sync and mirrorlist update."
echo "###############################################################"

timedatectl set-ntp true
reflector --country $country --protocol https --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Entering chroot to configure the system..."
echo "###############################################################"

arch-chroot /mnt /bin/bash <<EOF
username="$username"
userpass="$userpass"
localdomains="$localdomains"

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Configuring locale and hostname."
echo "###############################################################"
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "LC_TIME=fr_FR.UTF-8" >> /etc/locale.conf
echo "KEYMAP=fr-latin9" > /etc/vconsole.conf

echo "arch" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
for domain in \$localdomains; do
    echo "127.0.0.1 \$domain" >> /etc/hosts
done

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Creating user \$username."
echo "###############################################################"
useradd -m -G wheel,users -s /usr/bin/zsh "\$username"
echo "\$username:\$userpass" | chpasswd

echo "Enabling sudo."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing base packages."
echo "###############################################################"
pacman -Syu --noconfirm \
git base-devel pciutils acpid btrfs-progs iwd llvm networkmanager snapper snap-pac grub-btrfs os-prober efibootmgr \
nss-mdns pacman-contrib ufw unzip p7zip ripgrep plocate cifs-utils exfatprogs gvfs-mtp gvfs-smb \
ffmpeg poppler iputils fontconfig jq wireless-regdb fzf pipewire-pulse wireplumber bluez

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing terminal and utilities."
echo "###############################################################"
pacman -Syu --noconfirm \
kitty fastfetch zsh yazi ffmpegthumbnailer imv man tldr nano

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing Oh My Zsh and plugins for user \$username."
echo "###############################################################"
sudo -u "\$username" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
sudo -u "\$username" git clone https://github.com/zsh-users/zsh-autosuggestions /home/"\$username"/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sudo -u "\$username" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /home/"\$username"/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing detected graphics drivers."
echo "###############################################################"
if lspci | grep -qi nvidia; then
    pacman -Syu --noconfirm nvidia nvidia-utils nvidia-settings
elif lspci | grep -qi "amd\|ati"; then
    pacman -Syu --noconfirm xf86-video-amdgpu vulkan-radeon
elif lspci | grep -qi intel; then
    pacman -Syu --noconfirm xf86-video-intel vulkan-intel
fi

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing printer support."
echo "###############################################################"
pacman -Syu --noconfirm \
system-config-printer cups cups-browsed cups-filters

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing fonts."
echo "###############################################################"
pacman -Syu --noconfirm \
noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-bitstream-vera \
ttf-cascadia-mono-nerd ttf-fira-mono ttf-firacode-nerd ttf-liberation \
ttf-opensans ttf-roboto woff2-font-awesome ttf-jetbrains-mono-nerd

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing web browsers and multimedia applications."
echo "###############################################################"
pacman -Syu --noconfirm \
chromium firefox vlc discord podman podman-desktop qbittorrent

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installing GNOME Desktop Environment."
echo "###############################################################"
pacman -Syu --noconfirm \
gnome gdm gnome-tweaks extension-manager gnome-shell-extensions gnome-browser-connector papirus-icon-theme gnome-themes-extra

# Theme and font settings
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface font-name 'JetBrainsMono Nerd Font Semi-Bold 11'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface document-font-name 'JetBrainsMono Nerd Font Propo 12'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font Mono 11'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.wm.preferences titlebar-font 'JetBrainsMono Nerd Font Bold 11'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface font-hinting 'slight'
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
sudo -u \$username dbus-launch gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'fr')]"
# Power settings
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'suspend'
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power energy-performance-preference 'performance'
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'suspend'
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 900
sudo -u "\$username" dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.interface show-battery-percentage true
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.session idle-delay 0
# Trackpad settings
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.peripherals.touchpad click-method 'areas'
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
# Nautilus settings
ln -sf /usr/bin/kitty /mnt/usr/local/bin/x-terminal-emulator
sudo -u "\$username" dbus-launch gsettings set org.gnome.desktop.default-applications.terminal exec-arg '-e'

localectl set-x11-keymap fr pc105 latin9

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Configuring and enabling services."
echo "###############################################################"
printf "[device]\nwifi.backend=iwd\n" > /etc/NetworkManager/conf.d/wifi_backend.conf
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable acpid
systemctl enable gdm

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Configuring snapshots."
echo "###############################################################"
umount /.snapshots 2>/dev/null || true
rm -rf /.snapshots
snapper --no-dbus -c root create-config /
rm -rf /.snapshots
mkdir /.snapshots

root_dev=$(findmnt -n -o SOURCE /)
mount -o compress=zstd,subvol=@snapshots "\$root_dev" /.snapshots

chmod 750 /.snapshots
chown :wheel /.snapshots
snapper --no-dbus -c root set-config "TIMELINE_LIMIT_HOURLY=0" "TIMELINE_LIMIT_DAILY=7" "TIMELINE_LIMIT_WEEKLY=0" "TIMELINE_LIMIT_MONTHLY=0" "TIMELINE_LIMIT_YEARLY=0"

echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfsd
EOF

echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Copy configuration files."
echo "###############################################################"

echo "Importing .zshrc for user $username."
cp ./config/zsh/.zshrc /mnt/home/"$username"/.zshrc
chown "$username:$username" /mnt/home/"$username"/.zshrc

echo "Importing fastfetch configuration for user $username."
mkdir -p /mnt/home/"$username"/.config/fastfetch/
cp ./config/fastfetch/config.jsonc /mnt/home/"$username"/.config/fastfetch/config.jsonc

chroot /mnt chown -R "$username":"$username" /home/"$username"/.config/

echo ""
echo ""
echo "###############################################################"
echo "# [ARCH-INSTALL-SCRIPT] Installation complete."
echo "###############################################################"
echo "Press any key to unmount partitions and reboot into your new Arch Linux system."

read -r
umount -R /mnt
swapoff "$partswap"
reboot