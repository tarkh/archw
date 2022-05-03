#!/bin/bash

sudo pacman --noconfirm -S terminator
mkdir -p $V_HOME/.config/terminator
\cp -r ./package/terminator/config $V_HOME/.config/terminator

#
# Add to picom
sed -i -E \
"/\b(Terminator)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"79\:class_g = 'Terminator' \&\& !focused\",:" \
$V_HOME/.config/picom/picom.conf

#
# .bashrc mod
sed -i "\:^\s*PS1=.*:d" $V_HOME/.bashrc
echo 'PS1="\[\033[38;5;34m\][\[\033[38;5;96m\]\h \[\033[38;5;182m\]\w\[\033[38;5;34m\]]\\$\[$(tput sgr0)\] "' >> $V_HOME/.bashrc
