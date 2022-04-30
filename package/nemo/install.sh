#!/bin/bash

sudo pacman --noconfirm -S nemo nemo-fileroller

if [ "$S_SYSTEM_FM" == "nemo" ]; then
  xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
fi

#
# Do not display hidden files by default
gsettings set org.nemo.preferences show-hidden-files false

#
# Network share
sudo pacman --noconfirm -S avahi nss-mdns nemo-share
sudo systemctl enable avahi-daemon.service
