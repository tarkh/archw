#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# LANG - keyboard language switch
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--lang                    ;Input language manipulation
"
fi
if [ "$1" == 'help' ]; then
  echo "
--lang <mode>             ;Input language manipulation <mode>s:
  ls                      ;List all avaliable input language codes
  get                     ;Get current active input language code
  set <lang>              ;Set active input <lang> code
  cycle-set  [<lang> ...] ;Get current language codes setup, optionally set [<lang1> ...] for cycle switching
  cycle                   ;Switch input languages consistently from cycle-set
  load                    ;Load cycle-set layout to system
"
fi

#
# Module content
lang () {

  langconf() {
    #
    # Load config
    wconf load "lang.conf"
    echo $LANGLAYOUTS
  }

  i3sr() {
    archw --sys restart i3status
  }

	if [ -n "$2" ]; then
		if [ $2 == "ls" ]; then
			echo "Avaliable input language codes:"
			localectl list-x11-keymap-layouts | column -c 80
      return 0
		elif [ $2 == "get" ]; then
      echo "$(xkblayout-state print "%s")"
      return 0
		elif [ $2 == "set" ]; then
      #
      # Check if language code is provided
      if [ -z "$3" ]; then
        echo "No language code provided"
        exit 1
      fi

      #
      # Check if language code is in layout list
      local langs=($(langconf))
      if ! inArray "$3" "${langs[@]}"; then
        echo "Language code \"$3\" can't be found in curret layout list: ${langs[@]}"
        exit 1
      fi

      #
      # Find language code index in layout list
      # and set it as active layout
      local IND=0
      for l in "${langs[@]}"; do
        if [ "$l" == "$3" ]; then
          break
        fi
        IND=$(( $IND + 1 ))
      done
      xkblayout-state set $IND
      i3sr
      echo "Language set: $3"
      return 0
		elif [ $2 == "cycle" ]; then
			xkblayout-state set +1
      i3sr
      echo "Language switched: $(xkblayout-state print "%s")"
      return 0
		elif [ $2 == "cycle-set" ]; then
      #
      # Check if languages provided
      if [ -z $3 ]; then
        langconf
        exit 0
      fi

      #
      # Check if us exist
      shift 2
      if ! inArray "us" "$@"; then
        echo "Cycle must contain \"us\" language"
        exit 1
      fi

      #
      # Rearrange langs so that US always first
      local langs=( us )
      for l in "$@"; do
        if [ "$l" != "us" ]; then
          langs+=( $l )
        fi
      done

      #
      # Check if codes exist
      for l in "${langs[@]}"; do
        if ! localectl list-x11-keymap-layouts | grep -w $l > /dev/null 2>&1; then
          echo "Language code \"$l\" can't be found. Applying last/default config"
          langs=($(langconf))
        fi
      done

      #
      # Save settings
      local LOSTR=$( IFS=$' '; echo "${langs[*]}" )
      wconf set "lang.conf" LANGLAYOUTS "\"$LOSTR\""
      setxkbmap -layout $(echo "${langs[@]}" | sed -E "s:\s:,:g")
      i3sr
			echo "Cycle set: ${langs[@]}"
      return 0
    elif [ $2 == "load" ]; then
      local LANG=$(langconf)
      setxkbmap -layout $(echo "${LANG}" | sed -E "s:\s+:,:g")
      echo "Language config loaded to system: ${LANG}"
      return 0
		fi
	fi
  error
}
