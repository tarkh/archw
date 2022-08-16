#!/bin/bash

sudo systemctl stop NetworkManager.service > /dev/null 2>&1
service_ctl user off aw-nm-applet-autostart.service

#
# Install NetworkManager and add l2tp functionality
sudo pacman --noconfirm -S networkmanager network-manager-applet networkmanager-l2tp strongswan

#
# Config
#sudo mkdir -p /etc/NetworkManager/conf.d
#sudo bash -c "cat >> /etc/NetworkManager/conf.d/dhcp-client.conf" << EOL
#[main]
#dhcp=dhclient
#EOL

sudo systemctl disable iwd.service
sleep 2
sudo systemctl enable NetworkManager.service

#
# Enable IWD backend
sudo mkdir -p /etc/NetworkManager/conf.d/
sudo bash -c "cat >> /etc/NetworkManager/conf.d/wifi_backend.conf" << EOL
[device]
wifi.backend=iwd
EOL

#
# Autorun with i3
service_ctl user install-on ./package/networkmanager/systemd/user/aw-nm-applet-autostart.service

#
# Restart on resume
sudo chmod +x ./package/networkmanager/systemd/system-sleep/*
sudo \cp -r ./package/networkmanager/systemd/system-sleep/* /usr/lib/systemd/system-sleep/

#
# On
service_ctl user on aw-nm-applet-autostart.service
