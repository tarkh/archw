#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# OSD - on screen display server
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--osd                       ;On Screen Display
"
fi
if [ "$1" == 'help' ]; then
  echo "
--osd <mod>                 ;On Screen Display server <mod>s:
  send <head> [<txt>] [opt] ;Send notification with <head>er, optional [<txt>] and [opt]ions
  config                    ;Edit notification service config
  pause                     ;Pause notificatio service
  resume                    ;Resume notification service
  restart                   ;Restart notification service
"
fi

#
# Module content
osd () {
  if [ -n "$2" ]; then
    #
    # Send notification
    if [ $2 == "send" ] && [ -n "$3" ]; then
      local TITLE=$3
      if [ -n "$4" ]; then
        local MSG=$4
        shift 1
      fi
      shift 3

      local NOTI_ID=$(dunstify "$TITLE" "$MSG" "$@")
      return 0
    fi

    #
    # Edit config
    if [ $2 == "config" ]; then
      nano -Sablq ~/.config/dunst/dunstrc
      killall dunst
      notify-send -a archw "OSD server" "reconfigured"
      return 0
    fi

    #
    # Pause
    if [ $2 == "pause" ]; then
      notify-send -a archw "OSD server" "pausing notification service..." -t 2000
      sleep 2.5
      killall -SIGUSR1 dunst
      return 0
    fi

    #
    # Resume
    if [ $2 == "resume" ]; then
      killall -SIGUSR2 dunst
      notify-send -a archw "OSD server" "notification service resumed" -t 2000
      return 0
    fi

    #
    # Restart
    if [ $2 == "restart" ]; then
      killall dunst
      notify-send -a archw "OSD server" "restarted"
      return 0
    fi

    #
    # System section
    #

    #
    # Volume indicator
    if [ $2 == "show-volume" ]; then
      local AMIXER=$(amixer sget Master)
      local VOLUME=$(echo $AMIXER | grep 'Right:' | awk -F'[][]' '{ print $2 }' | tr -d "%")
      local MUTE=$(echo $AMIXER | grep -o '\[off\]' | tail -n 1)
      local ICON=true
      local STAT="at ${VOLUME}%"
      # Adjust icon
      if [ -n "$ICON" ]; then
        if [ "$VOLUME" -le 20 ]; then
          ICON=audio-volume-low
        elif [ "$VOLUME" -le 60 ]; then
          ICON=audio-volume-medium
        else
          ICON=audio-volume-high
        fi
      fi
      # Check for mute
      if [ "$MUTE" == "[off]" ]; then
        ICON=audio-volume-muted
        STAT="muted"
        VOLUME=0
      fi
      # Send notification
      local NOTI_ID=$(dunstify \
      -a archw \
      -h string:x-canonical-private-synchronous:audio \
      "Volume $STAT" \
      -h int:value:"$VOLUME" \
      -t 2000 \
      --icon $ICON)
      return 0
    fi

    #
    # Screen brightness indicator
    if [ $2 == "show-brightness" ] && [ -n "$3" ]; then
      local MAX=$(brightnessctl -d $3 max)
      local CUR=$(brightnessctl -d $3 get)
      #local BRIGHTNESS=$(printf "%.0f" $(awk "BEGIN {print $CUR/$(awk "BEGIN {print $MAX/100}")}"))
      local BRIGHTNESS=$(round $(awk "BEGIN {print $CUR/$(awk "BEGIN {print $MAX/100}")}") 0)
      local ICON=true
      local STAT="at ${BRIGHTNESS}%"
      local LABEL="Brightness"
      # Adjust label
      if [ -n "$4" ]; then
        LABEL=$4
      fi
      # Adjust icon
      if [ -n "$ICON" ]; then
        if [ $BRIGHTNESS -eq 0 ]; then
          ICON=brightnesssettings
        elif [ $BRIGHTNESS -le 30 ]; then
          ICON=brightnesssettings
        elif [ $BRIGHTNESS -le 70 ]; then
          ICON=brightnesssettings
        else
          ICON=brightnesssettings
        fi
      fi
      # Send notification
      local NOTI_ID=$(dunstify \
      -a archw \
      -h string:x-canonical-private-synchronous:brightness \
      "$LABEL $STAT" \
      -h int:value:"$BRIGHTNESS" \
      -t 2000 \
      --icon $ICON)
      return 0
    fi
  fi
  error
}
