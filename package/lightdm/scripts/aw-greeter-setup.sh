#!/bin/sh

#
# Check wallpaper
#CHECKWALLPAPER=true
if [ -n "$CHECKWALLPAPER" ]; then
  #
  # Run wp setup, but don't wait for it
  bash -c "archw --wp" &
fi
