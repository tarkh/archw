#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# CHROOT STAGE

#
# Packagrs
ProgressBar
pacman --noconfirm -S broadcom-wl

#
# Tweaks
. ./tweaks/intel_iommu.sh
. ./tweaks/intel_video_tune.sh

#
# Sleep mode and lid
# Helper script
ProgressBar
\cp -r ./patch/MacBookPro11x/bin/mac-pre-suspend /usr/local/bin/
chmod +x /usr/local/bin/mac-pre-suspend

#
# Service
\cp -r ./patch/MacBookPro11x/systemd/mac-pre-suspend.service /etc/systemd/system/
systemctl enable mac-pre-suspend.service
