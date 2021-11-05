#!/bin/bash

yay --noconfirm -S openrgb-git

#
# Default ArchW conf
mkdir -p $V_HOME/.config/OpenRGB/
\cp ./package/openrgb/ArchW.orp $V_HOME/.config/OpenRGB/
