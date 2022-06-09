#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# Load patch config
loadPatchConf() {
  config require "./patches/$1/config/main.cfg"
  config require "./patches/$1/config/software.cfg"
}

#
# Base installer path
runBase() {
  log "Running base patch"
  # Get patches list
  local patches=(${S_PATCHES//,/ })
  # Enable banner
  if ! arg "-t"; then
    . ./library/interface.sh
    int_ui
    int_print_archw_banner
    ProgressBar create
  fi

}
