#!/bin/bash

#sudo pacman --noconfirm -S picom
yay --noconfirm -S picom-git
mkdir -p $V_HOME/.config/picom
cp /etc/xdg/picom.conf.example $V_HOME/.config/picom/picom.conf

#
# Picom
sed -i -E \
"s:^\s*(fade-in-step\s*=).*:\1 0.009;:; \
s:^\s*(fade-out-step\s*=).*:\1 0.009;:; \
s:^\s*(#\s*fade-delta\s*=.*):\1\nfade-delta = 1:; \
s:^\s*(inactive-opacity\s*=.*):#\1;:; \
s:^\s*#\s*(opacity-rule\s*=)\s*\[\s*\].*:\1 \[\n  \"78\:class_g \*= '' \&\& \!focused\",\n  \"97\:class_g \*= '' \&\& focused\"\n\]:; \
s:^\s*(blur-kern\s*=.*):#\1;:; \
s:^\s*(backend\s*=).*:\1 \"glx\":; \
s:^\s*(#\s*unredir-if-possible\s+.*):\1\nunredir-if-possible = true:g; \
s:^\s*(#\s*glx-no-stencil\s+.*):\1\nglx-no-stencil = true:g; \
s:^\s*(#\s*glx-no-rebind-pixmap\s+.*):\1\nglx-no-rebind-pixmap = true:g; \
s:^\s*(#\s*xrender-sync-fence\s+.*):\1\nxrender-sync-fence = true:g" \
$V_HOME/.config/picom/picom.conf

if [ -n "$S_PICOM_EXP_BACK" ]; then
  sed -i -E \
  "s:^\s*(#\s*blur-method\s+.*):\1\nblur-method = \"dual_kawase\":g; \
  s:^\s*(#\s*blur-strength\s+.*):\1\nblur-strength = 1:g" \
  $V_HOME/.config/picom/picom.conf
fi
