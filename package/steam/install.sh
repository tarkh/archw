#!/bin/bash

#
# Enable multilib
sudo sed -i -E \
"/\[multilib\]/,/Include/"'s/^#//' \
/etc/pacman.conf
sudo pacman -Syyu

#
# Install steam
sudo pacman --noconfirm -S ttf-liberation steam
