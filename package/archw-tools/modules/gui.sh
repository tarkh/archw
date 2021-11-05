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
--gui <mode>      ;Tune graphics interface for Retina/Large displays with <mode>s:
  preset [preset] ;Get current GUI preset or set one of optional [preset]s:
                  ;20   - for ~20″ size monitor
                  ;20x2 - for ~20″ size monitor x2 UI elements size for HiDPI screens
                  ;30, 30x2, 40, 40x2
  dpi [num]       ;Set default DPI or override it with optional <num>
"
# todo
#scale [percent]   ;Get current scaling mode or set one with oprional [percent] value:
#                  ;100 - no interface scale
#                  ;125 - scale GUI to 125%
#                  ;150, 175, 200, 225, 250, 275, 300
fi

#
# Module content
gui () {
  #
  # Default start DPI
  DPISTART=96
  DPIDEF=$DPISTART

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
    # Check xinitrc
    if ! cat ~/.xinitrc | grep "xrdb -merge ~/.Xresources" > /dev/null 2>&1; then
      echo -e "xrdb -merge ~/.Xresources\n$(cat ~/.xinitrc)" > ~/.xinitrc
    fi
    #
    # Remove entries if exist
    if [ -f ~/.Xresources ]; then
      sed -i -E \
      "\:^\s*Xft\.(dpi|autohint|lcdfilter|lcdfilter|hintstyle|hinting|antialias|rgba).*:d" \
      ~/.Xresources
    fi
    #
    # Add entries
    bash -c "cat >> ~/.Xresources" << EOL
Xft.dpi: $DPIDEF
Xft.autohint: 0
Xft.lcdfilter: lcddefault
Xft.hintstyle: hintslight
Xft.hinting: true
Xft.antialias: 1
Xft.rgba: rgb
EOL
    #
    # If rofi installed
    if [ -f ~/.config/rofi/config.rasi ]; then
      sudo sed -i -E \
      "s:^(\s*dpi\:).*:\1 ${DPIDEF};:" \
      ~/.config/rofi/config.rasi
    fi
    #

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
    #
  }

  #
  # xprofile
  set_xprof () {
    #
    # On/off
    local MOD=""
    if [ "$1" == "on" ]; then
      :
    elif [ "$1" == "off" ]; then
      MOD="#"
    else
      error
    fi
    #
    # Scale options
    local GDK_SCALE=2
    local GDK_DPI_SCALE=0.5
    local QT_AUTO_SCREEN_SCALE_FACTOR=0
    local QT_SCALE_FACTOR=1
    local QT_FONT_DPI=$DPIDEF
    if [ -n "$2" ] && [ -n "$3" ] && [ -n "$4" ] && [ -n "$5" ] && [ -n "$6" ]; then
      GDK_SCALE=$2
      GDK_DPI_SCALE=$3
      QT_AUTO_SCREEN_SCALE_FACTOR=$4
      QT_SCALE_FACTOR=$5
      QT_FONT_DPI=$6
    fi
    # Scale
    sed -i -E \
    "s:^[\s]*(XPROF_PRESET=).*:\1${XPROF_PRESET}:; \
    s:^[#\s]*(export GDK_SCALE=).*:${MOD}\1${GDK_SCALE}:; \
    s:^[#\s]*(export GDK_DPI_SCALE=).*:${MOD}\1${GDK_DPI_SCALE}:; \
    s:^[#\s]*(export QT_AUTO_SCREEN_SCALE_FACTOR=).*:${MOD}\1${QT_AUTO_SCREEN_SCALE_FACTOR}:; \
    s:^[#\s]*(export QT_SCALE_FACTOR=).*:${MOD}\1${QT_SCALE_FACTOR}:; \
    s:^[#\s]*(export QT_FONT_DPI=).*:${MOD}\1${QT_FONT_DPI}:" \
    ~/.config/archw/xprof.conf
  }

  if [ -n "$2" ]; then
    if [ "$2" == "preset" ]; then
      #
      # Set screen presets
      XPROF_PRESET=$3
      if [ -n "$3" ]; then
        if [ "$3" == "20" ]; then
          set_i3gaps 3
          set_custom_dpi
          set_xprof off
        elif [ "$3" == "20x2" ]; then
          set_i3gaps 4
          set_custom_dpi 192
          set_xprof on
        elif [ "$3" == "30" ]; then
          set_i3gaps 4
          set_custom_dpi 150
          set_xprof off
        elif [ "$3" == "30x2" ]; then
          set_i3gaps 5
          set_custom_dpi 166
          set_xprof on
        elif [ "$3" == "40" ]; then
          set_i3gaps 5
          set_custom_dpi 120
          set_xprof off
        elif [ "$3" == "40x2" ]; then
          set_i3gaps 6
          set_custom_dpi 140
          set_xprof on
        else
          error
        fi
      else
        echo "Current preset: $(cat ~/.config/archw/xprof.conf | grep XPROF_PRESET= | cut -d "=" -f2)"
        exit 0
      fi
      echo "GUI profile \"$3\" applied. You have to re-login for changase to take effect"
      return 0
    elif [ "$2" == "scale" ] && [ -n "$3" ]; then
      #
      # Set screen presets
      if [ "$3" == "100" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "125" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "150" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "175" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "200" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "225" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "250" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "275" ]; then
        set_custom_dpi dpi
        set_xprof off
      elif [ "$3" == "300" ]; then
        set_custom_dpi dpi
        set_xprof off
      else
        error
      fi
      echo "GUI profile \"$3\" applied. You have to re-login for changase to take effect"
      return 0
    elif [ $2 == "dpi" ]; then
      local DPI=$DPIDEF
      if [ -n "$3" ] && [[ $3 =~ ^[0-9]+$ ]]; then
        DPI=$3
      fi
      set_custom_dpi $3
      echo "DPI set to $3"
      return 0
    fi
  fi
  error
}
