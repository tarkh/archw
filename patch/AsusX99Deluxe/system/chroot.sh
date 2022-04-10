#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# CHROOT STAGE

#
# Packages
ProgressBar
if [ "$S_LINUX" == "linux" ]; then
  pacman --noconfirm -S broadcom-wl
else
  pacman --noconfirm -S ${S_LINUX}-headers dkms broadcom-wl-dkms
fi
