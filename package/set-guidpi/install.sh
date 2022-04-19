#!/bin/bash

if [ -n "$S_GUISCALE" ]; then
  if ! archw --gui preset $S_GUISCALE; then
    echo "GUI preset can't be applied: $S_GUISCALE"
  else
    archw --gui auto
  fi
else
  archw --gui auto
fi
