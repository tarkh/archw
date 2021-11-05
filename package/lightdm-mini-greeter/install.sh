#!/bin/bash

#
# YAY
sudo rm -rf /etc/lightdm/lightdm-mini-greeter.conf /etc/lightdm/lightdm-mini-greeter.conf.ref > /dev/null 2>&1
yay --noconfirm -S lightdm-mini-greeter-git

#
# Patch config
sudo sed -i -E "s:^\s*[#]*(greeter-session=).*:\1lightdm-mini-greeter:" /etc/lightdm/lightdm.conf

sudo sed -i -E \
"s:^\s*[#]*(user\s*=).*:\1 $S_MAINUSER:; \
s:^\s*[#]*(password-input-width\s*=).*:\1 13:; \
s:^\s*[#]*(show-image-on-all-monitors\s*=).*:\1 true:; \
s:^\s*[#]*(show-input-cursor\s*=).*:\1 false:; \
s:^\s*[#]*(font\s*=).*:\1 \"RobotoMono Nerd Font\":; \
s:^\s*[#]*(font-weight\s*=).*:\1 regular:; \
s:^\s*[#]*(text-color\s*=).*:\1 \"#fbbef3\":; \
s:^\s*[#]*(error-color\s*=).*:\1 \"#f5a28c\":; \
s:^\s*[#]*(background-image\s*=).*:\1 \"/usr/share/wallpapers/wallpaper.png\":; \
s:^\s*[#]*(background-image-size\s*=).*:\1 cover:; \
s:^\s*[#]*(background-color\s*=).*:\1 \"#000000\":; \
s:^\s*[#]*(window-color\s*=).*:\1 \"#2c1735\":; \
s:^\s*[#]*(border-color\s*=).*:\1 \"#4c2e55\":; \
s:^\s*[#]*(border-width\s*=).*:\1 2px:; \
s:^\s*[#]*(layout-space\s*=).*:\1 16:; \
s:^\s*[#]*(password-color\s*=).*:\1 \"#eee3f1\":; \
s:^\s*[#]*(password-background-color\s*=).*:\1 \"#280931\":; \
s:^\s*[#]*(password-border-color\s*=).*:\1 \"#4c2e55\":; \
s:^\s*[#]*(password-border-width\s*=).*:\1 2px:; \
s:^\s*[#]*(password-border-radius\s*=).*:\1 0:" \
/etc/lightdm/lightdm-mini-greeter.conf

#
# Create ref config
sudo cp /etc/lightdm/lightdm-mini-greeter.conf /etc/lightdm/lightdm-mini-greeter.conf.ref
