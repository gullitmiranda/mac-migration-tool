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

# Function to run commands with verbose support
run_command() {
	local cmd=("$@")

	if [[ "${VERBOSE}" = true ]]; then
		echo "Run: ${cmd[*]}"
	fi

	"${cmd[@]}"
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
