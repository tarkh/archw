#!/bin/bash

# Remove grub
sudo pacman --noconfirm -Rns grub

#
# Try to install prebuilt version
# if fails, build and install
if ! sudo pacman --noconfirm -U ./package/grub-silent/prebuilt/grub-silent-2.06-2-x86_64.pkg.tar.zst; then
  # Build and install grub-silent
  yay --noconfirm -S grub-silent
fi

#
# TMP typo fix
sudo sed -i -E \
"s:^\s+(EOF.*):\1:" \
/etc/grub.d/10_linux

#
# Get res and check splash file
SCREEN_RES=""
SPLASH_IMG="/usr/share/wallpapers/splash.png"
LASTDISP=$(basename -- "$(compgen -G "/usr/share/archw/LDISP_*")")
if [ -n "$LASTDISP" ]; then
  SCREEN_RES="$(echo $LASTDISP | cut -d '_' -f3),"
fi

GRUBCFG_TIMEOUT=1
GRUBCFG_HIDDENTIMEOUT=1
GRUBCFG_DISABLE="#"

if [ "$S_ADD_GRUBCFG" == "text" ] || [ "$S_ADD_GRUBCFG" == "menu" ]; then
  GRUBCFG_TIMEOUT=3
elif [ "$S_ADD_GRUBCFG" == "silent" ]; then
  GRUBCFG_DISABLE=""
fi

#
# Set config
sudo sed -i -E \
"s:^[#\s]*(GRUB_TIMEOUT=).*:\1${GRUBCFG_TIMEOUT}:; \
s:^[#\s]*(GRUB_DISTRIBUTOR=).*:\1\"${S_BOOTLOADER_ID}\":; \
s:^[#\s]*(GRUB_HIDDEN_TIMEOUT=).*:${GRUBCFG_DISABLE}\1${GRUBCFG_HIDDENTIMEOUT}:; \
s:^[#\s]*(GRUB_HIDDEN_TIMEOUT_QUIET=).*:${GRUBCFG_DISABLE}\1true:;
s:^[#\s]*(GRUB_GFXMODE=)(.*):\1${SCREEN_RES},\2:;
s:^[#\s]*(GRUB_COLOR_NORMAL=).*:\1\"magenta/black\":; \
s:^[#\s]*(GRUB_COLOR_HIGHLIGHT=).*:\1\"light-magenta/magenta\":; \
s:^[#\s]*(GRUB_BACKGROUND=).*:\1\"${SPLASH_IMG}\":" \
/etc/default/grub

#
# Set grub
install_grub
