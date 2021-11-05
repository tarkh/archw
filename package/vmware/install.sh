#!/bin/bash

sudo systemctl disable vmtoolsd.service > /dev/null 2>&1
sudo systemctl disable vmware-vmblock-fuse.service > /dev/null 2>&1
sudo systemctl stop archw-vmware-automount.service > /dev/null 2>&1

service_ctl sys off archw-vmware-automount.service

sudo pacman --noconfirm -S open-vm-tools gtkmm3 xf86-input-vmmouse xf86-video-vmware

sudo systemctl enable vmtoolsd.service
sudo systemctl enable vmware-vmblock-fuse.service

#
# Enable mounting for user
sudo sed -i -E "s:^\s*[#]*(user_allow_other).*:\1:" /etc/fuse.conf

sudo touch /usr/share/archw/vminstall
sudo touch /usr/share/archw/vmvmware

#
# Auto scripts
sudo \cp -r ./package/vmware/suspend-vm-default.d /etc/vmware-tools/scripts/

#
# Time from host
sudo systemctl start vmtoolsd.service
sudo vmware-toolbox-cmd timesync enable

#
# ArchW
sudo \cp -r ./package/vmware/vmwareautomount /usr/local/bin
sudo mkdir -p /usr/share/archw/automount
sudo chmod -R 0777 /usr/share/archw/automount

#
# Automount service
service_ctl sys install-on ./package/vmware/systemd/archw-vmware-automount.service
service_ctl sys on archw-vmware-automount.service
sudo systemctl enable archw-vmware-automount.service
#
# Add archw module
sudo \cp -r ./package/vmware/archw-module/* /usr/local/lib/archw/modules
