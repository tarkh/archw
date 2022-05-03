#
# Fix gui i3
if ! grep "i3bar_command i3bar -t" ~/.config/i3/config; then
  sed -i -E "s:^([ ]+i3bar_command i3bar).*$:\1 -t:" ~/.config/i3/config
fi
if grep -E "^[ ]+background #140B19[ ]+$" ~/.config/i3/config; then
  sed -i -E "s:^([ ]+background #140B19)([ ]+)$:\100\2:" ~/.config/i3/config
fi
if grep -E "^[ ]+#position (top|bottom)[ ]+$" ~/.config/i3/config; then
  sed -i -E "s:^([ ]+)#(position (top|bottom))[ ]+$:\1\2:" ~/.config/i3/config
fi
\cp -r ./package/i3/img/lock-shadow.png ~/.config/i3/img/

#
# Terminator
sed -i -E \
"s:^([ ]*background_color =).*:\1 \"#140B19\":" \
$V_HOME/.config/terminator/config

#
# Xresources
\cp -r ./package/set-interface/.Xresources ~/

#
# Fix picom
sed -i -E \
"s:^\s*(shadow-radius\s*=).*:\1 0;:; \
s:^\s*(#\s*shadow-opacity\s*=.*):\1\nshadow-opacity = 1:; \
s:^\s*(shadow-offset-x\s*=).*:\1 0;:; \
s:^\s*(shadow-offset-y\s*=).*:\1 0;:; \
s:^\s*(#\s*shadow-color\s*=.*):\1\nshadow-color = \"#140B19\":; \
s:^([ ]+\")92(\:class_g = 'Terminator' && \!focused\"):\179\2:; \
s:^([ ]+\")82(\:window_type = 'dock' && class_g = 'i3bar'\"):\1100\2:; \
s:^([ ]+\")78(\:class_g \*= '' && \!focused\"):\172\2:; \
s:^\s*(unredir-if-possible\s*=).*:\1 false:; \
s:^([ ]+dock = \{).*:\1 fade = true; shadow = true; full-shadow = true; clip-shadow-above = true; \}:" \
$V_HOME/.config/picom/picom.conf

#
# Gui pannel
#archw --gui pannel bottom
