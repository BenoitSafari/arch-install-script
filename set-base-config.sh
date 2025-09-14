#!/bin/bash

HOSTNAME="$1"
TIMEZONE="$2"
LOCALE="$3"
LANG="$4"

echo "Configuring base system..."

ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
hwclock --systohc
echo "$LOCALE" >> /etc/locale.gen
echo "LANG=$LANG" > /etc/locale.conf
locale-gen

echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
127.0.0.1 $HOSTNAME.com
127.0.0.1 $HOSTNAME.fr
127.0.0.1 $HOSTNAME.de
127.0.0.1 $HOSTNAME.lu
127.0.0.1 $HOSTNAME.be
127.0.0.1 $HOSTNAME.ch
EOF

systemctl enable NetworkManager
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
