#!/bin/bash

sudo pacman --noconfirm -S mpv

mkdir -p ${V_HOME}/.config/mpv
bash -c "cat >> ${V_HOME}/.config/mpv/mpv.conf" << EOL
hwdec=auto
EOL

#
# Add to picom
sed -i -E \
"/\b(mpv)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'mpv' \&\& focused\",:; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'mpv' \&\& \!focused\",:g" \
$V_HOME/.config/picom/picom.conf
