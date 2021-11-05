#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# WP - desktop wallpaper tools
#

#
# Help content
if [ "$1" == 'help_draft' ]; then
  echo "
--wp          ;Wallpaper settings
"
fi
if [ "$1" == 'help' ]; then
  echo "
--wp [<mode>] ;Check wallpaper, optional [<mode>]s:
  reset       ;Reset to ArchW default wallpaper
  set <img>   ;Set custom <img> as wallpaper
  refresh     ;Soft refresh of wallpaper
"
fi

#
# Module content
wp () {
  local S_WALLPAPER_FOLDER=/usr/share/wallpapers

  run_feh () {
		feh --no-fehbg --bg-fill $S_WALLPAPER_FOLDER/wallpaper.png 2>/dev/null
	}

  #
  # Clear custom wallpapers
  rm_custom_wp () {
    local WPCUSTOM=($(ls $S_ARCHW_FOLDER/WPCUSTOM_* 2>/dev/null));
    for f in "${WPCUSTOM[@]}" ; do
      rm -f $S_WALLPAPER_FOLDER/$(basename "$f") 2>/dev/null
      rm -f $f 2>/dev/null
    done
  }

	set_wallpaper () {
    #
    # Get largest display
    local L_DISP=$($S_ARCHW_BIN/archw --disp rget lg)
    local DISP_NAME=$(echo $L_DISP | cut -d " " -f1)
    local SCREEN_RES=$(echo $L_DISP | cut -d " " -f2)
    local SCREEN_RES_W=$(echo $SCREEN_RES | cut -d "x" -f1)
    local SCREEN_RES_H=$(echo $SCREEN_RES | cut -d "x" -f2)
    local SCREEN_RR=$(echo $L_DISP | cut -d " " -f3)
    local LASTDISP="LDISP_${DISP_NAME//_/-}_${SCREEN_RES}_${SCREEN_RR}"

    #
    #
    echo "Processing images..."

    #
    # If installed on vm
    #if [ -f "${S_ARCHW_FOLDER}/vminstall" ]; then
    #  DISP_NAME=$(echo $DISP_NAME | tr -d '-')
    #fi

    #
    # If wallpaper exists
    if [ -f $S_WALLPAPER_FOLDER/wallpaper.png ]; then
      local WPF_RES=$(magick identify -ping -format "%wx%h" $S_WALLPAPER_FOLDER/wallpaper.png)
      local WPF_RES_W=$(echo $WPF_RES | cut -d "x" -f1)
      local WPF_RES_H=$(echo $WPF_RES | cut -d "x" -f2)
    fi

    #
    # If wallpaper less then screen or not exist
    if [ -z "$WPF_RES" ] || (( $WPF_RES_W < $SCREEN_RES_W )); then
      #
      # Set source file name
      # If custom wallpaper exist, use it as source
      local SRC_FILE=$S_WALLPAPER_FOLDER/archw-wallpaper-src.png
      if ls $S_ARCHW_FOLDER/WPCUSTOM_* > /dev/null 2>&1; then
        local WPCUSTOM=($(ls $S_ARCHW_FOLDER/WPCUSTOM_*));
        WPCUSTOM="${WPCUSTOM[0]}"
        if [ -f $S_WALLPAPER_FOLDER/$(basename "$WPCUSTOM") ]; then
          SRC_FILE=$S_WALLPAPER_FOLDER/$(basename "$WPCUSTOM")
        else
          rm -f $WPCUSTOM
        fi
      fi

      #
      # Convert source for largest display
      # Set proper splash screen
      convert $SRC_FILE -resize "${SCREEN_RES}^" -gravity center -extent $SCREEN_RES $S_WALLPAPER_FOLDER/wallpaper.png
      convert $S_WALLPAPER_FOLDER/archw-splash-src.png -resize "${SCREEN_RES}^" -gravity center -extent $SCREEN_RES $S_WALLPAPER_FOLDER/splash.png
    else
      echo $WPF_RES_W
    fi

    #
    # Save LASTDISP
    if [ ! -f $S_ARCHW_FOLDER/$LASTDISP ]; then
      rm -f $S_ARCHW_FOLDER/LDISP_* 2>/dev/null
      touch $S_ARCHW_FOLDER/$LASTDISP
      chmod 0777 $S_ARCHW_FOLDER/$LASTDISP
    fi

    #
    # Set background
    run_feh
	}

	if [ -n "$2" ]; then
		if [ "$2" == "reset" ]; then
      #
      # Delete wallpaper and splash
			rm -rf "${S_WALLPAPER_FOLDER}/wallpaper.png" 2>/dev/null
			rm -rf "${S_WALLPAPER_FOLDER}/splash.png" 2>/dev/null

      #
      # Delete custom wallpapers if exist
      rm_custom_wp

      #
      # Set default wallpaper
			set_wallpaper
			echo "Wallpaper reset completed"
      return 0
		elif [ "$2" == "set" ]; then
      #
      # Flush previous custom wallpaper
      rm_custom_wp

      #
      # Copy new custom wallpaper and create pointer
      local FILENAME=$(basename "$3")
      local FILE=$(readlink -f $3)
			\cp -r "$FILE" "$S_WALLPAPER_FOLDER/WPCUSTOM_${FILENAME}"
      touch "$S_ARCHW_FOLDER/WPCUSTOM_${FILENAME}"
      chmod 0777 "$S_ARCHW_FOLDER/WPCUSTOM_${FILENAME}"
      rm -rf "${S_WALLPAPER_FOLDER}/wallpaper.png" 2>/dev/null
      rm -rf "${S_WALLPAPER_FOLDER}/splash.png" 2>/dev/null

      #
      # Set wallpaper
			set_wallpaper
			echo "Wallpaper set completed"
      return 0
    elif [ "$2" == "refresh" ]; then
      run_feh
      echo "Wallpaper refreshed"
      return 0
		fi
    error
	else
    #
    # Set wallpaper
		set_wallpaper
		echo "Wallpaper check completed"
	fi
}
