#
# Set hibernation
echo "Enabling system hibernation..."
set_hibernation

if [ -n "$S_ARCHW_FOLDER" ] && [ -d "$S_ARCHW_FOLDER" ]; then
  sudo touch ${S_ARCHW_FOLDER}/HIB
fi
