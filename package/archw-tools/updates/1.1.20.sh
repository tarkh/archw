#
# Set dbus update env
echo "# DBUS-UPDATE-ENV" >> ~/.profile
echo "dbus-update-activation-environment --systemd --all" >> ~/.profile

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
sudo \cp -r ./package/nemo/smb.conf /etc/samba/
sudo systemctl enable smb.service
sudo systemctl enable nmb.service
# Nemo share
#sudo pacman --noconfirm -S nemo-share
# Tmp nemo-share flag fix
CWDIR=$(pwd)
cd ./package/nemo/nemo-share/
makepkg -si --noconfirm
cd $CWDIR
