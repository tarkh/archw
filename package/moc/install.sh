#!/bin/bash

sudo pacman --noconfirm -S moc faad2 ffmpeg libmodplug libmpcdec speex taglib wavpack

mkdir -p $V_HOME/.moc
\cp -r ./package/moc/config $V_HOME/.moc
\cp -r ./package/moc/keymap $V_HOME/.moc
\cp -r ./package/moc/themes $V_HOME/.moc
