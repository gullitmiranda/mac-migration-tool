#!/bin/bash

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}sync-home"

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "DEFAULT_SYNC_HOME_LOG" "DEFAULT_SYNC_HOME_EXCLUDE_FILE"

# Set default values
SYNC_HOME_LOG="${SYNC_HOME_LOG:-${DEFAULT_SYNC_HOME_LOG}}"
EXCLUDE_FILE="${EXCLUDE_FILE:-${DEFAULT_SYNC_HOME_EXCLUDE_FILE}}"

# Function to display usage
usage() {
	cat <<EOF
Sync home folder to the destination MacBook.

Usage: ${CLI_NAME} sync-home [OPTIONS] [USER@]HOST:[DEST]

Arguments:
  [USER@]HOST:[DEST]         Destination in rsync format. DEST is optional and defaults to ~/

Options:
  -o, --output FILE         Specify output log file (default: ${SYNC_HOME_LOG})
  -x, --exclude-file FILE   Specify exclude file for rsync (default: ${EXCLUDE_FILE})
  -d, --dry-run             Perform a dry run without making changes
  -h, --help                Display this help message
EOF
}

# Parse command-specific options
while [[ $# -gt 0 ]]; do
	case $1 in
	-x | --exclude-file)
		EXCLUDE_FILE="$2"
		shift 2
		;;
	-d | --dry-run)
		DRY_RUN=true
		shift
		;;
	-o | --output)
		SYNC_HOME_LOG="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		if [[ -z ${DESTINATION} ]]; then
			DESTINATION="$1"
			shift
		else
			echo "Unknown option: $1" >&2
			usage
			exit 1
		fi
		;;
	esac
done

# Check if required options are set
if [[ -z ${DESTINATION} ]]; then
	log_error "Destination not specified."
	usage
	exit 1
fi

# Parse the destination
if [[ ${DESTINATION} =~ ^([^@]+@)?([^:]+)(:(.*))?$ ]]; then
	USERNAME="${BASH_REMATCH[1]%@}"
	HOST_DEST="${BASH_REMATCH[2]}"
	DEST_PATH="${BASH_REMATCH[4]}"
else
	log_error "Invalid destination format. Use [USER@]HOST:[DEST]"
	usage
	exit 1
fi

# Set default destination path if not provided
DEST_PATH="${DEST_PATH:-~/}"

FULL_DESTINATION="${USERNAME}@${HOST_DEST}:${DEST_PATH}"

log_info "Starting home folder sync process..."
log_info "  - Target: ${FULL_DESTINATION}"
log_info "  - Sync log: ${SYNC_HOME_LOG}"
log_info "  - Exclude file: ${EXCLUDE_FILE}"

mkdir_parent "${SYNC_HOME_LOG}"

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

rsync_cmd+=" ~/ \"${FULL_DESTINATION}\""

if [[ ${DRY_RUN} == true ]]; then
	log_info "Previewing sync operation..."
	rsync_cmd+=" --dry-run"
else
	log_info "Starting sync operation..."
fi

log_warning "ATTENTION: You may be prompted to enter the password for ${USERNAME:-your account} on the destination Mac."

# Run the rsync command and capture the output and exit status
log_verbose_run_command "${rsync_cmd} >${SYNC_HOME_LOG} 2>&1"
if ! eval "${rsync_cmd}" >"${SYNC_HOME_LOG}" 2>&1; then
	# Check if the process was interrupted by the user
	if grep -q "rsync error: received SIGINT, SIGTERM, or SIGHUP" "${SYNC_HOME_LOG}"; then
		log_warning "Sync process was interrupted. No changes were made."
		exit 2
	else
		log_error "Home folder sync encountered errors."
		log_error "Please check ${SYNC_HOME_LOG} for full details."

		# Display the last few lines of the log file, which often contain error messages
		log_error "Last few lines of the log file:"
		tail -n 10 "${SYNC_HOME_LOG}" | while IFS= read -r line; do
			log_error "  ${line}"
		done || true

		# Check for specific error messages and provide more informative output
		if grep -q "Too many authentication failures" "${SYNC_HOME_LOG}"; then
			log_error "Authentication failed. Please check your SSH key or password and try again."
		elif grep -q "connection unexpectedly closed" "${SYNC_HOME_LOG}"; then
			log_error "Connection was unexpectedly closed. Please check your network connection and try again."
		elif grep -q "No such file or directory" "${SYNC_HOME_LOG}"; then
			log_error "Destination directory does not exist. Please check the path and try again."
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
	read -r TOTAL_FILES < <(grep "Number of files transferred" "${SYNC_HOME_LOG}" | awk '{print $5}') || true
	TOTAL_FILES=${TOTAL_FILES:-N/A}
	read -r TOTAL_SIZE < <(grep "Total transferred file size" "${SYNC_HOME_LOG}" | awk '{print $5, $6}') || true
	TOTAL_SIZE=${TOTAL_SIZE:-N/A}

	log_info "Sync Statistics:"
	log_info "  - Total files transferred: ${TOTAL_FILES}"
	log_info "  - Total data transferred: ${TOTAL_SIZE}"
fi
