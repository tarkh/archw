#!/bin/bash

#
# Install packages
sudo pacman --noconfirm -S gucharmap ttf-roboto noto-fonts-emoji
yay --noconfirm -S nerd-fonts-roboto-mono

#
# GTK
cd $V_AUR
mkdir DraculaGTK
cd DraculaGTK
curl -L -O https://github.com/dracula/gtk/archive/master.tar.gz
tar -xvf master.tar.gz
mv gtk-master Dracula
sudo mv Dracula /usr/share/themes/
cd $S_PKG

#
# QT
cd $V_AUR
mkdir DraculaQT
cd DraculaQT
curl -L -O https://github.com/dracula/qt5/archive/master.tar.gz
tar -xvf master.tar.gz
QT_VER=(5 6)
for qtv in "${QT_VER[@]}"; do
  sudo pacman --noconfirm -S qt${qtv}-base qt${qtv}ct qt${qtv}-svg
  mkdir -p $V_HOME/.config/qt${qtv}ct/colors/
  cp ./qt5-master/Dracula.conf $V_HOME/.config/qt${qtv}ct/colors/
done
cd $S_PKG
for qtv in "${QT_VER[@]}"; do
  \cp -r ./package/interface/qt${qtv}ct.conf $V_HOME/.config/qt${qtv}ct/
  \cp -r ./package/interface/qss $V_HOME/.config/qt${qtv}ct/
  # Patch with user path
  sudo sed -i -E \
  "s:^\s*(color_scheme_path=)(.*):\1${V_HOME}/\2:; \
  s:^\s*(stylesheets=)(.*):\1${V_HOME}/\2:" \
  $V_HOME/.config/qt${qtv}ct/qt${qtv}ct.conf
done

# PAPIRUS
# icons
sudo pacman --noconfirm -S papirus-icon-theme
yay --noconfirm -S papirus-folders-git
papirus-folders -C violet

# DRACULA
# icons
#cd $V_AUR
#git clone https://github.com/matheuuus/dracula-icons.git
#sudo \cp -r ./dracula-icons /usr/share/icons/Dracula
#cd $S_PKG

#
# Custom icons font
sudo cp ./package/interface/fonts/archw-selected-icons.ttf /usr/share/fonts/TTF/
sudo fc-cache

mkdir -p $V_HOME/.config/gtk-3.0
\cp -r ./package/interface/settings.ini $V_HOME/.config/gtk-3.0

mkdir -p $V_HOME/.themes/Dracula/gtk-3.0
bash -c "cat >> $V_HOME/.themes/Dracula/gtk-3.0/gtk-dark.css" << EOL
/* Load the original theme */
@import url("/usr/share/themes/Dracula/gtk-3.20/gtk-dark.css");

/* Override */
scrollbar slider {
        background-color: #615B63;
}
scrollbar slider:hover {
        background-color: #7F7F7F;
}
EOL

bash -c "cat >> $V_HOME/.themes/Dracula/gtk-3.0/gtk.css" << EOL
/* Load the original theme */
@import url("/usr/share/themes/Dracula/gtk-3.20/gtk.css");

/* Override */

EOL

#
# Set up gsettings
gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
gsettings set org.gnome.desktop.interface icon-theme "ePapirus-Dark"
