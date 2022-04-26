#!/bin/bash

sudo systemctl stop NetworkManager.service > /dev/null 2>&1
service_ctl user off aw-nm-applet-autostart.service

sudo pacman --noconfirm -S networkmanager network-manager-applet

#
# Config
#sudo mkdir -p /etc/NetworkManager/conf.d
#sudo bash -c "cat >> /etc/NetworkManager/conf.d/dhcp-client.conf" << EOL
#[main]
#dhcp=dhclient
#EOL

#
# If IW connected
if [ -f "${S_PKG}/autonetworkwifi" ]; then
  #. ${S_PKG}/autonetworkwifi
  #echo "Reconnecting WiFi with NetworkManager"
  #INAME=$(iw dev | grep Interface | cut -d " " -f2)
  #iwctl station $INAME disconnect
  #iwctl known-networks "${AN_SSID}" forget
  #sudo systemctl stop iwd.service
  sudo systemctl disable iwd.service
  sleep 2
  sudo systemctl enable NetworkManager.service
  #sudo systemctl start NetworkManager.service
  #sleep 2
  #sudo nmcli dev wifi
  #echo "Connecting to wifi network ${AN_SSID}... This might take up to 60 seconds..."
  #sleep 5
  #nmcli device wifi connect "${AN_SSID}" password "$AN_PASS"
  #sleep 2
  #ip address show
  #
else
  sudo systemctl disable iwd.service
  sleep 2
  sudo systemctl enable NetworkManager.service
fi

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
