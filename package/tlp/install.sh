#!/bin/bash

#
# Off if exist
sudo systemctl disable NetworkManager-dispatcher.service > /dev/null 2>&1
sudo systemctl disable tlp.service > /dev/null 2>&1

#
# Install package
sudo pacman --noconfirm -S tlp
yay --noconfirm -S tlpui-git

#
# Set conf to be editable by wheel
sudo chown root:wheel /etc/tlp.conf
sudo chmod 664 /etc/tlp.conf

#
# On
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl enable tlp.service
