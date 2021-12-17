#!/bin/bash

# Add kernel flags
add_kernel_param "intel_iommu=on iommu=pt"

#
# Set grub
install_grub
