#
# Fix rofi config update
sed -i -E \
"/^\s*theme\:.*\;\s*$/d; \
/^\s*\@theme\s+.*$/d" \
~/.config/rofi/config.rasi

echo "@theme \"archw-theme\"" >> ~/.config/rofi/config.rasi
