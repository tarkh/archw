#!/bin/bash

sudo mkdir -p /usr/share/wallpapers
sudo \cp -r ./package/set-wallpapers/* /usr/share/wallpapers
sudo chmod -R 0777 /usr/share/wallpapers
