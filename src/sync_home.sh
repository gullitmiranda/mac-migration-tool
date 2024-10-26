#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Check if required environment variables are set
check_required_vars "NEW_MAC_IP" "USERNAME" "OUTPUT_DIR" "EXCLUDE_FILE"

log_info "Preparing to sync home folder to ${NEW_MAC_IP}..."
log_info "You will be prompted to enter the password for ${USERNAME} on the new Mac."

# Prepare rsync command
rsync_cmd="rsync -az"

# Add verbose flag if VERBOSE is true
if [[ "${VERBOSE}" = true ]]; then
	rsync_cmd+="v"
fi

# Add exclude file to rsync command
rsync_cmd+=" --exclude-from=\"${EXCLUDE_FILE}\""

rsync_cmd+=" ~/ \"${USERNAME}@${NEW_MAC_IP}:~/\""

if [[ "${DRY_RUN}" = true ]]; then
	log_info "[DRY RUN] Previewing sync operation..."
	run_command eval "${rsync_cmd} --dry-run"
	log_info "[DRY RUN] Sync preview complete. No changes were made."
else
	log_info "Starting home folder sync..."
	run_command eval "${rsync_cmd}"
	log_info "Home folder sync complete!"
fi
