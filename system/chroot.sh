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

usermod -a -G wheel,video,storage,power $S_MAINUSER
#sed -i -E "s/[#]*\s*(%wheel ALL=\(ALL\) NOPASSWD)/\1/"  /etc/sudoers
sed -i -E "s/[#]*\s*(%wheel ALL=\(ALL\:ALL\) NOPASSWD\: ALL)/\1/"  /etc/sudoers
# Add no pass mode for wheel
#bash -c "cat >> /etc/sudoers.d/wheelnopwd" << EOL
#%wheel ALL=(ALL:ALL) NOPASSWD: ALL
#EOL

#
# System tweaks
install_system_tweaks

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
# Add btrfs module
if [ "$S_MAKEFS_SYS_FS" == "btrfs" ]; then
  add_system_module "btrfs"
fi

#
# Set grub
ProgressBar
install_grub packageInstall

#
# Enable hibernation
ProgressBar
if [ -n "$S_CREATE_SWAP" ] && [ -n "$S_HIBERNATION" ]; then
  set_hibernation
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
  echo ""; read -p "CHROOT install stage has been completed! Exit to ISO? (y/n) " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    clear
    exit 0
  fi
fi
ProgressBar remove
clear
umount -a
exit 0
