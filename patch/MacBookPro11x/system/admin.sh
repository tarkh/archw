#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# ADMIN STAGE

#
# Add archw module
ProgressBar
sudo \cp -r ./patch/${S_PATCH}/archw-module/* /usr/local/lib/archw/modules

#
# Install key service
ProgressBar
if [ -n "$S_ADD_SXHKD" ]; then
  mkdir -p $V_HOME/.config/sxhkd/
  bash -c "cat > $V_HOME/.config/sxhkd/macbookbrightness.conf" << EOL
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

#
# Alter trackpad config
sed -i -E \
"s:^(\s*Option \"Sensitivity\").*:\1 \"0.15\":; \
s:^(\s*Option \"ScrollDistance\").*:\1 \"700\":" \
/etc/X11/xorg.conf.d/00-mtrack.conf

#
# Install fan control (mbfan)
ProgressBar
yay --noconfirm -S mbpfan-git
sudo systemctl enable mbpfan.service
sudo systemctl start mbpfan.service
sleep 1
archw --fan normal

#
# Camera
ProgressBar
sudo pacman --noconfirm -S ${S_LINUX}-headers
yay --noconfirm -S facetimehd-firmware bcwc-pcie-git
sudo depmod
sudo modprobe facetimehd

#
# Update i3settings config
sed -i -E \
"/^\s*block\s*=\s*\"temperature\"\s*$/,\@^[#\s]*\[@ s/^(\s*info\s*=).*$/\1 75/; \
/^\s*block\s*=\s*\"temperature\"\s*$/,\@^[#\s]*\[@ s/^(\s*warning\s*=).*$/\1 92/" \
$V_HOME/.config/i3status-rust/config.toml
