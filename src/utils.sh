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
