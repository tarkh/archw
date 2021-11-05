#!/bin/bash

sleep 1

for f in $HOME/.i3-autorun/*.sh; do
  echo "Running ${f}"
  bash "$f" &
done
