#!/bin/bash

sudo pacman --noconfirm -S ${S_LINUX}-headers
yay --noconfirm -S openrazer-meta polychromatic
sudo gpasswd -a $S_MAINUSER plugdev
