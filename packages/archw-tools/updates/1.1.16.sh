#
# Picom tweak
# Disable because of i3/picom flicker
# after display sleep
sed -i -E \
"s:^\s*(unredir-if-possible\s+=):\1 false:g" \
$V_HOME/.config/picom/picom.conf

#
# Disable aw-screenoni3 i3 restarter
# because we don't need ti anymore
systemctl --user stop aw-screenoni3.service
systemctl --user disable aw-screenoni3.service

#
# Restart NM on resume
sudo chmod +x ./package/networkmanager/systemd/system-sleep/*
sudo \cp -r ./package/networkmanager/systemd/system-sleep/* /usr/lib/systemd/system-sleep/
