#!/bin/bash

#
# Off if exist
service_ctl user off aw-blueman-applet-autostart.service

#
# Autorun with i3
service_ctl user install-on ./package/blueman/systemd/aw-blueman-applet-autostart.service

if [[ -n "$S_SYSTEMCTL_BLUETOOTH" || -n "$ARCHW_PKG_INST" ]]; then
  #
  # On
  service_ctl user on aw-blueman-applet-autostart.service
fi
