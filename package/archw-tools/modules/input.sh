#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# INPUT - input devices controller
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--input <mode>                ;Input device settings
"
fi
if [ "$1" == 'help' ]; then
  echo "
--input <mode>                ;Input device settings <mode>s:
  trackpad [<option> <value>] ;Show trackpad settings, optionally set it with [<option> <value>]:
                              ;sens: pointer sensitivity, number: -1.00 to 1.00
                              ;accel: acceleration profile, number: 0 to 2
                              ;natscr: natural scrolling, boolean: true, false
  mouse [<option> <value>]    ;Show mouse settings, optionally set it with [<option> <value>]:
                              ;accel: pointer acceleration speed, number: -1.00 to 1.00
                              ;natscr: natural scrolling, boolean: true, false
  config [<name>]             ;Show avaliable configs, edit optional [<name>] config
"
fi

#
# Module content
input () {
  #
  # Set options maps
  local OPTS_MTRACK=(
    "sens|Trackpad Sensitivity|Sensitivity|FLO|-1.00|1.00"
    "accel|Device Accel Profile|AccelerationProfile|DEC|0|2"
    "natscr|Trackpad Scroll Buttons|ScrollUpButton,ScrollDownButton|BOOL|5,4,*|4,5,*"
  )
  local OPTS_LIBINPUT=(
    "accel|libinput Accel Speed|AccelSpeed|FLO|-1.00|1.00"
    "natscr|libinput Natural Scrolling Enabled|NaturalScrolling|BOOL|1|0"
  )

  #
  # List pointer device
  list_pointers () {
    local ID=($(xinput list | awk 'BEGIN {is_pt=0}; /Virtual core pointer/ {is_pt=1}; /⎣/ {is_pt=0}; {if (is_pt==1) {print $0}} ' | sed -E "s:.*id=(\w+).*:\1:"))
    local id=()
    for n in "${ID[@]}" ; do
      if xinput list-props $n | grep -w "$1" > /dev/null 2>&1; then
        id+=($n)
      fi
    done
    echo ${id[@]}
  }

  #
  # Parse line
  parse_line () {
    echo $1 | tr "|" "\n"
  }

  #
  # Show settings
  show_settings () {
    IFS=$'\n'
    local OPT=($(parse_line $1))
    unset IFS
    local VAL=$(xinput list-props ${TP[0]} | grep "${OPT[1]} (" | cut -d ":" -f2 | xargs)
    if [ "${OPT[3]}" == "BOOL" ]; then
      if [[ "$VAL" =~ ^$(echo ${OPT[4]} | sed -E "s:\*:.\*:g; s:,:,[[\:space\:]]*:g") ]]; then
        echo "${OPT[0]}: true"
      elif [[ "$VAL" =~ ^$(echo ${OPT[5]} | sed -E "s:\*:.\*:g; s:,:,[[\:space\:]]*:g") ]]; then
        echo "${OPT[0]}: false"
      fi
    else
      echo "${OPT[0]}: $VAL"
    fi
  }

  #
  # Write settings
  write_settings () {

  }

  #
  # Set settings
  set_settings () {
    if [ "$1" == "trackpad" ]; then
      local FILE=/etc/X11/xorg.conf.d/00-mtrack.conf
      for opt in "${OPTS_MTRACK[@]}" ; do
        #
        # Check if option exist
        IFS=$'\n'
        local tmpOPT=($(parse_line $opt))
        if [ "${tmpOPT[0]}" == "$2" ]; then
          local OPT=("${tmpOPT[@]}")
        fi
        unset IFS
      done

      if [ -n "$OPT" ]; then
        #
        # Check if value is in right format
        if [ "${OPT[3]}" == "BOOL" ]; then
          if [ "$3" == "true" ]]; then
            for tp in "${TP[@]}" ; do
              local VAL=$(xinput list-props $tp | grep "${OPT[1]} (" | cut -d ":" -f2 | xargs)
              write_settings "$FILE" "$2" "$3"
            done
          elif [ "$3" == "false" ]]; then
          else
            echo "Invalid argument for boolean option"
            exit 1
          fi
        elif [ "${OPT[3]}" == "FLO" ]; then
          if [[ "$3" =~ ^[-]?[0-9]+\.[0-9]*$ ]] && (( $(echo "$3 >= ${OPT[4]}" | bc -l) )) && (( $(echo "$3 <= ${OPT[5]}" | bc -l) )); then
            :
          fi
        elif [ "${OPT[3]}" == "DEC" ]; then
          if [[ "$3" =~ ^[-]?[0-9]+$ ]] && (( $(echo "$3 >= ${OPT[4]}" | bc -l) )) && (( $(echo "$3 <= ${OPT[5]}" | bc -l) )); then
            :
          fi
        fi
      else
        echo "Wrong option: $2"
        exit 1
      fi
    elif [ "$1" == "mouse" ]; then

    fi
  }

  if [ -n "$2" ]; then
    if [ "$2" == "trackpad" ]; then
      #
      # Trackpad
      # List trackpads
      local TP=($(list_pointers "Trackpad Sensitivity"))
      #
      # If no one found
      if [ ${#TP[@]} -eq 0 ]; then
        echo "Trackpad device not found"
        return 1
      fi

      if [ -n "$3" ]; then
        if [ -n "$4" ]; then
          set_settings "trackpad" "$3" "$4"
        fi
      else
        #
        # Iterate options
        for opt in "${OPTS_MTRACK[@]}" ; do
          show_settings "$opt"
        done
        return 0
      fi
    elif [ "$2" == "mouse" ]; then
      #
      # Mouse
      # List mouses
      local TP=($(list_pointers "libinput Accel Speed"))
      #
      # If no one found
      if [ ${#TP[@]} -eq 0 ]; then
        echo "Mouse device not found"
        return 1
      fi

      if [ -n "$3" ]; then
        if [ -n "$4" ]; then
          set_settings "mouse" "$3" "$4"
        fi
      else
        #
        # Iterate options
        for opt in "${OPTS_LIBINPUT[@]}" ; do
          show_settings "$opt"
        done
        return 0
      fi
    fi
  fi
  error
}
