#!/bin/bash

#
# Off if exist
service_ctl user off redshift-autostart.service

#
# Install package
sudo pacman --noconfirm -S geoclue redshift

bash -c "cat > $V_HOME/.config/redshift.conf" << EOL
; Global settings for redshift
[redshift]
; Set the day and night screen temperatures
temp-day=6500
temp-night=4500

; Enable/Disable a smooth transition between day and night
; 0 will cause a direct change from day to night screen temperature.
; 1 will gradually increase or decrease the screen temperature.
transition=1

; Set the screen brightness. Default is 1.0.
brightness=1.0
; It is also possible to use different settings for day and night
; since version 1.8.
brightness-day=1.0
brightness-night=0.75
; Set the screen gamma (for all colors, or each color channel
; individually)
;gamma=0.8
;gamma=0.8:0.7:0.8
; This can also be set individually for day and night since
; version 1.10.
;gamma-day=0.8:0.7:0.8
;gamma-night=0.6

; Set the location-provider: 'geoclue', 'geoclue2', 'manual'
; type 'redshift -l list' to see possible values.
; The location provider settings are in a different section.
location-provider=geoclue2

; Set the adjustment-method: 'randr', 'vidmode'
; type 'redshift -m list' to see all possible values.
; 'randr' is the preferred method, 'vidmode' is an older API.
; but works in some cases when 'randr' does not.
; The adjustment method settings are in a different section.
adjustment-method=randr

; Configuration of the location-provider:
; type 'redshift -l PROVIDER:help' to see the settings.
; ex: 'redshift -l manual:help'
; Keep in mind that longitudes west of Greenwich (e.g. the Americas)
; are negative numbers.
;[manual]
;lat=48.1
;lon=11.6

; Configuration of the adjustment-method
; type 'redshift -m METHOD:help' to see the settings.
; ex: 'redshift -m randr:help'
; In this example, randr is configured to adjust screen 1.
; Note that the numbering starts from 0, so this is actually the
; second screen. If this option is not specified, Redshift will try
; to adjust _all_ screens.
;[randr]
;screen=1
EOL

#
# Install redshift complex start script
sudo \cp -r ./package/redshift/bin/redshift-start /usr/local/bin/
sudo chmod +x /usr/local/bin/redshift-start

#
# Autorun with i3
service_ctl user install-on ./package/redshift/systemd/redshift-autostart.service

#
# Geoclue
sudo sed -i -E \
"s:^#(url\=.*mozilla.*\=).*:\1geoclue:g" \
/etc/geoclue/geoclue.conf

sudo sed -i -E \
'/\[redshift]$/,/^(\[|$)/d' \
/etc/geoclue/geoclue.conf

sudo bash -c "cat >> /etc/geoclue/geoclue.conf" << EOL

[redshift]
allowed=true
system=false
users=
EOL

#
# Add to hotkey
mkdir -p $V_HOME/.config/sxhkd/
bash -c "cat > $V_HOME/.config/sxhkd/redshift.conf" << EOL
# Toggle redshift
super + control + t
  pkill -USR1 redshift

EOL

#
# On
service_ctl user on redshift-autostart.service