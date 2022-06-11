#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# HELP - help information extracter
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--help [--all|<mod>] ;Shows current information. Add [<mod>] or [--all] for full help content
"
fi
if [ "$1" == 'help' ]; then
  echo "
--help [--all|<mod>] ;Show avaliable modules draft. Optionally show [<mod>] or [--all] modules full help content
"
fi

#
# Module content
help () {
	echo "ArchW control center
Usage: `basename "$0"` --<mod> [opt]"
	# Loop modules
	local HELP=""
	if $(ls $S_ARCHW_MODULES/${2//-/}.sh 2>/dev/null); then
		HELP+="$(bash "$S_ARCHW_MODULES/${2//-/}.sh" help)
    "
	else
		for m in "${MODLIST[@]}"; do
			if [ "$2" == "--all" ]; then
			  HELP+="
				$(bash "$m" help)"
			else
				HELP+="$(bash "$m" help_draft)"
			fi
		done
	fi
	# Format with column
	echo "$HELP" | sed -E "s/\s*;/;/" | column -L -s ';' -t -d -N C1,C2 -W C2
	exit 0
}
