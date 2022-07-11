#!/bin/bash

#sudo pacman --noconfirm -S picom
yay --noconfirm -S picom-git
mkdir -p $V_HOME/.config/picom
cp /etc/xdg/picom.conf.example $V_HOME/.config/picom/picom.conf

#
# Picom
sed -i -E \
"s:^\s*(shadow-radius\s*=).*:\1 0;:; \
s:^\s*(#\s*shadow-opacity\s*=.*):\1\nshadow-opacity = 1:; \
s:^\s*(shadow-offset-x\s*=).*:\1 0;:; \
s:^\s*(shadow-offset-y\s*=).*:\1 0;:; \
s:^\s*(#\s*shadow-color\s*=.*):\1\nshadow-color = \"#140B19\":; \
s:^\s*(fade-in-step\s*=).*:\1 0.009;:; \
s:^\s*(fade-out-step\s*=).*:\1 0.009;:; \
s:^\s*(#\s*fade-delta\s*=.*):\1\nfade-delta = 1:; \
s:^\s*(inactive-opacity\s*=.*):#\1;:; \
s:^\s*#\s*(opacity-rule\s*=)\s*\[\s*\].*:\1 \[\n  \"80\:class_g \*= '' \&\& \!focused\",\n  \"97\:class_g \*= '' \&\& focused\"\n\]:; \
s:^\s*(\s*corner-radius\s*=.*):\1\ncorner-radius = 12:; \
s:^\s*(rounded-corners-exclude\s*=\s*\[):\1\n \"class_g = 'i3bar'\",:g; \
s:^\s*(blur-kern\s*=.*):#\1;:; \
s:^\s*(backend\s*=).*:\1 \"glx\"\nglx-use-copysubbuffer-mesa = true:; \
s:^\s*(#\s*unredir-if-possible\s+.*):\1\nunredir-if-possible = true:; \
s:^\s*(use-damage\s*=).*:\1 false;:; \
s:^\s*(#\s*glx-no-stencil\s+.*):\1\nglx-no-stencil = true:g; \
s:^\s*(#\s*glx-no-rebind-pixmap\s+.*):\1\nglx-no-rebind-pixmap = true:; \
s:^\s*(#\s*xrender-sync-fence\s+.*):\1\nxrender-sync-fence = true:; \
s:^([ ]+dock = \{).*:\1 fade = true; shadow = true; full-shadow = true; clip-shadow-above = true; \}:" \
$V_HOME/.config/picom/picom.conf

COMMENTHASH="#"
if [ -n "$S_PICOM_EXP_BACK" ]; then
  COMMENTHASH=""
fi
sed -i -E \
"s:^\s*(#\s*blur-method\s+.*):\1\n${COMMENTHASH}blur-method = \"dual_kawase\":g; \
s:^\s*(#\s*blur-strength\s+.*):\1\n${COMMENTHASH}blur-strength = 1:g" \
$V_HOME/.config/picom/picom.conf

#
# Autorun with i3
service_ctl user install-on ./package/picom/systemd/aw-picom.service

#
# Experimental backends
if [ -n "$S_PICOM_EXP_BACK" ]; then
  sudo sed -i -E \
  "s:(.*/usr/bin/picom):\1 --experimental-backends:" \
  /usr/lib/systemd/user/aw-picom.service
fi

#
# On
service_ctl user on aw-picom.service
