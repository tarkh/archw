#!/bin/bash

#
# Run wp setup, but don't wait for it
bash -c "archw --disp dset; sleep 1; archw --wp" &
