#!/bin/bash

sudo pacman --noconfirm -S atom

mkdir -p $V_HOME/.atom
mkdir -p $V_HOME/.atom/packages
\cp -r ./package/atom/config.cson $V_HOME/.atom
\cp -r ./package/atom/packages/* $V_HOME/.atom/packages

#
# Add to picom
#sed -i -E \
#"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"97\:class_g = 'Atom' \&\& focused\",:; \
#s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"92\:class_g = 'Atom' \&\& \!focused\",:" \
#$V_HOME/.config/picom/picom.conf
