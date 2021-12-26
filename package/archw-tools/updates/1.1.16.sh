# Input module (not yet ready)

# Lightdm
# Reconfig on vt1
sudo sed -i -E \
"s:^\s*[#]*(minimum-vt=).*:\11:" \
/etc/lightdm/lightdm.conf
# Update scripts
sudo \cp -r ./package/lightdm/scripts/* /usr/share/lightdm/scripts
sudo chmod +x /usr/share/lightdm/scripts/*

#
# Grub reform
if pacman -Q --info grub-silent; then
  yay -noconfirm -R grub-silent
fi
#
#sudo sed -i -E \
#"s:\s*(S_ADD_GRUBCFG=).*:\1silent:; \
#s:\s*(S_ADD_GRUBSILENT=.*):#\1:" \
#$S_ARCHW_FOLDER/config/patch/config
#
#sudo pacman -S grub
#. ./package/grub/install.sh

#
# Set hibernation
if ! cat $S_ARCHW_FOLDER/config/config | grep "S_SWAP_FILE=" > /dev/null; then
  sudo sed -i -E \
  "s:(S_CREATE_SWAP=.*):\1\n# Swap file location\nS_SWAP_FILE=/swapfile:" \
  /usr/share/archw/config/config
fi
set_hibernation
touch ${S_ARCHW_FOLDER}/HIB
