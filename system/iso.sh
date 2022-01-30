#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# ISO STAGE

#
# Check for internet
if ! connected; then
  ProgressBar remove
  clear
  echo "Connection to internet is needed for this installation!"
	echo "Please, manually set up connection and run installer again."
	exit 1
fi

#
# Create sda1 partition on whole space
# and format fo ext4 file system
echo ""
echo "######################################################"
printf " ArchW autoinstaller script is going to install\n Arch Linux, additional software and custom settings\n"
if [ -n "$ARG_MANUAL" ]; then
  echo " (MANUAL MODE)"
fi
echo "######################################################"

sleep 3

#
# Update date and time
timedatectl set-ntp true
sleep 1
timedatectl status

#
# Update Arch mirror list
if ! reflector --country "$S_COUNTRY" -l 50 -p https --sort rate --save /etc/pacman.d/mirrorlist; then
  echo "Error occured while updating repository mirror list"
  exit 1
fi

#
# Format disk
ProgressBar
if [ -n "$S_FORMAT_DISK" ]; then
	if [ $S_BOOT == "bios" ]; then
    ProgressBar pause
		echo ""; read -p "WARNING! Installing in bios mode! Format ${S_DISK} disk? (y/n) " -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    ProgressBar resume
    sfdisk -f --delete /dev/$S_DISK
		echo 'type=83' | sfdisk /dev/$S_DISK
	elif [ $S_BOOT == "uefi" ]; then
    ProgressBar pause
		echo ""; read -p "WARNING! Installing in uefi mode! Format ${S_DISK} disk? (y/n) " -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    ProgressBar resume
    sfdisk -f --delete /dev/$S_DISK
		echo "label: gpt" | sfdisk /dev/$S_DISK
		sfdisk /dev/$S_DISK <<EOF
,256M,U
,,L
EOF
	elif [ $S_BOOT == "hfs" ]; then
    ProgressBar pause
		echo ""; read -p "WARNING! Installing in hfs mode! Format ${S_DISK} disk? (y/n) " -r
		if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    ProgressBar resume
    sfdisk -f --delete /dev/$S_DISK
		echo "label: gpt" | sfdisk /dev/$S_DISK
		sfdisk /dev/$S_DISK <<EOF
,256M,U
,,L
EOF
	fi
fi

#
# Make fs
ProgressBar
if [ -n "$S_MAKEFS_PARTITIONS" ]; then
  #
  # Warn if disk format was skipped
  if [ -z "$S_FORMAT_DISK" ]; then
    ProgressBar pause
    if [ $S_BOOT == "bios" ]; then
      echo ""; read -p "WARNING! Format partition /dev/${S_DISK}${S_DISK_SYSTEM} ? (y/n) " -r
    else
      echo ""; read -p "WARNING! Format partitions /dev/${S_DISK}${S_DISK_EFI} and /dev/${S_DISK}${S_DISK_SYSTEM} ? (y/n) " -r
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then exit 0; fi
    ProgressBar resume
  fi

	#
	# Set proper partition type
	if [ $S_BOOT == "bios" ]; then
    wipefs --all --force /dev/${S_DISK}${S_DISK_SYSTEM}
		sfdisk -f --part-type /dev/$S_DISK $S_DISK_SYSTEM $(partition_guid linux)
  else
    wipefs --all --force /dev/${S_DISK}${S_DISK_EFI}
    wipefs --all --force /dev/${S_DISK}${S_DISK_SYSTEM}
    sfdisk -f --part-type /dev/$S_DISK $S_DISK_SYSTEM $(partition_guid linux)
    if [ $S_BOOT == "uefi" ]; then
		  sfdisk -f --part-type /dev/$S_DISK $S_DISK_EFI $(partition_guid efi)
    elif [ $S_BOOT == "hfs" ]; then
		  sfdisk -f --part-type /dev/$S_DISK $S_DISK_EFI $(partition_guid hfsplus)
    else
      echo "Error! Unknown system boot type provided: $S_BOOT"
      exit 1
    fi
	fi
	sleep 1
	partprobe /dev/${S_DISK}
	sleep 1

  #
  # Make swap
  makesysswap () {
    if [ -n "$S_CREATE_SWAP" ]; then
      local MNT=/dev/"${S_DISK}${S_DISK_SYSTEM}"
      if [ "$S_MAKEFS_SYS_FS" == "ext4" ]; then
        dd if=/dev/zero of=/mnt${S_SWAP_FILE} bs=$S_SWAP_BS count=$S_SWAP_COUNT status=progress
      	chmod 600 /mnt${S_SWAP_FILE}
      	mkswap /mnt${S_SWAP_FILE}
      	swapon /mnt${S_SWAP_FILE}
      elif [ "$S_MAKEFS_SYS_FS" == "btrfs" ]; then
        S_SWAP_FILE="/.swap/${S_SWAP_FILE}"
        truncate -s 0 /mnt${S_SWAP_FILE}
        chattr +C /mnt${S_SWAP_FILE}
        btrfs property set /mnt${S_SWAP_FILE} compression none
        # Convert swap size
        local SWAPSIZE="$(( $(sed -E "s:[a-z]+::ig" <<< "$S_SWAP_BS") * $S_SWAP_COUNT ))$(sed -E "s:[0-9]+::g" <<< "$S_SWAP_BS")"
        fallocate -l $SWAPSIZE /mnt${S_SWAP_FILE}
        chmod 600 /mnt${S_SWAP_FILE}
        mkswap /mnt${S_SWAP_FILE}
        swapon /mnt${S_SWAP_FILE}
      fi
    fi
  }

	#
	# Make proper file system
  makesysfs () {
    local MNT=/dev/"${S_DISK}${S_DISK_SYSTEM}"
    if [ "$S_MAKEFS_SYS_FS" == "ext4" ]; then
      #
      # FS ext4
      mkfs.ext4 -L "$S_BOOTLOADER_ID" -F /dev/"${S_DISK}${S_DISK_SYSTEM}"
      # Mount system partition
      mount $MNT /mnt
    elif [ "$S_MAKEFS_SYS_FS" == "btrfs" ]; then
      #
      # FS btrfs
      mkfs.btrfs -L "$S_BOOTLOADER_ID" -n $S_BTRFS_BS /dev/"${S_DISK}${S_DISK_SYSTEM}"
      # Mount system partition
      mount $MNT /mnt
      # Create btrfs subvolumes
      btrfs su cr /mnt/@
      #btrfs su cr /mnt/@btrfs
      btrfs su cr /mnt/@home
      btrfs su cr /mnt/@opt
      btrfs su cr /mnt/@srv
      btrfs su cr /mnt/@abs
      btrfs su cr /mnt/@pkg
      btrfs su cr /mnt/@tmp
      btrfs su cr /mnt/@snapshots
      btrfs su cr /mnt/@swap
      umount /mnt
      sleep 1
      # Mount partitions
      mount -o ${S_BTRFS_OPTS},subvol=@ $MNT /mnt
      # Create dirs
      mkdir -p /mnt/{boot,home,opt,srv,var,.snapshots,.swap}
      mkdir -p /mnt/var/{abs,cache/pacman/pkg,tmp}
      # Mount subvolumes
      mount -o ${S_BTRFS_OPTS},subvol=@home $MNT /mnt/home
      mount -o ${S_BTRFS_OPTS},subvol=@opt $MNT /mnt/opt
      mount -o ${S_BTRFS_OPTS},subvol=@srv $MNT /mnt/srv
      mount -o ${S_BTRFS_OPTS},subvol=@abs $MNT /mnt/var/abs
      mount -o ${S_BTRFS_OPTS},subvol=@pkg $MNT /mnt/var/cache/pacman/pkg
      mount -o ${S_BTRFS_OPTS},subvol=@tmp $MNT /mnt/var/tmp
      mount -o ${S_BTRFS_OPTS},subvol=@snapshots $MNT /mnt/.snapshots
      mount -o ${S_BTRFS_OPTS_SWAP},subvol=@swap $MNT /mnt/.swap
      #mount -o ${S_BTRFS_OPTS},subvol=5 $MNT /mnt/btrfs
    else
      echo "Option S_MAKEFS_SYS_FS is empty! Please, correct your config"
      exit 1
    fi
    #
    # Make swap
    makesysswap
  }

	if [ $S_BOOT == "bios" ]; then
		makesysfs
	elif [ $S_BOOT == "uefi" ]; then
		mkfs.fat -F32 /dev/"${S_DISK}${S_DISK_EFI}"
		makesysfs
	elif [ $S_BOOT == "hfs" ]; then
		# FS for S_DISK_EFI will be made later in
		# chroot env with hfsplus tools installed
		makesysfs
	fi
fi

#
# Remove old pacman sync if exist
rm -R /mnt/var/lib/pacman/sync/ > /dev/null 2>&1

#
# Install linux
ProgressBar
pacman --noconfirm -Syy
echo "Waiting for devices before system install..."
sleep 1
# Set CPU related packages
if [ "$CPUM" == "intel" ]; then
  CPURELP="intel-ucode"
elif [ "" == "" ]; then
  CPURELP="amd-ucode"
fi
# Set btrfs related packages
if [ "$S_MAKEFS_SYS_FS" == "btrfs" ]; then
  $BTRFSRELP="btrfs-progs"
fi
# Pacstrap init
if ! pacstrap /mnt base $S_LINUX linux-firmware $CPURELP \
base-devel parted grub openssh curl wget ntp zip unzip nano vim git $BTRFSRELP \
acpi cpupower lm_sensors \
feh imagemagick scrot libicns \
xorg-server xorg-apps xorg-xinit xclip arandr \
gnome-keyring libsecret seahorse \
networkmanager nm-connection-editor network-manager-applet \
bluez bluez-utils blueman \
alsa-utils pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol \
playerctl; then
  echo ""
  echo "Error happened while installing new system!"
  echo "Please, check the errors and try to resolve them manually."
  exit 1
fi

#
# Run custom patch
ProgressBar
if [ -n "$S_PATCH" ]; then
	. ./patch/${S_PATCH}/install.sh
fi

#
# Generate fstab
ProgressBar
genfstab -U /mnt >> /mnt/etc/fstab

#
# Copy ArchW maker to new system
ProgressBar
mkdir -p "/mnt${S_PKG}"
cp -R ./* "/mnt${S_PKG}"
chmod -R 777 "/mnt${S_PKG}"

ProgressBar remove
clear
${S_SWAP_FILE}
#
# Chroot to new system
arch-chroot /mnt sh -c "cd ${S_PKG};./install.sh --chroot${ARG_MANUAL}"

#
# Reboot
echo "ArchW installer: stage 1 completed!"
if [ -z "$ARG_MANUAL" ]; then
	umount -a
	shutdown -r now
else
	echo "Auto-reboot disabled due to manual mode."
fi
