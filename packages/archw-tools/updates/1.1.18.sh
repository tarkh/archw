#
# Install dex
sudo pacman --noconfirm -S dex

#
# Set xdg
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

#
# NetworkManager fix
# Restart on resume
sudo chmod +x ./package/networkmanager/systemd/system-sleep/*
sudo \cp -r ./package/networkmanager/systemd/system-sleep/* /usr/lib/systemd/system-sleep/
