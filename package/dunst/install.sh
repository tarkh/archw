#!/bin/bash

#sudo pacman --noconfirm -S libnotify dunst
#sudo pacman --noconfirm -R dunst > /dev/null 2>&1

sudo pacman --noconfirm -S libnotify
yay --noconfirm -S pod2man dunst

#
# Copy config
mkdir -p $V_HOME/.config/dunst
\cp -r /usr/etc/xdg/dunst/dunstrc $V_HOME/.config/dunst/

#
# Patch config
sed -i -E \
"s:^(\s*follow\s+=).*:\1 none:; \
s:^(\s*width\s+=).*:\1 400:; \
s:^(\s*height\s+=).*:\1 80:; \
s:^(\s*offset\s+=).*:\1 30x30:; \
s:^(\s*notification_limit\s+=).*:\1 6:; \
s:^(\s*progress_bar_height\s+=).*:\1 5:; \
s:^(\s*progress_bar_frame_width\s+=).*:\1 0:; \
s:^(\s*progress_bar_min_width\s+=).*:\1 400:; \
s:^(\s*progress_bar_max_width\s+=).*:\1 400:; \
s:^(\s*transparency\s+=).*:\1 15:; \
s:^(\s*padding\s+=).*:\1 6:; \
s:^(\s*horizontal_padding\s+=).*:\1 6:; \
s:^(\s*text_icon_padding\s+=).*:\1 10:; \
s:^(\s*frame_width\s+=).*:\1 0:; \
s:^(\s*frame_color\s+=).*:\1 \"#741B86\":; \
s:^(\s*separator_color\s+=).*:\1 auto:; \
s:^(\s*font\s+=).*:\1 'RobotoMono Nerd Font' 10:; \
s:^(\s*ellipsize\s+=).*:\1 end:; \
s:^(\s*ignore_newline\s+=).*:\1 yes:; \
s:^(\s*show_indicators\s+=).*:\1 no:; \
s:^(\s*min_icon_size\s+=).*:\1 48:; \
s:^(\s*max_icon_size\s+=).*:\1 68:; \
s:^(\s*icon_path\s+=).*:\1 /usr/share/icons/Papirus-Dark/16x16/actions/\:/usr/share/icons/Papirus-Dark/16x16/devices/\:/usr/share/icons/Papirus-Dark/24x24/panel/:; \
s:^(\s*history_length\s+=).*:\1 30:; \
s:^(\s*mouse_middle_click\s+=).*:\1 close_all:; \
s:^(\s*mouse_right_click\s+=).*:\1 do_action, close_current:; \
/^\[urgency_low\]$/,/^\[/ s:(\s*background\s+=).*:\1 \"#140B19\":; \
/^\[urgency_low\]$/,/^\[/ s:(\s*)(foreground\s+=).*:\1\2 \"#A75EAF\"\n\1highlight = \"#A75EAF\":; \
/^\[urgency_low\]$/,/^\[/ s:(\s*)[#]*(\s*icon\s+=).*:\1\2 state-information:; \
/^\[urgency_normal\]$/,/^\[/ s:(\s*background\s+=).*:\1 \"#140B19\":; \
/^\[urgency_normal\]$/,/^\[/ s:(\s*)(foreground\s+=).*:\1\2 \"#D2AAD2\"\n\1highlight = \"#D2AAD2\":; \
/^\[urgency_normal\]$/,/^\[/ s:(\s*)[#]*(\s*icon\s+=).*:\1\2 state-information:; \
/^\[urgency_critical\]$/,/^\[/ s:(\s*background\s+=).*:\1 \"#4d1000\":; \
/^\[urgency_critical\]$/,/^\[/ s:(\s*)(foreground\s+=).*:\1\2 \"#F73602\"\n\1highlight = \"#F73602\":; \
/^\[urgency_critical\]$/,/^\[/ s:(\s*frame_color\s+=).*:\1 \"#F73602\":; \
/^\[urgency_critical\]$/,/^\[/ s:(\s*)[#]*(\s*icon\s+=).*:\1\2 state-error:" \
$V_HOME/.config/dunst/dunstrc

#
# Rofi
if [ -n "$S_ADD_ROFI" ]; then
  sed -i -E \
  "s:^(\s*dmenu\s*=\s*).*:\1${V_XPROF} /usr/bin/rofi -dmenu -p dunst:" \
  $V_HOME/.config/dunst/dunstrc
fi

#
# Add archw module
sudo \cp -r ./package/dunst/archw-module/* /usr/local/lib/archw/modules

#
# Restart dunst
killall dunst > /dev/null 2>&1

#
# Set common hot keys
mkdir -p $V_HOME/.config/sxhkd
bash -c "cat > $V_HOME/.config/sxhkd/dunst.conf" << EOL
# Pause notifications
super + control + n + p
  archw --osd pause

# Resume notifications
super + control + n + r
  archw --osd resume

EOL
if [ -n "$ARCHW_PKG_INST" ]; then
  archw --key restart
fi
