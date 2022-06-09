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
    echo "$(color B_HRed Error:) $(color HRed "$1")" >&2
    if [ -n "$S_LOGFILE" ]; then
      echo "[$(datetime time)] Error: $1" >> $S_LOGFILE
    fi
  }
  if [ -n "$1" ]; then
    print "$1"
  else
    print "Something went wrong!"
  fi
  if [ -n "$2" ]; then
    echo $(color B_HRed "Exit program now...")
    exit 1
  fi
  return 1
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
# Cache system
cache() {
  :
}

#
# Override config from args config
argsConf() {
  if optval=$(arg "--config") && [ -n "$optval" ]; then
    local _IFS_=$IFS
    IFS=';'
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
    local f=$1
    # If cache enabled
    if [ -n "$S_CACHE" ]; then
      # Check in cache
      f=$(cache get "$f")
    fi
    # If file do not exist
    if [ -z "$f" ] || ! [ -f "$f" ]; then
      return 1
    fi
    # Load file
    . "$f"
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
