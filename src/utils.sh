#!/bin/bash

# Logging functions
log_info() {
	echo "[INFO] $1"
}

log_error() {
	echo "[ERROR] $1" >&2
}

log_warning() {
	echo "[WARNING] $1" >&2
}

# Function to run commands with dry-run support
run_command() {
	local cmd=("$@")
	local last_arg="${cmd[-1]}"

	if [[ ${last_arg} == "--dry-run" ]]; then
		unset 'cmd[-1]'
		echo "[DRY RUN] Would execute: ${cmd[*]}"
	else
		echo "Executing: ${cmd[*]}"
		"${cmd[@]}"
	fi
}

check_required_vars() {
	local missing_vars=()
	for var in "$@"; do
		if [[ -z "${!var}" ]]; then
			missing_vars+=("$var")
		fi
	done

	if [[ ${#missing_vars[@]} -gt 0 ]]; then
		log_error "The following required environment variables are not set: ${missing_vars[*]}"
		log_error "Please run this script through the main mac-migrate.sh script."
		exit 1
	fi
}
