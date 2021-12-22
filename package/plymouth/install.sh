#!/bin/bash

#
# Off if exist
sudo systemctl disable lightdm-plymouth.service > /dev/null 2>&1
sudo systemctl disable lightdm.service > /dev/null 2>&1

#
# Install package
yay --noconfirm -S plymouth-git

#
# Add hook
add_system_hook "sd-plymouth" "" "systemd"

#
# Add theme
sudo cp -r ./package/plymouth/theme/archw /usr/share/plymouth/themes/
# Add archw logo
sudo convert ./package/wallpapers/archw-logo-src.png -resize "128x128" /usr/share/plymouth/themes/archw/watermark.png
# Set theme
sudo sed -i -E \
"s:\s*(Theme=).*:\1archw:" \
/etc/plymouth/plymouthd.conf

#
# Alter services
sudo sed -i -E \
"s:\s*(ExecStart=.*):\1 --retain-splash:" \
/usr/lib/systemd/system/plymouth-quit.service

sudo sed -i -E \
"s:\s*(ExecStart=.*):\1 --tty=tty${S_SYS_TTY}:" \
/usr/lib/systemd/system/plymouth-start.service

sudo systemctl daemon-reload

#
# On
sudo systemctl enable lightdm-plymouth.service

#
# Adjust GRUB
#sudo sed -i -E \
#"s:\s*(GRUB_BACKGROUND=.*):#\1:" \
#/etc/default/grub

#
# Rebuild GRUB and kernel
install_grub
