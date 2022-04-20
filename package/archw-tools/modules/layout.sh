#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# LAYOUT - X windows layout manager
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--layout                      ;X windows layout manager
"
fi
if [ "$1" == 'help' ]; then
  echo "
--layout <mode>               ;X windows layout manager <mode>s:
  menu                        ;Open menu to list, load and save presets
  auto [on|off]               ;Show layout keeper status, optionally set it to [on] or [off]
  ls                          ;List all saved presets
  rm <name>                   ;Remove preset <name>
  save [<name>] [<workspace>] ;Save current layout state, optionally save [<workspace>] number as preset [<name>]. (For scripting)
  load [<name>] [<workspace>] ;Load last layout state, optionally load preset [<name>] for [<workspace>] number. (For scripting)
"
fi

#
# Module content
layout () {
  #
  # Service Active checker
  sa() {
    if [ "$(systemctl --user show -p ActiveState --value $1)" == "active" ]; then
      return 0
    fi
    return 1
  }

  #
  # Set initial paths
  local LODIR=$S_ARCHW_CONFIG/layouts
  if [ ! -d $LODIR ]; then
    mkdir -p $LODIR/auto
    mkdir -p $LODIR/presets
  fi

  #
  # Dedupe apps array
  # Run this apps only onece in auto mode
  local REMOVE_DUPLICATES_FOR_APPS=(
    "firefox$"
  )

  #
  # Leave titles for this apps
  #local LEAVE_TITLES_FOR_CLASSES=(
  #  "firefoxdeveloperedition"
  #)

  #
  # Manually map i3wm classnames to apps bin
  declare -A MANUAL_APPS_MAPPING=(
    ["^Tor\ Browser$"]="torbrowser-launcher"
  )

  #
  # Set source DISP
  local DISP=$(archw --disp rget | grep primary | cut -d " " -f1)
  #
  # Set path
  local LOPATH=$LODIR/auto
  local MODE=auto
  local SCRNAME="apps.sh"

  #
  #
  # SAVE
  #
  if [ "$2" == "save" ]; then
    #
    # Check if aw-i3.target active
    if ! sa "aw-i3.target"; then
      exit 0
    fi

    #
    # If preset name defined
    if [ -n "$3" ]; then
      MODE=preset
      LOPATH=$LODIR/presets
      local LONAME=$3
      #
      # Check if name match regexp
      if ! [[ $LONAME =~ ^[A-Za-z0-9_\-]{1,32}$ ]]; then
        echo "Preset name error. Allowed characters: A-Za-z0-9_- with maximum length of 32 characters"
        exit 1
      fi
    fi

    #
    # If workspace defined
    if [ -n "$4" ]; then
      MODE=workspace
      local WS=($4)
      #
      # Check if workspace exist
      if [ "$4" != "$(i3-msg -t get_workspaces | jq ".[] | select(.name==\"$4\").name" | sed -E "s:\"::g")" ]; then
        echo "Workspace with name \"$4\" can't be found"
        exit 1
      fi
    else
      #
      # If no, scan active workspaces
      local WS=($(i3-msg -t get_workspaces | jq '.[]."name"' | sed -E "s:\"::g"))
    fi

    #
    # If auto + ws_upd mode
    if [ "$MODE" == "auto" ] && [ "$5" == "ws_upd" ]; then
      if [ -f $LOPATH/$SCRNAME ]; then
        local FWS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' | cut -d"\"" -f2)
        if cat $LOPATH/$SCRNAME | grep "^i3-msg workspace" > /dev/null 2>&1; then
          sed -i -E \
          "s:^(i3-msg workspace).*$:\1 \"$FWS\":" \
          $LOPATH/$SCRNAME
        else
          echo "i3-msg workspace \"$FWS\"" >> "$LOPATH/$SCRNAME"
        fi
        echo "Auto script updated with focused workspace name"
      fi
      #
      # End save function
      return 0
    fi

    #
    # If preset name defined, but workspace not, create folder
    if [ -n "$LONAME" ] && [ -z "$4" ]; then
      LOPATH="$LOPATH/$LONAME"
      mkdir -p $LOPATH
    fi

    #
    # If preset not defined, flush auto directory
    if [ -z "$LONAME" ]; then
      rm -rf $LOPATH/* 2>/dev/null
    fi

    #
    # Loop workspaces
    for w in "${WS[@]}" ; do
      local NUM=$(i3-msg -t get_workspaces | jq ".[] | select(.name==\"$w\").num" | cut -d"\"" -f2)
      local OUTPUT=$(i3-msg -t get_workspaces | jq ".[] | select(.name==\"$w\").output" | cut -d"\"" -f2)
      local WSNAME="$OUTPUT.$NUM.$w"
      #
      # If preset name and workspace defined, set name as CN (filename)
      if [ -n "$LONAME" ] && [ -n "$4" ]; then
        WSNAME=$LONAME
        SCRNAME="${LONAME}.sh"
      fi

      #
      # Save each one
      if ! i3-save-tree --workspace="$w" > $LOPATH/${WSNAME}.json; then
        echo "Unexpected error occured while dumping workspace tree ($w), exiting now"
        exit 1
      fi

      #
      # PROCESS LAYOUT CONTENTS
      # Get class names
      IFS=$'\n'
      local CNAMES=($(cat $LOPATH/${WSNAME}.json | grep '"class"' | awk -F: '{print $2}' | sed -E "s:\s*\"(.*)\",:\1:" | sed -E "s:\\\\::"))
      unset IFS

      #
      # Patch layout
      sed -i -E \
      "\:\s*//\s+[^\"].*:d; \
      s:(\s*)//:\1:; \
      \:\s*\"name\"\:.*:d;
      s:(\s*)\"title\"\:\s+\"(.*)\"([,]*)\s*$:\1\"title\"\: \"^.*$\"\3:" \
      $LOPATH/${WSNAME}.json

      #
      # Create launch script
      for c in "${CNAMES[@]}"; do
        local APPID=$(xdotool search --class "$c" getwindowpid)
        local APPCMD=""

        #
        # Manual mapping
        for mclass in "${!MANUAL_APPS_MAPPING[@]}"; do
          #
          # If class matched, set APPCMD
          if [ "$mclass" == "$c" ]; then
            APPCMD="${MANUAL_APPS_MAPPING[$mclass]}"
          fi
        done

        #
        # If no APPCMD has been defined, do automatic mapping
        if [ -z "$APPCMD" ]; then
          APPCMD=$(ps -f --pid $APPID | grep $APPID | awk '{ s = ""; for (i = 8; i <= NF; i++) s = s $i " "; print s }' | sed -E "s:.*\s+(/.*)$:\1:")
          # If exec path is relative, try to readlink the process
          if [[ $APPCMD =~ ^\./[^[:space:]]+ ]]; then
            local APPCMDREADLINK=$(readlink /proc/$APPID/exe | sed -E "s:(.*)/\S+$:\1:")
            #
            # App cmd line fixes
            APPCMD=$(echo $APPCMD | perl -ne 's/(\-\-class\s+)([^"]+?)(?=\s+\-|$)/$1\"$2\"/g; print;')
            #
            APPCMD="cd $APPCMDREADLINK && $APPCMD"
          fi
        fi

        #
        # Modify keeped titles
        #if [ "$MODE" == "auto" ]; then
        #  for class in "${LEAVE_TITLES_FOR_CLASSES[@]}"; do
        #    if [[ $class =~ $c ]]; then
        #      sed -i -E \
        #      "/^\s+\"class\"\:\s+\"\\^${class}\\$\"/,/^\s+\]/ s:(\s*)\"title\"\:(.*)$:\1\"title-autokeep\"\:\2:" \
        #      $LOPATH/${WSNAME}.json
        #    fi
        #  done
        #fi

        #
        # Trim APPCMD
        APPCMD=$(echo $APPCMD | xargs echo -n)

        local WRITE=1
        #
        # Checks if auto mode
        if [ "$MODE" == "auto" ]; then
          #
          # Check for dedupe
          for app in "${REMOVE_DUPLICATES_FOR_APPS[@]}"; do
            if [[ $APPCMD =~ $app ]]; then
              if [ -f "${LOPATH}/$SCRNAME" ] && cat "${LOPATH}/$SCRNAME" | sed -E "s:\s+\&\)\s*$::" | grep -w $app > /dev/null 2>&1; then
                WRITE=0
                break
              fi
            fi
          done
        fi

        #
        # Save to file
        if [ "$WRITE" == "1" ]; then
          echo "($APPCMD &)" >> "${LOPATH}/$SCRNAME"
        fi
      done

      #
      # Patch titles
      #sed -i -E \
      #"s:(\s*)\"title\"\:\s+\"(.*)\"([,]*)\s*$:\1\"title\"\: \"^.*$\"\3:" \
      #$LOPATH/${WSNAME}.json

      #
      # Restore keeped titles
      #sed -i -E \
      #"s:(\s*)\"title-autokeep\"\:(.*)$:\1\"title\"\:\2:" \
      #$LOPATH/${WSNAME}.json

    done
    #
    # If mode auto, append focused workspace to script
    if [ "$MODE" == "auto" ]; then
      local FWS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' | cut -d"\"" -f2)
      echo "i3-msg workspace \"$FWS\"" >> "$LOPATH/$SCRNAME"
    fi

    #
    # Add script header
    cat <<< "#!/usr/bin/env bash
$(cat $LOPATH/$SCRNAME)" > $LOPATH/$SCRNAME
    chmod +x "${LOPATH}/$SCRNAME"
    #
    #
    echo "Layout saved${SUFFIX}"
    return 0
  #
  #
  # LOAD
  #
  elif [ "$2" == "load" ]; then
    #
    # If preset name defined
    if [ -n "$3" ]; then
      LOPATH=$LODIR/presets
      local LONAME=$3
      #
      # Check if profile exists and it's type
      if [ -f $LOPATH/${LONAME}.json ]; then
        MODE=workspace
        #
        # Workspace type
        if [ -n "$4" ]; then
          local WS=($4)
        else
          local WS=($(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' | cut -d"\"" -f2))
        fi
      elif [ -d $LOPATH/$LONAME ]; then
        MODE=preset
        LOPATH=$LOPATH/$LONAME
        #
        # Screen type
        local WS=($(ls $LOPATH | grep '\.json$' 2>/dev/null))
      fi
    else
      local WS=($(ls $LOPATH | grep '\.json$' 2>/dev/null))
    fi
    #
    # If auto or preset, close all windows
    if [[ $MODE == "auto" || $MODE == "preset" ]]; then
      local ALLWS=($(i3-msg -t get_workspaces | jq '.[].name' | cut -d"\"" -f2 | sort))
      for w in "${ALLWS[@]}" ; do
        i3-msg "[workspace=$w] kill"
      done
    fi

    #
    # Loop workspaces
    for w in "${WS[@]}" ; do
      if [ -n "$LONAME" ] && [ -f $LOPATH/${LONAME}.json ]; then
        #
        # Append layout
        i3-msg "workspace $w; append_layout $LOPATH/${LONAME}.json" > /dev/null
        #
        # Alter w
        SCRNAME="${LONAME}.sh"
        local WNAME=w
        w=$LONAME
      else
        local WDISP=$(echo "$w" | cut -d "." -f1)
        local WNAME=$(echo "$w" | cut -d "." -f3)
        if ! archw --disp rget | grep -w $WDISP > /dev/null; then
          WDISP=$DISP
        fi
        #
        # Append layout
        echo "$WNAME > $WDISP ($LOPATH/$w)"
        i3-msg "workspace $WNAME; move workspace to output $WDISP;" > /dev/null
        i3-msg "focus output $WDISP, workspace $WNAME; append_layout $LOPATH/$w;" > /dev/null
      fi
    done

    #
    # Open apps
    nohup bash -c "$LOPATH/$SCRNAME" > /dev/null 2>&1 &

    #
    #
    echo "Layout restored"
    return 0
  #
  #
  # LIST
  #
  elif [ "$2" == "ls" ]; then
    local LOLIST=($(ls $LODIR/presets/))
    for p in "${LOLIST[@]}" ; do
      if [ -f $LODIR/presets/$p ] && $(echo "$p" | grep '\.json$' > /dev/null); then
        echo "${p%%.*} (workspace)"
      elif [ -d $LODIR/presets/$p ]; then
        echo "${p}"
      fi
    done
    return 0
  #
  #
  # REMOVE
  #
  elif [ "$2" == "rm" ]; then
    LOPATH=$LODIR/presets
    local LONAME=$3
    #
    # Check if profile exists and it's type
    if [ -f $LOPATH/${LONAME}.json ]; then
      rm $LOPATH/${LONAME}.json $LOPATH/${LONAME}.sh > /dev/null
      echo "Workspace preset \"$LONAME\" deleted"
    elif [ -d $LOPATH/$LONAME ]; then
      rm -rf $LOPATH/$LONAME
      echo "Preset \"$LONAME\" deleted"
    else
      echo "Preset \"$LONAME\" can't be found"
      exit 1
    fi
    return 0
  #
  #
  # AUTO
  #
  elif [ "$2" == "auto" ]; then
    if [ -n "$3" ]; then
      if [ "$3" == "on" ]; then
        systemctl --user enable aw-autolayoutloader.service > /dev/null 2>&1
        systemctl --user enable aw-autolayout.service > /dev/null 2>&1
        systemctl --user start aw-autolayout.service > /dev/null 2>&1
        echo "Auto layout manager enabled"
        return 0
      elif [ "$3" == "off" ]; then
        systemctl --user disable aw-autolayoutloader.service > /dev/null 2>&1
        systemctl --user disable aw-autolayout.service > /dev/null 2>&1
        systemctl --user stop aw-autolayout.service > /dev/null 2>&1
        echo "Auto layout manager disabled"
        return 0
      fi
    else
      echo "Auto layout manager status: $(systemctl --user show -p UnitFileState --value aw-autolayout.service)"
      return 0
    fi
  #
  #
  # MENU
  #
  elif [ "$2" == "menu" ]; then
    #
    # Show main menu
    local OPT=$(echo -e "Load layout\nSave layout\nSave current workspace layout" | rofi -dmenu -p "Layout menu" -no-custom)

    #
    # Submenus
    if [ "$OPT" == "Load layout" ]; then
      #
      # Load layout
      OPT=$(archw --layout ls | rofi -dmenu -p "Load layout" -no-custom | sed -E "s:\s+\(.*\)::")
      if [ -n "$OPT" ]; then
        archw --layout load $OPT
      fi
    elif [[ "$OPT" =~ "Save" ]]; then
      if [[ $OPT =~ "workspace" ]]; then
        local WS=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' | cut -d"\"" -f2)
      fi
      #
      # Save layout
      OPT=$(rofi -dmenu -p "Save layout as")
      if [ -n "$OPT" ]; then
        if ! RES=$(archw --layout save "$OPT" $WS); then
          archw --osd send "Layout manager error" "$RES" -u critical
          exit 1
        else
          archw --osd send "Layout manager" "$RES"
        fi
      fi
    fi
    return 0
  fi
  error
}
