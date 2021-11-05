#!/bin/bash
#
# Patch file for ArchW
# Do not modify options here, do it in
# selected patch folder
#
# =====================
# To patch installer, create directory of your patch name in ./patches and copy
# this installer file there, renaming it to install.sh, then add your patch
# name to config file in S_PATCH variable.
#
# Patching is avaliable on 4 install stages:
# 0. Bootstrap stage, will run code before base ArchW installer
# 1. Boot ISO stage, will run code in ELSE statement
# 2. CHROOT stage, will run code in IF $ARG_CHROOT variable exist statement
# 3. ADMIN stage (after reboot), will run code in IF $ARG_ADMIN variable exist statement
# =====================

#
# Here you can override settings
# from main config

#
# Patch
if [ -n "$STAGE_BOOTSTRAP" ]; then
  #
  # BOOTSTRAP stage
  if [ -n "$ARG_CHROOT" ]; then
    :
  elif [ -n "$ARG_ADMIN" ]; then
    :
  else
    :
  fi
  :
elif [ -n "$ARG_CHROOT" ]; then
  #
  # CHROOT stage
  :
elif [ -n "$ARG_ADMIN" ]; then
  #
  # ADMIN stage
  # Runs from created user, so use sudo if needed.
  # On this stage it will not ask for password.
  :
else
  #
  # Boot ISO stage
  :
fi
