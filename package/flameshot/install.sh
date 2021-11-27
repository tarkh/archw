#!/bin/bash

#
# Off if exist
service_ctl user off flameshot-autostart.service

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
service_ctl user install-on ./package/flameshot/systemd/flameshot-autostart.service

#
# On
service_ctl user on flameshot-autostart.service