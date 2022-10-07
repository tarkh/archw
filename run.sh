#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# Set system vars
cd "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

#
# Load libraries
. "./library/common.sh"

#
# Read and set arguments
args "$@"
set -- "${ARGV[@]}"

#
# Statements
if [ "$1" == "install" ]; then
  #
  # Run installer
  . "./library/installer.sh"
  runInstaller
elif [ "$1" == "update" ]; then
  #
  # Run updater
  :
else
  #
  # Show help
  columnFormat "
usage: `basename "$0"` <command> [options]

commands:
  install               ;Run ArchW installer
  update                ;Update ArchW system

options:
  -t                    ;Run in text mode
  -y                    ;Run without any prompts
  --base-patch <name>   ;Set base patch for installer. Default is 'base'
  --config <key=val,..> ;Override installer config
"
fi