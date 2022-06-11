#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# MON - system monitor
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--mon          ;Live system hardware monitor
"
fi
if [ "$1" == 'help' ]; then
  echo "
--mon [<mode>] ;Live system hardware monitor, optional [<mode>]s:
  <num>        ;Set monitor refresh rate in <num> seconds
  static       ;Print static monitor screen and exit
"
fi

#
# Module content
mon () {
  monitor () {
    echo "Tempratures"
    sensors | grep 'Package\|Core'

    # If FAN
    if FANS=$(sensors | grep -iF "RPM" 2>/dev/null); then
      echo ""
      echo "System fans"
      echo -e "${FANS}"
    fi

    echo ""
    echo "Frequencies"
    grep 'cpu MHz' /proc/cpuinfo
    # If there is iGPU
    if IGPU=$(cat /sys/class/drm/card*/gt_cur_freq_mhz 2>/dev/null); then
      echo -e "iGPU MHz\t: ${IGPU}"
    fi
  }

  local INT=1
  if [ -n "$2" ]; then
    if [[ $2 == "static" ]]; then
      monitor
      return 0
    elif [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
      INT=$2
    else
      error
    fi
  fi
  watch -n $INT $S_ARCHW_BIN/archw --mon static
  return 0
}
