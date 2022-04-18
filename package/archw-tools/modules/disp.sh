#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# DISP - display tools
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--disp                       ;Display options
"
fi
if [ "$1" == 'help' ]; then
  echo "
--disp <mode>                ;Display options <mode>s:
  gui                        ;Launch GUI displays manager
  rset <res>@<rr> [<disp>]   ;Set custom <res> as WxH and refresh rate <rr> for optional [<disp>]
  rget [lg]                  ;Get current resolution of all displays, optional [lg] will show largest one
  dset [<disp1*>,<disp2>...] ;Set up multiple displays automatically, or with optional <disp> order with * appended to the primary display
  scale <monitor> <factor>   ;Scale <monitor> to <factor> (WxH) value
  autoscale [enable|disable] ;Show autoscale status, optionally [enable|disable] autoscale of socondary monitors to fit primary one
"
fi

#
# Module content
disp () {
  if [ -n "$2" ]; then
    if [ $2 == "gui" ]; then
      arandr 2>/dev/null &
      return 0
    elif [ $2 == "scale" ] && [ -n "$3" ] && [[ $3 =~ ^[0-9\.]+$ ]]; then
      if xrandr --output $3 --scale $4; then
        echo "Scale factor $4 for display $3 has been set"
        return 0
      else
        echo "Cant set scale factor $4 to display $3"
        return 1
      fi
    elif [ $2 == "autoscale" ]; then
      if [ -n "$3" ]; then
        if [ "$3" == "enable" ]; then
          touch $S_ARCHW_FOLDER/AUTOSCALE
        elif [ "$3" == "disable" ]; then
          rm $S_ARCHW_FOLDER/AUTOSCALE
        else
          error
        fi
        # Re-apply dset
        $S_ARCHW_BIN/archw --disp dset
        echo "Autoscale ${3}d"
        return 0
      else
        if [ -f $S_ARCHW_FOLDER/AUTOSCALE ]; then
          echo "Autoscale enabled"
        else
          echo "Autoscale disabled"
        fi
        return 0
      fi
		elif [ $2 == "rset" ]; then
      #
      # Get screen infos
      local SCR_INFO=$(xrandr)

      #
      # Display name
      # (if not provided, 1st is default)
      if [ -n "$4" ]; then
        local DISP_NAME="$4"
      else
        local DISP_NAME=($(echo "$SCR_INFO" | grep -w connected  | awk -F'[ \+]' '{print $1}' 2>/dev/null))
        DISP_NAME="${DISP_NAME[0]}"
      fi

      #
			# Screen res and refresh rate
			if [ -n "$3" ]; then
				local SCREEN_RES=$(echo "$3" | cut -d "@" -f1)
        local SCREEN_RR=$(echo "$3" | cut -d "@" -f2 -s)
        if [ -z "$SCREEN_RES" ] || [ -z "$SCREEN_RR" ]; then
          error
        fi
			fi

			# Set resolution
			local SCREEN_W=$(echo $SCREEN_RES | cut -d 'x' -f1)
			local SCREEN_H=$(echo $SCREEN_RES | cut -d 'x' -f2)
			local MODELINE=$(gtf $SCREEN_W $SCREEN_H "${SCREEN_RR}" | grep Modeline | sed -E "s:\s*Modeline\s*::" | tr -d '"')
			local MODELINE_NAME=$(echo $MODELINE | cut -d ' ' -f1)
			if xrandr --newmode $MODELINE > /dev/null; then
				xrandr --addmode $DISP_NAME $MODELINE_NAME
      else
        return 1
			fi
			xrandr --output $DISP_NAME --mode $MODELINE_NAME
			echo "Resolution set completed!"
			$S_ARCHW_BIN/archw --wp
      return 0
    elif [ $2 == "rget" ]; then
      #
      # Get screen infos
      local SCR_INFO=$(xrandr)

      #
      # Get connected displays
      local DISP_NAME=($(echo "$SCR_INFO" | grep -w connected  | awk -F'[ \+]' '{print $1}' 2>/dev/null))

      #
      # Get primary display
      local DISP_PRIM=($(echo "$SCR_INFO" | grep -w primary  | awk -F'[ \+]' '{print $1}' 2>/dev/null))

      #
      # Get screen res and ref rate
      local SCREEN_RES=($(echo "$SCR_INFO"  | grep '*' | uniq | awk '{print $1}' | cut -d '_' -f1 | tr -d 'i'))
      local SCREEN_RR=($(echo "$SCR_INFO" | grep '*' | uniq | awk '{print $2}' | cut -d '*' -f1))

      if [ "$3" == "lg" ]; then
        #
        # Find largest display index
        local res_max=$(echo "${DISP_NAME[0]}" | cut -d "x" -f1)
        local res_ind=0
        local res_cn=0
        for n in "${DISP_NAME[@]}" ; do
          n=$(echo "$n" | cut -d "x" -f1)
          (($n > max)) && res_max=$n && res_ind=$res_cn
          ((res_cn++))
        done
      fi

      #
      # Loop displays and echo info
      local res_cn2=0
      for n in "${DISP_NAME[@]}" ; do
        if [ "$3" == "lg" ] && [[ $res_cn2 -ne $res_ind ]]; then
          continue
        else
          local IS_PRIMARY=""
          if [ "${DISP_NAME[$res_cn2]}" == "$DISP_PRIM" ]; then
            IS_PRIMARY=" primary"
          fi
          echo "${DISP_NAME[$res_cn2]} ${SCREEN_RES[$res_cn2]} ${SCREEN_RR[$res_cn2]}${IS_PRIMARY}"
        fi
        ((res_cn2++))
      done
      return 0
    elif [ $2 == "dset" ]; then
      #
      # Get all displays
      IFS=$'\n'
      local DISP=($($S_ARCHW_BIN/archw --disp rget))
      unset IFS

      #
      # Get primary disp params
      local DISP_PRIM=$(printf '%s\n' "${DISP[@]}" | grep primary)
      if [ -z "$DISP_PRIM" ]; then
        DISP_PRIM=$DISP
      fi
      DISP_PRIM_NAME=$(echo "$DISP_PRIM" | cut -d " " -f1)
      DISP_PRIM_RES=$(echo "$DISP_PRIM" | cut -d " " -f2)
      DISP_PRIM_RES_W=$(echo "$DISP_PRIM_RES" | cut -d "x" -f1)
      DISP_PRIM_RES_H=$(echo "$DISP_PRIM_RES" | cut -d "x" -f2)

      #
      # Check if user contains dpi settings
      local USER=$(ls $S_ARCHW_FOLDER/USER_* | cut -d "_" -f2)
      if [ -n "$USER" ]; then
        local XRESDPI=$(cat /home/$USER/.Xresources | grep "Xft.dpi:" | cut -d " " -f2)
        if [ -n "$XRESDPI" ]; then
          XRESDPI="-d $XRESDPI "
        fi
      fi

      #
      # If there is more then 1 display
      if (( ${#DISP[@]} > 1 )); then
        #
        # Process command
        local CMD=""
        local ASCMD=""
        if [ -n "$3" ]; then
          #
          # If there is input displays option
          local INP=($(echo "$3" | sed -E "s:,:\n:g"))

          #
          # Iterate over options
          for d in "${INP[@]}" ; do
            #
            # Check if prinary set
            if echo "$d" | grep "*" > /dev/null; then
              d=${d//\*/}
              local IS_PRIMARY=$d
              echo $d
            fi

            #
            # If display exist
            if printf '%s\n' "${DISP[@]}" | grep -w "$d" > /dev/null; then
              CMD+=" -o $d"
            else
              echo "Error in display name input! Please, check avaliable displays with '--disp rget' option"
              exit 1
            fi
          done

          #
          # Check if primary display is set, otherwise use current
          if [ -z "$IS_PRIMARY" ]; then
            local IS_PRIMARY=$DISP_PRIM_NAME
          fi

          #
          # Apply command
          xlayoutdisplay ${XRESDPI}-p ${IS_PRIMARY}${CMD} > /dev/null

          #
          # Apply scaling if enabled
          for d in "${DISP[@]}"; do
            local dNAME=$(echo $d | cut -d " " -f1)
            if [ "$dNAME" != "$IS_PRIMARY" ]; then
              # Set autoscale
              local PMH=$(printf '%s\n' "${DISP[@]}" | grep $IS_PRIMARY | cut -d " " -f2 | cut -d "x" -f2)
              local SMH=$(echo $d | cut -d " " -f2 | cut -d "x" -f2)
              local ASFACTOR=$(awk "BEGIN {print $PMH/$SMH}")
              #
              # Check if scaling enabled
              local ASFACTOR_GROUP=1x1
              if [ -f $S_ARCHW_FOLDER/AUTOSCALE ]; then
                ASFACTOR_GROUP=${ASFACTOR}x${ASFACTOR}
              fi

              ASCMD+=" --output $dNAME --scale $ASFACTOR_GROUP"
            fi
          done
          xrandr${ASCMD} > /dev/null
        else
          #
          # If there is NO input displays option
          for d in "${DISP[@]}"; do
            CMD+=" -o $(echo $d | cut -d " " -f1)"
          done

          #
          # Apply command
          xlayoutdisplay ${XRESDPI}-p ${DISP_PRIM_NAME}${CMD} > /dev/null

          #
          # Apply scaling if enabled

          for d in "${DISP[@]}"; do
            local dNAME=$(echo $d | cut -d " " -f1)
            if [ "$dNAME" != "$IS_PRIMARY" ]; then
              #
              # Set autoscale
              local SMH=$(echo $d | cut -d " " -f2 | cut -d "x" -f2)
              local ASFACTOR=$(awk "BEGIN {print $DISP_PRIM_RES_H/$SMH}")
              #
              # Check if scaling enabled
              local ASFACTOR_GROUP=1x1
              if [ -f $S_ARCHW_FOLDER/AUTOSCALE ]; then
                ASFACTOR_GROUP=${ASFACTOR}x${ASFACTOR}
              fi

              ASCMD+=" --output $dNAME --scale $ASFACTOR_GROUP"
            fi
          done
          xrandr${ASCMD} > /dev/null
        fi
      else
        #
        # Do for one
        local DISP_NAME=$(echo $DISP | cut -d " " -f1)
        xlayoutdisplay ${XRESDPI}-p $DISP_NAME -o $DISP_NAME > /dev/null
        #xrandr --output $DISP_NAME --auto
      fi
      return 0
    elif [ $2 == "info" ]; then
      local RES=$(xrandr | grep primary | awk '{print $4}' | cut -d '+' -f1)
      local SIZE_MM=$(xrandr | grep primary | sed -E "s:.*[ ]+([0-9]+)mm[ ]+x[ ]+([0-9]+)mm:\1x\2:")
      local DIAG_INCH=$(echo "sqrt($(echo $SIZE_MM | cut -d 'x' -f1)^2+$(echo $SIZE_MM | cut -d 'x' -f2)^2) / 25.4" | bc)
      local PPI=$(echo "sqrt($(echo $RES | cut -d 'x' -f1)^2+$(echo $RES | cut -d 'x' -f2)^2) / $DIAG_INCH" | bc)
      echo "Resolution: $RES"
      echo "Screen size (mm): $SIZE_MM"
      echo "Screen diagonal (in): $DIAG_INCH"
      echo "PPI: $PPI"
		fi
	fi
  error
}
