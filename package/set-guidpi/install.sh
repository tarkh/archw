#!/bin/bash

if ! archw --gui preset $S_GUIDPI; then
  echo "GUI preset can't be applied: $S_GUIDPI"
fi
