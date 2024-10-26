#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Append to the existing LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}sync-home"

# If no exclude file is specified, use the default
if [[ -z ${EXCLUDE_FILE} ]]; then
	EXCLUDE_FILE="${DEFAULT_EXCLUDE_FILE}"
fi

# Create a log file for rsync output
RSYNC_LOG="${OUTPUT_DIR}/rsync_log.txt"

# Check if required environment variables are set
check_required_vars "NEW_MAC_IP" "USERNAME" "OUTPUT_DIR" "EXCLUDE_FILE"

log_info "Starting home folder sync process..."
log_info "  - Target: ${USERNAME}@${NEW_MAC_IP}"
log_info "  - Exclude file: ${EXCLUDE_FILE}"
log_info "  - Rsync log: ${RSYNC_LOG}"

if [[ ${DRY_RUN} == true ]]; then
	log_info "  - Mode: Dry run (no changes will be made)"
else
	log_info "  - Mode: Live run"
fi

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

rsync_cmd+=" ~/ \"${USERNAME}@${NEW_MAC_IP}:~/\""

if [[ ${DRY_RUN} == true ]]; then
	log_info "Previewing sync operation..."
	rsync_cmd+=" --dry-run"
else
	log_info "Starting sync operation..."
fi

log_warning "ATTENTION: Maybe you will be prompted to enter the password for ${USERNAME} on the new Mac."

# Run the rsync command and capture the output and exit status
log_verbose_run_command "${rsync_cmd} >${RSYNC_LOG} 2>&1"
if ! eval "${rsync_cmd}" >"${RSYNC_LOG}" 2>&1; then
	# Check if the process was interrupted by the user
	if grep -q "rsync error: received SIGINT, SIGTERM, or SIGHUP" "${RSYNC_LOG}"; then
		log_warning "Sync process was interrupted. No changes were made."
		exit 2
	else
		log_error "Home folder sync encountered errors."
		log_error "Please check ${RSYNC_LOG} for full details."

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
	fi
else
	if [[ ${DRY_RUN} == true ]]; then
		log_info "Sync preview completed successfully. No changes were made."
	else
		log_info "Home folder sync completed successfully!"
	fi

	# Extract and display statistics
	read -r TOTAL_FILES < <(grep "Number of files transferred" "${RSYNC_LOG}" | awk '{print $5}') || true
	TOTAL_FILES=${TOTAL_FILES:-N/A}
	read -r TOTAL_SIZE < <(grep "Total transferred file size" "${RSYNC_LOG}" | awk '{print $5, $6}') || true
	TOTAL_SIZE=${TOTAL_SIZE:-N/A}

	log_info "Sync Statistics:"
	log_info "  - Total files transferred: ${TOTAL_FILES}"
	log_info "  - Total data transferred: ${TOTAL_SIZE}"
fi
