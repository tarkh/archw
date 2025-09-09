#!/bin/bash

#
# Exit if script running not under sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 
fi

#
# Install target
W_DIR=/opt/w

#
# Switch to current working dir
W_SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
W_SCRIPT_DIR="$(dirname "$W_SCRIPT_PATH")"
W_MODULE_DIR=${W_SCRIPT_DIR}/apps/w
cd "${W_SCRIPT_DIR}"

#
# Untar w.tar.gz
tar -xzf w.tar.gz

# Create target dir
sudo mkdir -p $W_DIR

#
# Move w to /opt
sudo mv w/* ${W_DIR}

#
# Switch to dir
cd ${W_DIR}

#
# Install W
. ${W_MODULE_DIR}/install.sh

#
# Run W initial system setup
w setup-new-system default