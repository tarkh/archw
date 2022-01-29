#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# PM - basic power management
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--pm             ;Basic power management
"
fi
if [ "$1" == 'help' ]; then
  echo "
--pm [<mode>]    ;List basic PM status, optional [<mode>]s:
  mon <sec>      ;Turn off monitor after <sec>, 0 to disable
  sleep <sec>    ;System sleep after <sec> after monitor is off, 0 to disable.
  hib <sec>      ;System hibernation after <sec> after sleep, 0 to disable.
  monbat <sec>   ;Same as <mon>, but when system is on battery
  sleepbat <sec> ;Same as <sleep>, but when system is on battery
  hibbat <sec>   ;Same as <hib>, but when system is on battery
"
fi

#
# Module content
pm () {
  #
  # Load config
  wconf load "pm.conf"

  #
  # Service Active checker
  sa() {
    if [ "$(systemctl --user show -p ActiveState --value $1)" == "active" ]; then
      return 0
    fi
    return 1
  }

  #
  # dpms set
  dpms() {
    if sa "aw-dc-state-on.target"; then
      TIMEOUT=$SCREEN_OFF_AC
    else
      TIMEOUT=$SCREEN_OFF_BAT
    fi
    xset dpms $TIMEOUT $TIMEOUT $TIMEOUT
    if [ "$TIMEOUT" == "0" ]; then
      TIMEOUT="off"
    fi
    xset s $TIMEOUT
  }

  #
  #
  if [ -n "$2" ]; then
    if [ -n "$3" ] && [ "$3" -eq "$3" ] 2>/dev/null; then
      if [ $2 == "mon" ]; then
        wconf set "pm.conf" SCREEN_OFF_AC "$3"
      elif [ $2 == "sleep" ]; then
        wconf set "pm.conf" SUSPEND_AC "$3"
      elif [ $2 == "hib" ]; then
        if [ -f "/usr/share/archw/HIB" ]; then
          wconf set "pm.conf" HIBERNATE_AC "$3"
        else
          echo "Hibernation is not configured on your system"
          return 1
        fi
      elif [ $2 == "monbat" ]; then
        wconf set "pm.conf" SCREEN_OFF_BAT "$3"
      elif [ $2 == "sleepbat" ]; then
        wconf set "pm.conf" SUSPEND_BAT "$3"
      elif [ $2 == "hibbat" ]; then
        if [ -f "/usr/share/archw/HIB" ]; then
          wconf set "pm.conf" HIBERNATE_BAT "$3"
        else
          echo "Hibernation is not configured on your system"
          return 1
        fi
      else
        error
      fi
      archw --pm applynow
      echo "Settings applied: $2: $3"
      return 0
    elif [ $2 == "applynow" ]; then
      dpms
      aw-pmhibmod
      return 0
    fi
    error
  else
    #
    # Show current settings
    echo "mon: $SCREEN_OFF_AC
sleep: $SUSPEND_AC
hib: $HIBERNATE_AC
monbat: $SCREEN_OFF_BAT
sleepbat: $SUSPEND_BAT
hibbat: $HIBERNATE_BAT"
    return 0
  fi
  error
}
