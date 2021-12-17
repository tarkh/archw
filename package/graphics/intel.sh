#!/bin/bash

pacman --noconfirm -S intel-ucode mesa xf86-video-intel libva-intel-driver \
libva-utils libva-vdpau-driver libvdpau-va-gl

# Config
mkdir -p /etc/X11/xorg.conf.d/
bash -c "cat >> /etc/X11/xorg.conf.d/20-intel.conf" << EOL
Section "Device"
  Identifier "Intel Graphics"
  Driver "intel"
  Option "TearFree" "true"
EndSection
EOL

# Kernel module
add_system_module "i915"

# Modprobe
mkdir -p /etc/modprobe.d/
bash -c "cat >> /etc/modprobe.d/i915.conf" << EOL
options i915 modeset=1
EOL

#
# Mkinit
mkinitcpio -P
