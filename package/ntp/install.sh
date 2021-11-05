#!/bin/bash

#
# Off if exist
sudo systemctl disable ntpd.service > /dev/null 2>&1

#
# Install package
sudo pacman --noconfirm -S ntp

#
# On
sudo systemctl enable ntpd.service
