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
if [[ ${VERBOSE} == true ]]; then
	rsync_cmd+="v"
fi

# Add exclude file to rsync command
rsync_cmd+=" --exclude-from=\"${EXCLUDE_FILE}\""

# Add options for better error handling and reporting
rsync_cmd+=" --itemize-changes --stats"

# Create a log file for rsync output
RSYNC_LOG="${OUTPUT_DIR}/rsync_log.txt"

rsync_cmd+=" ~/ \"${USERNAME}@${NEW_MAC_IP}:~/\""

if [[ ${DRY_RUN} == true ]]; then
	log_info "[DRY RUN] Previewing sync operation..."
	run_command eval "${rsync_cmd} --dry-run" >"${RSYNC_LOG}" 2>&1
	log_info "[DRY RUN] Sync preview complete. No changes were made."
else
	log_info "Starting home folder sync..."

	# Run the rsync command and capture the output
	if run_command eval "${rsync_cmd}" >"${RSYNC_LOG}" 2>&1; then
		log_info "Home folder sync completed successfully!"

		# Extract and display statistics
		read -r TOTAL_FILES < <(grep "Number of files transferred" "${RSYNC_LOG}" | awk '{print $5}') || true
		TOTAL_FILES=${TOTAL_FILES:-N/A}
		read -r TOTAL_SIZE < <(grep "Total transferred file size" "${RSYNC_LOG}" | awk '{print $5, $6}') || true
		TOTAL_SIZE=${TOTAL_SIZE:-N/A}

		log_info "Total files transferred: ${TOTAL_FILES}"
		log_info "Total data transferred: ${TOTAL_SIZE}"

		# Display some of the transferred files (limit to 10 for brevity)
		log_info "Sample of transferred files:"
		while IFS= read -r file; do
			log_info "  - ${file}"
		done < <(grep '^>f' "${RSYNC_LOG}" | head -n 10 | sed 's/^>f[^ ]* //' || true)

		if [[ $(grep -c '^>f' "${RSYNC_LOG}" || true) -gt 10 ]]; then
			log_info "  ... and more. Check ${RSYNC_LOG} for full details."
		fi
	else
		log_error "Home folder sync encountered errors. Check ${RSYNC_LOG} for details."

		# Display some of the errors (limit to 5 for brevity)
		log_error "Sample of errors encountered:"
		while read -r error; do
			log_error "  - ${error}"
		done < <(grep 'rsync:' "${RSYNC_LOG}" | head -n 5 || true)

		if [[ $(grep -c 'rsync:' "${RSYNC_LOG}" || true) -gt 5 ]]; then
			log_error "  ... and more. Check ${RSYNC_LOG} for full error list."
		fi
	fi
fi

log_info "Rsync log saved to ${RSYNC_LOG}"
