#!/bin/bash

country="France"
localdomains="dev.localhost.com dev.localhost.io dev.localhost.fr dev.localhost.de dev.localhost.ch dev.localhost.be dev.localhost.lu"

timedatectl set-ntp true

echo "[ARCH-INSTALL-SCRIPT] Setup your partitions."
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

echo "[ARCH-INSTALL-SCRIPT] Will now format partitions."
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
mkdir -p /mnt/{boot/home,.snapshots}
if [[ $shouldFormatEfi -eq 1 ]]; then
    mkdir -p /mnt/boot
fi

mount -o compress=zstd,subvol=@home "$partroot" /mnt/home
mount -o compress=zstd,subvol=@snapshots "$partroot" /mnt/.snapshots
mount "$partefi" /mnt/boot

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

echo "[ARCH-INSTALL-SCRIPT] Arch Linux base installation will begin now."
pacstrap /mnt base base-devel linux linux-firmware intel-ucode amd-ucode sudo rsync reflector

echo "[ARCH-INSTALL-SCRIPT] Generating fstab."
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

echo "[ARCH-INSTALL-SCRIPT] Time sync and mirrorlist update."

timedatectl set-ntp true
reflector --country $country --protocol https --latest 5 --sort rate --save /etc/pacman.d/mirrorlist

echo "[ARCH-INSTALL-SCRIPT] Entering chroot to configure the system..."

arch-chroot /mnt /bin/bash <<EOF
echo "[ARCH-INSTALL-SCRIPT] Configuring locale, timezone, and hostname."
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr-latin9" > /etc/vconsole.conf
echo "LC_TIME=fr_FR.UTF-8" >> /etc/locale.conf
echo "LC_PAPER=fr_FR.UTF-8" >> /etc/locale.conf
echo "LC_MEASUREMENT=fr_FR.UTF-8" >> /etc/locale.conf

echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
for domain in $localdomains; do
    echo "127.0.0.1 \$domain" >> /etc/hosts
done

echo "[ARCH-INSTALL-SCRIPT] Installing base packages."
pacman -Syu --noconfirm \
git base-devel acpid btrfs-progs iwd llvm networkmanager snapper snap-pac grub-btrfs os-prober efibootmgr \
nss-mdns pacman-contrib ufw unzip p7zip ripgrep plocate cifs-utils exfatprogs gvfs-mtp gvfs-smb \
ffmpeg poppler iputils fontconfig jq wireless-regdb fzf pipewire-pulse wireplumber bluez

echo "[ARCH-INSTALL-SCRIPT] Installing terminal and utilities."
pacman -Syu \
kitty fastfetch zsh btop yazi ffmpegthumbnailer imv man tldr nano

echo "[ARCH-INSTALL-SCRIPT] Installing printer support."
pacman -Syu \
system-config-printer cups cups-browsed cups-filters

echo "[ARCH-INSTALL-SCRIPT] Installing fonts."
pacman -Syu \
noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-bitstream-vera \ 
ttf-cascadia-mono-nerd ttf-fira-mono ttf-firacode-nerd ttf-liberation \
ttf-opensans ttf-roboto woff2-font-awesome ttf-jetbrains-mono-nerd

echo "[ARCH-INSTALL-SCRIPT] Installing web browsers and multimedia applications."
pacman -Syu \
chromium firefox vlc discord podman podman-desktop qbittorrent

echo "[ARCH-INSTALL-SCRIPT] Creating user $username."
useradd -m -G wheel,users -s /usr/bin/zsh "$username"
echo "$username:$userpass" | chpasswd

echo "Enabling sudo."
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[ARCH-INSTALL-SCRIPT] Configuring and enabling services."
printf "[device]\nwifi.backend=iwd\n" > /etc/NetworkManager/conf.d/wifi_backend.conf
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable acpid

echo "[ARCH-INSTALL-SCRIPT] Configuring snapshots."
umount /.snapshots
rm -rf /.snapshots
snapper --no-dbus -c root create-config /
rm -rf /.snapshots
mkdir /.snapshots

mount -a
chmod 750 /.snapshots
chown :wheel /.snapshots
snapper --no-dbus -c root set-config "TIMELINE_LIMIT_HOURLY=0" "TIMELINE_LIMIT_DAILY=7" "TIMELINE_LIMIT_WEEKLY=0" "TIMELINE_LIMIT_MONTHLY=0" "TIMELINE_LIMIT_YEARLY=0"

echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfsd
EOF

echo "[ARCH-INSTALL-SCRIPT] Installation complete. You can reboot now."