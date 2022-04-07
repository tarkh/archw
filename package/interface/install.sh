#!/bin/bash

#
# Install packages
sudo pacman --noconfirm -S gucharmap ttf-roboto noto-fonts-emoji
yay --noconfirm -S nerd-fonts-roboto-mono

# Create root .config
sudo mkdir -p /root/.config/

#
# Set profile
ProgressBar
\cp -r ./package/interface/.profile $V_HOME/
# Copy profile to root
sudo cp $V_HOME/.profile /root/

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
#cd $V_AUR
#mkdir DraculaQT
#cd DraculaQT
#curl -L -O https://github.com/dracula/qt5/archive/master.tar.gz
#tar -xvf master.tar.gz
#QT_VER=(5 6)
#for qtv in "${QT_VER[@]}"; do
#  sudo pacman --noconfirm -S qt${qtv}-base qt${qtv}ct qt${qtv}-svg
#  mkdir -p $V_HOME/.config/qt${qtv}ct/colors/
#  cp ./qt5-master/Dracula.conf $V_HOME/.config/qt${qtv}ct/colors/
#done
#cd $S_PKG
#for qtv in "${QT_VER[@]}"; do
#  mkdir -p $V_HOME/.config/qt${qtv}ct/qss/
#  \cp -r ./package/interface/qt${qtv}ct.conf $V_HOME/.config/qt${qtv}ct/
#  \cp -a ./package/interface/qss${qtv}/. $V_HOME/.config/qt${qtv}ct/qss/
#  # Patch with user path
#  sudo sed -i -E \
#  "s:^\s*(color_scheme_path=)(.*):\1${V_HOME}/\2:; \
#  s:^\s*(stylesheets=)(.*):\1${V_HOME}/\2:" \
#  $V_HOME/.config/qt${qtv}ct/qt${qtv}ct.conf
#  # Copy to root
#  sudo cp -r $V_HOME/.config/qt${qtv}ct /root/.config/
#done

#
# LXQT + Kvantum
sudo pacman --noconfirm -S kvantum lxqt-qtplugin lxqt-config
\cp -r ./package/interface/Kvantum $V_HOME/.config/
\cp -r ./package/interface/lxqt $V_HOME/.config/
\cp -r ./package/interface/.Xdefaults $V_HOME/
\cp -r ./package/interface/.icons $V_HOME/

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

#
# Gtk 2
\cp -r ./package/interface/.gtkrc-2.0 $V_HOME/
# Copy profile to root
sudo cp $V_HOME/.gtkrc-2.0 /root/

#
# Gtk 3
mkdir -p $V_HOME/.config/gtk-3.0
\cp -r ./package/interface/settings.ini $V_HOME/.config/gtk-3.0
# Copy to root
sudo cp -r $V_HOME/.config/gtk-3.0 /root/.config/
#
mkdir -p $V_HOME/.themes/Dracula/gtk-3.0
\cp -r ./package/interface/gtk.css ./package/interface/gtk-dark.css $V_HOME/.themes/Dracula/gtk-3.0
# Copy to root
sudo cp -r $V_HOME/.themes /root/

#
# Set up gsettings
gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
gsettings set org.gnome.desktop.interface icon-theme "ePapirus-Dark"
