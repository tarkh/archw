#!/bin/bash

sudo pacman --noconfirm -S ${S_LINUX}-headers ruby
yay --noconfirm -S vmware-workstation

#
# Activate product if key provided
if [ -n "$S_ADD_VMWARE_WORKSTATION_KEY" ]; then
  sudo /usr/lib/vmware/bin/vmware-vmx-debug --new-sn $S_ADD_VMWARE_WORKSTATION_KEY
fi

#
# Install VM aw-autosuspend on system sleep
#sudo chmod +x ./package/vmware-workstation/system-sleep/*
#sudo \cp -r ./package/vmware-workstation/system-sleep/* /usr/lib/systemd/system-sleep/

#
# Load kernel module and enable services
sudo modprobe -a vmw_vmci vmmon
sudo systemctl enable vmware-networks.service
sudo systemctl enable vmware-usbarbitrator.service

#
# Add to picom
sed -i -E \
"/\b(Vmware)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g = 'Vmware' \&\& focused\",:g" \
$V_HOME/.config/picom/picom.conf
