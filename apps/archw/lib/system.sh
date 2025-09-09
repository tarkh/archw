#!/bin/bash

#
# W System
# This module contains various helper functions for main program
#

#
# logt
#
# Log with time string
logt() {
	local message="$1"
	echo "[$(date '+%Y-%m-d %H:%M:%S')] $message"
}

#
# log
#
# Simple log without anything
log() {
	local message="$1"
	echo $message
}

#
# initcpio_hooks
#
# Modifies the HOOKS array in /etc/mkinitcpio.conf by adding or removing a hook.
# Supports positioning new hook with optional before=<entry> or after=<entry>.
# Adds at end if before entry not found; errors if after entry not found.

initcpio_hooks() {
	local action_entry="$1"
	local before_entry=""
	local after_entry=""
	local config_file="/etc/mkinitcpio.conf"
	local hooks_line hooks_array new_hooks

	# Parse action (add/remove)
	case "$action_entry" in
		add=*) action="add"; entry="${action_entry#add=}" ;;
		remove=*) action="remove"; entry="${action_entry#remove=}" ;;
		*) echo "Error: First argument must be 'add=<hook>' or 'remove=<hook>'" >&2; return 1 ;;
	esac

	# Parse optional arguments
	for arg in "${@:2}"; do
		case "$arg" in
			before=*) before_entry="${arg#before=}" ;;
			after=*) after_entry="${arg#after=}" ;;
			*) echo "Error: Invalid argument '$arg'" >&2; return 1 ;;
		esac
	done

	# Validate entry
	if [[ -z "$entry" ]]; then
		echo "Error: Hook name is required" >&2
		return 1
	fi

	# Check if config file exists
	if [[ ! -f "$config_file" ]]; then
		echo "Error: Configuration file $config_file not found" >&2
		return 1
	fi

	# Read the HOOKS line
	hooks_line=$(grep '^HOOKS=' "$config_file")
	if [[ -z "$hooks_line" ]]; then
		echo "Error: HOOKS array not found in $config_file" >&2
		return 1
	fi

	# Extract hooks array
	hooks_array=$(echo "$hooks_line" | sed -E 's/HOOKS=\((.*)\)/\1/')
	IFS=' ' read -r -a hooks <<< "$hooks_array"

	# Handle action
	new_hooks=()
	if [[ "$action" == "add" ]]; then
		# Check if hook already exists
		for hook in "${hooks[@]}"; do
			if [[ "$hook" == "$entry" ]]; then
				echo "Warning: Hook '$entry' already exists in HOOKS" >&2
				return 0
			fi
		done

		# Handle insertion
		if [[ -n "$before_entry" ]]; then
			local found=false
			for hook in "${hooks[@]}"; do
				if [[ "$hook" == "$before_entry" ]]; then
					new_hooks+=("$entry" "$hook")
					found=true
				else
					new_hooks+=("$hook")
				fi
			done
			if [[ "$found" == false ]]; then
				echo "Warning: Before entry '$before_entry' not found, adding '$entry' at end" >&2
				new_hooks=("${hooks[@]}" "$entry")
			fi
		elif [[ -n "$after_entry" ]]; then
			local found=false
			for hook in "${hooks[@]}"; do
				new_hooks+=("$hook")
				if [[ "$hook" == "$after_entry" ]]; then
					new_hooks+=("$entry")
					found=true
				fi
			done
			if [[ "$found" == false ]]; then
				echo "Error: After entry '$after_entry' not found in HOOKS" >&2
				return 1
			fi
		else
			new_hooks=("${hooks[@]}" "$entry")
		fi
	elif [[ "$action" == "remove" ]]; then
		local found=false
		for hook in "${hooks[@]}"; do
			if [[ "$hook" != "$entry" ]]; then
				new_hooks+=("$hook")
			else
				found=true
			fi
		done
		if [[ "$found" == false ]]; then
			echo "Warning: Hook '$entry' not found in HOOKS" >&2
			return 0
		fi
	fi

	# Create new HOOKS line
	new_hooks_line="HOOKS=(${new_hooks[*]})"

	# Update config file
	if ! sed -i "s|^HOOKS=.*|$new_hooks_line|" "$config_file"; then
		echo "Error: Failed to update $config_file" >&2
		return 1
	fi

  # Rebuild initcpio
  if ! mkinitcpio -P; then
  	echo "Error: Failed to rebuild initcpio" >&2
  	return 1
  fi

	echo "Successfully ${action}ed '$entry' in HOOKS in $config_file"
	return 0
}
