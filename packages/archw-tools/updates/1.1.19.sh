#
# Set as default terminal
gsettings set org.gnome.desktop.default-applications.terminal exec i3-sensible-terminal
gsettings set org.cinnamon.desktop.default-applications.terminal exec i3-sensible-terminal
gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg -e

#
# Nemo file-roller
sudo pacman --noconfirm -S nemo-fileroller

#
# Nemo network share
sudo pacman --noconfirm -S avahi nss-mdns nemo-share
sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service
