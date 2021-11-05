#!/bin/bash

sudo pacman --noconfirm -S rustup
rustup default stable
rustup component add rustfmt
rustup component add rls
