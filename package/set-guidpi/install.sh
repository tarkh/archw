#!/bin/bash

if ! archw --gui preset $S_GUISCALE; then
  echo "GUI preset can't be applied: $S_GUISCALE"
fi
