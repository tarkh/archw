#!/bin/bash

# yay
yay --noconfirm -Yc

# pacman
sudo pacman --noconfirm -Scc
sudo pacman --noconfirm -Rns $(pacman -Qtdq)

# system
rm -rf ~/.cache/*
sudo rm -rf $S_PKG
sudo journalctl --rotate
sudo journalctl --vacuum-time=1s
