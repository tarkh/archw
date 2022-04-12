#!/bin/bash

sudo groupadd -r autologin
sudo gpasswd -a $S_MAINUSER autologin

#
# Patch configs
sudo sed -i -E "s:^\s*[#]*(autologin-user=).*:\1$S_MAINUSER:" /etc/lightdm/lightdm.conf
if [ -n "$S_AUTOLOGIN_TIMEOUT" ]; then
  sudo sed -i -E "s:^\s*[#]*(autologin-user-timeout=).*:\1$S_AUTOLOGIN_TIMEOUT:" /etc/lightdm/lightdm.conf
fi
sudo sed -i -E "s:^\s*[#]*(autologin-session=).*:\1$i3:" /etc/lightdm/lightdm.conf
