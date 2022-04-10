#!/bin/bash

# Add kernel flags
add_kernel_param "libata.force=1:noncq"

#
# Set grub
if [ -n "$ARCHW_PKG_INST" ]; then
  install_grub
fi
