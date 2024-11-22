#!/bin/bash

cd $V_AUR
git clone https://github.com/Kir-Antipov/outline-cli
cd outline-cli
sudo ./install.sh -y
cd $S_PKG

#
# Add to hotkey
mkdir -p $V_HOME/.config/sxhkd/
bash -c "cat > $V_HOME/.config/sxhkd/outline.conf" << EOL
# Toggle vpn
control + shift + v
  pkexec /usr/local/bin/__vpn_manager toggle -n

# Connect to vpn server 1-9
alt + shift + v + 1
  pkexec /usr/local/bin/__vpn_manager connect 1 -n
alt + shift + v + 2
  pkexec /usr/local/bin/__vpn_manager connect 2 -n
alt + shift + v + 3
  pkexec /usr/local/bin/__vpn_manager connect 3 -n
alt + shift + v + 4
  pkexec /usr/local/bin/__vpn_manager connect 4 -n
alt + shift + v + 5
  pkexec /usr/local/bin/__vpn_manager connect 5 -n
alt + shift + v + 6
  pkexec /usr/local/bin/__vpn_manager connect 6 -n
alt + shift + v + 7
  pkexec /usr/local/bin/__vpn_manager connect 7 -n
alt + shift + v + 8
  pkexec /usr/local/bin/__vpn_manager connect 8 -n
alt + shift + v + 9
  pkexec /usr/local/bin/__vpn_manager connect 9 -n

EOL
