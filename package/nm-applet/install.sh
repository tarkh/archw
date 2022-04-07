#!/bin/bash

#
# Off if exist
service_ctl user off aw-nm-applet-autostart.service

sudo pacman --noconfirm -S network-manager-applet

#
# Autorun with i3
service_ctl user install-on ./package/nm-applet/systemd/aw-nm-applet-autostart.service

#
# On
if [[ -n "$S_SYSTEMCTL_NETWORKMANAGER" || -n "$ARCHW_PKG_INST" ]]; then
  service_ctl user on aw-nm-applet-autostart.service
fi
