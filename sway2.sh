#!/bin/sh

# Archlinux sway windows manager minimal installation.
# Wireless network is required.
# Encrypt system with luks.

# Step 2: Download and setup system.

set -e

ln -s /hostlvm /run/lvm || true

timedatectl set-ntp true

pacman -Syyu  --noconfirm
pacman -S linux linux-firmware intel-ucode lvm2 grub net-tools inetutils man \
    iwd gnu-free-fonts sway alacritty firefox openssh git --noconfirm

ln -sf /usr/share/zoneinfo/Europe/Kiev /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo 'LANG="en_US.UTF-8"' > /etc/locale.conf
locale-gen
echo pc >> /etc/hostname
passwd

printf "Enter user name: "
read -r username
useradd -m -g users -G wheel,storage,power -s /bin/zsh "$username"
passwd "$username"

mkdir -p /boot/loader/entries
echo 'initrd /intel-ucode.img' > /boot/loader/entries/arch.conf
echo 'initrd /initramfs-linux.img' >> /boot/loader/entries/arch.conf

update_grup() {
    sed -i -E "s/(^$$1)\"(.*)\"/\1\"cryptdevice=UUID=$(cat /crypto_partition):cryptlvm root=\/dev\/SysVolGroup\/root \2\"/g" /etc/default/grub
}

update_grup "GRUB_CMDLINE_LINUX_DEFAULT="
update_grup "GRUB_CMDLINE_LINUX="
rm -rf /crypto_partition

grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
sed -i -E 's/(^HOOKS.*)block(.*)/\1block encrypt lvm2 keymap\2/g' /etc/mkinitcpio.conf
mkinitcpio -p linux

wlan_iface="$(iwctl device list | tail -n2 | head -n1 | awk '{print $1}')"
cat <<EOF > /etc/systemd/network/25-wireless.network
[Match]
Name=$wlan_iface

[Network]
DHCP=yes
IgnoreCarrierLoss=3s
EOF

user_home="/home/$username"
sway_config_dir="$user_home/.config/sway"
mkdir -p "$sway_config_dir"
cp /etc/sway/config "$sway_config_dir"
sed -i -E "s/(set \$term)\s+(\w+)/\1 alacritty/" "$sway_config_dir"/config
chown "$username":users -R "$user_home"/.config

cat <<EOF >> "$user_home"/.zprofile
[ "$(tty)" = "/dev/tty1" ] && [ -x "$(command -v sway)" ] && exec sway
EOF
chown "$username":users "$user_home"/.zprofile

systemctl enable systemd-networkd.service
systemctl enable systemd-resolved.service
systemctl enable iwd.service

echo "Done. Please unmount and reboot."
