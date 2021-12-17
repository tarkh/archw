#!/bin/bash

# Add options
sudo sed -i -E \
"s:\s*(options i915 .*)$:\1 enable_fbc=0 fastboot=1 disable_power_well=1 mitigations=off:" \
/etc/modprobe.d/i915.conf

#
# Set grub
install_grub
