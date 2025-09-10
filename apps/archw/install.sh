#
# ArchW package
#

# Install function
install_archw() {
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
  #echo "export PATH=\$PATH:${W_DIR_BIN}" | sudo tee /etc/profile.d/archw.sh > /dev/null
  sudo mkdir -p /etc/environment.d
  echo "PATH=$(echo $PATH):${W_DIR_BIN}" | sudo tee /etc/environment.d/archw.conf > /dev/null
  systemctl --user import-environment PATH

  # Load
  #. /etc/profile.d/archw.sh
  export PATH=${PATH}:${W_DIR_BIN}

  # Completed
  log "Installation completed: $W_MODULE_NAME"
}