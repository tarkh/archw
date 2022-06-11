#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# CPU - cpu frequency control
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--cpu              ;CPU profile controller
"
fi
if [ "$1" == 'help' ]; then
  echo "
--cpu <mode>       ;CPU profile controller <mode>s:
  ps               ;Powersaver CPU profile
  media            ;Custom CPU profile for media playback
  normal           ;Normal CPU profile
  turbo            ;Performance CPU profile
  freq <min> <max> ;Manually set the <min> and <max> cpu frequency in MHz
  static <freq>    ;Manually set a static cpu <freq> in MHz
  reset            ;Reset manual CPU settings
"
fi

#
# Module content
cpu () {
  scpu () {
    if [ -n "$1" ] && [ -n "$2" ]; then
      sudo cpupower frequency-set -d ${1}MHz
      sudo cpupower frequency-set -u ${2}MHz
    else
      sudo cpupower frequency-set -g $1
      echo "$1 profile applied"
    fi
  }

  if [ $2 == "reset" ]; then
    scpu 1 100000
    $S_ARCHW_BIN/archw --cpu normal
    echo "Manual CPU frequency has been reset"
    return 0
  elif [ $2 == "freq" ]; then
    if [ -n "$3" ] && [ -n "$4" ]; then
      scpu ${2} ${3}
      echo "Manual frequency has been set: min $3 MHz, max $4 MHz"
      return 0
    fi
  elif [ $2 == "static" ]; then
    if [ -n "$3" ]; then
      sudo cpupower frequency-set -f ${2}MHz
      echo "Static frequency has been set to $3 MHz"
      return 0
    fi
  elif [ $2 == "ps" ]; then
    scpu "powersave"
    return 0
  elif [ $2 == "media" ]; then
    scpu "manual" 800 1800
    echo "Custom $1 profile applied"
    return 0
  elif [ $2 == "normal" ]; then
    scpu "ondemand"
    return 0
  elif [ $2 == "turbo" ]; then
    scpu "performance"
    return 0
  fi
  error
}
