#!/bin/bash

sudo pacman --noconfirm -S rustup gcc sccache
rustup default stable
rustup component add rls rust-analysis rust-src clippy rustfmt
