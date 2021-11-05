#!/bin/bash

sudo pacman --noconfirm -S btop

mkdir -p $V_HOME/.config/btop
bash -c "cat > $V_HOME/.config/btop/btop.conf" << EOL
color_theme = "/usr/share/btop/themes/dracula.theme"
theme_background  = False

EOL
