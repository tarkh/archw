#
# Evaluate ArchW GUI env vars
eval "$(archw --gui set-env-vars)"

#
# Global GUI settings
export QT_QPA_PLATFORMTHEME=lxqt
export QT_STYLE_OVERRIDE=kvantum
export XDG_CURRENT_DESKTOP=gnome
export MOZ_USE_XINPUT2=1
export GTK_CSD=0
export LD_PRELOAD=/usr/lib/libgtk3-nocsd.so.0
