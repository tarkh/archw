#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# LOCK - screen locker
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--lock             ;Lock screen
"
fi
if [ "$1" == 'help' ]; then
  echo "
--lock [<mode>]    ;Lock screen, optional [<mode>]s:
  sleep [on|off]   ;Show lock on system sleep state, optionally turn it [on|off]
  monsleep [<sec>] ;Show lock on monitor sleep state, set with optional <sec> delay, 0 to disable
"
fi

#
# Module content
lock () {
  if [ -n "$2" ]; then
    #
    # Load config
    wconf load "lock.conf"

    #
    #
    if [ $2 == "sleep" ]; then
      local USER=$(ls /usr/share/archw/ | grep USER | cut -d "_" -f2)
      if [ -n "$3" ]; then
        if [ "$3" == "on" ]; then
          if sudo systemctl enable suspendlock@${USER} > /dev/null; then
            echo "Sleep screen lock: enabled"
            return 0
          else
            echo "Error enabling sleep screen lock"
            return 1
          fi
        elif [ "$3" == "off" ]; then
          if sudo systemctl disable suspendlock@${USER} > /dev/null; then
            echo "Sleep screen lock: disabled"
            return 0
          else
            echo "Error disabling sleep screen lock"
            return 1
          fi
        fi
      else
        echo "Sleep screen lock status: $(systemctl show -p UnitFileState --value suspendlock@${USER})"
        return 0
      fi
    elif [ $2 == "monsleep" ]; then
      if [ -n "$3" ]; then
        if [ "$3" -eq "$3" ]; then
          wconf set "lock.conf" MON_SLEEP_LOCK "$3"
          echo "Monitor sleep screen lock: ${3}d"
          return 0
        fi
      else
        echo "Monitor sleep screen lock status: $MON_SLEEP_LOCK"
        return 0
      fi
    fi
  else
    #
    # Pixelate values: X times to scale down and back up
    LOCK_PIXELATE=8
    # Optional blur, comment out to disable
    # Values: (https://legacy.imagemagick.org/Usage/blur/#blur_args)
    LOCK_BLUR="1x8"
    # Pathes
    icon="$HOME/.config/i3/img/lock.png"
    img=/tmp/i3lock.png
    # Switch input lang to US for passwd to unlock later
    $S_ARCHW_BIN/archw --lang set us 1> /dev/null &
    # Take screenshot
    #scrot -o $img
    # Blur
    IMM_BLUR_MODE=""
    if [ -n "$LOCK_BLUR" ]; then
      IMM_BLUR_MODE="-blur ${LOCK_BLUR} "
    fi
    # Pixelate
    LOCK_SCALE_DOWN=$(awk "BEGIN {print 100/$LOCK_PIXELATE}")
    LOCK_SCALE_UP=$(awk "BEGIN {print 100/$LOCK_SCALE_DOWN*100}")

    #
    # Set convert string
    CONVERT=""

    #
    # Get monitors
    IFS=$'\n'
    local DISP=($(archw --disp rget))
    unset IFS
    if (( ${#DISP[@]} > 1 )); then
      #
      # If there is more then 1 display
      # Get icon sizes
      local ICON_SIZE=$(identify -ping -format "%[fx:w]x%[fx:h]" $icon)
      local ICON_W=$(echo "$ICON_SIZE" | cut -d "x" -f1)
      local ICON_H=$(echo "$ICON_SIZE" | cut -d "x" -f2)
      # Apply composite for displays
      local TOTAL_FROM_LEFT=0
      local COMMAND=""
      for d in "${DISP[@]}" ; do
        # Get display size
        local D_SIZE=$(echo "$d" | cut -d " " -f2)
        local D_W=$(echo "$D_SIZE" | cut -d "x" -f1)
        local D_H=$(echo "$D_SIZE" | cut -d "x" -f2)
        # Define offsets
        local OFF_W=$(( $TOTAL_FROM_LEFT + ($D_W / 2) - ($ICON_W / 2) ))
        local OFF_H=$(( ($D_H / 2) - ($ICON_H / 2) ))
        # Set convert string part
        COMMAND+=" ( $icon -geometry +$OFF_W+$OFF_H ) -composite"
        # Increase total from west
        TOTAL_FROM_LEFT=$(( $TOTAL_FROM_LEFT + $D_W ))
      done
      CONVERT="$COMMAND $img"
    else
      #
      # If only one display
      # Overlay the icon onto the screenshot
      CONVERT="$icon -gravity center -composite $img"
    fi

    #
    # Apply convert
    scrot -q 100 -o /dev/stdout | convert - -scale ${LOCK_SCALE_DOWN}% ${IMM_BLUR_MODE}-scale ${LOCK_SCALE_UP}% $CONVERT

    # Lock
    i3lock -u -i $img -p default -t
    #
    return 0
  fi
  error
}
