#!/bin/bash

sudo pacman --noconfirm -S gpicview

#
# Set style
mkdir -p $V_HOME/.config/gpicview
\cp -r ./package/gpicview/gpicview.conf $V_HOME/.config/gpicview

#
# Set default image viewer
xdg-mime default gpicview.desktop `grep 'MimeType=' /usr/share/applications/gpicview.desktop | sed -e 's/.*=//' -e 's/;/ /g'`

#
# Add to picom
sed -i -E \
"/\b(Gpicview)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'Gpicview' \&\& focused\",:g" \
$V_HOME/.config/picom/picom.conf
