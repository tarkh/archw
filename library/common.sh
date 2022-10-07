#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2022

#
# Round numbers
round() {
  printf "%.${2}f" "${1}"
}

#
# Match in array
inArray () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

#
# General date time
datetime() {
  if [ "$1" == "time" ]; then
    echo $(date '+%H:%M:%S')
  elif [ "$1" == "date" ]; then
    echo $(date '+%Y-%m-%d')
  else
    echo $(date '+%Y-%m-%d %H:%M:%S')
  fi
}

#
# General error print
error() {
  print() {
    echo "$(color B_HRed $1) $(color HRed "$2")" >&2
    if [ -n "$S_LOGFILE" ]; then
      echo "[$(datetime time)] $1 $2" >> $S_LOGFILE
    fi
  }
  if [ -n "$2" ]; then
    print "[Panic!]" "$1"
    echo $(color B_HRed "Stopping program now...")
    exit 1
  elif [ -n "$1" ]; then
    print "[Error]" "$1"
  else
    print "[Error]" "Something went wrong!"
  fi
  return 1
}
panic() {
  error "$@" true
}

#
# General warning print
warn() {
  print() {
    echo "$(color B_HYellow Warning:) $(color HYellow "$1")" >&2
    if [ -n "$S_LOGFILE" ]; then
      echo "Warning: $1" >> $S_LOGFILE
    fi
  }
  if [ -n "$1" ]; then
    print "$1"
  else
    print "Something went with warnings!"
  fi
  return 0
}

#
# General info print
log() {
  print() {
    echo "$1"
    if [ -n "$S_LOGFILE" ]; then
      echo "$1" >> $S_LOGFILE
    fi
  }
  print "$1"
  return 0
}

#
# Logger
logger() {
  if [ -z "$S_LOGFILE" ]; then
    return 0
  fi
  # Create file
  touch $S_LOGFILE
  chmod 777 $S_LOGFILE
  log "[$(datetime)] Starting log"
}

#
# Colors
color() {
  #
  # Codes: https://i.stack.imgur.com/3V6qs.png
  #

  #
  # If no text
  if [ -z "$1" ] || [ -z "$2" ]; then
    return 0
  else
    local code=$1
  fi

  #
  # If color names
  if [[ "$code" =~ ^[A-Za-z_]+$ ]]; then
    # If additional style provided
    local style=""
    if [[ "$code" =~ ^[A-Z]+_[A-Za-z]+$ ]]; then
      style=${code//_*/_}
      code=${code//*_/}
    fi

    #
    # Set 8 colors name
    declare -A colors
    # Regular Colors
    colors[Black]=000        # Black
    colors[Red]=001          # Red
    colors[Green]=002        # Green
    colors[Yellow]=003       # Yellow
    colors[Blue]=004         # Blue
    colors[Purple]=005       # Purple
    colors[Cyan]=006         # Cyan
    colors[White]=007        # White
    # Regular Colors High
    colors[HBlack]=008        # Black
    colors[HRed]=009          # Red
    colors[HGreen]=010        # Green
    colors[HYellow]=011       # Yellow
    colors[HBlue]=012         # Blue
    colors[HPurple]=013       # Purple
    colors[HCyan]=014         # Cyan
    colors[HWhite]=015        # White
    # Check if name exist
    if [ "${colors[$code]+_}" ]; then
      code="${style}${colors[$code]}"
    else
      error "color name '$code' could not be found"
    fi
  fi

  #
  # If manual color code provided
  local res=""
  local style=""
  if [[ "$code" =~ ^[0-9]+$ ]]; then
    res="\033[38;5;${code}m"
  elif [[ "$code" =~ ^(BG|[BIUS]+)_[0-9]+$ ]]; then
    style=${code//_*/}
    code=${code//*_/}
    if [[ "$style" =~ BG ]]; then
      res="\033[48;5;${code}m"
    else
      if [[ "$style" =~ B ]]; then res="\033[1;38;5;${code}m"; fi
      if [[ "$style" =~ I ]]; then res+="\033[3;38;5;${code}m"; fi
      if [[ "$style" =~ U ]]; then res+="\033[4;38;5;${code}m"; fi
      if [[ "$style" =~ S ]]; then res+="\033[9;38;5;${code}m"; fi
    fi
  else
    error "color code '$code' format error"
  fi
  echo -e "${res}$2\033[0m"
}

#
# Config loader
ldconf() {
  local CPATH=$(readlink -f $1)
  if [ -f "$CPATH" ]; then
    . $CPATH
  elif [ -z "$2" ]; then
    error "Config file '$1 ($CPATH)' not found"
  fi
  return 0
}

#
# Arguments
# ARGV: regular array
ARGV=()
# ARGS: key->value array
declare -A ARGS
args() {
  # Prepare arg list combinations
  local END_OF_OPT=
  while [[ $# -gt 0 ]]; do
    local arg="$1"; shift
    case "${END_OF_OPT}${arg}" in
      --) ARGV+=("$arg"); END_OF_OPT=1 ;;
      --*=*)ARGV+=("${arg%%=*}" "${arg#*=}") ;;
      --*) ARGV+=("$arg") ;;
      -*) for i in $(seq 2 ${#arg}); do ARGV+=("-${arg:i-1:1}"); done ;;
      *) ARGV+=("$arg") ;;
    esac
  done
  # Set key->value array
  for (( i=0; i<${#ARGV[@]}; i++ )); do
    # If current is key
    if [[ "${ARGV[$i]}" =~ ^- ]]; then
      # If next is not key
      if [ -n "${ARGV[$i+1]}" ] && [[ ! "${ARGV[$i+1]}" =~ ^- ]]; then
        ARGS+=([${ARGV[$i]}]="${ARGV[$i+1]}")
        i=$((i+1))
        continue
      fi
    fi
    ARGS+=(${ARGV[$i]})
  done
  return 0
}

#
# Arguments helper
arg() {
  if [ ${ARGS[$1]+_} ]; then
    echo "${ARGS[$1]}"
    return 0
  fi
  return 1
}

#
# Override config from args config
argsConf() {
  if optval=$(arg "--config") && [ -n "$optval" ]; then
    local _IFS_=$IFS
    IFS=','
    read -ra CONFARGS <<< "$optval"
    for i in "${CONFARGS[@]}"; do
      # Check if it's config format
      if [[ "$i" =~ ^S_[A-Za-z0-9_]+\= ]]; then
        local varname=${i/=*/}
        local varval=${i/$varname=/}
        if [[ $varval =~ (\$|\(|\)|\`) ]]; then
          varval="'$(echo "$varval" | sed -E \
            "s:\`:\\\`:g; \
            s:(^\"|\"$)::g; \
            s:(^\\\\'|\\\\'$)::g" \
          )'"
        fi
        eval "$varname=$varval"
      fi
    done
    IFS=$_IFS_
  fi
}

#
# Config system
config() {
  # Config loader
  confld() {
    # If file do not exist
    if [ -z "$1" ] || ! [ -f "$1" ]; then
      return 1
    fi
    # Load file
    . "$1"
    return 0
  }
  # Modes
  if [ "$1" == "require" ]; then
    if ! confld "$2"; then
      error "can't load config $2" true
    fi
  elif [ "$1" == "load" ]; then
    confld "$2"
  fi
  return 0
}

#
# Column formater
columnFormat() {
	echo "$@" | sed -E "s/\s*;/;/" | column -L -s ';' -t -d -N C1,C2 -W C2
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