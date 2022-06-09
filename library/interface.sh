#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# ArchW text interface
#

int_ui {
  #!/bin/bash
  # https://github.com/pollev/bash_progress_bar - See license at end of file
  #
  # Modified by ArchW

  # Usage:
  # Source this script
  # int_enable_trapping <- optional to clean up properly if user presses ctrl-c
  # int_setup_scroll_area <- create empty progress bar
  # int_draw_progress_bar 10 <- advance progress bar
  # int_draw_progress_bar 40 <- advance progress bar
  # int_block_progress_bar 45 <- turns the progress bar yellow to indicate some action is requested from the user
  # int_draw_progress_bar 90 <- advance progress bar
  # int_destroy_scroll_area <- remove progress bar

  # Constants
  local CODE_SAVE_CURSOR="\033[s"
  local CODE_RESTORE_CURSOR="\033[u"
  local CODE_CURSOR_IN_SCROLL_AREA="\033[1A"
  local COLOR_FG="\e[30m"
  local COLOR_BG="\e[42m"
  if [ -n "$BANNERC1" ]; then COLOR_BG=$BANNERC1; fi
  local COLOR_BG_BLOCKED="\e[43m"
  local RESTORE_FG="\e[39m"
  local RESTORE_BG="\e[49m"

  # Variables
  local PROGRESS_BLOCKED="false"
  local TRAPPING_ENABLED="false"
  local TRAP_SET="false"

  local CURRENT_NR_LINES=0

  int_setup_scroll_area() {
      local TL=$1
      if [ -z "$TL" ]; then TL=0; fi

      # If trapping is enabled, we will want to activate it whenever we setup the scroll area and remove it when we break the scroll area
      if [ "$TRAPPING_ENABLED" = "true" ]; then
          int_trap_on_interrupt
      fi

      local lines=$(tput lines)
      CURRENT_NR_LINES=$lines
      let lines=$lines-1
      # Scroll down a bit to avoid visual glitch when the screen area shrinks by one row
      echo -en "\n"

      # Save cursor
      echo -en "$CODE_SAVE_CURSOR"
      # Set scroll region (this will place the cursor in the top left)
      echo -en "\033[${1};${lines}r"

      # Restore cursor but ensure its inside the scrolling area
      echo -en "$CODE_RESTORE_CURSOR"
      echo -en "$CODE_CURSOR_IN_SCROLL_AREA"

      # Start empty progress bar
      int_draw_progress_bar 0
  }

  int_destroy_scroll_area() {
      local lines=$(tput lines)
      # Save cursor
      echo -en "$CODE_SAVE_CURSOR"
      # Set scroll region (this will place the cursor in the top left)
      echo -en "\033[0;${lines}r"

      # Restore cursor but ensure its inside the scrolling area
      echo -en "$CODE_RESTORE_CURSOR"
      echo -en "$CODE_CURSOR_IN_SCROLL_AREA"

      # We are done so clear the scroll bar
      int_clear_progress_bar

      # Scroll down a bit to avoid visual glitch when the screen area grows by one row
      echo -en "\n\n"

      # Once the scroll area is cleared, we want to remove any trap previously set. Otherwise, ctrl+c will exit our shell
      if [ "$TRAP_SET" = "true" ]; then
          trap - INT
      fi
  }

  int_draw_progress_bar() {
      local percentage=$1
      local lines=$(tput lines)
      let lines=$lines

      # Check if the window has been resized. If so, reset the scroll area
      if [ "$lines" -ne "$CURRENT_NR_LINES" ]; then
          int_setup_scroll_area
      fi

      # Save cursor
      echo -en "$CODE_SAVE_CURSOR"

      # Move cursor position to last row
      echo -en "\033[${lines};0f"

      # Clear progress bar
      tput el

      # Draw progress bar
      PROGRESS_BLOCKED="false"
      int_print_bar_text $percentage

      # Restore cursor position
      echo -en "$CODE_RESTORE_CURSOR"
  }

  int_block_progress_bar() {
      local percentage=$1
      local lines=$(tput lines)
      let lines=$lines
      # Save cursor
      echo -en "$CODE_SAVE_CURSOR"

      # Move cursor position to last row
      echo -en "\033[${lines};0f"

      # Clear progress bar
      tput el

      # Draw progress bar
      PROGRESS_BLOCKED="true"
      int_print_bar_text $percentage

      # Restore cursor position
      echo -en "$CODE_RESTORE_CURSOR"
  }

  int_clear_progress_bar() {
      local lines=$(tput lines)
      let lines=$lines
      # Save cursor
      echo -en "$CODE_SAVE_CURSOR"

      # Move cursor position to last row
      echo -en "\033[${lines};0f"

      # clear progress bar
      tput el

      # Restore cursor position
      echo -en "$CODE_RESTORE_CURSOR"
  }

  int_print_bar_text() {
      local percentage=$1
      local cols=$(tput cols)
      let bar_size=$cols-17

      local color="${COLOR_FG}${COLOR_BG}"
      if [ "$PROGRESS_BLOCKED" = "true" ]; then
          color="${COLOR_FG}${COLOR_BG_BLOCKED}"
      fi

      # Prepare progress bar
      let complete_size=($bar_size*$percentage)/100
      let remainder_size=$bar_size-$complete_size
      local progress_bar=$(echo -ne "${BANNERC2}["; echo -en "${color}"; int_printf_new "#" $complete_size; echo -en "${RESTORE_FG}${RESTORE_BG}${BANNERC2}"; int_printf_new "." $remainder_size; echo -ne "]${RESTORE_FG}");

      # Print progress bar
      echo -ne " ${BANNERC2}Progress ${percentage}% ${progress_bar}${RESTORE_FG}"
  }

  int_enable_trapping() {
      TRAPPING_ENABLED="true"
  }

  int_trap_on_interrupt() {
      # If this function is called, we setup an interrupt handler to cleanup the progress bar
      TRAP_SET="true"
      trap int_cleanup_on_interrupt INT
  }

  int_cleanup_on_interrupt() {
      int_destroy_scroll_area
      exit
  }

  int_printf_new() {
      local str=$1
      local num=$2
      local v=$(printf "%-${num}s" "$str")
      echo -ne "${v// /$str}"
  }


  # SPDX-License-Identifier: MIT
  #
  # Copyright (c) 2018--2020 Polle Vanhoof
  #
  # Permission is hereby granted, free of charge, to any person obtaining a copy
  # of this software and associated documentation files (the "Software"), to deal
  # in the Software without restriction, including without limitation the rights
  # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  # copies of the Software, and to permit persons to whom the Software is
  # furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in all
  # copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  # SOFTWARE.

  #
  # Text banner functions
  #

  int_vertical_padding () {
    local x=1
    while [ $x -le $1 ]; do
      echo ""
      x=$(( $x + 1 ))
    done
  }

  local BANNERTOTALH=0
  local BANNERC1="\u001b[45m"
  local BANNERC2="\u001b[35;1m"

  int_print_archw_banner () {
  	#
  	# If no gui
  	if [ -n "$ARG_NOTXTGUI" ]; then return 0; fi

  	#
  	# Print benner
  	if [ -n "$1" ]; then
  		local SUFFIX=" ($1)"
  	fi
  	#
  	# Basic settings
  	local LABEL="ArchW Linux installation$SUFFIX"
  	local C1="\u001b[35m"
  	local C2=$BANNERC2
  	local CL="\e[0m"
  	local IMGW=64
  	local IMGH=23
  	local DIVH=2
  	local DIVVT=8
  	local DIVVB=8
  	local COLS=$(tput cols)
  	local LINES=$(tput lines)
  	local SPACING=$(int_printf_new " " $(round $(awk "BEGIN {print ($COLS-$IMGW)/$DIVH}") 0))
  	local SPACINGLABEL=$(int_printf_new " " $(round $(awk "BEGIN {print ($COLS-${#LABEL})/$DIVH}") 0))
  	local SUBLINE=$(int_printf_new "-" $COLS)
  	local XDIVVT=$(round $(awk "BEGIN {print ($LINES-$IMGH)/$DIVVT}") 0)
  	local XDIVVB=$(round $(awk "BEGIN {print ($LINES-$IMGH)/$DIVVB}") 0)
  	BANNERTOTALH=$(awk "BEGIN {print $XDIVVT + $XDIVVB + $IMGH + 2}")
  	#
  	# Print text banner
  	clear
  	int_vertical_padding $XDIVVT
  	printf "${SPACING}${CL}                              ${C1}WWWW${CL}
${SPACING}${CL}                              ${C1}WWWW${CL}
${SPACING}${CL}                              ${C1}WWWW${CL}
${SPACING}${CL}                            ${C1}WWWWWWWW${CL}
${SPACING}${CL}                            ${C1}WWWWWWWW${CL}
${SPACING}${C2}^^^^${CL}                      ${C1}WWWWWWWWWWWW${CL}                      ${C2}^^^^${CL}
${SPACING}${CL}  ${C2}^^^^^^${CL}                    ${C1}WWWWWWWWWW${CL}                  ${C2}^^^^^^${CL}
${SPACING}${CL}    ${C2}^^^^^^^^${CL}            ${C1}WWWW${CL}  ${C1}WWWWWWWWWW${CL}            ${C2}^^^^^^^^${CL}
${SPACING}${CL}    ${C2}^^^^^^^^^^^^${CL}        ${C1}WWWWWWWWWWWWWWWW${CL}        ${C2}^^^^^^^^^^^^${CL}
${SPACING}${CL}      ${C2}^^^^^^^^^^${CL}        ${C1}WWWWWWWWWWWWWWWW${CL}        ${C2}^^^^^^^^^^${CL}
${SPACING}${CL}      ${C2}^^^^^^^^^^${CL}        ${C1}WWWWWWWWWWWWWWWW${CL}        ${C2}^^^^^^^^^^${CL}
${SPACING}${CL}        ${C2}^^^^^^^^${CL}        ${C1}WWWWWWWWWWWWWWWW${CL}        ${C2}^^^^^^^^${CL}
${SPACING}${CL}        ${C2}^^^^^^^^^^${CL}    ${C1}WWWWWWWWWWWWWWWWWWWW${CL}    ${C2}^^^^^^^^^^${CL}
${SPACING}${CL}          ${C2}^^^^^^^^${CL}${C1}WWWWWWWWWWWW${CL}    ${C1}WWWWWWWWWWWW${C2}^^^^^^^^${CL}
${SPACING}${CL}          ${C2}^^^^^^^^${CL}${C1}WWWWWWWWWW${CL}        ${C1}WWWWWWWWWW${C2}^^^^^^^^${CL}
${SPACING}${CL}            ${C2}^^^^${CL}${C1}WWWWWWWWWWWW${CL}        ${C1}WWWWWWWWWWWW${C2}^^^^${CL}
${SPACING}${CL}            ${C2}^^^^${CL}${C1}WWWWWWWWWW${CL}            ${C1}WWWWWW${CL}  ${C1}WW${C2}^^^^${CL}
${SPACING}${CL}              ${C1}WWWWWWWWWWWW${CL}            ${C1}WWWWWWWW${CL}
${SPACING}${CL}            ${C1}WWWWWWWWWWWWWW${CL}            ${C1}WWWWWWWWWWWW${CL}
${SPACING}${CL}            ${C1}WWWWWWWWWW${CL}                    ${C1}WWWWWWWWWW${CL}
${SPACING}${CL}          ${C1}WWWWWWWW${CL}                            ${C1}WWWWWWWW${CL}
${SPACING}${CL}          ${C1}WWWW${CL}                                    ${C1}WWWW${CL}
${SPACING}${CL}        ${C1}WW${CL}                                            ${C1}WW${CL}";
  	int_vertical_padding $XDIVVB
  	printf "${C1}${SPACINGLABEL}$LABEL${CL}\n"
  	printf "${C1}$SUBLINE${CL}\n"
  }

  #
  # Progress bar controller
  #
  PROGCOUNTER=0
  PROGTOTAL=0
  PROGCOMPL=0
  ProgressBar() {
    #
    # Progress increaser
    ProgressIncreaser () {
      echo $(round $(awk "BEGIN {print ($PROGCOUNTER+$PROGCOMPL)/($PROGTOTAL/100)}") 0)
    }

    #
    # Modes
    if [ -n "$1" ]; then
      #
      # If there is some modifiers
      if [ "$1" == "create" ]; then
        #
        # Create progress bar
        TRAPPING_ENABLED="true"
        int_setup_scroll_area $BANNERTOTALH
      elif [ "$1" == "pause" ]; then
        #
        # Hold progress for input activity
        int_block_progress_bar $(ProgressIncreaser)
      elif [ "$1" == "resume" ]; then
        #
        # Resume progress bar but stays on same position
        int_draw_progress_bar $(ProgressIncreaser)
      elif [ "$1" == "remove" ]; then
        #
        # Remove progress bar
        int_destroy_scroll_area
      elif [ "$1" == "init" ] && [ -n "$2" ]; then
        #
        # Count total process
        local INPT=($(echo "$2" | sed -E "s:,:\n:g"))
        for f in "${INPT[@]}" ; do
          #
          # Check links
          local LINKS=($(readlink -f $f))
          for l in "${LINKS[@]}" ; do
            local GREPTOTAL=$(cat $l | grep -Eo '^\s*ProgressBar\s*$' | wc -l)
            PROGTOTAL=$((PROGTOTAL+GREPTOTAL))
          done
        done

        #
        # Count completed process
        if [ -n "$3" ]; then
          local INPC=($(echo "$3" | sed -E "s:,:\n:g"))
          for f in "${INPC[@]}" ; do
            #
            # Check links
            local LINKS=($(readlink -f $f))
            for l in "${LINKS[@]}" ; do
              local GREPTOTALC=$(cat $l | grep -Eo '^\s*ProgressBar\s*$' | wc -l)
              PROGCOMPL=$((PROGCOMPL+GREPTOTALC))
            done
          done
        fi
      fi
    else
      #
      # If nothing, try to rotate progress
      ((PROGCOUNTER++))
      int_draw_progress_bar $(ProgressIncreaser)
    fi
  }
}
