#!/bin/bash

#
# Run display setup
. $HOME/.profile
archw --disp dset
bash -c "sleep 1; archw --wp" &
