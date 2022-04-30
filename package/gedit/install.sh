#!/bin/bash

sudo pacman --noconfirm -S gedit aspell hspell nuspell libvoikko

#
# Install dracula style
sudo mkdir -p /usr/share/gtksourceview-4/styles/
sudo \cp -r ./package/gedit/theme/archw-dracula.xml /usr/share/gtksourceview-4/styles/

#
# Apply settings
gsettings set org.gnome.gedit.preferences.editor editor-font 'RobotoMono Nerd Font 10'
gsettings set org.gnome.gedit.preferences.editor scheme 'archw-dracula'
