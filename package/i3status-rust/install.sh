#!/bin/bash

#
# Off if exist
service_ctl user off update-checker.timer update-checker.service

S_ARCHW_FOLDER=/usr/share/archw
S_ARCHW_CONFIG=$HOME/.config/archw
S_ARCHW_TMPFS=/tmp/archw-runtime

sudo pacman --noconfirm -S i3status-rust

#
# Add archw module
sudo \cp -r ./package/i3status-rust/archw-module/* /usr/local/lib/archw/modules

#
# Create config
mkdir -p $V_HOME/.config/i3status-rust
\cp -r ./package/i3status-rust/config/* $V_HOME/.config/i3status-rust
\cp -r ./package/i3status-rust/archw-config/* $S_ARCHW_FOLDER

#
# Merge configs
mergeconf user ./package/i3status-rust/archw-config/ $S_ARCHW_CONF
mergeconf user ./package/i3status-rust/archw-config/ $S_ARCHW_TMPFS

#
# Set time format
if [ -e "$S_I3_STATUS_TIMEFORMAT" ]; then
  archw --status json formatset "$S_I3_STATUS_TIMEFORMAT"
fi

#
# Autorun with i3
service_ctl user install ./package/i3status-rust/systemd/update-checker.service
service_ctl user install-on ./package/i3status-rust/systemd/update-checker.timer

#
# Patch i3 config source/local config
sudo sed -i -E \
"s:(\s*status_command).*:\1 i3status-rs:" \
${V_HOME}/.config/i3/config

#
# On
service_ctl user on update-checker.timer update-checker.service
