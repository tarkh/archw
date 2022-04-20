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
s:^\s*[#]*(display-setup-script=).*:\1/usr/share/lightdm/scripts/aw-display-setup.sh:" \
/etc/lightdm/lightdm.conf
