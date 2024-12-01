#!/bin/bash

sudo pacman --noconfirm -S nemo nemo-fileroller gvfs

if [ "$S_SYSTEM_FM" == "nemo" ]; then
  xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
fi

#
# Do not display hidden files by default
gsettings set org.nemo.preferences show-hidden-files false

#
# Set as default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec i3-sensible-terminal
gsettings set org.cinnamon.desktop.default-applications.terminal exec i3-sensible-terminal
gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg -e

#
# Network share
sudo pacnam --noconfirm -S gvfs-smb gvfs-dnssd avahi nss-mdns samba
sudo systemctl enable avahi-daemon.service
# SMB
sudo mkdir /var/lib/samba/usershares
sudo groupadd -r sambashare
sudo chown root:sambashare /var/lib/samba/usershares
sudo chmod 1770 /var/lib/samba/usershares
sudo usermod -a -G sambashare $S_MAINUSER
sudo \cp -r ./package/nemo/smb/smb.conf /etc/samba/
sudo systemctl enable smb.service
sudo systemctl enable nmb.service
# Nemo share
sudo pacman --noconfirm -S nemo-share
# Tmp nemo-share flag fix
#cd $V_AUR
#mkdir nemo-share && cd nemo-share
#cp $S_PKG/package/nemo/nemo-share/PKGBUILD ./
#makepkg -si --noconfirm
#cd $S_PKG
