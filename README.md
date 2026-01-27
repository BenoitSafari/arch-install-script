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

#### Start SSH and connect from another computer *(optional)*
```
passwd
ip addr
systemctl start sshd
```
Use the output to connect from another machine using ssh.
```
scp ./install-arch.sh root@[ip]:/root/
ssh root@[ip]
```

#### Clone the repository and execute the script

```
git clone https://github.com/BenoitSafari/arch-install-script.git
chmod +x install-arch.sh
bash install-arch.sh
```