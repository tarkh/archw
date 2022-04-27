#!/bin/bash
#
# ArchW build script
# by tarkh (c) 2021
#
# ADMIN STAGE

#
# Check for internet
if ! connected; then
  ProgressBar remove
  clear
  echo "Connection to internet is needed for this installation!"
	echo "Please, manually set up connection and run installer again."
	echo "This is user stage process, you need to cd ${S_PKG}"
	echo "and execute installer with flag ./install.sh --admin"
	exit 1
fi

#
# Set shortcuts
ProgressBar
V_HOME="/home/${S_MAINUSER}"

#
# Create dirs
mkdir -p $V_AUR
mkdir -p $V_PB

#
# Remove autoinstaller from .bashrc
ProgressBar
sed -i "\:^\s*cd\s*$S_PKG\s*:d" "${V_HOME}/.bashrc"
sed -i "\:^\s*./install.sh\s*--admin:d" "${V_HOME}/.bashrc"

#
# Update pacman keys
sudo pacman -Sy archlinux-keyring

#
# Install archw tools
ProgressBar
. ./package/archw-tools/install.sh

#
# Copy install configs to ArchW share
mkdir -p $S_ARCHW_FOLDER/config/patch
\cp -r ./config $S_ARCHW_FOLDER/config
\cp -r ./patch/config $S_ARCHW_FOLDER/config/patch
mkdir -p $S_ARCHW_FOLDER/config/patch/$S_PATCH
\cp -r ./patch/$S_PATCH/config $S_ARCHW_FOLDER/config/patch/$S_PATCH
\cp -r ./software $S_ARCHW_FOLDER/config

#
# Save disk/fs info
ProgressBar
save_devices_config

#
# If hibernate supported
if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_HIBERNATION" ]; then
  touch ${S_ARCHW_FOLDER}/HIB
fi

#
# Autodetect sensors
sudo sensors-detect --auto

#
# Nano highlight
ProgressBar
curl https://raw.githubusercontent.com/scopatz/nanorc/master/install.sh | sh

#
# Language info tool
ProgressBar
yay --noconfirm -S xkblayout-state-git

#
# Add wallpapers
ProgressBar
. ./package/set-common-scripts/wallpapers.sh

#
# Install interface and theme
ProgressBar
. ./package/set-interface/install.sh

#
# If Xorg
ProgressBar
if [ "$S_GS" == "xorg" ]; then
	# Install Picom
	. ./package/picom/install.sh
fi
#
ProgressBar
if [ "$S_GS" == "xorg" ]; then
  # Set Xprof wrapper path
  V_XPROF=aw-xprof
	# Install i3
	. ./package/i3/install.sh
fi

#
# Set grub
ProgressBar
if [ -n "$S_ADD_GRUBSILENT" ]; then
  #
  # Grub silent
  . ./package/grub-silent/install.sh
elif [ -n "$S_ADD_GRUBCFG" ]; then
  #
  # Grub regular
  . ./package/grub/install.sh
fi

#
# Enable hibernation
ProgressBar
if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_HIBERNATION" ]; then
  set_hibernation
fi

#
# Libinput general config
if [ -n "$S_ADD_LIBINPUT" ]; then
  sudo cp ./package/set-common-scripts/40-aw-libinput.conf /etc/X11/xorg.conf.d/
fi

#
# If bluetooth autorun is enabled
ProgressBar
. ./package/blueman/install.sh

#
# Install lightdm
ProgressBar
. ./package/lightdm/install.sh

#
# Plymouth
ProgressBar
if [ -n "$S_ADD_PLYMOUTH" ]; then
. ./package/plymouth/install.sh
fi

#
# Install lightdm-mini-greeter
ProgressBar
. ./package/lightdm-mini-greeter/install.sh

#
# Enable autologin
ProgressBar
if [ -n "$S_AUTOLOGIN" ]; then
. ./package/set-common-scripts/autologin.sh
fi

#
# Install terminator
ProgressBar
if [ -n "$S_ADD_TERMINATOR" ]; then
. ./package/terminator/install.sh
fi

#
# Install additional software
ProgressBar
. ./library/software.sh
# Custom official packages
ProgressBar
if [ -n "$S_CUSTOMSOFT" ]; then
  sudo pacman --noconfirm -S $S_CUSTOMSOFT
fi
# Custom aur packages
ProgressBar
if [ -n "$S_CUSTOMSOFT_AUR" ]; then
  yay --noconfirm -S $S_CUSTOMSOFT_AUR
fi

#
# Install parallel tools
ProgressBar
if [[ "$S_VM_TOOLS" =~ "parallels-"* ]]; then
. ./package/parallels-tools/install.sh
fi

#
# Install vmware tools
ProgressBar
if [ "$S_VM_TOOLS" == "vmware" ]; then
. ./package/vmware/install.sh
fi

#
# Lang sw init
archw --lang cycle-set $S_KEYMAP_SW

#
# If hibernate supported
# Activate autohibernate
if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_HIBERNATION" ]; then
  # After 12 hr of sleep on AC
  archw --pm hib 43200
  # After 2 hr of sleep ob Battery
  archw --pm hibbat 7200
fi

#
# Run custom patch
ProgressBar
if [ -n "$S_PATCH" ]; then
	. ./patch/${S_PATCH}/install.sh
fi

#
# Enable NetworkManager
ProgressBar
if [ -n "$S_ADD_NETWORKMANAGER" ]; then
  . ./package/networkmanager/install.sh
fi

#
# Copy install log to home dir
ProgressBar
cp ./ARCHW_INSTALL.log ~/

#
# Create skel template from home directory
ProgressBar
mkdir $S_ARCHW_FOLDER/homeskel
cp -a $V_HOME/. $S_ARCHW_FOLDER/homeskel/

#
# Regenerate GRUB bootloader
GRUB_CONTENT_REBUILD=1
install_grub
unset $GRUB_CONTENT_REBUILD

#
# Cleanup system
ProgressBar
. ./package/set-common-scripts/cleanup.sh

#
# Disable admin autologin
ProgressBar
sudo rm -rf "/etc/systemd/system/getty@tty1.service/autologin.conf"

#
# Run reboot with timeout
# Set sudo mode to normal with password
turn_off_no_passwd () {
  sudo sed -i -E "s/[#]*\s*(%wheel ALL=\(ALL\:ALL\) ALL)/\1/"  /etc/sudoers
  sudo sed -i -E "s/[#]*\s*(%wheel ALL=\(ALL\:ALL\) NOPASSWD\: ALL)/#\s\1/"  /etc/sudoers
  # Add sudo mode for whwwl
#  sudo bash -c "cat >> /etc/sudoers.d/wheelsudo" << EOL
#%wheel ALL=(ALL:ALL) ALL
#EOL
  # Remove no pass mode from wheel
  #sudo rm -rf /etc/sudoers.d/wheelnopwd
}

ProgressBar remove
if [ -n "$S_REBOOT_PROMPT" ]; then
  echo ""; read -p "Installation of WrchW has been completed! Reboot to new system ? (y/n) " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    turn_off_no_passwd
    clear
    exit 0
  fi
fi
sudo bash -c "sleep 5 && shutdown -r now" &
turn_off_no_passwd
echo ""
echo "All done! Preparing for final reboot..."
sleep 6
exit 0
