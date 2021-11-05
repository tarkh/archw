#!/bin/bash

yay --noconfirm -S polybar
mkdir -p $V_HOME/.config/polybar
cp .package/polybar/config/* $V_HOME/.config/polybar

#
# Add to i3 (Under dev...)
