#!/bin/bash

#
# Copy bin
# (deprecated)
#if [ "$S_ADD_GRUBCFG" != "text" ]; then
#  sudo \cp -r ./package/grub/bin/grub-mkconfig /usr/local/bin
#  sudo chmod +x /usr/local/bin/grub-mkconfig
#fi
# Engage new bin in shell
#PATH=$PATH

#
# Get res and check splash file
SCREEN_RES=""
SPLASH_IMG="/usr/share/wallpapers/splash.png"
LASTDISP=$(basename -- "$(compgen -G "/usr/share/archw/LDISP_*")")
if [ -n "$LASTDISP" ]; then
  SCREEN_RES="$(echo $LASTDISP | cut -d '_' -f3)"
fi

GRUBCFG_CMDLINE="quiet splash rd.systemd.show_status=auto loglevel=3 rd.udev.log_priority=3 vt.global_cursor_default=0"
GRUBCFG_TIMEOUT=3
GRUBCFG_STYLE=menu

if [ "$S_ADD_GRUBCFG" == "text" ]; then
  GRUBCFG_CMDLINE="splash"
elif [ "$S_ADD_GRUBCFG" == "menu" ]; then
  GRUBCFG_TIMEOUT=3
elif [ "$S_ADD_GRUBCFG" == "silent" ]; then
  GRUBCFG_TIMEOUT=1
  GRUBCFG_STYLE=hidden
fi

#
# Set config
sudo sed -i -E \
"s:^[#\s]*(GRUB_TIMEOUT=).*:\1${GRUBCFG_TIMEOUT}:; \
s:^[#\s]*(GRUB_DISTRIBUTOR=).*:\1\"${S_BOOTLOADER_ID}\":; \
s:^[#\s]*(GRUB_CMDLINE_LINUX_DEFAULT=).*:\1\"${GRUBCFG_CMDLINE}\":; \
s:^[#\s]*(GRUB_TIMEOUT_STYLE=).*:\1${GRUBCFG_STYLE}:;
s:^[#\s]*(GRUB_GFXMODE=).*:\1${SCREEN_RES},auto:;
s:^[#\s]*(GRUB_COLOR_NORMAL=).*:\1\"magenta/black\":; \
s:^[#\s]*(GRUB_COLOR_HIGHLIGHT=).*:\1\"light-magenta/magenta\":; \
s:^[#\s]*(GRUB_BACKGROUND=).*:\1\"${SPLASH_IMG}\":" \
/etc/default/grub

#
# Set grub
GRUB_CONTENT_REBUILD=1
install_grub
unset $GRUB_CONTENT_REBUILD
