#!/bin/bash

#
# Enable multilib
sudo sed -i -E \
"/\[multilib\]/,/Include/"'s/^#//' \
/etc/pacman.conf
sudo pacman -Syyu

#
# Install steam
sudo pacman --noconfirm -S \
wine wine-gecko wine-mono \
lib32-mesa \
lib32-libpulse \
lib32-mpg123 lib32-giflib lib32-libpng lib32-gnutls lib32-gst-plugins-base lib32-gst-plugins-good \
samba

#
# Optional
#yay --noconfirm -S lib32-gst-plugins-bad lib32-gst-plugins-ugly

#
# Activate Vulcan
# ***
# DXVK overrides the DirectX 10 and 11 DLLs,
# which may be considered cheating in online
# multiplayer games, and may get your account
# banned. Use at your own risk!
# ***
#
# Install DXVK
#yay --noconfirm -S dxvk-bin
#
# Enable DXVK in Wine
#setup_dxvk install
#
# Disable DXVK in Wine
#setup_dxvk uninstall

#
# Fonts
cd ${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts && for i in /usr/share/fonts/**/*.{ttf,otf}; do ln -s "$i" ; done

#
# Font smoothing
cat << EOF > /tmp/fontsmoothing
REGEDIT4

[HKEY_CURRENT_USER\Control Panel\Desktop]
"FontSmoothing"="2"
"FontSmoothingOrientation"=dword:00000001
"FontSmoothingType"=dword:00000002
"FontSmoothingGamma"=dword:00000578
EOF

WINE=${WINE:-wine} WINEPREFIX=${WINEPREFIX:-$HOME/.wine} $WINE regedit /tmp/fontsmoothing 2> /dev/null

#
# Start services
sudo systemctl enable start-binfmt.service
