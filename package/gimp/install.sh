#!/bin/bash

sudo pacman --noconfirm -S gimp

#
# Add to picom
sed -i -E \
"/\b(gimp)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g \*\?= 'gimp' \&\& focused\",:g" \
$V_HOME/.config/picom/picom.conf
