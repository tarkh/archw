#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# STATUS - i3status-rust archw module
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--status        ;i3status pannel options
"
fi
if [ "$1" == 'help' ]; then
  echo "
--status <mode> ;i3status pannel option <mode>s:
  time [24|12]  ;Show time mode status, optionally set clock to [24|12] mode
  config        ;Edit i3status config
"
#
# System api:
# json          ;System interface for i3status custom widgets
#
fi

#
# Module content
status () {
  if [ -n $2 ]; then
    if [ $2 == "config" ]; then
      #
      # Edit config
      nano -Sablq -Y SH ~/.config/i3status-rust/config.toml
      archw --sys i3status-restart > /dev/null 2>&1
      notify-send -a $S_ARCHW_BIN/archw "i3status" "reconfigured"
      return 0
    elif [ $2 == "time" ]; then
      #
      # Time format
      wconf load "status.conf"
      if [[ $3 =~ ^(24|12)$ ]]; then
        wconf set "status.conf" TIME_FORMAT $3
        archw --sys i3status-restart > /dev/null 2>&1
        echo "Time format set: $3"
        return 0
      elif [ -n "$3" ]; then
        echo "Wrong time format: $3"
        return 1
      fi
      #
      # Show current settings
      echo "Current time format: $TIME_FORMAT"
      return 0
    elif [ $2 == "json" ]; then
      wconf load "status.conf"
      #
      # JSON interface
      if [ "$3" == "time" ]; then
        #
        # Time controller
        if [ "$4" == "sectoggle" ]; then
          #
          # If sec switch
          if [ "$TIME_SHOW_SECONDS" == "1" ]; then
            wconf set "status.conf" TIME_SHOW_SECONDS "0"
          else
            wconf set "status.conf" TIME_SHOW_SECONDS "1"
          fi
          archw --sys i3status-restart
        else
          #
          # If show sec
          if [ "$TIME_SHOW_SECONDS" == "1" ]; then
            local SC=":%S"
          fi

          #
          # Time format
          if [ "$TIME_FORMAT" == "12" ]; then
            local TF="%I:%M${SC}%n%p"
          elif [ "$TIME_FORMAT" == "24" ]; then
            local TF="%H:%M${SC}"
          else
            # failsafe
            local TF="%H:%M"
          fi

          #
          # Print time JSON
          echo '{"icon":"time","text":"'$(date +$TF)'"}'
          return 0
        fi
      elif [ "$3" == "sysupd" ]; then
        #
        # System updates controller
        if [ "$4" == "check" ]; then
          #
          # Wait for connection
          archw --sys waitconn 60 30

          #
          # Check for updates
          IFS=$'\n'
          UPDPKGS=($(archw --sys upd check))
          unset IFS

          if [[ ${#UPDPKGS[@]} -gt 0 ]]; then
            wconf set "status.conf" UPDATES_PENDING "${#UPDPKGS[@]}"
          else
            wconf set "status.conf" UPDATES_PENDING "0"
          fi
          #
          # If update contains specific warn packages
          if printf "%s\n" "${UPDPKGS[@]}" | egrep -i $UPDATES_WARNING_REGEXP > /dev/null 2>&1; then
            wconf set "status.conf" UPDATES_WARNING "1"
          else
            wconf set "status.conf" UPDATES_WARNING "0"
          fi
          #
          # Print packages
          for pkg in "${UPDPKGS[@]}"; do
            echo $pkg
          done
          return 0
        elif [ "$4" == "run" ]; then
          #
          # Run update
          if [[ $UPDATES_PENDING -gt 0 ]]; then
            xprof i3-sensible-terminal -e "archw --status json sysupd runprompt"
          else
            archw --status json sysupd check
          fi
          archw --sys i3status-restart
          return 0
        elif [ "$4" == "runprompt" ]; then
          #
          # Run in opened terminal
          echo -e "Available packages for update:\n"
          archw --status json sysupd check
          archw --sys i3status-restart
          echo ""; read -p "Do you want to install all updates? (y/n) " -r
          if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
          archw --sys upd -y
          wconf set "status.conf" UPDATES_PENDING "0"
          wconf set "status.conf" UPDATES_WARNING "0"
          archw --sys i3status-restart
          return 0
        else
          #
          # Show updates
          if [[ $UPDATES_PENDING -gt 0 ]]; then
            #
            # If warn updates exist
            if [[ $UPDATES_WARNING -gt 0 ]]; then
              WARN=",\"state\":\"Warning\""
            fi

            #
            # Print JSON
            echo '{"icon":"update"'$WARN',"text":"'$UPDATES_PENDING'"}'
          else
            #
            # Print JSON
            echo '{"icon":"update","state":"Good","text":"0"}'
          fi
          return 0
        fi
      fi
    fi
  fi
  error
}
