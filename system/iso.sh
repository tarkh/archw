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
	# Make proper file system
	if [ $S_BOOT == "bios" ]; then
		mkfs.ext4 -L "$S_BOOTLOADER_ID" -F /dev/"${S_DISK}${S_DISK_SYSTEM}"
	elif [ $S_BOOT == "uefi" ]; then
		mkfs.fat -F32 /dev/"${S_DISK}${S_DISK_EFI}"
		mkfs.ext4 -L "$S_BOOTLOADER_ID" -F /dev/"${S_DISK}${S_DISK_SYSTEM}"
	elif [ $S_BOOT == "hfs" ]; then
		# FS for S_DISK_EFI will be made later in
		# chroot env with hfsplus tools installed
		mkfs.ext4 -L "$S_BOOTLOADER_ID" -F /dev/"${S_DISK}${S_DISK_SYSTEM}"
	fi
fi

#
# Mount system partition
ProgressBar
mount /dev/"${S_DISK}${S_DISK_SYSTEM}" /mnt

#
# Remove old pacman sync if exist
rm -R /mnt/var/lib/pacman/sync/ > /dev/null 2>&1

#
# Create swap file
ProgressBar
if [ -n "$S_CREATE_SWAP" ]; then
	dd if=/dev/zero of=/mnt/swapfile bs=$S_SWAP_BS count=$S_SWAP_COUNT status=progress
	chmod 600 /mnt/swapfile
	mkswap /mnt/swapfile
	swapon /mnt/swapfile
fi

#
# Install linux
ProgressBar
pacman --noconfirm -Syy
echo "Waiting for devices before system install..."
sleep 1
if ! pacstrap /mnt base $S_LINUX linux-firmware \
base-devel parted grub openssh curl wget ntp unzip nano vim git \
cpupower lm_sensors \
feh imagemagick scrot libicns \
xorg-server xorg-apps xorg-xinit xclip qt5-base qt5ct qt5-svg arandr \
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
