#!/bin/bash

if [ -n "$S_GRAPHICS" ]; then
  if [ "$S_GRAPHICS" == "intel" ]; then
    #
    # Intel
    . ./package/set-graphics/intel.sh
    #
  elif [ "$S_GRAPHICS" == "amd" ]; then
    #
    # AMD
    . ./package/set-graphics/amd.sh
    #
  elif [ "$S_GRAPHICS" == "nvidia" ]; then
    #
    # Nvidia
    . ./package/set-graphics/nvidia.sh
    #
  fi
fi
