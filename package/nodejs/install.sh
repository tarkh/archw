#!/bin/bash

yay --noconfirm -S nvm
#cd $V_AUR
#git clone https://aur.archlinux.org/nvm.git
#cd nvm
#makepkg -sri --noconfirm
#cd $S_PKG

echo 'source /usr/share/nvm/init-nvm.sh' >> ~/.bashrc
source /usr/share/nvm/init-nvm.sh

nvm --version

#
# Install node
nvm install --lts
node --version

#
# Install pm2
npm install pm2@latest -g
pm2 --version
pm2 startup | grep sudo | sh
