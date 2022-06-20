#!/usr/bin/env bash

# Copyright 2022 Elijah Danko

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Archlinux installation over luks password encryption.
# Wireless network is required.

set -euo pipefail

script_name="$(readlink -f "${BASH_SOURCE[0]}")"
script_dir="$(dirname "$script_name")"

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
# Ignore shellcheck warn (Don't use ls...). It's workaround: taking symlink uuid
# info by a device name pattern.
ls -l /dev/disk/by-uuid | grep sda2 | awk '{print $9}' > /mnt/crypto_partition

mkdir /mnt/hostlvm
mount --bind /run/lvm /mnt/hostlvm
cp "$script_dir"/*env.sh /mnt/
arch-chroot /mnt
