#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# SYS - system commands
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--sys                     ;System commands
"
fi
if [ "$1" == 'help' ]; then
  echo "
--sys <mode>              ;System commands <mode>s:
  upd [<opt>] [-y]        ;Update everything. Set --noconfirm mode with [-y] flag. [<opt>]ions:
                          ;core  - update only from core repository
                          ;aur   - update only from aur repository
                          ;archw - update only archw packages
                          ;check - check for available updates and list them
  autosnap [<num>]        ;if Timeshift installed, show status of automatic snapshots creation before system upgrade.
                          ;Optionally set [<num>] of autosnapshots to keep in recovery. Set [<num>] to 0 to disable.
                          ;Only works when updating with \"archw --upd\" command, or through menu bar button.
  install [<package> ...] ;List avaliable ArchW integrated packages, optionally set [<package> ...] to install
  audiosleep [on|off]     ;Show audio sleep status, optionally turn it [on|off]
  rsa [<name>]            ;Generate RSA key with optional [<name>] and copy it to clipboard
  gpg                     ;Generate GnuPG key
  enable-hib [force]      ;Enable system hibernation support. Re-enable with optional [force] parameter
"
#
# System api:
# i3status-restart        ;Restart i3status
# waitconn <sec> <try>    ;Wait <sec> for internet connection with <try> attempts
# pathconf <conf>         ;Get <conf> path (for service apps)
#
fi

#
# Module content
sys () {
  #
  # Get git pkg name
  archw_pkg_name () {
    local DIR="./"
    if [ -n "$1" ]; then
      local DIR=$1
    fi
    S_ARCHW_GITPKG_NAME=$(ls $DIR | grep $S_ARCHW_GITPKG_NAME | tr -d '[:space:]')
  }
  #
  # Get archw package
  archw_pkg_get () {
    local CD=$(pwd)
    cd /tmp
    curl -L $S_ARCHW_GITPKG | tar xz
    #
    # Set exact package name
    archw_pkg_name /tmp
    #
    # Go back
    cd $CD
  }

  #
  # ArchW tools update
  archw_tools_update () {
    local GITVER=$(curl --silent $S_ARCHW_GITPKG_VERSION -o /dev/stdout 2> /dev/null)
    local VER=$(archw --version | sed -n -e 's/^.*version //p')
    #
    # Check if archw exist locally
    if ls /tmp/$S_ARCHW_GITPKG_NAME > /dev/null 2>&1; then
      #
      # Get name
      archw_pkg_name /tmp
    fi

    if [ -n "$GITVER" ] && [ "$GITVER" != "$VER" ]; then
      #
      # If check only
      if [ "$1" == "check" ]; then
        echo "archw-tools $VER -> $GITVER"
        return 0
      fi
      #
      # Update
      echo "Updating ArchW tools"
      sudo rm -rf /tmp/$S_ARCHW_GITPKG_NAME > /dev/null 2>&1
      archw_pkg_get
      echo "Installing package: $S_ARCHW_GITPKG_NAME"
      (cd /tmp/$S_ARCHW_GITPKG_NAME && ./install.sh --archw-tools $1)
    else
      #
      # If not check only
      if [ "$1" != "check" ]; then
        echo "Latest version of ArchW tools installed: $VER"
        echo "there is nothing to do"
      fi
    fi
  }

  #
  # Autosnap
  autosnap () {
    #
    # Load config
    wconf load "sys.conf"
    #
    # Check if snap needed
    if [ -n "$AUTOSNAP" ] && [ "$AUTOSNAP" != "0" ] && which timeshift > /dev/null 2>&1; then
      local SNAPNAME="{autosnap} {created before upgrade}"
      #
      # Create snapshot
      echo "Creating new snapshot..."
      if ! sudo timeshift --create --comments "$SNAPNAME" > /dev/null 2>&1; then
        echo "Unable to run autosnap! Please close Timeshift and try again."
        echo ""; read -p "Press any key to exit..." -r
        exit 1
      fi
      #
      # Delete overlimit snapshots
      local TODELETE=($(sudo timeshift --list | sed -n "/$SNAPNAME/p" | awk '{print $3}'))
      if (( ${#TODELETE[@]} > $AUTOSNAP )); then
        local COUNTER=$(( ${#TODELETE[@]} - $AUTOSNAP - 1 ))
        echo "Deleting $(( $COUNTER + 1 )) old snapshot(s)..."
        for (( c=0; c<=$COUNTER; c++ )); do
          sudo timeshift --delete --snapshot "${TODELETE[$c]}"
          echo "Snapshot ${TODELETE[$c]} deleted"
        done
      fi
    fi
  }

  #
  # Save i3 socket
  if [ "$2" == "i3socketsave" ]; then
    echo "$I3SOCK" > "${S_ARCHW_FOLDER}/i3socket"
    echo "i3 socket saved"
    return 0
  fi

  if [ "$2" == "upd" ]; then
    #
    # Check for updates only
    if [ "$3" == "check" ]; then
      if RES=$(archw_tools_update check 2> /dev/null && checkupdates 2> /dev/null && yay -Qum 2> /dev/null); then
        echo "$RES"
      fi
      return 0
    fi

    #
    # Update

    #
    # Set noconfirm option
    if [ "$3" == "-y" ] || [ "$4" == "-y" ]; then
      NOCONFIRM="--noconfirm"
    fi

    #
    # Set mode
    if [ -n "$3" ] && [ "$3" != "-y" ]; then
      if [ -n "$4" ] && [ "$4" != "-y" ]; then
        error
      fi
      if [ $3 == "core" ]; then
        U_CORE=true
      elif [ $3 == "aur" ]; then
        U_AUR=true
      elif [ $3 == "archw" ]; then
        U_ARCHW=true
      else
        error
      fi
    else
      U_CORE=true
      U_AUR=true
      U_ARCHW=true
    fi

    #
    # Autosnapshot
    autosnap

    #
    # Update
    if [ -n "$U_CORE" ]; then
      sudo pacman -Syyu $NOCONFIRM
    fi
    if [ -n "$U_AUR" ]; then
      yay -Syyua $NOCONFIRM
    fi
    if [ -n "$U_ARCHW" ]; then
      archw_tools_update $NOCONFIRM
    fi
    exit 0
  elif [ "$2" == "autosnap" ]; then
    #
    # Check autosnap
    if [ -n "$3" ]; then
      if [[ "$3" =~ ^[0-9]+$ ]]; then
        wconf set "sys.conf" AUTOSNAP "$3"
        if [ "$3" == "0" ]; then
          echo "Autosnap disabled"
        else
          echo "Autosnap enabled with $3 latest snapshot(s) in recovery"
        fi
        return 0
      else
        error
      fi
    fi
    #
    # Print info
    wconf load "sys.conf"
    if [ -n "$AUTOSNAP" ] && [ "$AUTOSNAP" == "0" ]; then
      echo "Autosnap disabled"
    else
      echo "Autosnap enabled with $AUTOSNAP latest snapshot(s) in recovery"
    fi
    return 0
  elif [ "$2" == "install" ]; then
    #
    # Install archw packages
    archw_tools_update --noconfirm
    #
    # Check if archw package exist in tmp
    if [ ! -d /tmp/$S_ARCHW_GITPKG_NAME ]; then
      archw_pkg_get
    fi
    #
    # Install ArchW packages manually
    if [ -n "$3" ]; then
      shift 2
      local PKGS=($(echo "$@"))
      #
      # Check if pkgs exist
      for pkg in "${PKGS[@]}" ; do
        if [ ! -d /tmp/$S_ARCHW_GITPKG_NAME/package/$pkg ]; then
          echo "Package \"$pkg\" can't be found"
          exit 1
        fi
      done
      #
      # Install packages
      ARCHW_PKG_INST=1
      cd /tmp/$S_ARCHW_GITPKG_NAME
      #
      # Load package configs
      . ./config
      . ./patch/config
      . ./software
      # Load main functions
      . ./library/functions.sh
      # Load local archw config
      load_archw_local_conf
      # Set glob shortcuts
      set_glob_shortcuts
      # Create dirs
      mk_install_sys_dirs
      # Load devices config
      load_devices_config
      # Set update runtime shortcuts
      V_TMP_PKG=$S_PKG
      S_PKG=/tmp/$S_ARCHW_GITPKG_NAME
    	cd $S_PKG
    	S_MAINUSER=$(id -un)
      V_HOME=$HOME
      # loop packages
      for pkg in "${PKGS[@]}" ; do
        echo "Installing package \"$pkg\"..."
        . ./package/$pkg/install.sh
      done
      # Restart key service
      if ps -A | grep sxhkd; then
        archw --key restart > /dev/null 2>&1 &
      fi
      # Cleanup
      sudo rm -rf $V_TMP_PKG
      return 0
    fi
    #
    # List avaliable software
    echo "Avaliable packages:"
    ls /tmp/$S_ARCHW_GITPKG_NAME/package | sed -E "/(archw-tools|common-scripts|wallpapers)/d"
    return 0
  elif [ "$2" == "audiosleep" ]; then
    #
    # Control audio sleep
    # Check audio sleep status
    local AUDSLPSTAT="on"
    if cat /etc/pulse/default.pa | grep -w "#load-module module-suspend-on-idle" > /dev/null 2>&1; then
      AUDSLPSTAT="off"
    fi

    if [ -n "$3" ]; then
      if [ "$3" == "on" ]; then
        if [ "$AUDSLPSTAT" == "off" ]; then
          #
          # Enable module
          sudo sed -i -E \
          "s:^#(load-module module-suspend-on-idle):\1:" \
          /etc/pulse/default.pa
          #
          # Change idle time
          sudo sed -i -E \
          "s:^\s*(exit-idle-time =).*:\; \1 20:" \
          /etc/pulse/daemon.conf
        fi
        systemctl --user restart pulseaudio
        #bash -c "archw --sys aw-initiateaudio > /dev/null 2>&1" &
        echo "Audio sleep mode on"
        return 0
      elif [ "$3" == "off" ]; then
        if [ "$AUDSLPSTAT" == "on" ]; then
          #
          # Disable module
          sudo sed -i -E \
          "s:^(load-module module-suspend-on-idle):#\1:" \
          /etc/pulse/default.pa
          #
          # Change idle time
          sudo sed -i -E \
          "s:^\s*;\s*(exit-idle-time =).*:\1 -1:" \
          /etc/pulse/daemon.conf
        fi
        systemctl --user restart pulseaudio
        bash -c "archw --sys aw-initiateaudio > /dev/null 2>&1" &
        echo "Audio sleep mode off"
        return 0
      fi
    else
      echo "Audio sleep status: $AUDSLPSTAT"
      return 0
    fi
  elif [ "$2" == "enable-hib" ]; then
    #
    # Enable hibernation
    # Check if already enabled
    if [ -f "$S_ARCHW_FOLDER/HIB" ] && [ "$3" != "force" ]; then
      echo "Hibernation already enabled on your system"
      return 0
    fi
    #
    # Check sys memory and swap
    local MEMSIZE=$(free | grep "Mem:" | awk '{print $2}')
    local SWAPSIZE=$(free | grep "Swap:" | awk '{print $2}')
    if [ -z "$SWAPSIZE" ]; then
      echo "Error: your system has no swap. Please, enable it first."
      exit 1
    elif (( $MEMSIZE > $SWAPSIZE )); then
      echo "Attention: your swap size is less then RAM size."
      echo "For system hibernation it is advised to set up"
      echo "swap size larger then RAM size."
      read -p "Continue hibernation setup anyway? (y/n) " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    fi
    #
    # Load functions library
    load_functions
    # Load local archw config
    load_archw_local_conf
    # Load devices config
    load_devices_config
    # Enable hibernation
    set_hibernation
    if [[ $? -eq 0 ]]; then
      echo "System hibernation setup has been completed."
      echo "Check \"archw --help pm\" for configuration help"
      return 0
    else
      exit 1
    fi
  elif [ "$2" == "rsa" ]; then
    #
    # RSA gen
    S_IDRSA_PATH=$HOME/.ssh/id_rsa
  	if [ -n "$3" ]; then
  		CONF_NAME="-C $3"
  	fi
  	ssh-keygen -t rsa -b 2048 -f $S_IDRSA_PATH $CONF_NAME
    sleep 1
  	xclip -sel clip < "${S_IDRSA_PATH}.pub"
  	echo "Key ${S_IDRSA_PATH}.pub has been copied to clipboard"
    return 0
  elif [ "$2" == "gpg" ]; then
    #
    # GPG gen
    gpg --gen-key
    return 0
  elif [ "$2" == "i3status-restart" ]; then
    #
    # Restart i3status
    pgrep i3status | xargs --no-run-if-empty kill -s USR1
    return 0
  elif [ "$2" == "i3-restart" ]; then
    #
    # Restart i3
    #i3-msg reload
    i3-msg restart
    return 0
  elif [ "$2" == "waitconn" ] && [[ $3 =~ ^[0-9]+$ ]] && [[ $4 =~ ^[0-9]+$ ]]; then
    #
    # Wait for internet connection
    local SLEEPTIME=$3
    local ATTEMPTS=$4
    #
    # IP pinger
    check_ip () {
      #echo "Checking network connection (${1})"
      if ping -q -w 2 -c 1 $1 > /dev/null 2>&1; then
        return 0
      else
        return 1
      fi
    }
    # Check if machine connected to the internet
    # Run pinger on list of DNSes
    connected () {
      # servers to ping
      declare -a arr=(
                       8.8.8.8
                       8.8.4.4
                       77.88.8.8
                       77.88.8.1
                     )
      # ping in loop if false
      for i in "${!arr[@]}"
      do
        # if ping ok, return true
        if check_ip "${arr[$i]}"; then
          return 0
          break
        fi
      done
      # else return false
      return 1
    }
    #
    # Connection tester
    local CHECKCOUNTER=0
    ping_connection () {
      #
      # If no ip within provided attempts number
      if [ $CHECKCOUNTER -gt $ATTEMPTS ]; then
        exit 1
      fi

      #
      # Check loop
      if ! connected; then
        CHECKCOUNTER=$(( CHECKCOUNTER + 1 ))
        sleep $SLEEPTIME
        ping_connection
      fi
      return 0
    }
    #
    # Run test
    if ping_connection; then
      exit 0
    else
      exit 1
    fi
  elif [ $2 == "pathconf" ] && [ -n "$3" ]; then
    #
    # Get config path
    wconf path $3
    return 0
  elif [ $2 == "stopsystem" ]; then
    #
    # Gently stop system before logout/restart/shutdown
    systemctl --user stop aw-autolayoutloader.target
    systemctl --user stop aw-i3.target
    i3-msg workspace "Shutting down windows manager..."
    #
    # Wait
    sleep 1
    return 0
  elif [ $2 == "aw-initiateaudio" ]; then
    #
    # Fix some sound cards by initiating audio
    bash -c "aplay -f S16_LE /dev/zero" &
    local PID=$!
    sleep 5
    kill $PID > /dev/null 2>&1
    return 0
  fi
  error
}
#
