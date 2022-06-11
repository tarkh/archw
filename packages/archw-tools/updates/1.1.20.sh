#
# Set dbus update env
if ! grep "dbus-update-activation-environment" ~/.profile; then
  echo "# DBUS-UPDATE-ENV" >> ~/.profile
  echo "dbus-update-activation-environment --systemd --all" >> ~/.profile
fi

#
# Gedit fix
sudo pacman --noconfirm -S aspell hspell nuspell libvoikko

#
# Network share
sudo pacman --noconfirm -S avahi nss-mdns samba
#
sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service
#
sudo mkdir /var/lib/samba/usershares
sudo groupadd -r sambashare
sudo chown root:sambashare /var/lib/samba/usershares
sudo chmod 1770 /var/lib/samba/usershares
sudo usermod -a -G sambashare $USER
sudo \cp -r ./package/nemo/smb/smb.conf /etc/samba/
sudo systemctl enable smb.service
sudo systemctl enable nmb.service
# Nemo share
#sudo pacman --noconfirm -S nemo-share
# Tmp nemo-share flag fix
sudo pacman --noconfirm -R nemo-share
CWDIR=$(pwd)
cd ./package/nemo/nemo-share/
makepkg -si --noconfirm
cd $CWDIR

#
# Fix xdg
sudo pacman --noconfirm -R xdg-user-dirs
sudo rm /etc/xdg/user-dirs.default
sudo rm /etc/xdg/user-dirs.defaults
sudo pacman --noconfirm -S xdg-user-dirs
sudo sed -i -E \
"s:^(TEMPLATES):#\1:g" \
/etc/xdg/user-dirs.defaults
if ! cat /etc/xdg/user-dirs.defaults | grep '^DEV='; then
  sudo bash -c "cat >> /etc/xdg/user-dirs.defaults" << EOL
# Custom directories
DEV=Dev
EOL
fi
