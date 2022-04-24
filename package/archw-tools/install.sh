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
  service_ctl sys "$1" "aw-suspendlock@${S_MAINUSER}"

  #
  # User
  service_ctl user "$1" "$(ls ./package/archw-tools/systemd/user/ | egrep -i '\.(service|timer)$')"
}

#
# Version compare
version () {
  echo "$@" | awk -F. '{ printf("%d%04d%04d%04d\n", $1,$2,$3,$4); }'
}

if [ -n "$ARG_ARCHW_UPDATE" ]; then
  #
  # Get old (current) ArchW version
  OLDVER=$(archw --version | sed -n -e 's/^.*version //p')

  #
  # Disable services if updating
  sst off
  sleep 2
fi

#
# Packages
sudo pacman --noconfirm -S pacman-contrib bc jq xdotool
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
# Add functions library
sudo mkdir $S_ARCHW_LIB/library
sudo \cp -a ./library/functions.sh $S_ARCHW_LIB/library

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
mkdir -p $S_ARCHW_CONF
mergeconf user ./package/archw-tools/config/ $S_ARCHW_CONF

#
# Install services
sudo \cp -r ./package/archw-tools/systemd/system/* /etc/systemd/system/
sudo \cp -r ./package/archw-tools/systemd/user/* /usr/lib/systemd/user/
sudo \cp -r ./package/archw-tools/udev/* /etc/udev/rules.d/
sudo chmod +x ./package/archw-tools/systemd/system-sleep/*
sudo \cp -r ./package/archw-tools/systemd/system-sleep/* /usr/lib/systemd/system-sleep/

#
# Install systemd configs
sudo mkdir -p /usr/lib/systemd/{logind.conf.d,sleep.conf.d}
mergeconf sys ./package/archw-tools/systemd/logind.conf.d /usr/lib/systemd/logind.conf.d
mergeconf sys ./package/archw-tools/systemd/sleep.conf.d /usr/lib/systemd/sleep.conf.d

#
# Install sudoers.d
sudo \cp -r ./package/archw-tools/sudoers.d/* /etc/sudoers.d/

if [ -n "$ARG_ARCHW_UPDATE" ]; then
  #
  # Enable services state
  sst on

  #
  # Start some i3 driven services if updating
  sudo udevadm control --reload

  #
  # Install system updates
  # that not yet installed
  if [ -d ./package/archw-tools/updates ]; then
    SYSUPD=($(ls ./package/archw-tools/updates | sort --version-sort))
    for u in "${SYSUPD[@]}"; do
      uv="${u%.*}"
      if [ $(version $uv) -gt $(version $OLDVER) ]; then
        #&& [ $(version $uv) -lt $(version $NEWVER) ]
        if [ -f ./package/archw-tools/updates/$u ]; then
          echo "Installing system update $uv"
          . ./package/archw-tools/updates/$u
          sleep 1
        fi
      fi
    done
  fi
else
  #
  # Set default state while install
  sudo systemctl enable aw-suspendlock@${S_MAINUSER}
  systemctl --user enable aw-autosuspend.service
  systemctl --user enable aw-ondcscreenpm.service
  systemctl --user enable aw-ondci3status.service
  systemctl --user enable aw-pslistener.service
  systemctl --user enable aw-screen-state-off-lock.service
  systemctl --user enable aw-xeventbind-autostart.service
  systemctl --user enable aw-autolanguageloader.service
  systemctl --user enable aw-initiateaudio.service
  systemctl --user enable aw-screenoni3.service
  systemctl --user enable aw-alt-screenoff.service
  systemctl --user enable aw-onunlockscreenpm.service
fi
