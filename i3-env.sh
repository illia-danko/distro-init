#!/usr/bin/env bash

# Copyright 2022 Illia Danko

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

# Archlinux i3 installation.
# Wireless network is required.
# Encrypt system with luks.

# Step 2: Download and setup system.

set -euo pipefail

script_name="$(readlink -f "${BASH_SOURCE[0]}")"

ln -s /hostlvm /run/lvm || true

pacman -Syyu  --noconfirm
pacman -S linux linux-firmware intel-ucode xorg-xinit xorg-server xterm lvm2 grub man unzip zip firefox \
    openssh git networkmanager nm-connection-editor gnu-free-fonts polkit i3 alacritty \
    network-manager-applet wpa_supplicant bluez bluez-utils --noconfirm

ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
locale-gen
echo pc >> /etc/hostname
echo "Root password: "
passwd

printf "Enter user name: "
read -r username
useradd -m -g users -G wheel,storage,power -s /bin/zsh "$username"
echo "$username password: "
passwd "$username"

mkdir -p /boot/loader/entries
echo 'initrd /intel-ucode.img' > /boot/loader/entries/arch.conf
echo 'initrd /initramfs-linux.img' >> /boot/loader/entries/arch.conf

update_grup() {
    sed -i -E "s/(^$1)\"(.*)\"/\1\"cryptdevice=UUID=$(cat /crypto_partition):cryptlvm root=\/dev\/SysVolGroup\/root \2\"/g" /etc/default/grub
}

update_grup "GRUB_CMDLINE_LINUX_DEFAULT="
update_grup "GRUB_CMDLINE_LINUX="
rm -rf /crypto_partition

grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
sed -i -E 's/(^HOOKS.*)block(.*)/\1block encrypt lvm2 keymap\2/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

user_home="/home/$username"
config_dir="$user_home/.config/i3"
mkdir -p "$config_dir"
cp /etc/i3/config "$config_dir"
# Ignore shellcheck "Expressions don't expand in single quotes" warn.
# $term is a valid string.
sed -i -E 's/(set \$term)\s+\w+/\1 alacritty/' "$config_dir"/config
chown "$username":users -R "$user_home"/.config

cat <<EOF >> "$user_home"/.xinitrc
[ "$(tty)" = "/dev/tty1" ] && [ -x "$(command -v i3)" ] && startx /usr/bin/i3
EOF

systemctl enable bluetooth.service
systemctl enable NetworkManager.service

rm -rf "$script_name"
echo "Done. Please unmount and reboot."
