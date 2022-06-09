#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# Set system vars
cd "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
S_BASE_PATCH="base"

#
# Load common functions library
. "./library/common.sh"
. "./library/installer.sh"

#
# Read and set arguments
args "$@"
set -- "${ARGV[@]}"

#
# Base patch override
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
# Run base installer patch
runBase
