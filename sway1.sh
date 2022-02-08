#!/bin/sh

# Archlinux sway windows manager minimal installation.
# Wireless network is required.
# Encrypt system with luks.
#
# Step 1. Preapre a hard drive.

set -e

ip link
# iwctl device list
# iwctl station <device> connect <ssid>

timedatectl set-ntp true
pacman -Syy --noconfirm

# Clean up previous partition
dd if=/dev/zero of=/dev/sda bs=4M count=1
parted /dev/sda --script mklabel msdos
parted /dev/sda --script mkpart primary fat32 1MiB 2GiB
parted /dev/sda --script set 1 boot on
parted -a optimal /dev/sda --script mkpart primary ext4 2GiB 100%
mkfs.fat -F32 /dev/sda1

cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 cryptlvm
pvcreate /dev/mapper/cryptlvm
vgcreate SysVolGroup /dev/mapper/cryptlvm

lvcreate -L 16G SysVolGroup -n swap
lvcreate -l 100%FREE SysVolGroup -n root

mkfs.ext4 /dev/SysVolGroup/root
mkswap /dev/SysVolGroup/swap

mount /dev/SysVolGroup/root /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
swapon /dev/SysVolGroup/swap

pacstrap /mnt base base-devel neovim zsh
genfstab -p -U /mnt > /mnt/etc/fstab

# Save wireless connection settings.
cp -R /var/lib/iwd /mnt/var/lib/iwd

# Allow to use sudo.
sed -i -E 's/^#\s+%wheel\s+ALL(.*)/%wheel ALL\1/g' /mnt/etc/sudoers
# Save partition for further luks setup.
ls -l /dev/disk/by-uuid | grep sda2 | awk '{print $9}' > /mnt/crypto_partition

mkdir /mnt/hostlvm
mount --bind /run/lvm /mnt/hostlvm
arch-chroot /mnt
