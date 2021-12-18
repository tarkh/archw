#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021

#
# If logfile
. ./library/log.sh

#
# Prepare arg list combinations
ARGS=()
for arg in "$@"; do
	pat="^-[a-zA-Z]{2,}"
	if [[ $arg =~ $pat ]]; then
		arg="${arg:1}"
		for (( i=0; i<${#arg}; i++ )); do
			ARGS+=("-${arg:$i:1}")
		done
	else
		ARGS+=("$arg")
	fi
done

#
# Read args
for arg in "${ARGS[@]}"; do
	case $arg in
		--chroot)
		ARG_CHROOT=1
		shift
		;;
    --admin)
		ARG_ADMIN=1
		shift
		;;
		--manual)
		ARG_MANUAL=" --manual"
		shift
		;;
		--archw-tools)
		ARG_ARCHW_UPDATE=true
		shift
		;;
		--noconfirm)
		ARG_NOCONFIRM=true
		shift
		;;
		-t)
		ARG_NOTXTGUI=true
		shift
		;;
		-h|--help)
		echo "Usage: `basename "$0"` [options]"
		echo "ArchW installer."
		echo "Consists of 3 stages:"
		echo "1. Create new system from boot ISO."
		echo "2. Run chroot tasks."
		echo "3. Reboot to new system and continue installation."
		echo " "
		echo "options:"
		echo "--chroot      [stage 2] run chroot tasks"
		echo "--admin       [stage 3] run admin tasks"
		echo "--manual      run installer without auto reboot and auto start of stage 3"
		echo "-t            do not use text GUI"
		echo "-h            program help"
		exit 0
		;;
	esac
done

#
# Load configs
. ./config
. ./patch/config
. ./software

#
# Load base functions
. ./library/functions.sh
. ./library/banner.sh
. ./library/progress_bar.sh

#
# Load selected path config
if [ -z "$ARG_ARCHW_UPDATE" ]; then
	if [ -f ./patch/${S_PATCH}/config ]; then
		. ./patch/${S_PATCH}/config
	else
		echo "Can't find patch config file: ./patch/${S_PATCH}/config"
		echo "Please, check global config"
		exit 1
	fi
fi

################################
# Set global shortcuts
V_AUR="$S_PKG/AUR"
V_TR="https://github.com/tarkh"
V_PB="$S_PKG/PREBUILT"
V_RPB="${V_TR}/archw/raw/assets/prebuilt"

################################
# ArchW tools update
if [ -n "$ARG_ARCHW_UPDATE" ]; then
	if [ -z "$ARG_NOCONFIRM" ]; then
		echo ""; read -p "Update ArchW tools? (y/n) " -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
	fi
  # Create dirs
  sudo mkdir -p $S_PKG
  sudo chmod 777 $S_PKG
  mkdir -p $V_AUR
  mkdir -p $V_PB
  # Set update runtime shortcuts
  V_SYS_PKG=$S_PKG
  S_PKG=$(pwd)
	S_MAINUSER=$(id -un)
	V_HOME="/home/${S_MAINUSER}"
  # Run ArchW-tools install/update
	. ./package/archw-tools/install.sh
  # Cleanup
  sudo rm -rf $V_SYS_PKG
	echo "ArchW tools installed/updated!"
	exit 0
fi

################################
# Enable banner
print_archw_banner
ProgressBar create

################################
# PRE ADMIN section
# Sleep for a while and wait
# for network interfaces
#
if [ -n "$ARG_ADMIN" ]; then
  echo "Waiting for interfaces..."
  sleep 10
fi

################################
# Run custom patch before archw
#
#
#
if [ -n "$S_PATCH" ]; then
	STAGE_BOOTSTRAP=true
	. ./patch/${S_PATCH}/install.sh
	unset STAGE_BOOTSTRAP
fi

################################
# CHROOT section
#
#
#
if [ -n "$ARG_CHROOT" ]; then
	print_archw_banner "chroot stage"
	ProgressBar create
	ProgressBar init "./system/*,./library/software.sh,./patch/${S_PATCH}/system/*" "./system/iso.sh,./patch/${S_PATCH}/system/iso.sh"
	. ./system/chroot.sh

################################
# ADMIN section
#
#
#
elif [ -n "$ARG_ADMIN" ]; then
	print_archw_banner "sudo stage"
	ProgressBar create
	ProgressBar init "./system/*,./library/software.sh,./patch/${S_PATCH}/system/*" "./system/iso.sh,./system/chroot.sh,./patch/${S_PATCH}/system/iso.sh,./patch/${S_PATCH}/system/chroot.sh"
	. ./system/admin.sh

################################
# MAIN sectionqt5ct
#
#
#
else
	print_archw_banner "preparing new system"
	ProgressBar create
	ProgressBar init "./system/*,./library/software.sh,./patch/${S_PATCH}/system/*"
	. ./system/iso.sh
fi
