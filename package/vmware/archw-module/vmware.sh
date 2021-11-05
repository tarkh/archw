#!/bin/sh
#
# ArchW by tarkh (2021)
# module:
# VMWARE - tools for vmware
#

#
# Help content
if [ $1 == 'help' ]; then
  echo "
--vmware <mode>                 ;VMWare utils <mode>s:
  mount-list                    ;Show avaliable sources for mounting
  mount <source> <target>       ;Mount <source> on /<target> path
  mount-save <source> <target>  ;Mount <source> on /<target> path and make mount permanrnt on reboots
  mount-save-list [info]        ;Show saved mounts, optional [info] for details
  mount-delete <souce>          ;Delete saved <source> from permanent mount on reboots
  suspend-lock [(on|off)]       ;Show lock screen on VM suspend status, optional settings [(on|off)]
"
fi

#
# Module content
vmware () {
  if [ -n "$2" ]; then
		# Mount function
		mount () {
			if vmhgfs-fuse -o max_write=61440 -o allow_other -o auto_unmount .host:"$2" "$3"; then
				echo "$2 successfully mounted on $3"
				return 0
			else
				echo "Failed to mount $2 on $3"
				return 1
			fi
		}
		# Options
		if [ $2 == "mount-list" ]; then
			vmware-hgfsclient
      return 0
		elif [ $2 == "mount" ] && [ -n "$3" ] && [ -n "$4" ]; then
			mount "$3" "$4"
      return 0
		elif [ $2 == "mount-save" ] && [ -n "$3" ] && [ -n "$4" ]; then
			if mount "$3" "$4"; then
				mkdir -p "${S_ARCH_AUTOMOUNT}"
				if echo $(readlink -f "$4") > "${S_ARCH_AUTOMOUNT}/${2}"; then
					echo "Mount saved"
          return 0
				else
					echo "Failed to save mount"
				fi
      else
        echo "Cant mount $3 on $4"
			fi
      return 1
		elif [ $2 == "mount-save-list" ]; then
			if [ -n "$3" ] && [ $3 == "--info" ]; then
				for i in $(ls -p "${S_ARCH_AUTOMOUNT}" 2>/dev/null | grep -v /); do
					echo "$i --> $(cat $S_ARCH_AUTOMOUNT/$i)"
				done
			else
				ls -p "${S_ARCH_AUTOMOUNT}" 2>/dev/null | grep -v /
			fi
      return 0
		elif [ $2 == "mount-delete" ] && [ -n "$3" ]; then
			if $S_ARCHW_BIN/archw --vmware mount-save-list | grep "$3"; then
				if rm -rf "${S_ARCH_AUTOMOUNT}/$3"; then
					echo "Source $3 removed from automount"
          return 0
				else
					echo "Can't remove source $3 from automount"
				fi
			else
				echo "Source $3 not found in automount list"
			fi
      return 1
		elif [ $2 == "suspend-lock" ]; then
			SL_ON_FILE="${S_ARCHW_FOLDER}/suspendlock"
			if [ -n "$3" ] && [ $3 == "on" ]; then
				touch "$SL_ON_FILE"
			elif [ -n "$3" ] && [ $3 == "off" ]; then
				rm -f "$SL_ON_FILE"
			elif [ -n "$3" ] && [ $3 == "execute" ]; then
				#
				# Execute suspend lock (system)
				if [ -f "$SL_ON_FILE" ] && [ -f "${S_ARCHW_FOLDER}/i3socket" ]; then
					if i3-msg -s $(cat "${S_ARCHW_FOLDER}/i3socket") 'exec archw --lock'; then
						echo "Screen locked!"
					fi
				fi
			fi
			# SL status
			if [ -f "$SL_ON_FILE" ]; then
				echo "Suspend screen lock: ON"
			else
				echo "Suspend screen lock: OFF"
			fi
      return 0
		fi
	fi
  error
}
