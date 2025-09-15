#!/bin/bash
set -euo pipefail

WIFI_SSID=""
WIFI_PASSWORD=""

USERNAME=""
USER_PASS=""
EFI_DISK=""
MOUNT_POINT="/mnt"
HOSTNAME="archlinux"
TIMEZONE="Europe/Paris"
LOCALE="en_US.UTF-8 UTF-8"
LANG="en_US.UTF-8"

usage() {
    echo "  --efi       EFI disk to use (e.g., /dev/sda1)"
    echo "  --hostname  Hostname for the system (default: archlinux)"
    echo "  --usr       Username for the new user"
    echo "  --psw       Password for the new user (will be root password as well)"
    echo "  --wifi-psw  Wi-Fi password (if connecting to Wi-Fi)"
    echo "  --wifi-ssid Wi-Fi SSID (if connecting to Wi-Fi)"
    exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --usr) USERNAME="$2"; shift ;;
    --psw) USER_PASS="$2"; shift ;;
    --efi) EFI_DISK="$2"; shift ;;
    --hostname) HOSTNAME="$2"; shift ;;
    --wifi-psw) WIFI_PASSWORD="$2"; shift ;;
    --wifi-ssid) WIFI_SSID="$2"; shift ;;
    *) usage ;;
  esac
  shift
done

if [[ -z "$USERNAME" || -z "$USER_PASS" || -z "$EFI_DISK" ]]; then
    echo "Error: Missing required arguments."
    [[ -z "$USERNAME" ]] && echo "  --usr USERNAME is required"
    [[ -z "$USER_PASS" ]] && echo "  --psw USER_PASS is required"
    [[ -z "$EFI_DISK" ]] && echo "  --efi EFI_DISK is required"
    exit 1
fi

echo "Starting Arch Linux installation..."
echo "Installing base system..."
mkdir -p "$MOUNT_POINT/boot"
mount "$EFI_DISK" "$MOUNT_POINT/boot"

systemctl start NetworkManager
if [ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASSWORD" ]; then
    echo "Connecting to Wi-Fi network '$WIFI_SSID'..."
    nmcli device wifi connect "$WIFI_SSID" password "$WIFI_PASSWORD"
fi

pacstrap "$MOUNT_POINT" \
    base linux linux-lts linux-firmware networkmanager grub efibootmgr \
    nano vim sudo btrfs-progs sof-firmware alsa-firmware intel-ucode amd-ucode \
    bash zsh git wget curl openssh rsync openvpn \

genfstab -U "$MOUNT_POINT" > "$MOUNT_POINT/etc/fstab"

cp set-*.sh "$MOUNT_POINT/"
chmod +x "$MOUNT_POINT"/set-*.sh

arch-chroot "$MOUNT_POINT" /bin/bash -c \
    "/set-base-config.sh '$HOSTNAME' '$TIMEZONE' '$LOCALE' '$LANG'"
arch-chroot "$MOUNT_POINT" /bin/bash -c \
    "/set-base-user.sh '$USER_PASS' '$USERNAME' '$USER_PASS'"
