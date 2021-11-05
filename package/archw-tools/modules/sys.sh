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
  install [<package> ...] ;List avaliable ArchW integrated packages, optionally set [<package> ...] to install
  rsa [<name>]            ;Generate RSA key with optional [<name>] and copy it to clipboard
  gpg                     ;Generate GnuPG key
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
  # Get archw package
  archw_pkg_get () {
    local CD=$(pwd)
    cd /tmp
    curl $S_ARCHW_GITPKG | tar xz
    cd $CD
  }

  #
  # ArchW tools update
  archw_tools_update () {
    local GITVER=$(curl --silent $S_ARCHW_GITPKG_VERSION -o /dev/stdout 2> /dev/null)
    local VER=$(archw --version | sed -n -e 's/^.*version //p')
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
      archw_tools_update check 2> /dev/null
      checkupdates 2> /dev/null
      yay -Qum 2> /dev/null
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
  elif [ "$2" == "install" ]; then
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

      # load configs
      . $S_ARCHW_FOLDER/config/config
      . $S_ARCHW_FOLDER/config/patch/config
      . $S_ARCHW_FOLDER/config/patch/${S_PATCH}/config
      . $S_ARCHW_FOLDER/config/software
      #
      S_PKG=/tmp/$S_ARCHW_GITPKG_NAME
      V_AUR=$S_PKG/AUR
      cd $S_PKG
      . ./library/functions.sh
      local ARCHW_PKG_INST=1
      local V_HOME=$HOME
      local S_ARCHW_FOLDER=/usr/share/archw
      mkdir -p $V_AUR
      chmod 777 $V_AUR
      # loop packages
      for pkg in "${PKGS[@]}" ; do
        echo "Installing package \"$pkg\"..."
        . ./package/$pkg/install.sh
      done
      # Restart key service
      if ps -A | grep sxhkd; then
        archw --key restart > /dev/null 2>&1 &
      fi
      return 0
    fi
    #
    # List avaliable software
    echo "Avaliable packages:"
    ls /tmp/$S_ARCHW_GITPKG_NAME/package | sed -E "/(archw-tools|common-scripts|wallpapers)/d"
    return 0
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
  elif [ "$2" == "waitconn" ] && [[ $3 =~ ^[0-9]+$ ]] && [[ $4 =~ ^[0-9]+$ ]]; then
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
    wconf path $3
    return 0
  fi
  error
}
#
