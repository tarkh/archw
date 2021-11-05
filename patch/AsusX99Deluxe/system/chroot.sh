#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# CHROOT STAGE

#
# Install
ProgressBar
pacman --noconfirm -S broadcom-wl
