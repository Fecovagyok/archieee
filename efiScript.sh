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

q_if_empty() {
  if [[ -z "$1" ]]; then
    echo Empty variable $2
    exit 1
  fi
}

hostname="VirtualArch"
user="tumpek"
password="" 

q_if_empty "$password" password

rootdevice=""
swapdevice=""
bootdevice=""

# logging
exec 1> >(tee "stdout.log")
exec 2> >(tee "stderr.log")

# formatting boot device
mkfs.fat -F 32 "${bootdevice}"

# formatting the root device
mkfs.ext4 "${rootdevice}"

# formatting the swapdevice
mkswap "${swapdevice}"

# mounting devices
swapon "${swapdevice}"
mount "${rootdevice}" /mnt
mkdir /mnt/esp
mount "${bootdevice}" /mnt/esp

# installing base package
pacstrap /mnt base linux linux-firmware vim nano

# generating fstab
genfstab -U /mnt >> /mnt/etc/fstab

# setting clock and timezone
ln -sf /mnt/usr/share/zoneinfo/Europe/Budapest /mnt/etc/localtime
arch-chroot /mnt hwclock --systohc

# uncommenting locales
sed -i 's/#hu_HU.UTF-8 UTF-8/hu_HU.UTF-8 UTF-8/ ; s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
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


arch-chroot /mnt << EOF
locale-gen
groupadd autologin
useradd -m -G wheel,audio,video,storage,autologin "$user"
pacman -Syu --noconfirm
pacman -S sudo grub efibootmgr networkmanager --needed --noconfirm
systemctl enable NetworkManager
grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB --removable --recheck
sudo sed -i 's/loglevel=3 quiet/loglevel=3/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
EDITOR="sed -i 's/# %wheel ALL=(ALL) ALL/ %wheel ALL=(ALL) ALL/'" visudo
sudo ln -s /usr/bin/vim /usr/bin/vi
EOF

arch-chroot /mnt passwd "${user}" << EOF
$password
$password
EOF

# Installing more packages
packages=( $(cat packages) )

# Assumes that home directory is under /home
arch-chroot /mnt << EOF
pacman -S ${packages[@]} --noconfirm --needed
mkdir /home/$user/aatmen
cd /home/$user/aatmen
wget 192.168.0.10:8080/storage/enRoot.zip
unzip enRoot.zip
cp -r enRoot/etc/* /etc/
chown -R tumpek enRoot/home/$user --preserve
cp -r enRoot/home/* /home/
cd ..
rm -r aatmen
EOF

echo script vege
