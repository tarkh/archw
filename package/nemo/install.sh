#!/bin/bash

sudo pacman --noconfirm -S nemo

if [ "$S_SYSTEM_FM" == "nemo" ]; then
  xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
fi
