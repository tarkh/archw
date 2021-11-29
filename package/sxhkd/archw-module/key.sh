#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# KEY - hot key server
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--key             ;Hot keys options
"
fi
if [ "$1" == 'help' ]; then
  echo "
--key <mode>      ;Hot keys server <mode>s:
  find            ;Find key codes with xev inspector
  config [<name>] ;Show avaliable configs, edit optional [<name>] config
  restart         ;Restart Hotkey server (sxhkd)
"
fi

#
# Module content
key () {
  if [ -n $2 ]; then
    #
    # Edit config
    if [ $2 == "find" ]; then
      echo "
Press keys while focused on white field to capture key codes,
then return to this terminal and press Ctrl+C for exit."
      echo ""; read -p "Start inspector? (y/n) " -n 1 -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then echo "" && exit 0; fi
      echo ""
      echo ""
      systemctl --user stop sxhkd-autostart.service > /dev/null 2>&1
      trap : INT
      xev | awk -F'[ )]+' '/^KeyPress/ { a[NR+2] } NR in a { printf "%-3s %s\n", $5, $8 }'
      echo ""
      systemctl --user start sxhkd-autostart.service > /dev/null 2>&1
      return 0
    fi

    #
    # Edit config
    if [ $2 == "config" ]; then
      if [ -n "$3" ]; then
        if [ ! -f ~/.config/sxhkd/${3}.conf ]; then
          echo "Config \"$3\" can't be found"
          exit 1
        fi
        nano -Sabq -Y SH ~/.config/sxhkd/${3}.conf
        #systemctl --user restart sxhkd-autostart.service > /dev/null 2>&1
        pkill -USR1 -x sxhkd
        notify-send -a $S_ARCHW_BIN/archw "Hot keys server" "reconfigured"
        return 0
      fi
      #
      # List configs
      echo "Avaliable hot keys configs:"
      ls ~/.config/sxhkd/ | grep '\.conf$' | sed -E "s:(.*)\.conf$:\1:"
      return 0
    fi

    #
    # Restart
    if [ $2 == "restart" ]; then
      systemctl --user stop sxhkd-autostart.service > /dev/null 2>&1
      killall sxhkd > /dev/null 2>&1
      killall sxhkdrun > /dev/null 2>&1
      systemctl --user start sxhkd-autostart.service > /dev/null 2>&1
      notify-send -a $S_ARCHW_BIN/archw "Hot keys server" "restarted"
      return 0
    fi
  fi
  error
}
