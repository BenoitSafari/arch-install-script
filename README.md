# Instructions
Follow the provided instruction to use this script.

## Arch installation
*This **README** assumes that you've already booted into the **archiso image** and want to install it alongside Windows*
### Prepare installation
#### Setup keyboard and network
```
loadkeys fr-latin9 #
```
*Skip this part if connected with LAN*
```
iwctl --passphrase [password] station wlan0 connect [network]
ping -c4 www.archlinux.org
```

#### Setup SSH and connect from another computer *(optional)*
**ENSURE THIS IS DISABLED ONCE THE SYSTEM IS INSTALLED!**
```
passwd
ip addr
systemctl start sshd
systemctl disable sshd
```
Use the output to connect from another machine using ssh.
```
ssh root@[ip]
```

### Setup partitions
*We will setup a `btrfs` partition for backup strategy.*

Ensure system time is accurate.
```
timedatectl set-ntp true
```

You can use the following commands for partition setup:
|cmd|purpose|
|---|---|
|`lsblk`|List all available disks|
|`parted /dev/[disk] print free`|Get detailed disk informations|
|`gdisk /dev/[disk]`|Launch partition tool|

You will need:
- a `swap` partition *(type 19)* **that does not exceed the size of your RAM**.
- a `Linux filesystem` partition *(default type)*.


#### Format partitions
```
# Swap
mkswap /dev/[disk]p[swap-part]
swapon /dev/[disk]p[swap-part]

# OS
mkfs.btrfs -f /dev/[disk]p[os-part]

```

#### Create subvolumes
```
# Mount the OS partition
mount /dev/[disk]p[os-part] /mnt

# Create the subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots

umount -R /mnt

# Remount with compression
mount -o compress=zstd,subvol=@ /dev/[disk]p[os-part] /mnt

# Create directories
mkdir -p /mnt/{home,boot,.snapshots}

mount -o compress=zstd,subvol=@home /dev/[disk]p[os-part] /mnt/home
mount -o compress=zstd,subvol=@snapshots /dev/[disk]p[os-part] /mnt/.snapshots

# Mount the windows EFI *(for dual boot setup only)*
mount /dev/[windows-EFI-part] /mnt/boot
```

### Bootstrap
#### Installation

```
pacstrap /mnt base base-devel linux linux-firmware intel-ucode amd-ucode sudo rsync neovim reflector
```

#### Generate fstab
```
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
```

#### Sync and mirrors
```
timedatectl set-ntp true

reflector --country France --protocol https --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
```

### Setup OS environment
chroot into the system
```
arch-chroot /mnt
```

#### Localization
```
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

# OS in english
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=fr-latin9" > /etc/vconsole.conf

# French format for dates, metrics...
echo "LC_TIME=fr_FR.UTF-8" >> /etc/locale.conf
echo "LC_PAPER=fr_FR.UTF-8" >> /etc/locale.conf
echo "LC_MEASUREMENT=fr_FR.UTF-8" >> /etc/locale.conf
```

#### Host
```
# Set hostname and localhost
echo "arch" >> /etc/hostname

# Update hosts file with localhost
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts

# ...And custom addresses if needed
echo "127.0.0.1 dev.localhost.com" >> /etc/hosts
echo "127.0.0.1 dev.localhost.io" >> /etc/hosts
echo "127.0.0.1 dev.localhost.fr" >> /etc/hosts
echo "127.0.0.1 dev.localhost.de" >> /etc/hosts
echo "127.0.0.1 dev.localhost.ch" >> /etc/hosts
echo "127.0.0.1 dev.localhost.be" >> /etc/hosts
echo "127.0.0.1 dev.localhost.lu" >> /etc/hosts
```

### Install base packages
```
# Base packages
pacman -Syu \
git kitty acpid base-devel fastfetch btrfs-progs cifs-utils zsh bat dmidecode dust exfat-utils ffmpeg fontconfig gvfs-mtp gvfs-smb inetutils iwd jq less libqalculate llvm man nss-mdns pacman-contrib playerctl plocate poppler resvg ripgrep tldr tree-sitter-cli ufw uwsm unzip p7zip virt-manager wf-recorder whois wireless-regdb xmlstarlet grim fzf networkmanager pipewire-pulse wireplumber playerctl bluez blueman snapper snap-pac grub-btrfs os-prober nano efibootmgr

# Printer utilities
pacman -Syu \
system-config-printer cups cups-browsed cups-filters cups-pdf

# Hyprland (...and desktop related)
pacman -Syu \
hyprland hypridle hyprlock hyprpicker hyprlauncher hyprshot hyprsunset hyprland-guiutils xdg-desktop-portal-hyprland xdg-desktop-portal-gtk waybar mako swaybg swayosd slurp btop yazi brightnessctl ffmpegthumbnailer gnome-calculator gnome-keyring gnome-themes-extra polkit-gnome nautilus imv sddm

# Dev stuff
pacman -Syu \
clang

# Web
pacman -Syu \
chromium firefox

# Multimedia
pacman -Syu \
vlc
  
# Fonts
pacman -Syu \
noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra ttf-bitstream-vera ttf-cascadia-mono-nerd ttf-fira-mono ttf-firacode-nerd ttf-liberation ttf-opensans ttf-roboto woff2-font-awesome ttf-jetbrains-mono-nerd
```

### Setup admin and users
```
# Root password
passwd

# Create user
useradd -m -G wheel,users -s /usr/bin/zsh BenoitSafari
passwd BenoitSafari

# Activate wheel
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
```

### Enable services

```
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups
systemctl enable sshd
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable acpid
systemctl enable libvirtd
systemctl enable sddm
```

### Setup snapshots and windows dualboot
```
snapper --no-dbus -c root create-config /
snapper --no-dbus -c root set-config "TIMELINE_LIMIT_HOURLY=0" "TIMELINE_LIMIT_DAILY=7" "TIMELINE_LIMIT_WEEKLY=0" "TIMELINE_LIMIT_MONTHLY=0" "TIMELINE_LIMIT_YEARLY=0"

btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a

chmod 750 /.snapshots
chown :wheel /.snapshots

echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
mkdir -p /boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer
systemctl enable grub-btrfsd
```

### Setup user environment

```
localectl set-keymap fr-latin9
localectl set-x11-keymap fr
```

pinta source-git