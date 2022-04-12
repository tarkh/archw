#!/bin/bash

#
# Enable multilib
sed -i -E \
"/\[multilib\]/,/Include/"'s/^#//' \
/etc/pacman.conf
pacman -Syyu

# Install drivers
pacman --noconfirm -S mesa nvidia nvidia-utils lib32-nvidia-utils \
nvidia-settings libva-vdpau-driver libvdpau-va-gl
# OC/Fan GUI control
yay --noconfirm -S gwe

# Config
mkdir -p /etc/X11/xorg.conf.d/
bash -c "cat >> /etc/X11/xorg.conf.d/20-nvidia.conf" << EOL
Section "Device"
        Identifier "Nvidia Card"
        Driver "nvidia"
        Option "Coolbits" "28"
        VendorName "NVIDIA Corporation"
        Option "NoLogo" "1"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    Monitor        "Monitor0"
    Option         "MetaModes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option         "AllowIndirectGLXProtocol" "off"
    Option         "TripleBuffer" "on"
EndSection
EOL

# Kernel module
add_system_module "nvidia nvidia_modeset nvidia_uvm nvidia_drm"

# Enable DRM
bash -c "cat >> /etc/modprobe.d/nvidia.conf" << EOL
options nvidia-drm modeset=1
options nvidia NVreg_UsePageAttributeTable=1 NVreg_RegistryDwords="OverrideMaxPerf=0x1"
EOL
# Preserve video memory after suspend
#bash -c "cat >> /etc/modprobe.d/nvidia-power-management.conf" << EOL
#options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/nvidia-memtmp
#EOL

mkdir -p /etc/pacman.d/hooks/
bash -c "cat >> /etc/pacman.d/hooks/nvidia.hook" << EOL
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux
# Change the linux part above and in the Exec line if a different kernel is used

[Action]
Description=Update Nvidia module in initcpio
Depends=mkinitcpio
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c 'while read -r trg; do case \$trg in linux) exit 0; esac; done; /usr/bin/mkinitcpio -P'
EOL

mkdir -p /etc/udev/rules.d/
bash -c "cat >> /etc/udev/rules.d/70-nvidia.rules" << EOL
ACTION=="add", DEVPATH=="/bus/pci/drivers/nvidia", RUN+="/usr/bin/nvidia-modprobe -c0 -u"
EOL

#nvidia-xconfig

#
# Mkinit
mkinitcpio -P
