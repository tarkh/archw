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
  monbat <sec>   ;Same as <mon>, but when system is on battery
  sleepbat <sec> ;Same as <sleep>, but when system is on battery
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
    if sa "dc-state-on.target"; then
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
      elif [ $2 == "monbat" ]; then
        wconf set "pm.conf" SCREEN_OFF_BAT "$3"
      elif [ $2 == "sleepbat" ]; then
        wconf set "pm.conf" SUSPEND_BAT "$3"
      fi
      archw --pm applynow
      echo "PM applied, $2: $3"
      return 0
    elif [ $2 == "applynow" ]; then
      dpms
      return 0
    fi
    error
  else
    #
    # Show current settings
    echo "mon: $SCREEN_OFF_AC
sleep: $SUSPEND_AC
monbat: $SCREEN_OFF_BAT
sleepbat: $SUSPEND_BAT"
    return 0
  fi
  error
}
