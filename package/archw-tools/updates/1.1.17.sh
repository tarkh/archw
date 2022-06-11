#
# Fix i3lock opacity in Picom
sed -i -E \
"/\b(i3lock)\b/d" \
$V_HOME/.config/picom/picom.conf

sed -i -E \
"s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g ~= 'i3lock' \&\& focused\",:g; \
s:^\s*(opacity-rule\s*=\s*\[):\1\n  \"100\:class_g ~= 'i3lock' \&\& \!focused\",:g" \
$V_HOME/.config/picom/picom.conf
