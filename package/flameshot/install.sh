#!/bin/bash

#
# Off if exist
service_ctl user off aw-flameshot-autostart.service

#
# Install package
sudo pacman --noconfirm -S flameshot

#
# Put preconf
mkdir -p $V_HOME/.config/flameshot/
\cp -r ./package/flameshot/flameshot.ini $V_HOME/.config/flameshot/

#
# Add to hotkey
mkdir -p $V_HOME/.config/sxhkd/
bash -c "cat > $V_HOME/.config/sxhkd/flameshot.conf" << EOL
# Screenshot
super + control + s
  flameshot gui

# Fullscreen capture
super + control + shift + s
  flameshot screen -r -p ~/Screenshots

EOL

#
# Autorun with i3
service_ctl user install-on ./package/flameshot/systemd/aw-flameshot-autostart.service

#
# On
if [ -n "$ARCHW_PKG_INST" ]; then
  service_ctl user on aw-flameshot-autostart.service
fi
