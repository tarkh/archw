#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# CHROOT STAGE

#
# Check for internet
if ! connected; then
  ProgressBar remove
  clear
  echo "Connection to internet is needed for this installation!"
	echo "Please, manually set up connection and run installer again."
	echo "This is chroot stage process, you need to execute"
	echo "installer with flag ./install.sh --chroot"
	exit 1
fi

#
# Set vars
ProgressBar
V_AUR=$S_PKG/AUR
mkdir -p $V_AUR
chmod 777 $V_AUR

#
# Set region
ProgressBar
ln -sf /usr/share/zoneinfo/$S_REGION /etc/localtime

#
# Set clock
ProgressBar
hwclock --systohc

#
# Localization
ProgressBar
sed -i -E "s/[#]*($S_LOCALES)/\1/" /etc/locale.gen
locale-gen
echo "LANG=$(echo $S_LOCALES | cut -d ' ' -f1)" > /etc/locale.conf

#
# Keymap
ProgressBar
echo "KEYMAP=${S_KEYMAP}" > /etc/vconsole.conf

#
# Hostname
ProgressBar
echo $S_HOSTNAME > /etc/hostname

#
# Hosts
ProgressBar
bash -c "cat >> /etc/hosts" << EOL
127.0.0.1	localhost
::1		localhost
127.0.1.1	myhostname.localdomain	$S_HOSTNAME
EOL

#
# Enable system services
ProgressBar
if [ -n "$S_SYSTEMCTL_NETWORKMANAGER" ]; then
  systemctl enable NetworkManager
fi
if [ -n "$S_SYSTEMCTL_SSHD" ]; then
  systemctl enable sshd
fi
if [ -n "$S_SYSTEMCTL_BLUETOOTH" ]; then
  systemctl enable bluetooth.service
fi

#
# Set root password
#echo ""
#echo "#"
#echo "# Please, set root password"
#echo "#"
#passwd

#
# Create main user
ProgressBar
useradd --create-home $S_MAINUSER
echo ""
echo "#"
echo "# Please, set ${S_MAINUSER} password"
echo "#"

ProgressBar pause
passwd $S_MAINUSER
ProgressBar

usermod -a -G wheel $S_MAINUSER
usermod -a -G video $S_MAINUSER
sed -i -E "s/[#]*\s*(%wheel ALL=\(ALL\) NOPASSWD)/\1/"  /etc/sudoers

#
# Update system
#ProgressBar
#pacman --noconfirm -Syu

#
# Install yay
ProgressBar
cd $V_AUR
git clone https://aur.archlinux.org/yay.git
chmod -R 777 yay
cd yay
su $S_MAINUSER -c "makepkg -si --noconfirm"
cd $S_PKG

#
# Set grub
ProgressBar
install_grub packageInstall

#
# Enable hibernation
if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_HIBERNATION" ]; then
  #
  # Set kernel hook
  sed -i -E \
  "s:^\s*(HOOKS=\(.* filesystems )(.*):\1resume \2:" \
  /etc/mkinitcpio.conf
  #
  # Get swapfile UUID
  SWAPFILE_UUID=$(findmnt -no UUID -T /swapfile)
  SWAPFILE_UUID_PARAM="resume=UUID=${SWAPFILE_UUID}"
  SWAPFILE_OFFSET=$(filefrag -v /swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')
  SWAPFILE_OFFSET_PARAM="resume_offset=${SWAPFILE_OFFSET}"
  # patch grub config
  sed -i -E \
  "s:^(\s*GRUB_CMDLINE_LINUX_DEFAULT=\")(.*):\1${SWAPFILE_UUID_PARAM} ${SWAPFILE_OFFSET_PARAM} \2:" \
  /etc/default/grub
  # Apply
  install_grub
  #
  # Maj:min device number
  MAJMIN_DEV_NUM=$(lsblk | grep -w ${S_DISK}${S_DISK_SYSTEM} | awk '{print $2}')
  # Apply immediately
  echo $MAJMIN_DEV_NUM > /sys/power/resume
  echo $SWAPFILE_OFFSET > /sys/power/resume_offset
fi

#
# Set .bashrc
ProgressBar
touch "/home/${S_MAINUSER}/.bashrc"
if [ -z "$ARG_MANUAL" ]; then
	bash -c "cat >> /home/${S_MAINUSER}/.bashrc" << EOL
cd $S_PKG
./install.sh --admin
EOL
fi

#
# Enable admin autologin
ProgressBar
if [ -z "$ARG_MANUAL" ]; then
	mkdir -p /etc/systemd/system/getty@tty1.service.d
	bash -c "cat >> /etc/systemd/system/getty@tty1.service.d/autologin.conf" << EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $S_MAINUSER --noclear %I 38400 linux
EOL
fi

#
# Graphics
ProgressBar
. ./package/graphics/install.sh

#
# Ignore power button
if [ -n "$S_SYS_IGNORE_PWR" ]; then
  sed -i -E \
  "s:^[#\s]*(HandlePowerKey=).*:\1ignore:" \
  /etc/systemd/logind.conf
fi

#
# Run custom patch
ProgressBar
if [ -n "$S_PATCH" ]; then
	. ./patch/${S_PATCH}/install.sh
fi

#
# Exit section
if [ -n "$S_REBOOT_PROMPT" ]; then
  echo ""; read -p "ISO and CHROOT install stages has been completed! Reboot to continue installation ? (y/n) " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    clear
    exit 0
  fi
fi
ProgressBar remove
clear
umount -a
exit 0
