# Instructions
Follow the provided instruction to use this script.

## Create the installation media
Install `archiso` using the following command:
```
sudo pacman -S archiso
```

Build the iso file
```
mkarchiso -v -r -w ./tmp ./iso/
```

## Partitioning
Use `cfdisk` for easy partioning. Select `gpt` on first prompt and create the following volumes:

- EFI formatted as FAT32 512Mb
- Swap partition (should be `>=` to RAM)
- Data partition formatted as EXT4 xxGb (used for personnal files)
- The root partition formatted as BTRFS with the rest of the disk

Write the changes you've made and use the following commands to format the partitions.
```bash
mkfs.fat -F 32 /dev/<EFI partition>
mkswap /dev/<Swap partition>
mkfs.ext4 /dev/sda3/<Data partition>
mkfs.btrfs /dev/sda4<Root partition>
```
