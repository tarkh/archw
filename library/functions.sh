#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021

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
# Set glob shortcuts
V_AUR=""
V_PB=""
V_TR=""
V_RPB=""
set_glob_shortcuts () {
  if [ -n "$S_PKG" ]; then
    V_AUR="$S_PKG/AUR"
    V_PB="$S_PKG/PREBUILT"
    V_TR="https://github.com/tarkh"
    V_RPB="${V_TR}/archw/raw/assets/prebuilt"
  else
    echo "Error: \$S_PKG variable empty"
    exit 1
  fi
}

#
# Save DEVICES
V_DEV_SYSTEM=""
V_DEV_EFI=""
V_DEV_SWAP=""
save_devices_config () {
  echo "Creating DEVICES config"
  #
  if [ -n "$S_DISK" ] && [ -n "$S_DISK_SYSTEM" ] && [ -n "$S_ARCHW_FOLDER" ]; then
    # Set DEVICES file
    sudo touch $S_ARCHW_FOLDER/DEVICES
    # Write system device UUID
    V_DEV_SYSTEM=$(sudo lsblk -o PATH,UUID | grep ${S_DISK}${S_DISK_SYSTEM} | awk '{print $2}')
    sudo bash -c "echo "V_DEV_SYSTEM=$V_DEV_SYSTEM" > $S_ARCHW_FOLDER/DEVICES"
    # If EFI exist
    if [ "$S_BOOT" != "bios" ] && [ -n "$S_DISK_EFI" ]; then
      # Write EFI device UUID
      V_DEV_EFI=$(sudo lsblk -o PATH,UUID | grep ${S_DISK}${S_DISK_EFI} | awk '{print $2}')
      sudo bash -c "echo "V_DEV_EFI=$V_DEV_EFI" >> $S_ARCHW_FOLDER/DEVICES"
    fi
    # If swap exist
    if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_SWAP_FILE" ]; then
      V_DEV_SWAP=$(findmnt -no UUID -T ${S_SWAP_FILE})
      sudo bash -c "echo "V_DEV_SWAP=$V_DEV_SWAP" >> $S_ARCHW_FOLDER/DEVICES"
    fi
  else
    echo "Can't save DEVICES config, insufficient parameters"
    return 1
  fi
}

#
# Load DEVICES
load_devices_config () {
  echo "Loading DEVICES config"
  if [ -f "${S_ARCHW_FOLDER}/DEVICES" ]; then
    . ${S_ARCHW_FOLDER}/DEVICES
  else
    echo "DEVICES config not found"
    save_devices_config
  fi
}

#
# Load local confs
load_archw_local_conf () {
  if [ -n "$S_ARCHW_FOLDER" ] && [ -f "${S_ARCHW_FOLDER}/config/config" ] && [ -f "${S_ARCHW_FOLDER}/config/patch/config" ] && [ -f "$S_ARCHW_FOLDER/config/software" ]; then
    . $S_ARCHW_FOLDER/config/config
    . $S_ARCHW_FOLDER/config/patch/config
    . $S_ARCHW_FOLDER/config/patch/${S_PATCH}/config
    . $S_ARCHW_FOLDER/config/software
    echo "Local config loaded"
  else
    if [[ -n "$ARCHW_PKG_INST" || -n "$ARG_ARCHW_UPDATE" ]] && [ ! -f "$S_ARCHW_FOLDER/DEVICES" ]; then
      echo "Local config and DEVICES config not found, installation process can't continue"
      exit 1
    else
      echo "WARNING! Local config not found"
      read -p "Use default? (y/n) " -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    fi
  fi

}

#
# Create install additional dirs
mk_install_sys_dirs () {
  if [ -n "$S_PKG" ]; then
    sudo mkdir -p $S_PKG
    sudo chmod 777 $S_PKG
    mkdir -p $V_AUR
    mkdir -p $V_PB
  fi
}

#
# Set hibernation
set_hibernation () {
  #
  # Set kernel hook
  add_system_hook "resume" "" "filesystems"

  #
  # Check for required var
  if [ -z "$S_SWAP_FILE" ]; then
    echo "Error: can't get swapfile name"
    exit 1
  fi

  #
  # Get swapfile UUID
  if [ -z "$V_DEV_SWAP" ]; then
    V_DEV_SWAP=$(findmnt -no UUID -T ${S_SWAP_FILE})
  fi
  local SWAPFILE_UUID_PARAM="resume=UUID=${V_DEV_SWAP}"
  SWAPFILE_OFFSET=$(sudo filefrag -v ${S_SWAP_FILE} | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')
  SWAPFILE_OFFSET_PARAM="resume_offset=${SWAPFILE_OFFSET}"
  # patch grub config
  remove_kernel_param "resume"
  remove_kernel_param "resume_offset"
  add_kernel_param "${SWAPFILE_UUID_PARAM} ${SWAPFILE_OFFSET_PARAM}"

  # Apply
  install_grub

  #
  # Maj:min device number
  local DEVPATH=$(lsblk -o PATH,UUID | grep "$V_DEV_SWAP" | awk '{print $1}')
  MAJMIN_DEV_NUM=$(lsblk | grep -w $DEVPATH | awk '{print $2}')
  # Apply immediately
  sudo bash -c "echo $MAJMIN_DEV_NUM > /sys/power/resume"
  sudo bash -c "echo $SWAPFILE_OFFSET > /sys/power/resume_offset"
}

#
# Progress bar
PROGCOUNTER=0
PROGTOTAL=0
PROGCOMPL=0
function ProgressBar {
  #
  # If no gui
  if [ -n "$ARG_NOTXTGUI" ]; then return 0; fi

  #
  # Progress increaser
  ProgressIncreaser () {
    echo $(round $(awk "BEGIN {print ($PROGCOUNTER+$PROGCOMPL)/($PROGTOTAL/100)}") 0)
  }

  #
  # Modes
  if [ -n "$1" ]; then
    #
    # If there is some modifiers
    if [ "$1" == "create" ]; then
      #
      # Create progress bar
      TRAPPING_ENABLED="true"
      setup_scroll_area $BANNERTOTALH
    elif [ "$1" == "pause" ]; then
      #
      # Hold progress for input activity
      block_progress_bar $(ProgressIncreaser)
    elif [ "$1" == "resume" ]; then
      #
      # Resume progress bar but stays on same position
      draw_progress_bar $(ProgressIncreaser)
    elif [ "$1" == "remove" ]; then
      #
      # Remove progress bar
      destroy_scroll_area
    elif [ "$1" == "init" ] && [ -n "$2" ]; then
      #
      # Count total process
      local INPT=($(echo "$2" | sed -E "s:,:\n:g"))
      for f in "${INPT[@]}" ; do
        #
        # Check links
        local LINKS=($(readlink -f $f))
        for l in "${LINKS[@]}" ; do
          local GREPTOTAL=$(cat $l | grep -Eo '^\s*ProgressBar\s*$' | wc -l)
          PROGTOTAL=$((PROGTOTAL+GREPTOTAL))
        done
      done

      #
      # Count completed process
      if [ -n "$3" ]; then
        local INPC=($(echo "$3" | sed -E "s:,:\n:g"))
        for f in "${INPC[@]}" ; do
          #
          # Check links
          local LINKS=($(readlink -f $f))
          for l in "${LINKS[@]}" ; do
            local GREPTOTALC=$(cat $l | grep -Eo '^\s*ProgressBar\s*$' | wc -l)
            PROGCOMPL=$((PROGCOMPL+GREPTOTALC))
          done
        done
      fi
    fi
  else
    #
    # If nothing, try to rotate progress
    ((PROGCOUNTER++))
    draw_progress_bar $(ProgressIncreaser)
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
nm_try_connect () {
  cd $S_PKG
  if [ -f "${S_PKG}/autonetworkwifi" ]; then
    . ./autonetworkwifi
    echo "Connecting to wifi network ${AN_SSID}... This might take up to 60 seconds..."
    sleep 5
    nmcli device wifi connect "${AN_SSID}" password $AN_PASS
    sleep 5
    ip address show
  fi
}
#
iwctl_try_connect () {
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
  sleep 1
  iwctl station $INAME get-networks
  echo "";
  # Prompt for network name
  read -p "Enter your network name: " SSID
  # Prompt for network pass
  read -p "Enter your network password: " PASSWD
  # connect
  iwctl --passphrase="${PASSWD}" station $INAME connect "${SSID}"
  echo "Connecting to wifi network ${SSID}... This might take up to 60 seconds..."
  sleep 1
  # Check connection
  ping_connection
  # Save connection
  bash -c "cat > ./autonetworkwifi" << EOL
AN_SSID="${SSID}"
AN_PASS="${PASSWD}"
EOL
}

#
# Partition GUID selector
# https://en.wikipedia.org/wiki/GUID_Partition_Table#Partition_type_GUIDs
partition_guid () {
  if [ -n "$1" ]; then
    if [ $1 == "bios" ]; then
      echo "21686148-6449-6E6F-744E-656564454649"
    elif [ $1 == "efi" ]; then
      echo "C12A7328-F81F-11D2-BA4B-00A0C93EC93B"
    elif [ $1 == "swap" ]; then
      echo "0657FD6D-A4AB-43C4-84E5-0933C84B4F4F"
    elif [ $1 == "linux" ]; then
      echo "0FC63DAF-8483-4772-8E79-3D69D8477DE4"
    elif [ $1 == "hfsplus" ]; then
      echo "48465300-0000-11AA-AA11-00306543ECAC"
    fi
  else
    return 1
  fi
}

#
# Grub install function
# We use sudo because this function also
# could be called from admin section by
# grub-silent package (without packageInstall option)
install_grub () {
  #
  # Errors
  efi_mount_err () {
    echo "Error occured while mounting EFI drive! Please check UUID of your EFI drive in the /usr/share/archw/DEVICES config."
  }
  efi_umount_err () {
    echo "Error occured while unmounting /boot/EFI. Please, unmount drive manually and repeat this process."
  }

  #
  # Change udev to systemd
  sudo sed -i -E \
  "s:^\s*(HOOKS=.*[\( ])udev([\) ].*):\1systemd\2:" \
  /etc/mkinitcpio.conf

  #
  # Boot modes
  if [ "$S_BOOT" == "bios" ]; then
    sudo mkdir -p /boot
    sudo mkdir -p /boot/grub/
    sudo mkinitcpio -p $S_LINUX
    sudo grub-install /dev/$S_DISK
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  elif [ "$S_BOOT" == "uefi" ]; then
    if [ "$1" == "packageInstall" ]; then
      pacman --noconfirm -S efibootmgr dosfstools os-prober mtools
    fi
    sudo mkdir -p /boot/EFI
    sudo mkdir -p /boot/grub/
    # Mount EFI
    sudo umount /boot/EFI
    sleep 1
    # Try to load with UUID
    if [ -n "$V_DEV_EFI" ]; then
      if ! sudo mount -U "$V_DEV_EFI" /boot/EFI; then
        efi_mount_err
        exit 1
      fi
    else
      sudo mount /dev/${S_DISK}${S_DISK_EFI} /boot/EFI
    fi
    sudo mkinitcpio -p $S_LINUX
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    sudo grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=$S_BOOTLOADER_ID --recheck
  elif [ "$S_BOOT" == "hfs" ]; then
    if [ "$1" == "packageInstall" ]; then
      # Install hfs tools
      su $S_MAINUSER -c "yay --noconfirm -S hfsprogs"
      modprobe hfsplus
      # Make hfsplus
      mkfs.hfsplus /dev/${S_DISK}${S_DISK_EFI} -v "${S_BOOTLOADER_ID}"
      # Install grub
      pacman --noconfirm -S efibootmgr dosfstools os-prober mtools
    fi
    sudo mkdir -p /boot/EFI
    sudo mkdir -p /boot/grub/
    # Mount HFS+ EFI
    sudo umount /boot/EFI
    sleep 1
    # Try to load with UUID
    if [ -n "$V_DEV_EFI" ]; then
      if ! sudo mount -U "$V_DEV_EFI" /boot/EFI; then
        efi_mount_err
        exit 1
      fi
    else
      sudo mount /dev/${S_DISK}${S_DISK_EFI} /boot/EFI
    fi
    #
    sudo mkinitcpio -p $S_LINUX
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    if [ -n "$GRUB_CONTENT_REBUILD" ]; then
      sudo rm -rf /boot/EFI/System
      sudo touch /boot/EFI/mach_kernel
      sudo mkdir -p /boot/EFI/System/Library/CoreServices/
      sudo bash -c "cat > /boot/EFI/System/Library/CoreServices/SystemVersion.plist" << EOL
<?xml version="1.0" encoding="UTF-8"?>
 <plist version="1.0">
 <dict>
        <key>ProductBuildVersion</key>
        <string></string>
        <key>ProductName</key>
        <string>Linux</string>
        <key>ProductVersion</key>
        <string>ArchW</string>
 </dict>
 </plist>
EOL
      # Copy blessed ArchW partition label
      sudo cp -a $S_PKG/package/common-scripts/blessed/. /boot/EFI/System/Library/CoreServices/
      # Install ArchW icon
      sudo convert $S_PKG/package/wallpapers/archw-logo-src.png -resize "128x128" /tmp/VolumeIcon.png
      sudo png2icns /boot/EFI/.VolumeIcon.icns /tmp/VolumeIcon.png
    fi
    # Copy standalone grub
    sudo grub-mkstandalone -o /boot/EFI/System/Library/CoreServices/boot.efi \
    -d /usr/lib/grub/x86_64-efi -O x86_64-efi --compress=xz /boot/grub/grub.cfg
  fi
}

#
# Service disabler/enabler
# Set system variables for enabled and running services
SCTL_SYS_ENABLED=()
SCTL_SYS_RUNNING=()
SCTL_USR_ENABLED=()
SCTL_USR_RUNNING=()
service_ctl () {
  #
  # Check type
  if [ "$1" == "sys" ]; then
    local OPT="sudo "
    local SRVSPATH="/etc/systemd/system"
  elif [ "$1" == "user" ]; then
    local OPT2=" --user"
    local SRVSPATH="/usr/lib/systemd/user"
  else
    echo "(service_ctl) Error with parameter 1: $1"
    return 1
  fi

  #
  # Check command
  if [ "$2" == "off" ]; then
    local CMD=disable
    local CMD2=stop
  elif [ "$2" == "install" ]; then
    local CMD=install
  elif [ "$2" == "install-on" ]; then
    local CMD=install-on
  elif [ "$2" == "on" ]; then
    local CMD=enable
    local CMD2=start
    if [ -z "$OPT" ]; then
      systemctl --user daemon-reload
    else
      ${OPT}systemctl daemon-reload
      systemctl --user daemon-reload
    fi
  else
    echo "(service_ctl) Error with parameter 2: $2"
    return 1
  fi

  #
  # Get service list
  if [ -z "$3" ]; then
    echo "(service_ctl) Error with parameter 3: $3"
    return 1
  fi

  shift 2
  local SRVS=($(echo "$@"))
  for s in "${SRVS[@]}"; do
    if [ "$CMD" == "disable" ]; then
      #
      # If disable
      if [ "$(systemctl${OPT2} show -p UnitFileState --value $s)" == "enabled" ]; then
        echo "$CMD: $s"
        ${OPT}systemctl${OPT2} $CMD $s
        if [ -z "$OPT" ]; then
          SCTL_USR_ENABLED+=( $s )
        else
          SCTL_SYS_ENABLED+=( $s )
        fi
      fi
      if [ "$(systemctl${OPT2} show -p ActiveState --value $s)" == "active" ]; then
        echo "$CMD2: $s"
        ${OPT}systemctl${OPT2} $CMD2 $s
        if [ -z "$OPT" ]; then
          SCTL_USR_RUNNING+=( $s )
        else
          SCTL_SYS_RUNNING+=( $s )
        fi
      fi
    elif [ "$CMD" == "install" ]; then
      #
      # Just install service
      sudo \cp $s $SRVSPATH
    elif [ "$CMD" == "install-on" ]; then
      #
      # Install and add to enabler list if new
      local BN=$(basename $s)
      if [ ! -f $SRVSPATH/$BN ]; then
        if [ -z "$OPT" ]; then
          SCTL_USR_ENABLED+=( $BN )
        else
          SCTL_SYS_ENABLED+=( $BN )
        fi
      fi
      sudo \cp $s $SRVSPATH
    elif [ "$CMD" == "enable" ]; then
      #
      # If enable
      if [ -z "$OPT" ]; then
        if inArray $s ${SCTL_USR_ENABLED[@]}; then
          echo "$CMD: $s"
          ${OPT}systemctl${OPT2} $CMD $s
        fi
        if inArray $s ${SCTL_USR_RUNNING[@]}; then
          echo "$CMD2: $s"
          ${OPT}systemctl${OPT2} $CMD2 $s
        fi
      else
        if inArray $s ${SCTL_SYS_ENABLED[@]}; then
          echo "$CMD: $s"
          ${OPT}systemctl${OPT2} $CMD $s
        fi
        if inArray $s ${SCTL_SYS_RUNNING[@]}; then
          echo "$CMD2: $s"
          ${OPT}systemctl${OPT2} $CMD2 $s
        fi
      fi
    fi
  done
  #
  # If enable mode, flush arrays
  if [ "$CMD" == "enable" ]; then
    if [ -z "$OPT" ]; then
      SCTL_USR_ENABLED=()
      SCTL_USR_RUNNING=()
    else
      SCTL_SYS_ENABLED=()
      SCTL_SYS_RUNNING=()
    fi
  fi
  #
  #echo "SCTL_SYS_ENABLED [${#SCTL_SYS_ENABLED[@]}]: ${SCTL_SYS_ENABLED[@]}"
  #echo "SCTL_SYS_RUNNING [${#SCTL_SYS_RUNNING[@]}]: ${SCTL_SYS_RUNNING[@]}"
  #echo "SCTL_USR_ENABLED [${#SCTL_USR_ENABLED[@]}]: ${SCTL_USR_ENABLED[@]}"
  #echo "SCTL_USR_RUNNING [${#SCTL_USR_RUNNING[@]}]: ${SCTL_USR_RUNNING[@]}"
  #
}

#
# Merge configs
mergeconf () {
  #
  # Return if no args
  if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    return
  fi

  #
  # Check type
  if [ "$1" == "sys" ]; then
    local OPT="sudo "
  elif [ "$1" == "user" ]; then
    :
  else
    echo "(mergeconf) Error with parameter 1: $1"
    return 1
  fi

  #
  # Source
  if [ -d "$2" ]; then
    local SFL=($(ls -d $2/*))
  elif [ -f "$2" ]; then
    local SFL=( $2 )
  fi

  if [ -n "$SFL" ]; then
    for f in "${SFL[@]}"; do
      #
      # Target
      if [ -f "$3/$(basename $f)" ]; then
        local TFL="$3/$(basename $f)"
      elif [ -f "$3" ]; then
        local TFL=$3
      fi

      if [ -n "$TFL" ]; then
        #
        # If file exist, merge it
        local CONF=$(awk -F= '!a[$1]++' $TFL $f)
        echo "$CONF" > $TFL
      else
        #
        # Otherwise just copy
        ${OPT}cp $f $3
      fi
    done
  fi
}
