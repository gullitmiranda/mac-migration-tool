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
	rsync_cmd+=" --dry-run"
fi

# Run the rsync command and capture the output and exit status
if ! run_command eval "${rsync_cmd}" >"${RSYNC_LOG}" 2>&1; then
	log_error "Home folder sync encountered errors. Check ${RSYNC_LOG} for details."

	# Display the last few lines of the log file, which often contain error messages
	log_error "Last few lines of the log file:"
	tail -n 10 "${RSYNC_LOG}" | while IFS= read -r line; do
		log_error "  ${line}"
	done || true

	# Check for specific error messages and provide more informative output
	if grep -q "Too many authentication failures" "${RSYNC_LOG}"; then
		log_error "Authentication failed. Please check your SSH key or password and try again."
	elif grep -q "connection unexpectedly closed" "${RSYNC_LOG}"; then
		log_error "Connection was unexpectedly closed. Please check your network connection and try again."
	fi

	exit 1
else
	if [[ ${DRY_RUN} == true ]]; then
		log_info "[DRY RUN] Sync preview completed successfully. No changes were made."
	else
		log_info "Home folder sync completed successfully!"
	fi

	# Extract and display statistics
	read -r TOTAL_FILES < <(grep "Number of files transferred" "${RSYNC_LOG}" | awk '{print $5}') || true
	TOTAL_FILES=${TOTAL_FILES:-N/A}
	read -r TOTAL_SIZE < <(grep "Total transferred file size" "${RSYNC_LOG}" | awk '{print $5, $6}') || true
	TOTAL_SIZE=${TOTAL_SIZE:-N/A}

	log_info "Total files transferred: ${TOTAL_FILES}"
	log_info "Total data transferred: ${TOTAL_SIZE}"

	# Display some of the transferred files (limit to 10 for brevity)
	log_info "Sample of transferred files:"
	grep '^>f' "${RSYNC_LOG}" | head -n 10 | sed 's/^>f[^ ]* //' | while IFS= read -r file; do
		log_info "  - ${file}"
	done || true

	if [[ $(grep -c '^>f' "${RSYNC_LOG}" || true) -gt 10 ]]; then
		log_info "  ... and more. Check ${RSYNC_LOG} for full details."
	fi
fi

log_info "Rsync log saved to ${RSYNC_LOG}"
