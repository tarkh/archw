#!/bin/bash

#
# Install from AUR
yay --noconfirm -S xf86-input-mtrack

#
# PATCHED version
# Build and install from tarkh's GitHub
cd $V_AUR
curl -L ${V_TR}/xf86-input-mtrack/tarball/scrollCoastingEnhancement | tar -xz
cd tarkh-xf86-input-mtrack*
sudo pacman -S xorg-server-devel xorgproto pixman
autoreconf --install && ./configure --prefix=/usr && make && sudo make install
cd $V_HOME
