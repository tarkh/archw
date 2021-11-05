#!/bin/bash

#
# Install dmenu
ProgressBar
if [ -n "$S_ADD_DMENU" ]; then
. ./package/dmenu/install.sh
fi

#
# Install rofi
ProgressBar
if [ -n "$S_ADD_ROFI" ]; then
. ./package/rofi/install.sh
fi

#
# Time sync
ProgressBar
if [ -n "$S_ADD_NTP" ]; then
. ./package/ntp/install.sh
fi

#
# Xrandr-extend
ProgressBar
if [ -n "$S_ADD_REDSHIFT" ]; then
. ./package/redshift/install.sh
fi

#
# Power management
ProgressBar
if [ -n "$S_ADD_TLP" ]; then
. ./package/tlp/install.sh
fi

#
# System monitor
ProgressBar
if [ -n "$S_ADD_BTOP" ]; then
. ./package/btop/install.sh
fi

#
# Grub silent
ProgressBar
if [ -n "$S_ADD_ACPILIGHT" ]; then
. ./package/acpilight/install.sh
fi

#
# Key service
ProgressBar
if [ -n "$S_ADD_SXHKD" ]; then
. ./package/sxhkd/install.sh
fi

#
# Trackpad
ProgressBar
if [ -n "$S_ADD_MTRACK" ]; then
. ./package/mtrack/install.sh
fi

#
# Mouse wheel
ProgressBar
if [ -n "$S_ADD_IMWHEEL" ]; then
. ./package/imwheel/install.sh
fi

#
# Mouse wheel
ProgressBar
if [ -n "$S_ADD_DUNST" ]; then
. ./package/dunst/install.sh
fi

#
# Install nemo
ProgressBar
if [ -n "$S_ADD_NEMO" ]; then
. ./package/nemo/install.sh
fi

#
# Install MC
ProgressBar
if [ -n "$S_ADD_MC" ]; then
. ./package/mc/install.sh
fi

#
# Pix image viewer
ProgressBar
if [ -n "$S_ADD_GPICVIEW" ]; then
. ./package/gpicview/install.sh
fi

#
# QEMU
ProgressBar
if [ -n "$S_ADD_QEMU" ]; then
. ./package/qemu/install.sh
fi

#
# Virtualbox
ProgressBar
if [ -n "$S_ADD_VIRTUALBOX" ]; then
. ./package/virtualbox/install.sh
fi

#
# VMWare workstation
ProgressBar
if [ -n "$S_ADD_VMWARE_WORKSTATION" ]; then
. ./package/vmware-workstation/install.sh
fi

#
# Install firefox
ProgressBar
if [ -n "$S_ADD_FF" ]; then
. ./package/firefox/install.sh
fi

#
# Install Tor browser
ProgressBar
if [ -n "$S_ADD_TORBROWSER" ]; then
. ./package/torbrowser/install.sh
fi

#
# Install qBitTorrent
ProgressBar
if [ -n "$S_ADD_QBITTORRENT" ]; then
. ./package/qbittorrent/install.sh
fi

#
# Install bluetooth extra codecs
ProgressBar
if [ -n "$S_ADD_BTEXTRA" ]; then
. ./package/bluetooth-extra/install.sh
fi

#
# Install moc audio player
ProgressBar
if [ -n "$S_ADD_MOC" ]; then
. ./package/moc/install.sh
fi

#
# Audacious audio hi-fi player
ProgressBar
if [ -n "$S_ADD_AUDACIOUS" ]; then
. ./package/audacious/install.sh
fi

#
# Install mpv video player
ProgressBar
if [ -n "$S_ADD_MPV" ]; then
. ./package/mpv/install.sh
fi

#
# Install telegram messanger
ProgressBar
if [ -n "$S_ADD_TELEGRAM" ]; then
. ./package/telegram-desktop/install.sh
fi

#
# Install atom
ProgressBar
if [ -n "$S_ADD_ATOM" ]; then
. ./package/atom/install.sh
fi

#
# Install nodejs
ProgressBar
if [ -n "$S_ADD_NODEJS" ]; then
. ./package/nodejs/install.sh
fi

#
# Install rust
ProgressBar
if [ -n "$S_ADD_RUST" ]; then
. ./package/rust/install.sh
fi

#
# GIMP
ProgressBar
if [ -n "$S_ADD_GIMP" ]; then
. ./package/gimp/install.sh
fi

#
# Systemd GUI manager
ProgressBar
if [ -n "$S_ADD_SYSTEMDGENIE" ]; then
. ./package/systemdgenie/install.sh
fi

#
# Open RGB
ProgressBar
if [ -n "$S_ADD_OPENRGB" ]; then
. ./package/openrgb/install.sh
fi

#
# Open YouTubeMusic
ProgressBar
if [ -n "$S_ADD_YOUTUBEMUSIC" ]; then
. ./package/youtubemusic/install.sh
fi

#
# LibreOffice
ProgressBar
if [ -n "$S_ADD_LIBREOFFICE" ]; then
. ./package/libreoffice/install.sh
fi

#
# Flameshot
ProgressBar
if [ -n "$S_FLAMESHOT" ]; then
. ./package/flameshot/install.sh
fi

#
# GuiDpi
ProgressBar
if [ -n "$S_GUIDPI" ]; then
  . ./package/guidpi/install.sh
fi
