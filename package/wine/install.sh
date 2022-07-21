#!/bin/bash

#
# Enable multilib
sudo sed -i -E \
"/\[multilib\]/,/Include/"'s/^#//' \
/etc/pacman.conf
sudo pacman -Syyu

#
# Get WINE and common packages
sudo pacman --noconfirm -S --needed \
wine-staging wine-mono wine-gecko giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls \
mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error \
lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo \
sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama \
ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 \
lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader \
samba

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
mkdir -p ${WINEPREFIX:-~/.wine}/drive_c/windows/Fonts
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
#sudo systemctl enable start-binfmt.service
