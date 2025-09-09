#
# W package
#

# Install function
install_w() {
  # Log
  log "Installation started: $W_MODULE_NAME"

  # Set dirs
  W_DIR_BIN="$W_DIR/bin"
  W_DIR_LIB="$W_DIR/lib"

  # Cleanup if needed
  if [ -d "$W_DIR_BIN" ]; then
    log "Cleaning up $W_DIR_BIN"
    sudo rm -rf "$W_DIR_BIN"
  fi
  if [ -d "$W_DIR_LIB" ]; then
    log "Cleaning up $W_DIR_LIB"
    sudo rm -rf "$W_DIR_LIB"
  fi

  # Copy bin and lib folders
  sudo cp -r ${W_MODULE_DIR}/bin ${W_DIR}
  sudo cp -r ${W_MODULE_DIR}/lib ${W_DIR}

  # Add new system wide env
  echo "export PATH=\$PATH:${W_DIR_BIN}" | sudo tee /etc/profile.d/w.sh > /dev/null
  sudo chmod +x /etc/profile.d/w.sh

  # Load
  . /etc/profile.d/w.sh

  # Completed
  log "Installing completed: $W_MODULE_NAME"
}