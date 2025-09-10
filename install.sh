#!/bin/bash

echo "Starting ArchW installation..."

# Install target
W_DIR=/opt/archw
W_PKG_URL=https://github.com/tarkh/archw/archive/refs/heads/main.zip

# Create a unique temporary directory
TEMP_DIR=$(mktemp -d -t w_install_XXXXXX)
if [ -z "$TEMP_DIR" ]; then
  echo "Failed to create temporary directory"
  exit 1
fi

# Function to clean up temporary files
cleanup() {
  echo "Cleaning up temporary files in $TEMP_DIR"
  rm -rf "$TEMP_DIR"
}

# Trap signals for cleanup (EXIT, INT, TERM)
trap cleanup EXIT INT TERM

# Download the package from GitHub to temp directory
curl -L -o "${TEMP_DIR}/archw.zip" $W_PKG_URL
if [ $? -ne 0 ]; then
  echo "Failed to download package"
  exit 1
fi

# Unzip package in temp directory
unzip -q "${TEMP_DIR}/archw.zip" -d "$TEMP_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to unzip package"
  exit 1
fi

# Create target directory
echo "############################################"
echo "# SUDO PASSWORD IS NEEDED TO INSTALL ARCHW #"
echo "############################################"

# Check if target dir exist, warn and delete it
if [ -d "$W_DIR" ]; then
  echo "Target directory already exists, cleaning up"
  sudo rm -rf "$W_DIR"
fi

# Create app dir
sudo mkdir -p "$W_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to create target directory $W_DIR"
  exit 1
fi

# Move contents to target directory
# Adjust path to match unzipped directory structure
sudo mv "${TEMP_DIR}/archw-main/"* "$W_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to move files to $W_DIR"
  exit 1
fi

# Chown root:root for new app
sudo chown root:root "$W_DIR"

# Switch to target directory
cd "$W_DIR" || { echo "Failed to change to $W_DIR"; exit 1; }
W_MODULE_DIR="${W_DIR}/apps/archw"

# Load lib
. ${W_MODULE_DIR}/lib/system.sh

# Install ArchW
if [ -f "${W_MODULE_DIR}/install.sh" ]; then
  . "${W_MODULE_DIR}/install.sh"
  install_archw
else
  echo "Install script not found at ${W_MODULE_DIR}/install.sh"
  exit 1
fi

# Run W initial system setup
archw initsetup
if [ $? -ne 0 ]; then
  echo "Failed to run ArchW setup"
  exit 1
fi

echo "Installation completed successfully"