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
makeConfig() {
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
  # Make config
  makeConfig
}

#
# Add kernel parameters
add_kernel_param () {
  echo "Adding kernel parameters: $1"
  sudo sed -i -E \
  "s:^(\s*GRUB_CMDLINE_LINUX_DEFAULT=\".*)(\")\s*$:\1 $1\2:" \
  /etc/default/grub
}

#
# Remove kernel parameters
remove_kernel_param () {
  echo "Removing kernel parameters: $1"
  sudo sed -i -E \
  -e "/^\s*GRUB_CMDLINE_LINUX_DEFAULT=.*/"'s:'$1'(=[^ \"]+|[=]*[ ]+|[=]*([\"]+)):\2:g' \
  -e "/^\s*GRUB_CMDLINE_LINUX_DEFAULT=.*/"'s:\"\s+:\":' \
  -e "/^\s*GRUB_CMDLINE_LINUX_DEFAULT=.*/"'s:\s+\":\":' \
  -e "/^\s*GRUB_CMDLINE_LINUX_DEFAULT=.*/"'s:\s+: :g' \
  /etc/default/grub
}

#
# Add system entrie
add_system_entrie () {
  # Check for proper params
  if [[ -z "$1" || ( -z "$2" && -z "$3" ) ]]; then
    return 1
  fi
  # Check if entrie alredy exist
  if cat /etc/mkinitcpio.conf | grep -E "^[[:space:]]*$1=" | grep -w "${2:-$3}" > /dev/null; then
    echo "add_system_entrie: \"${2:-$3}\" alredy exist in \"$1\""
    return 0
  fi
  # Replace
  if [ -n "$2" ] && [ -n "$3" ]; then
    sudo sed -i -E \
    "s:^\s*($1=.*[\( ])($3)([\) ].*):\1 $2 \2\3:" \
    /etc/mkinitcpio.conf
  elif [ -n "$4" ]; then
    sudo sed -i -E \
    "s:^\s*($1=.*[\( ])($4)([\) ].*):\1\2 $2 \3:" \
    /etc/mkinitcpio.conf
  elif [ -z "$2" ] && [ -n "$3" ]; then
    sudo sed -i -E \
    "s:^\s*($1=.*)(\))\s*$:\1 $3\2:" \
    /etc/mkinitcpio.conf
  else
    sudo sed -i -E \
    "s:^\s*($1=\()(.*\))\s*$:\1$2 \2:" \
    /etc/mkinitcpio.conf
  fi
  # Remove extra spaces
  sudo sed -i -E \
  -e "/^\s*$1=.*/"'s:\(\s+:\(:' \
  -e "/^\s*$1=.*/"'s:\s+\):\):' \
  -e "/^\s*$1=.*/"'s:\s+: :g' \
  /etc/mkinitcpio.conf
}

#
# Remove system entrie
remove_system_entrie () {
  # Check for proper params
  if [[ -z "$1" && -z "$2" ]]; then
    return 1
  fi
  # Check if entrie exist
  if ! cat /etc/mkinitcpio.conf | grep -E "^[[:space:]]*$1=" | grep -w "${2}" > /dev/null; then
    echo "remove_system_entrie: \"${2}\" does not exist in \"$1\""
    return 0
  fi
  # Replace
  sudo sed -i -E \
  "s:^\s*($1=.*[\( ])${2}([\) ].*):\1\2:" \
  /etc/mkinitcpio.conf
  # Remove extra spaces
  sudo sed -i -E \
  -e "/^\s*$1=.*/"'s:\s+: :g' \
  /etc/mkinitcpio.conf
}

#
# Add system modules
add_system_module () {
  # $1 - new module $1 at the beginning
  # $2 - new module $1 at the end
  # $1 $2 - new module $1 before hook $2
  # $1 $3 - new module $1 after hook $3
  #
  # example: add_system_module "test" "" "intel"
  # will add module test after module intel
  #
  echo "Adding system modules: ${1:-$2}"
  if ! add_system_entrie "MODULES" "$@"; then
    echo "add_system_module: error in parameters"
    return 1
  fi
}

#
# Remove system modules
remove_system_module () {
  # $1 - one module to remove per command
  #
  echo "Removing system module: ${1}"
  if ! remove_system_entrie "MODULES" "$1"; then
    echo "remove_system_module: error in parameters"
    return 1
  fi
}

#
# Add system hooks
add_system_hook () {
  # $1 - new hook $1 at the beginning
  # $2 - new hook $1 at the end
  # $1 $2 - new hook $1 before hook $2
  # $1 $3 - new hook $1 after hook $3
  #
  # example: add_system_hook "test" "" "block"
  # will add hook test after hook block
  #
  echo "Adding system hooks: ${1:-$2}"
  if ! add_system_entrie "HOOKS" "$@"; then
    echo "add_system_hook: error in parameters"
    return 1
  fi
}

#
# Remove system hooks
remove_system_hook () {
  # $1 - one hook to remove per command
  #
  echo "Removing system hook: ${1}"
  if ! remove_system_entrie "HOOKS" "$1"; then
    echo "remove_system_hook: error in parameters"
    return 1
  fi
}

#
# IP pinger
check_ip () {
  #echo "Checking network connection (${1})"
  if ping -q -w 2 -c 1 $1 > /dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}
# Check if machine connected to the internet
# Run pinger on list of DNSes
connected () {
  # servers to ping
  declare -a arr=(
                   8.8.8.8
                   8.8.4.4
                   77.88.8.8
                   77.88.8.1
                 )
  # ping in loop if false
  for i in "${!arr[@]}"
  do
    # if ping ok, return true
    if check_ip "${arr[$i]}"; then
      return 0
      break
    fi
  done
  # else return false
  return 1
}
#
# WiFi
try_connect () {
  #
  # IP checker
  local CHECKCOUNTER=0
  local CHECKCOUNTERMAX=45
  ping_connection () {
    #
    # If no ip within long time, quit
    if [ $CHECKCOUNTER -gt $CHECKCOUNTERMAX ]; then
      clear
      echo ""
      echo "========================================================="
      echo " Can't connect to selected WiFi network with provided"
      echo " auth. Error getting IP address. Please try again."
      echo "========================================================="
      echo ""
      exit 0
    fi

    #
    # Check loop
    if ! connected; then
      CHECKCOUNTER=$(( CHECKCOUNTER + 1 ))
      sleep 2
      ping_connection
    fi
    return 0
  }
  #
  INAME=$(iw dev | grep Interface | cut -d " " -f2)
  # Show networks
  iwctl station $INAME scan
  echo "Scaning networks on ${INAME}..."
  sleep 5
  iwctl station $INAME get-networks
  echo "";
  #
  if [ -f "${S_PKG}/autonetworkwifi" ]; then
    . ${S_PKG}/autonetworkwifi
  else
    # Prompt for network name
    read -p "Enter your network name: " AN_SSID
    # Prompt for network pass
    read -p "Enter your network password: " AN_PASS
  fi
  # connect
  iwctl --passphrase="${AN_PASS}" station $INAME connect "${AN_SSID}"
  echo "Connecting to wifi network ${AN_SSID}... This might take up to 60 seconds..."
  sleep 1
  # Check connection
  ping_connection
  # Save connection
  if ! [ -f "${S_PKG}/autonetworkwifi" ]; then
    bash -c "cat > ./autonetworkwifi" << EOL
AN_SSID="${AN_SSID}"
AN_PASS="${AN_PASS}"
EOL
  fi
}