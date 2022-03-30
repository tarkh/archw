#!/bin/bash

sudo pacman --noconfirm -R xorg-xbacklight
sudo pacman --noconfirm -S acpilight brightnessctl

sudo bash -c "cat > /etc/udev/rules.d/90-backlight.rules" << EOL
SUBSYSTEM=="backlight", ACTION=="add", \
  RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
SUBSYSTEM=="leds", ACTION=="add", KERNEL=="*::kbd_backlight", \
  RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", \
  RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
EOL

#
# Install suspend brightness save
sudo \cp -r ./package/acpilight/systemd/aw-acpilight /usr/lib/systemd/system-sleep/
sudo chmod +x /usr/lib/systemd/system-sleep/aw-acpilight
