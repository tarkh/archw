#!/bin/bash

# Add kernel flags
add_kernel_param "intel_iommu=on iommu=pt"

#
# Set grub
if [ -n "$ARCHW_PKG_INST" ]; then
  install_grub
fi
