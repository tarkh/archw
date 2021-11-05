#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021

#
# ArchW text logo
# 64x23 char

vertical_padding () {
  x=1
  while [ $x -le $1 ]
  do
    echo ""
    x=$(( $x + 1 ))
  done
}

BANNERTOTALH=0
BANNERC1="\u001b[45m"
BANNERC2="\u001b[35;1m"

print_archw_banner () {
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
	LABEL="ArchW Linux installation$SUFFIX"
	local C1="\u001b[35m"
	local C2=$BANNERC2
	local CL="\e[0m"
	local IMGW=64
	local IMGH=23
	local DIVH=2
	local DIVVT=6
	local DIVVB=6
	local COLS=$(tput cols)
	local LINES=$(tput lines)
	local SPACING=$(printf_new " " $(round $(awk "BEGIN {print ($COLS-$IMGW)/$DIVH}") 0))
	local SPACINGLABEL=$(printf_new " " $(round $(awk "BEGIN {print ($COLS-${#LABEL})/$DIVH}") 0))
	local SUBLINE=$(printf_new "-" $COLS)
	local XDIVVT=$(round $(awk "BEGIN {print ($LINES-$IMGH)/$DIVVT}") 0)
	local XDIVVB=$(round $(awk "BEGIN {print ($LINES-$IMGH)/$DIVVB}") 0)
	BANNERTOTALH=$(awk "BEGIN {print $XDIVVT + $XDIVVB + $IMGH + 2}")
	#
	# Print text banner
	clear
	vertical_padding $XDIVVT
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
	vertical_padding $XDIVVB
	printf "${C1}${SPACINGLABEL}$LABEL${CL}\n"
	printf "${C1}$SUBLINE${CL}\n"
}
