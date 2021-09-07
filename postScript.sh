#!/bin/bash
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
echo scriptvege
