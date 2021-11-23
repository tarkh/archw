#!/bin/bash

sudo pacman --noconfirm -S libimobiledevice
yay -S ifuse
sudo pacman --noconfirm -S gvfs-afc gvfs-gphoto2 udisks2
