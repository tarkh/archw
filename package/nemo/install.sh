#!/bin/bash

sudo pacman --noconfirm -S nemo

if [ "$S_SYSTEM_FM" == "nemo" ]; then
  xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
fi

#
# Do not display hidden files by default
gsettings set org.nemo.preferences show-hidden-files false
