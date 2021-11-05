#!/bin/bash

#
# Off if exist
service_ctl user off imwheel-autostart.service

#
# Install package
sudo pacman --noconfirm -S imwheel

#
# Autorun with i3
service_ctl user install-on ./package/imwheel/systemd/imwheel-autostart.service

#
# Copy preconfigs
\cp -r ./package/imwheel/.imwheelrc $V_HOME

#
# On
service_ctl user on imwheel-autostart.service
