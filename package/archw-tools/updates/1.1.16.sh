# Lightdm
# Reconfig on vt1
sudo sed -i -E \
"s:^\s*[#]*(minimum-vt=).*:\11:" \
/etc/lightdm/lightdm.conf
# Update scripts
sudo \cp -r ./package/lightdm/scripts/* /usr/share/lightdm/scripts
sudo chmod +x /usr/share/lightdm/scripts/*
