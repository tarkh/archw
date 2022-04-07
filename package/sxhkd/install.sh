#!/bin/bash

#
# Off if exist
service_ctl user off aw-sxhkd-autostart.service

#
# Install package
sudo pacman --noconfirm -S sxhkd

#
# Autorun with i3
service_ctl user install-on ./package/sxhkd/systemd/aw-sxhkd-autostart.service

#
# Install bin
sudo \cp -r ./package/sxhkd/bin/* /usr/local/bin
sudo chmod +x /usr/local/bin/*

#
# Remove duplicate controls from i3
sed -i -E \
"s:^[#\s]*(bindsym\s+XF86Audio):#\1:; \
s:^[#\s]*(bindsym.*exec archw --lang cycle):#\1:" \
$V_HOME/.config/i3/config

#
# Add archw module
sudo \cp -r ./package/sxhkd/archw-module/* /usr/local/lib/archw/modules

#
# Set common hot keys
mkdir -p $V_HOME/.config/sxhkd
bash -c "cat > $V_HOME/.config/sxhkd/common.conf" << EOL
# Switch language
control + space
  archw --lang cycle

# Volume
XF86Audio{Raise,Lower}Volume
  amixer set 'Master' 1%{+,-} && \
  archw --osd show-volume

# Mute
XF86AudioMute
  amixer -D pulse set 'Master' 1+ toggle && \
  archw --osd show-volume

# Media Play/Pause
XF86AudioPlay
  playerctl play-pause && \
  archw --osd send "Play/Pause toggled" "" -t 2000

# Media next
XF86AudioNext
  playerctl next

# Media Previous
XF86AudioPrev
  playerctl previous

# Media Stop
XF86AudioStop
  playerctl stop && \
  archw --osd send "Playback stopped" "" -t 2000

# Toggle floating mode
XF86LaunchA
  i3-msg "[class=*] floating toggle"

EOL

#
# On
if [ -n "$ARCHW_PKG_INST" ]; then
  service_ctl user on aw-sxhkd-autostart.service
fi
