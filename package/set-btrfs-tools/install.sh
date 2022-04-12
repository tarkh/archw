#!/bin/bash

#
# Pathes
S_ARCHW_BIN=/usr/local/bin

#
# Btrfs map physical
sudo gcc -o $S_ARCHW_BIN/btrfs_map_physical ./package/set-btrfs-tools/btrfs_map_physical.c
sudo chmod +x $S_ARCHW_BIN/btrfs_map_physical
