#!/bin/bash

source "$(dirname "$0")/utils.sh"

NEW_MAC_IP="$1"
USERNAME="$2"
DRY_RUN="$3"

log_info "Migrating settings to ${USERNAME}@${NEW_MAC_IP}..."

# Test SSH connection
if ! ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${USERNAME}@${NEW_MAC_IP}" exit; then
	log_error "Unable to establish SSH connection. Please check your network and ensure SSH is enabled on the target Mac."
	exit 1
fi

# List of settings files to migrate
SETTINGS_FILES=(
	".zshrc"
	".vimrc"
	".gitconfig"
	".ssh/config"
)

for file in "${SETTINGS_FILES[@]}"; do
	if [[ -f "${HOME}/${file}" ]]; then
		log_info "Migrating ${file}..."
		run_command scp "${HOME}/${file}" "${USERNAME}@${NEW_MAC_IP}:~/${file}" "${DRY_RUN}"
	else
		log_warning "File ${file} not found, skipping..."
	fi
done

log_info "Settings migration complete."
