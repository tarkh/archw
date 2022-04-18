#
# Load ArchW xprof
if XPROFPATH=$(archw --sys pathconf "xprof.conf"); then
  source $XPROFPATH
fi

#
# Global GUI settings
export QT_QPA_PLATFORMTHEME=lxqt
export QT_STYLE_OVERRIDE=kvantum
export XDG_CURRENT_DESKTOP=gnome
export MOZ_USE_XINPUT2=1
