#!/bin/bash

if [ "$S_LINUX" == "linux" ]; then
  sudo pacman --noconfirm -S virtualbox-host-modules-arch
else
  sudo pacman --noconfirm -S virtualbox-host-dkms
fi

sudo pacman --noconfirm -S virtualbox virtualbox-guest-iso

#
# Add to picom
sed -i -E \
"/\b(VBoxSDL|VirtualBox Machine)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'VBoxSDL' \&\& focused\",:g; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'VirtualBox Machine' \&\& focused\",:g" \
$V_HOME/.config/picom/picom.conf
