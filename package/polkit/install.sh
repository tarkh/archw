#!/bin/bash

#
# Off if exist
service_ctl user off aw-polkit-gnome-autostart.service

#
# Install packages
sudo pacman --noconfirm -S polkit polkit-gnome

#
# Add polkit config
sudo bash -c "cat >> /etc/polkit-1/rules.d/50-default.rules" << EOL
polkit.addAdminRule(function(action, subject) {
  return ["unix-group:wheel"];
});
EOL

#
# Install local pkexec wrapper
sudo \cp -r ./package/polkit/bin/pkexec /usr/local/bin/
sudo chmod +x /usr/local/bin/pkexec

#
# Autorun with i3
service_ctl user install-on ./package/polkit/systemd/aw-polkit-gnome-autostart.service

#
# On
service_ctl user on aw-polkit-gnome-autostart.service
