#!/bin/bash

#
# Off if exist
service_ctl user off nm-applet-autostart.service

#
# Autorun with i3
service_ctl user install-on ./package/nm-applet/systemd/nm-applet-autostart.service

if [[ -n "$S_SYSTEMCTL_NETWORKMANAGER" || -n "$ARCHW_PKG_INST" ]]; then
  #
  # On
  service_ctl user on nm-applet-autostart.service
fi
