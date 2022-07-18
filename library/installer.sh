#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# Load patch config
loadPatchConf() {
  config require "./patch/$1/config/main.cfg"
  config require "./patch/$1/config/software.cfg"
}

#
# Check config
checkConfig() {
  :
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

#
# Run installer
runInstaller() {
  . "./library/installer.sh"

  #
  # Base patch override
  S_BASE_PATCH="base"
  if optval=$(arg "--base-patch") && [ -n "$optval" ]; then
    S_BASE_PATCH="$optval"
  fi

  #
  # Load base configs
  loadPatchConf "$S_BASE_PATCH"

  #
  # Override config options with args
  argsConf

  #
  # Start logger
  logger

  #
  # Starting banner
  log "
  ========================
  STARTING ARCHW INSTALLER
  ========================
  "

  #
  # Check config
  checkConfig
}

