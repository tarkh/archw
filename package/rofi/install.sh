#!/bin/bash

sudo pacman --noconfirm -S rofi

ROFICMD="rofi -show drun"

#
# Rofi skin
mkdir -p ${V_HOME}/.config/rofi/
\cp -r ./package/rofi/archw-theme.rasi $V_HOME/.config/rofi/

#
# Rofi settings
\cp -r ./package/rofi/config.rasi $V_HOME/.config/rofi/
sed -i -E \
"s:^(\s*terminal\:).*:\1 \"$S_SYSTEM_TERMINAL\";:" \
$V_HOME/.config/rofi/config.rasi

#
# Add to picom
sed -i -E \
"/\b(Rofi)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"95\:class_g = 'Rofi' \&\& \!focused\",:" \
$V_HOME/.config/picom/picom.conf

#
# Hotkeys
if [ -n "$S_ADD_SXHKD" ]; then
  I3ROFIDISABLE="#"
  mkdir -p $V_HOME/.config/sxhkd/
  bash -c "cat > $V_HOME/.config/sxhkd/rofi.conf" << EOL
# Menu
{super + d, XF86LaunchB}
 aw-xprof $ROFICMD

alt + Tab
 aw-xprof rofi -show window

# Layout selector menu
super + control + l
  archw --layout menu

EOL
fi

#
# i3 config
if [ -z "$S_ADD_DMENU" ]; then
  sed -i -E \
  "s:^\s*[#]*(\s*bindsym.*mod\+)(\w+)(.*)dmenu_run.*:#\1\2\3:" \
  ${V_HOME}/.config/i3/config
fi
sed -i -E \
"s:^\s*[#]*\s*(bindsym|bindcode)\s*(.*mod\+)(\w+)(.*)\s\"rofi.*:${I3ROFIDISABLE}bindsym \2d\4 \"aw-xprof ${ROFICMD}\":" \
${V_HOME}/.config/i3/config

#
# Re-apply current gui dpi profile
if [ -n "$ARCHW_PKG_INST" ]; then
  S_GUIDPI=$(archw --gui preset | cut -d ":" -f2 | sed -E "s:\s+::")
  . ./package/set-guidpi/install.sh
fi
