# Instructions
Follow the provided instruction to use this script.

## Arch installation
*This **README** assumes that you've already booted into the **archiso image** and want to install it alongside Windows*
### Prepare installation
#### Setup keyboard and network
```
loadkeys fr-latin9
```
*Skip this part if connected with LAN*
```
iwctl --passphrase [password] station wlan0 connect [network]
ping -c4 www.archlinux.org
```

#### Start SSH and connect from another computer *(optional)*
```
passwd
ip addr
systemctl start sshd
```
Use the output to connect from another machine using ssh.
```
scp ./arch-install.sh root@[ip]:/root/
ssh root@[ip]
```

#### Clone the repository and execute the script

```
git clone https://github.com/BenoitSafari/arch-install-script.git
cd ./arch-install-script
chmod +x arch-i*.sh
bash arch-install.sh
# Or, with arguments
bash arch-install.sh --part-efi=/dev/nvme0n1p1 --part-root=/dev/nvme0n1p6 --part-swap=/dev/nvme0n1p5 --format-efi=0
```