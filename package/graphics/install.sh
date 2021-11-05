#!/bin/bash

if [ -n "$S_GRAPHICS" ]; then
  if [ "$S_GRAPHICS" == "intel" ]; then
    #
    # Intel
    . ./package/graphics/intel.sh
    #
  elif [ "$S_GRAPHICS" == "amd" ]; then
    #
    # AMD
    . ./package/graphics/amd.sh
    #
  elif [ "$S_GRAPHICS" == "nvidia" ]; then
    #
    # Nvidia
    . ./package/graphics/nvidia.sh
    #
  fi
fi
