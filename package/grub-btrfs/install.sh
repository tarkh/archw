#!/bin/bash

if [ "$S_MAKEFS_SYS_FS" == "btrfs" ]; then
  service_ctl libsys off grub-btrfs.path

  # Install grub-btrfs
  sudo pacman --noconfirm -S grub-btrfs

  #
  # Create service for Timeshift
  service_ctl libsys install-on ./package/grub-btrfs/systemd/grub-btrfs.path

  #
  # On
  service_ctl libsys on grub-btrfs.path
else
  echo "Skipping grub-silent: btrfs not available"
fi
