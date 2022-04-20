#!/bin/bash

sudo rm /etc/i3/config > /dev/null 2>&1
sudo pacman --noconfirm -S i3-gaps perl-anyevent-i3 ttf-dejavu i3lock i3status

\cp ./package/set-common-scripts/.xinitrc $V_HOME
sudo chmod +x ./package/i3/bin/*
sudo \cp -r ./package/i3/bin/* /usr/local/bin
mkdir -p $V_HOME/.config/i3
\cp -r ./package/i3/scripts $V_HOME/.config/i3
\cp -r ./package/i3/img $V_HOME/.config/i3
chmod +x $V_HOME/.config/i3/scripts/*

#
# Add i3bar to picom rules
sed -i -E \
"\:^\s*\"window_type = 'dock'\",.*:d; \
s:^(\s*dock\s+=\s+\{)(.*):\1 fade = true;\2:; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"82\:window_type = 'dock' \&\& class_g = 'i3bar'\",:" \
$V_HOME/.config/picom/picom.conf

#
# Create i3 systemd target
sudo \cp -r ./package/i3/systemd/aw-i3.target /usr/lib/systemd/user/

#
# Start Xorg and generate i3 config
sudo sed -i -E "s:^\s*(exec i3-config-wizard).*:\1 -m${S_I3_MODE_KEY}:" /etc/i3/config
#
sudo bash -c "cat >> /etc/i3/config" << EOL
exec archw --disp dset
exec archw --wp
EOL
#
(xinit "/usr/bin/i3" -- :1 vt1) &
echo "Initializing i3 config..."
sleep 5
# Turn off X
DISPLAY=:1 i3-msg exit
sudo sed -i -E "s:^\s*(exec i3-config-wizard).*:\1:" /etc/i3/config
sudo sed -i "\:^\s*exec\s*archw\s*--disp\s*dset\s*:d" /etc/i3/config
sudo sed -i "\:^\s*exec\s*archw\s*--wp\s*:d" /etc/i3/config
sleep 3
echo "i3 initialization completed!"
echo ""

#
# Comment out unneeded options
sed -i -E \
"s:^[#\s]*(exec --no-startup-id xss-lock.*):#\1:; \
s:^[#\s]*(exec --no-startup-id nm-applet.*):#\1:; \
s:^[#\s]*(exec --no-startup-id xss-lock.*):#\1:" \
${V_HOME}/.config/i3/config

#
# Add picom to the top of the i3 config
if [ -n "$S_PICOM_EXP_BACK" ]; then
  PICOM_EXP_BACK=" --experimental-backends"
fi
cat <<< "#
# Run picom
exec --no-startup-id picom -b${PICOM_EXP_BACK}

$(cat ${V_HOME}/.config/i3/config)" > ${V_HOME}/.config/i3/config

#
# Set windows titles font
sed -i -E \
"s:^\s*(font pango\:).*:\1RobotoMono Nerd Font 8:" \
${V_HOME}/.config/i3/config

#
# i3 status style
I3_STATUS_BAR_STYLE="\n
\n  i3bar_command i3bar
\n  font pango\:RobotoMono Nerd Font 10
\n  separator_symbol \" \"
\n  #position top
\n  #tray_output primary
\n  tray_padding 4
\n  colors {
\n    background #140B19
\n    #background #140B1900
\n    statusline #D2AAD2
\n    separator  #A485A4
\n    focused_workspace  #741B86 #741B86 #FFFFFF
\n    active_workspace   #741B86 #741B86 #D2AAD2
\n    inactive_workspace #532F5F #532F5F #A485A4
\n    urgent_workspace   #900000 #900000 #FFFFFF
\n    binding_mode       #900000 #900000 #FFFFFF
\n  }
\n"
I3_STATUS_BAR_STYLE=`echo ${I3_STATUS_BAR_STYLE} | tr '\n' "\\n"`

#
# Update i3 config
sed -i -E \
"s:^\s*(status_command.*):  \1${I3_STATUS_BAR_STYLE}:; \
s:^(.*)\s10\s*px\s*or\s*10\s*ppt\s*:\1 10 px or 1 ppt:; \
s:^(.*)\s+(i3-sensible-terminal.*):\1 \"\2\":" \
${V_HOME}/.config/i3/config

#
# Screen locker hibernate/suspend
SCR_LOCK_HIB_SUS_MENU=" (s) suspend,"
SCR_LOCK_HIB_SUS_PROC="
  bindsym s exec --no-startup-id systemctl suspend, mode \"default\"
"

#
# If hibernate on
if [ -n "$S_HIBERNATION" ]; then
  SCR_LOCK_HIB_SUS_MENU=" (s) suspend, (h) hibernate,"
  SCR_LOCK_HIB_SUS_PROC="
    bindsym s exec --no-startup-id systemctl suspend-then-hibernate, mode \"default\"
    bindsym h exec --no-startup-id systemctl hibernate, mode \"default\"
  "
fi

#
# If wmware, add copy/paste util launcher
if [ "$S_VM_TOOLS" == "vmware" ]; then
  SCR_LOCK_HIB_SUS_MENU=""
  SCR_LOCK_HIB_SUS_PROC=""
  bash -c "cat >> ${V_HOME}/.config/i3/config" << EOL
#
# Copy/Pase VMWare
exec --no-startup-id vmware-user

EOL
fi

#
# System stop script
SCR_SYSTEM_STOP="archw --sys stopsystem"

#
# Set HIB string
SCR_LOCK_HIB_SUS="System (l) lock, (e) logout,$SCR_LOCK_HIB_SUS_MENU (r) reboot, (Ctrl+s) shutdown"

#
# i3 config alt
bash -c "cat >> ${V_HOME}/.config/i3/config" << EOL
#
# ArchW additional colors
client.focused          #741B86 #741B86 #FFFFFF #A526BF   #A526BF
client.focused_inactive #532F5F #532F5F #A485A4 #484E50   #484E50
client.unfocused        #200030 #200030 #A197A4 #222222   #222222
client.urgent           #900000 #900000 #FFFFFF #900000   #900000
client.placeholder      #000000 #0C0C0C #FFFFFF #000000   #0C0C0C

#
# i3-msg socket save
exec --no-startup-id archw --sys i3socketsave

#
# Keyring
exec --no-startup-id /usr/bin/gnome-keyring-daemon --start --components=ssh,secrets,pkcs11

#
# Add lang switch
bindsym $S_KEYMAP_SW_COMBO exec archw --lang cycle

#
# Screen lock
set \$i3lockwall archw --lock
bindsym \$mod+Ctrl+Shift+l exec --no-startup-id \$i3lockwall

#
# shutdown / restart / suspend...
set \$mode_system $SCR_LOCK_HIB_SUS

mode "\$mode_system" {
  bindsym l exec --no-startup-id \$i3lockwall, mode "default"
  bindsym e exec --no-startup-id $SCR_SYSTEM_STOP && i3-msg exit, mode "default"$SCR_LOCK_HIB_SUS_PROC
  bindsym r exec --no-startup-id $SCR_SYSTEM_STOP && systemctl reboot, mode "default"
  bindsym Ctrl+s exec --no-startup-id $SCR_SYSTEM_STOP && systemctl poweroff -i, mode "default"

  # back to normal: Enter or Escape
  bindsym Return mode "default"
  bindsym Escape mode "default"
}

bindsym \$mod+BackSpace mode "\$mode_system"

# Disable window borders
# You can also use any non-zero value if you'd like to have a border
for_window [class=".*"] border pixel 0

gaps inner 4
gaps outer 0

# Only enable gaps on a workspace when there is at least one container
smart_gaps on

# Only enable outer gaps when there is exactly one container
smart_gaps inverse_outer

# Hide edge borders only if there is one window with no gaps
hide_edge_borders smart_no_gaps

#
# Add floating pop-ups
for_window [window_role="pop-up"]                       floating enable
for_window [window_role="bubble"]                       floating enable
for_window [window_role="task_dialog"]                  floating enable
for_window [window_role="Preferences"]                  floating enable
for_window [window_type="dialog"]                       floating enable
for_window [window_type="menu"]                         floating enable

#
# archw_plugins_injection

#
# Run aw-i3.target and all binded services
exec --no-startup-id systemctl --user start aw-i3.target &

EOL

#
# i3 conf ext
ProgressBar
I3_PLUGIN="
\n#
\n# DPI pop-ups
\nfloating_minimum_size 720 x 480
\nfloating_maximum_size -1 x -1
\n"
I3_PLUGIN=`echo ${I3_PLUGIN} | tr '\n' "\\n"`
sed -i -E "s:^\s*(# archw_plugins_injection)\s*:\1\n${I3_PLUGIN}:" $V_HOME/.config/i3/config

#
# Install key service for power button
if [ -n "$S_SYS_IGNORE_PWR" ]; then
  sudo sed -i -E \
  "s:power_menu_string:'mode \"$SCR_LOCK_HIB_SUS\"':" \
  /usr/local/bin/aw-poweraction
  # key config
  mkdir -p $V_HOME/.config/sxhkd
  bash -c "cat > $V_HOME/.config/sxhkd/power.conf" << EOL
# Toggle power menu
XF86PowerOff
  aw-poweraction off

EOL
fi

#
# i3status
. ./package/i3status-rust/install.sh
