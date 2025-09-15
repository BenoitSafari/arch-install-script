#!/bin/bash

ROOT_PASS=$1
USERNAME=$2
USER_PASS=$3

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd

sed -n '1,200p' /etc/sudoers | grep -q '^%wheel' || echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
