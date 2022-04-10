#!/bin/bash
#
# Patch file for ArchW
# =====================
# To patch installer, create directory of your patch name in ./patch and copy
# this installer file there, renaming it to install.sh, then add your patch
# name to config file in S_PATCH variable.
#
# Patching is avaliable on 3 install stages:
# 0. Bootstrap stage, will run code before base ArchW installer
# 1. Boot ISO stage, will run code in ELSE statement
# 2. CHROOT stage, will run code in IF $ARG_CHROOT variable exist statement
# 3. ADMIN stage (after reboot), will run code in IF $ARG_ADMIN variable exist statement
# =====================

if [ -n "$STAGE_BOOTSTRAP" ]; then
  #
  # BOOTSTRAP stage
  if [ -n "$ARG_CHROOT" ]; then
    :
  else
    if ! connected; then
      #
      # Manual device setup for BCM43xx
      echo "Initializing network device..."
      sudo rmmod b43
      sudo rmmod ssb
      sudo rmmod bcma
      sudo rmmod wl
      sleep 2
      if ! sudo modprobe wl; then
        echo "Can't load kernel module: wl"
        exit 1
      fi
      sudo depmod -a
      # Try to connect
      try_connect
    fi
  fi
elif [ -n "$ARG_CHROOT" ]; then
  #
  # CHROOT stage
  . ./patch/${S_PATCH}/system/chroot.sh
  #
elif [ -n "$ARG_ADMIN" ]; then
  #
  # ADMIN stage
  # Runs from created user, so use sudo if needed.
  # On this stage it will not ask for password.
  . ./patch/${S_PATCH}/system/admin.sh
  #
else
  #
  # Boot ISO stage
  . ./patch/${S_PATCH}/system/iso.sh
  #
fi
