#!/bin/bash

#
# Install
yay --noconfirm -S vscodium-bin

# Theme
mkdir -p $V_HOME/.vscode-oss/extensions
git clone https://github.com/dracula/visual-studio-code.git $V_HOME/.vscode-oss/extensions/theme-dracula
$V_HOME/.vscode-oss/extensions/theme-dracula
# Check for npm
if ! npm -v > /dev/null 2>&1; then
  # Install NodeJS and NPM
  . $S_PKG/nodejs/install.sh
fi
# Duild theme
npm install
npm run build
# Create user settings
mkdir -p $V_HOME/.config/VSCodium/User
bash -c "cat > $V_HOME/.config/VSCodium/User/settings.json" << EOL
{
    "workbench.colorTheme": "Dracula Soft"
}
EOL

# Gui askpass
sudo pacman -S lxqt-openssh-askpass
sudo ln -s /usr/bin/lxqt-openssh-askpass /usr/lib/ssh/ssh-askpass
