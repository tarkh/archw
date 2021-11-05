#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# VERSION - archw app version
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--version ;Show ArchW tools version
"
fi
if [ "$1" == 'help' ]; then
  echo "
--version ;Show ArchW tools version
"
fi

#
# Module content
version () {
  echo "ArchW tools version $(cat $S_ARCHW_LIB/VERSION)"
}
