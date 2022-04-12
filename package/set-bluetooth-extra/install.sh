#!/bin/bash

#
# Install additional BT codec support
sudo pacman --noconfirm -R pulseaudio-bluetooth
yay --noconfirm -S pulseaudio-modules-bt
sudo pacman --noconfirm -S libldac

#
# Disable avrcp
if [ -n "S_ADD_BTEXTRA_AVRCP_OFF"]; then
  sudo mkdir -p /etc/systemd/system/bluetooth.service.d
  sudo bash -c "/etc/systemd/system/bluetooth.service.d/noplugin-avrc.conf" << EOL
[Service]
ExecStart=
ExecStart=/usr/lib/bluetooth/bluetoothd --noplugin=avrcp

EOL
fi
