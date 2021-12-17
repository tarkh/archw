#!/bin/bash

pacman --noconfirm -S intel-ucode mesa xf86-video-amdgpu vulkan-radeon libva-mesa-driver \
mesa-vdpau libva-vdpau-driver libvdpau-va-gl radeontop

# Config
# Option "TearFree" "true"
mkdir -p /etc/X11/xorg.conf.d/
bash -c "cat >> /etc/X11/xorg.conf.d/20-amdgpu.conf" << EOL
Section "Device"
   Identifier "AMD"
   Driver "amdgpu"
EndSection
EOL

# Kernel module
add_system_module "amdgpu radeon"

# Mkinit
mkinitcpio -P
