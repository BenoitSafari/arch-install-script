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
scp ./install-arch.sh root@[ip]:/root/
ssh root@[ip]
```

Execute the script.
