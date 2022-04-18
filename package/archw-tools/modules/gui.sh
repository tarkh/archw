#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# GUI - Graphics User Interface
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--gui             ;Tune graphics interface for Retina/Large displays
"
fi
if [ "$1" == 'help' ]; then
  echo "
--gui <mode>     ;Tune graphics interface with <mode>s:
  auto           ;Automatically set preset based on screen PPI
  preset [name]  ;Get current preset name or set one with oprional [name] value:
                 ;100 - no interface scale, 100%
                 ;150 - scale GUI up to 150%
                 ;200, 250, 300
  dpi [num]      ;Get current DPI value or set custom one with optional [num]
  hidpi [on|off] ;Get current HiDPI status or set it with optional [on|off]
"
fi

#
# Module content
gui () {
  #
  # Default start DPI
  DPISTART=96
  DPIDEF=$DPISTART

  #
  # Load config
  wconf load "xprof.conf"

  #
  # Calculate scale
  calc_scale () {
    local P=$( round $(awk "BEGIN {print $1 * 100 / $DPISTART}") 0 )
    local S=$( round $(awk "BEGIN {print $2 / 100 * $P}") 0 )
    echo $S
  }

  #
  # Set gaps
  set_i3gaps () {
    sed -i -E \
    "s:^\s*(gaps inner).*:\1 $1:" \
    $HOME/.config/i3/config
  }

  #
  # set custom DPI
  set_custom_dpi () {
    if [ -n "$1" ]; then
      DPIDEF=$1
    fi

    #
    # Set dpi
    wconf set "xprof.conf" XPROF_DPI "$DPIDEF"
    wconf set "xprof.conf" QT_FONT_DPI "$DPIDEF"

    #
    # Alter Xresources
    touch ~/.Xresources
    sed -E -i \
    "s:^(\s*Xft.dpi\:).*$:\1 $DPIDEF:" \
    ~/.Xresources

    #
    # If rofi installed
    if [ -f ~/.config/rofi/config.rasi ]; then
      sudo sed -i -E \
      "s:^(\s*dpi\:).*:\1 ${DPIDEF};:" \
      ~/.config/rofi/config.rasi
    fi

    #
    # If lightdm-mini-greeter installed
    if [ -f /etc/lightdm/lightdm-mini-greeter.conf ]; then
      if [ ! -f /etc/lightdm/lightdm-mini-greeter.conf.ref ]; then
        sudo cp /etc/lightdm/lightdm-mini-greeter.conf /etc/lightdm/lightdm-mini-greeter.conf.ref
      fi
      #
      # Get ref value and calculate scale
      local REF_LS=$(cat /etc/lightdm/lightdm-mini-greeter.conf.ref | grep -w layout-space | sed -E "s:.*=\s*([0-9]+):\1:")
      local SCALED_LS=$(calc_scale $DPIDEF $REF_LS)
      #
      # Replace value
      sudo sed -i -E \
      "s:^\s*[#]*(layout-space\s*=).*:\1 ${SCALED_LS}:" \
      /etc/lightdm/lightdm-mini-greeter.conf
    fi
  }

  #
  # set hidpi
  set_hidpi () {
    local DPI=$XPROF_DPI
    if [ -n "$2" ]; then
      DPI=$2
    fi

    #
    # hidpi On/off
    if [ "$1" == "on" ]; then
      # i3bar tray_padding
      sed -i -E \
      "s:^([ ]*tray_padding)[ ]{1,}[0-9]{1,}[ ]*$:\1 3:" \
      ~/.config/i3/config
      # xprof
      local MULTI=2
      local SCALE=0.5
      if [ "$DPI" -ge "240" ]; then
        MULTI=3
        SCALE=0.33
      fi
      wconf set "xprof.conf" GDK_SCALE "$MULTI"
      wconf set "xprof.conf" GDK_DPI_SCALE "$SCALE"
      wconf set "xprof.conf" QT_SCALE_FACTOR "$MULTI"
      wconf set "xprof.conf" QT_FONT_DPI "$(( ($DPI + ($MULTI - 1)) / $MULTI ))"
    elif [ "$1" == "off" ]; then
      # i3bar tray_padding
      sed -i -E \
      "s:^([ ]*tray_padding)[ ]{1,}[0-9]{1,}[ ]*$:\1 4:" \
      ~/.config/i3/config
      # xprof
      wconf set "xprof.conf" GDK_SCALE "1"
      wconf set "xprof.conf" GDK_DPI_SCALE "1"
      wconf set "xprof.conf" QT_SCALE_FACTOR "1"
      wconf set "xprof.conf" QT_FONT_DPI "$DPI"
    fi
  }

  #
  # xprofile
  set_xprof () {
    #
    # Scale options
    wconf set "xprof.conf" XPROF_PRESET "$1"
    set_custom_dpi $2
    set_hidpi $3 $2
    set_i3gaps $4
  }

  if [ -n "$2" ]; then
    if [ "$2" == "auto" ]; then
      local PPI=$(archw --disp info | grep PPI | cut -d ':' -f2 | awk '{print $1}')
      # Check if we have PPI
      if ! [[ $PPI =~ ^[0-9]+$ ]]; then
        echo "Can't set GUI profile automatically: wrong PPI detected"
        exit 1
      fi
      # Select preset
      if [ "$PPI" -lt "144"]; then
        archw --gui preset 100
      elif [ "$PPI" -lt "192"]; then
        archw --gui preset 150
      elif [ "$PPI" -lt "240"]; then
        archw --gui preset 200
      elif [ "$PPI" -lt "288"]; then
        archw --gui preset 250
      elif [ "$PPI" -ge "288"]; then
        archw --gui preset 300
      fi
    elif [ "$2" == "preset" ]; then
      #
      # Set screen presets
      if [ -n "$3" ]; then
        if [ "$3" == "100" ]; then
          set_xprof $3 $DPISTART off 6
        elif [ "$3" == "150" ]; then
          set_xprof $3 144 on 4
        elif [ "$3" == "200" ]; then
          set_xprof $3 192 on 3
        elif [ "$3" == "250" ]; then
          set_xprof $3 240 on 3
        elif [ "$3" == "300" ]; then
          set_xprof $3 288 on 3
        else
          error
        fi
      else
        echo "Current preset: $XPROF_PRESET"
        return 0
      fi
      echo "GUI profile applied: \"$3\". You have to re-login for changase to take effect"
      return 0
    elif [ $2 == "dpi" ]; then
      if [ -n "$3" ]; then
        local DPI=$DPIDEF
        if [ -n "$3" ] && [[ $3 =~ ^[0-9]+$ ]]; then
          DPI=$3
        else
          error
        fi
        wconf set "xprof.conf" XPROF_PRESET "custom"
        set_custom_dpi $3
        if [ "$QT_SCALE_FACTOR" -gt "1" ]; then
          set_hidpi on $3
        fi
        echo "DPI set to $3"
        return 0
      fi
      echo "Current DPI: $XPROF_DPI"
      return 0
    elif [ $2 == "hidpi" ]; then
      if [ -n "$3" ]; then
        if [[ $3 =~ ^(on|off)$ ]]; then
          set_hidpi $3
          echo "HiDPI scaling: $3"
          return 0
        else
          error
        fi
      fi
      local HIDPI_STAT=off
      if [ "$QT_SCALE_FACTOR" -gt "1" ]; then
        HIDPI_STAT=on
      fi
      echo "HiDPI scaling: $HIDPI_STAT"
      return 0
    elif [ $2 == "set-env-vars" ]; then
      echo export GDK_SCALE=$GDK_SCALE
      echo export GDK_DPI_SCALE=$GDK_DPI_SCALE
      echo export QT_AUTO_SCREEN_SCALE_FACTOR=$QT_AUTO_SCREEN_SCALE_FACTOR
      echo export QT_SCALE_FACTOR=$QT_SCALE_FACTOR
      echo export QT_FONT_DPI=$QT_FONT_DPI
      exit 0
    fi
  fi
  error
}
