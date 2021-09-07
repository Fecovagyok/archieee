#!/bin/bash

# This is one my first scrpits
# This script should be run after the partitioning of the disks
# The things you need to run before would be probably
# loadkeys hu
# timedatectl set-ntp true
# then partition
# then write the device path into a variables
# then run the script

# logginh staff i read on the internet
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

hostname="VirtualArch"
user="tumpek"
password=""

# logging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")


loadkeys hu
timedatectl set-ntp true
fdisk /dev/sda << EOF
o
n
p
1
2048
+18G
n
p
2


t
2
82
a
1
w
EOF

rootdevice="/dev/sda1"
swapdevice="/dev/sda2"

# formatting the root device
mkfs.ext4 "${rootdevice}"

# formatting the swapdevice
mkswap "${swapdevice}"

# mounting devices
swapon "${swapdevice}"
mount "${rootdevice}" /mnt

# installing base package
pacstrap /mnt base linux linux-firmware vim nano

# generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

# setting clock and timezone
ln -sf /mnt/usr/share/zoneinfo/Europe/Budapest /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

# uncommenting locales
sed -i 's/#hu_HU.UTF-8 UTF-8/hu_HU.UTF-8 UTF-8/ ; s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8 UTF-8" > /mnt/etc/locale.conf
cat >> /mnt/etc/vconsole.conf << EOF
KEYMAP=hu
FONT=lat2-16
FONT_MAP=8859-2
EOF
echo "${hostname}" > /mnt/etc/hostname
cat > /mnt/etc/hosts << EOF
127.0.0.1	localhost
::1		localhost
127.0.1.1	$hostname.localdomain	$hostname
EOF
arch-chroot /mnt passwd << EOF
$password
$password
EOF

packages = ""

arch-chroot /mnt << EOF
locale-gen
groupadd autologin
useradd -m -G wheel,audio,video,storage,autologin "$user"
pacman -S sudo grub networkmanager $packages --needed --noconfirm
systemctl enable NetworkManager
grub-install --target=i386-pc /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
EDITOR="sed -i 's/# %wheel ALL=(ALL) ALL/ %wheel ALL=(ALL) ALL/'" visudo
EOF

arch-chroot /mnt passwd "${user}" << EOF
$password
$password
EOF
echo script vege
