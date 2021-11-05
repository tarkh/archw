#!/bin/bash

sudo pacman --noconfirm -S mc

#
# Copy skin
sudo \cp ./package/mc/archw-256.ini /usr/share/mc/skins

#
# Copy local conf
mkdir -p $V_HOME/.config/mc/mcedit
\cp -r ./package/mc/config/* $V_HOME/.config/mc/

#
# Make MC as an app
sudo bash -c "cat > /usr/share/applications/mc.desktop" << EOL
[Desktop Entry]
Type=Application
Name=Midnight Commander
Comment=Visual file manager
Exec=$S_SYSTEM_TERMINAL -e mc %U
Icon=folder
MimeType=inode/directory
Categories=FileManager;
EOL

#
# Set default system file manager
if [ "$S_SYSTEM_FM" == "mc" ]; then
  xdg-mime default mc.desktop inode/directory
fi
