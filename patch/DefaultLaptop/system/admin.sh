#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# ADMIN STAGE

#
# Install key service
ProgressBar
if [ -n "$S_ADD_SXHKD" ]; then
  mkdir -p $V_HOME/.config/sxhkd/
  bash -c "cat > $V_HOME/.config/sxhkd/brightness.conf" << EOL
# Display brightness
XF86MonBrightness{Up,Down}
  brightnessctl -d intel_backlight set {+1%,1%-} --save && \
  archw --osd show-brightness intel_backlight Screen

# Keyboard backlight brightness
XF86KbdBrightness{Up,Down}
  brightnessctl -d smc::kbd_backlight set {+1%,1%-} --save && \
  archw --osd show-brightness smc::kbd_backlight Keyboard

EOL

#
# Set brightness
sudo brightnessctl -d intel_backlight set 65% --save
sudo brightnessctl -d smc::kbd_backlight set 45% --save
fi
