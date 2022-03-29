#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# CHROOT STAGE

#
# Tweaks
. ./tweaks/intel_iommu.sh
. ./tweaks/intel_video_tune.sh

#
# Sleep mode and lid
# Helper script
ProgressBar
\cp -r ./patch/MacBookPro11x/bin/aw-mac-pre-suspend /usr/local/bin/
chmod +x /usr/local/bin/aw-mac-pre-suspend

#
# Service
\cp -r ./patch/MacBookPro11x/systemd/aw-mac-pre-suspend.service /etc/systemd/system/
systemctl enable aw-mac-pre-suspend.service
