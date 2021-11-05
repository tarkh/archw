#!/bin/bash

#gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
sudo pacman --noconfirm -S tor torbrowser-launcher
#sudo pacman --noconfirm -S tor
#yay --noconfirm -S tor-browser

#
# Add to picom
sed -i -E \
"/\b(Tor Browser)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'Tor Browser' \&\& focused\",:" \
$V_HOME/.config/picom/picom.conf
