#!/bin/bash

sudo pacman --noconfirm -S networkmanager network-manager-applet

#
# Config
#sudo bash -c "cat >> /etc/NetworkManager/conf.d/dhcp-client.conf" << EOL
#[main]
#dhcp=dhclient
#EOL

#
# If IW connected
if [ -f "${S_PKG}/autonetworkwifi" ]; then
  . ${S_PKG}/autonetworkwifi
  echo "Reconnecting WiFi with NetworkManager"
  INAME=$(iw dev | grep Interface | cut -d " " -f2)
  iwctl station $INAME disconnect
  #iwctl known-networks "${AN_SSID}" forget
  sudo systemctl stop iwd.service
  sudo systemctl disable iwd.service
  sleep 2
  sudo systemctl enable NetworkManager
  sudo systemctl start NetworkManager
  echo "Connecting to wifi network ${AN_SSID}... This might take up to 60 seconds..."
  sleep 2
  nmcli device wifi connect "${AN_SSID}" password $AN_PASS
  sleep 5
  ip address show
fi
