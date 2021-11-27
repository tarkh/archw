#!/bin/bash

#
# Pathes
S_ARCHW_BIN=/usr/local/bin
S_ARCHW_LIB=/usr/local/lib/archw
S_ARCHW_FOLDER=/usr/share/archw
S_ARCHW_CONF=$V_HOME/.config/archw

#
# Services
sst () {
  #
  # Sys
  service_ctl sys "$1" "suspendlock@${S_MAINUSER}"

  #
  # User
  service_ctl user "$1" "$(ls ./package/archw-tools/systemd/user/ | egrep -i '\.(service|timer)$')"
}

#
# Disable services if updating
if [ -n "$ARG_ARCHW_UPDATE" ]; then
  sst off
  sleep 2
fi

#
# Packages
sudo pacman --noconfirm -S pacman-contrib jq xdotool
yay --noconfirm -S xlayoutdisplay --needed

#
# Create dirs
sudo mkdir -p $S_ARCHW_FOLDER $S_ARCHW_LIB
sudo chmod 777 $S_ARCHW_FOLDER

#
# Touch various stuff
touch "$S_ARCHW_FOLDER/USER_${S_MAINUSER}"

#
# Copy programs and modules
sudo \cp -a ./package/archw-tools/bin/. $S_ARCHW_BIN
sudo chmod +x $S_ARCHW_BIN/*
sudo \cp -r ./package/archw-tools/VERSION ./package/archw-tools/modules $S_ARCHW_LIB
sudo chmod +x $S_ARCHW_LIB/modules/*

#
# Copy side modules and configs if updating
if [ -n "$ARG_ARCHW_UPDATE" ]; then
  #
  # Modules
  SMODULES=($(find ./ -type d -name "archw-module"))
  for smp in "${SMODULES[@]}"; do
    sml=($(ls $smp))
    for sm in "${sml[@]}" ; do
      if [ -f "${S_ARCHW_LIB}/modules/${sm}" ]; then
        sudo \cp $smp/$sm $S_ARCHW_LIB/modules
        sudo chmod +x $S_ARCHW_LIB/modules/$sm
      fi
    done
  done
  #
  # Configs
  SCONFIGS=($(find ./ -type d -name "archw-config"))
  for scp in "${SCONFIGS[@]}"; do
    scl=($(ls $scp))
    for sc in "${scl[@]}" ; do
      if [ -f "${S_ARCHW_FOLDER}/${sc}" ]; then
        sudo \cp "$scp/$sc" $S_ARCHW_FOLDER
        # Merge config
        mergeconf user "$scp/$sc" $S_ARCHW_CONF
      fi
    done
  done
fi

#
# Apps configs
sudo \cp -r ./package/archw-tools/config/* $S_ARCHW_FOLDER
#if [ -z "$ARG_ARCHW_UPDATE" ]; then
  mkdir -p $S_ARCHW_CONF
  mergeconf user ./package/archw-tools/config/ $S_ARCHW_CONF
#fi

#
# Install services
sudo \cp -r ./package/archw-tools/systemd/system/* /etc/systemd/system/
sudo \cp -r ./package/archw-tools/systemd/user/* /usr/lib/systemd/user/
sudo \cp -r ./package/archw-tools/udev/* /etc/udev/rules.d/
sudo chmod +x ./package/archw-tools/systemd/system-sleep/*
sudo \cp -r ./package/archw-tools/systemd/system-sleep/* /usr/lib/systemd/system-sleep/

#
# Enable services state
if [ -n "$ARG_ARCHW_UPDATE" ]; then
  sst on
else
  #
  # Set default state while install
  sudo systemctl enable suspendlock@${S_MAINUSER}
  systemctl --user enable autosuspend.service
  systemctl --user enable ondcscreenpm.service
  systemctl --user enable ondci3status.service
  systemctl --user enable pslistener.service
  systemctl --user enable screen-state-off-lock.service
  systemctl --user enable xeventbind-autostart.service
  systemctl --user enable autolanguageloader.service
  systemctl --user enable initiateaudio.service
fi

#
# Start some i3 driven services if updating
if [ -n "$ARG_ARCHW_UPDATE" ]; then
  sudo udevadm control --reload
fi
