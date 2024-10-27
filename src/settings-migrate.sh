#!/bin/bash

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}settings-migrate"

# Default values
NEW_MAC_IP=""
USERNAME=""

# Function to display usage
usage() {
	cat <<EOF
Migrate settings to a new MacBook.

Usage: ${CLI_NAME} settings-migrate [OPTIONS]

Options:
  -i, --ip IP_ADDRESS       IP address of the new MacBook
  -u, --username USERNAME   Username on both machines
  -h, --help                Display this help message
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-i | --ip)
		NEW_MAC_IP="$2"
		shift 2
		;;
	-u | --username)
		USERNAME="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		echo "Unknown option: $1"
		usage
		exit 1
		;;
	esac
done

# Check if required parameters are provided
if [[ -z ${NEW_MAC_IP} || -z ${USERNAME} ]]; then
	log_error "Error: IP address and username are required."
	usage
	exit 1
fi

log_info "Migrating settings to ${USERNAME}@${NEW_MAC_IP}..."

# Test SSH connection
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${USERNAME}@${NEW_MAC_IP}" exit; then
	log_error "Unable to establish SSH connection. Please check your network and ensure SSH is enabled on the target Mac."
	exit 1
fi

# Use SETTINGS_FILES from config.sh
for file in "${SETTINGS_FILES[@]}"; do
	if [[ -f "${HOME}/${file}" ]]; then
		log_info "Migrating ${file}..."
		run_command scp "${HOME}/${file}" "${USERNAME}@${NEW_MAC_IP}:~/${file}"
	else
		log_warning "File ${file} not found, skipping..."
	fi
done

log_info "Settings migration complete."
