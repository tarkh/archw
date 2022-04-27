#!/bin/bash

#
# Set previous GRUB install custom options
PCV_GRUB_FONT=$(cat /etc/default/grub | grep GRUB_FONT)

# Remove grub
sudo pacman --noconfirm -Rns grub

#
# Try to install prebuilt version to save overall install time
# if it fails, build and install from aur
cd $V_PB
curl -LO ${V_RPB}/grub-silent-2.06-5-x86_64.pkg.tar.zst
if ! sudo pacman --noconfirm -U grub-silent-2.06-5-x86_64.pkg.tar.zst; then
  # Build and install grub-silent
  yay --noconfirm -S grub-silent
fi
cd $S_PKG

#
# Get res and check splash file
SCREEN_RES=""
SPLASH_IMG="/usr/share/wallpapers/splash.png"
LASTDISP=$(basename -- "$(compgen -G "/usr/share/archw/LDISP_*")")
if [ -n "$LASTDISP" ]; then
  SCREEN_RES="$(echo $LASTDISP | cut -d '_' -f3)"
fi

GRUBCFG_TIMEOUT=1
GRUBCFG_HIDDENTIMEOUT=1
GRUBCFG_DISABLE="#"

if [ "$S_ADD_GRUBCFG" == "text" ] || [ "$S_ADD_GRUBCFG" == "menu" ]; then
  GRUBCFG_TIMEOUT=3
elif [ "$S_ADD_GRUBCFG" == "silent" ]; then
  GRUBCFG_DISABLE=""
  #GRUBCFG_TIMEOUT=0
fi

#
# Set config
sudo sed -i -E \
"s:^[#\s]*(GRUB_TIMEOUT=).*:\1${GRUBCFG_TIMEOUT}:; \
s:^[#\s]*(GRUB_DISTRIBUTOR=).*:\1\"${S_BOOTLOADER_ID}\":; \
s:^[#\s]*(GRUB_HIDDEN_TIMEOUT=).*:${GRUBCFG_DISABLE}\1${GRUBCFG_HIDDENTIMEOUT}:; \
s:^[#\s]*(GRUB_HIDDEN_TIMEOUT_QUIET=).*:${GRUBCFG_DISABLE}\1true:;
s:^[#\s]*(GRUB_GFXMODE=).*:\1${SCREEN_RES},auto:;
s:^[#\s]*(GRUB_COLOR_NORMAL=).*:\1\"magenta/black\":; \
s:^[#\s]*(GRUB_COLOR_HIGHLIGHT=).*:\1\"light-magenta/magenta\":; \
s:^[#\s]*(GRUB_BACKGROUND=).*:\1\"${SPLASH_IMG}\":" \
/etc/default/grub

#
# If GRUB_FONT
if [ -n "$PCV_GRUB_FONT" ]; then
  sudo bash -c "cat >> /etc/default/grub" << EOL
# Custom font
$PCV_GRUB_FONT
EOL
fi

#
# Set grub
if [ -n "$ARCHW_PKG_INST" ]; then
  GRUB_CONTENT_REBUILD=1
  install_grub
  unset $GRUB_CONTENT_REBUILD
fi
