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
# Install touchpad
# (if not installed by default)
ProgressBar
if [ -n "$S_ADD_MTRACK" ]; then
  sudo bash -c "cat > /etc/X11/xorg.conf.d/00-touchpad.conf" << EOL
Section "InputClass"
MatchIsTouchpad "on"
Identifier "Touchpads"
MatchDevicePath "/dev/input/event*"
Driver "mtrack"
# Physical buttons
Option "ButtonEnable" "true"
Option "ButtonIntegrated" "true"
# Zones
Option "ButtonZonesEnable" "true"
Option "FirstZoneButton" "1"
Option "SecondZoneButton" "2"
Option "ThirdZoneButton" "3"
Option "LimitButtonZonesToBottomEdge" "true"
Option "EdgeBottomSize" "0"
# Gesture wait time
Option "GestureWaitTime" "20"
# The faster you move, the more distance pointer will travel, using "polynomial" profile
#Option "AccelerationProfile" "2"
# Tweak cursor movement speed with this
Option "Sensitivity" "0.15"
# Pressure at which a finger is detected as a touch
Option "FingerHigh" "8"
# Pressure at which a finger is detected as a release
Option "FingerLow" "7"
# I often use thumb to press down the physical button, so let's not ignore it
Option "IgnoreThumb" "false"
Option "ThumbRatio" "70"
Option "ThumbSize" "25"
# Ignore palm, with palm takes up to 30% of your touch pad
Option "IgnorePalm" "true"
Option "PalmSize" "40"
# Trigger mouse button when tap: 1 finger - left click, 2 finger - right click, 3 - middle click
Option "TapButton1" "1"
Option "TapButton2" "3"
Option "TapButton3" "2"
Option "TapButton4" "0"
Option "ClickTime" "25"
# Disable tap-to-drag, we're using three finger drag instead
Option "TapDragEnable" "false"
# While touching the touch pad with # fingers, press the touchpad physical click button
Option "ClickFinger1" "1"
Option "ClickFinger2" "3"
Option "ClickFinger3" "2"
Option "ButtonMoveEmulate" "false"
Option "ButtonIntegrated" "true"
# The momentum after scroll fingers released
Option "ScrollCoastDuration" "950"
Option "ScrollCoastEnableSpeed" "0.05"
# Natural scrolling with two fingers
Option "ScrollSmooth" "true"
Option "ScrollUpButton" "4"
Option "ScrollDownButton" "5"
Option "ScrollLeftButton" "7"
Option "ScrollRightButton" "6"
# Tweak scroll sensitivity with ScrollDistance, don't touch ScrollSensitivity
Option "ScrollDistance" "650"
Option "ScrollClickTime" "20"
# Three finger drag
Option "SwipeDistance" "1"
Option "SwipeLeftButton" "1"
Option "SwipeRightButton" "1"
Option "SwipeUpButton" "1"
Option "SwipeDownButton" "1"
Option "SwipeClickTime" "0"
Option "SwipeSensitivity" "1500"
# Four finger swipe, 8 & 9 are for browsers navigating back and forth respectively
Option "Swipe4LeftButton" "9"
Option "Swipe4RightButton" "8"
# Mouse button >= 10 are not used by Xorg, so we'll map them with xbindkeys and xdotool later
Option "Swipe4UpButton" "11"
Option "Swipe4DownButton" "10"
# Mouse buttons triggered by 2-finger pinching gesture
Option "ScaleDistance" "300"
Option "ScaleUpButton" "12"
Option "ScaleDownButton" "13"
# Mouse buttons trigger by 2-finger rotating gesture, disabled to enhance the pinch gesture
Option "RotateLeftButton" "0"
Option "RotateRightButton" "0"
EndSection
EOL
fi

#
# Mouse
ProgressBar
sudo bash -c "cat > /etc/X11/xorg.conf.d/40-libinput.conf" << EOL
Section "InputClass"
      Identifier "libinput pointer catchall"
      MatchIsPointer "on"
      MatchDevicePath "/dev/input/event*"
      Driver "libinput"
      Option "NaturalScrolling" "False"
EndSection
EOL

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
