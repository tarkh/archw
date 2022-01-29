#!/bin/bash

sudo systemctl disable lightdm > /dev/null 2>&1

sudo pacman --noconfirm -S lightdm
sudo mkdir -p /usr/share/lightdm/scripts
sudo \cp -r ./package/lightdm/scripts/* /usr/share/lightdm/scripts
sudo chmod +x /usr/share/lightdm/scripts/*
sudo systemctl enable lightdm

#
# Patch config
sudo sed -i -E \
"s:^\s*[#]*(minimum-vt=).*:\1${S_SYS_TTY}:; \
s:^\s*[#]*(run-directory=).*:\1/run/lightdm:; \
s:^\s*[#]*(user-session=).*:\1i3:; \
s:^\s*[#]*(session-wrapper=).*:\1/etc/lightdm/Xsession:; \
s:^\s*[#]*(display-setup-script=).*:\1/usr/share/lightdm/scripts/aw-display-setupsh:; \
s:^\s*[#]*(greeter-setup-script=).*:\1/usr/share/lightdm/scripts/aw-greeter-setupsh:" \
/etc/lightdm/lightdm.conf

#
# Enable auto managers
if [ -n "$S_AUTODISPLAY" ]; then
  sudo sed -i -E "s/^\s*[#]*(AUTODISPLAY.*)/\1/" /usr/share/lightdm/scripts/aw-display-setupsh
fi
if [ -n "$S_AUTOWALLPAPER" ]; then
  sudo sed -i -E "s/^\s*[#]*(CHECKWALLPAPER.*)/\1/" /usr/share/lightdm/scripts/aw-greeter-setupsh
fi
