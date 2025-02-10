#!/bin/bash

yay --noconfirm -S openrgb-git

#
# Default ArchW conf
mkdir -p $V_HOME/.config/OpenRGB/
cp ./package/openrgb/ArchW.orp $V_HOME/.config/OpenRGB/

#
# Autorun with i3
service_ctl user install-on ./package/openrgb/systemd/openrgb-load-profile.service

#
# On
service_ctl user on openrgb-load-profile.service

#
# Copy openrgb load profile to systemd sleep
sudo cp ./package/openrgb/systemd/openrgb-load-profile /usr/lib/systemd/system-sleep/
sudo chmod +x /usr/lib/systemd/system-sleep/openrgb-load-profile