#!/bin/bash

#
# Off if exist
service_ctl user off telegram-desktop-autostart.service

#
# Install package
sudo pacman --noconfirm -S telegram-desktop

#
# Autorun with i3
service_ctl user install-on ./package/telegram-desktop/systemd/telegram-desktop-autostart.service

#
# Add ArchW appearance
mkdir -p $V_HOME/.local/share
rm -rf $V_HOME/.local/share/TelegramDesktop/*  > /dev/null 2>&1
\cp -r ./package/telegram-desktop/TelegramDesktop $V_HOME/.local/share

#
# Xdg mime
xdg-mime default telegramdesktop.desktop application/x-xdg-protocol-tg
xdg-mime default telegramdesktop.desktop x-scheme-handler/tg

#
# On
service_ctl user on telegram-desktop-autostart.service
