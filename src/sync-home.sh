#!/bin/bash

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}sync-home"

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/_sync.sh"
source "$(dirname "$0")/../config/config.sh"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "MM_OUTPUT_DIR"

# Function to display usage
usage() {
	cat <<EOF
Sync home folder to the destination MacBook.

Usage: ${CLI_NAME} sync-home [OPTIONS] [USER@]HOST:[DEST]

Arguments:
  [USER@]HOST:[DEST]         Destination in rsync format. DEST is optional and defaults to ~/

Options:
  -x, --exclude-file FILE    Specify exclude file for rsync (default: ${DEFAULT_SYNC_HOME_EXCLUDE_FILE})
  -p, --partial VALUE        Enable/disable partial file transfer support (true/false, default: ${MM_DEFAULT_SYNC_PARTIAL})
  -d, --dry-run              Perform a dry run without making changes
  -n, --no-edit              Skip editing the sync list before proceeding
  -r, --resume VALUE         Resume behavior for partial and previous syncs (yes/no/ask, default: ask)
$(usage_global_options || true)

Environment variables:
  MM_SYNC_HOME_EXCLUDE_FILE  Path to exclude file
  MM_SYNC_PARTIAL            Enable/disable partial transfer support (default: ${MM_DEFAULT_SYNC_PARTIAL})
  MM_SYNC_HOME_DRY_RUN       Set to "true" for dry run mode
  MM_SYNC_NOT_EDIT           Set to "true" to skip editing the sync list
  MM_SYNC_RESUME             Resume behavior (yes/no/ask, default: ask)
$(usage_global_env_vars || true)

EOF
}

# Environment variables that can be configured externally
: "${MM_SYNC_HOME_EXCLUDE_FILE:=${DEFAULT_SYNC_HOME_EXCLUDE_FILE}}"
: "${MM_SYNC_HOME_DRY_RUN:=false}"
: "${MM_SYNC_PARTIAL:=${MM_DEFAULT_SYNC_PARTIAL}}"
: "${MM_SYNC_NOT_EDIT:=false}"
: "${MM_SYNC_RESUME:=ask}"

# Parse command-specific options
while [[ $# -gt 0 ]]; do
	case $1 in
	-x | --exclude-file)
		MM_SYNC_HOME_EXCLUDE_FILE="$2"
		shift 2
		;;
	-p | --partial)
		if [[ $2 =~ ^(true|false)$ ]]; then
			MM_SYNC_PARTIAL="$2"
			shift 2
		else
			log_error "Invalid value for --partial: $2 (must be 'true' or 'false')"
			exit 1
		fi
		;;
	-d | --dry-run)
		MM_SYNC_HOME_DRY_RUN=true
		shift
		;;
	-n | --no-edit)
		MM_SYNC_NOT_EDIT=true
		shift
		;;
	-r | --resume)
		if [[ $2 =~ ^(yes|no|ask)$ ]]; then
			MM_SYNC_RESUME="$2"
			shift 2
		else
			log_error "Invalid value for --resume: $2 (must be 'yes', 'no', or 'ask')"
			exit 1
		fi
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
			log_error "Unknown option: $1"
			usage
			exit 1
		fi
		;;
	esac
done

# Validate destination format
if [[ -z ${DESTINATION} ]]; then
	log_error "Destination not specified"
	usage
	exit 1
fi

if [[ ! ${DESTINATION} =~ ^([^@]+@)?([^:]+)(:(.*))?$ ]]; then
	log_error "Invalid destination format. Use [USER@]HOST:[DEST]"
	usage
	exit 1
fi

# Parse destination components
USERNAME="${BASH_REMATCH[1]%@}"
HOST_DEST="${BASH_REMATCH[2]}"
DEST_PATH="${BASH_REMATCH[4]:-~/}"
FULL_DESTINATION="${USERNAME}@${HOST_DEST}:${DEST_PATH}"

# Setup sync configuration
SOURCE_PATH="${HOME}"
SYNC_TYPE="sync-home"

# Log debug information
log_debug "Configuration:"
log_debug "  Source: ${SOURCE_PATH}"
log_debug "  Target: ${FULL_DESTINATION}"
log_debug "  Exclude file: ${MM_SYNC_HOME_EXCLUDE_FILE}"
log_debug "  Dry run: ${MM_SYNC_HOME_DRY_RUN}"
log_debug "  Partial transfer: ${MM_SYNC_PARTIAL}"
log_debug "  Skip edit: ${MM_SYNC_NOT_EDIT}"
log_debug "  Resume mode: ${MM_SYNC_RESUME}"

# Execute sync based on mode
if [[ ${MM_SYNC_HOME_DRY_RUN} == true ]]; then
	# Generate sync list only
	TIMESTAMP=$(date +%Y%m%d_%H%M%S)
	SYNC_DIR="${MM_OUTPUT_DIR}/${SYNC_TYPE}"
	mkdir -p "${SYNC_DIR}"

	SYNC_LIST_FILE="${SYNC_DIR}/sync_${TIMESTAMP}.rsync"
	generate_sync_list "${SOURCE_PATH}" "${FULL_DESTINATION}" "${SYNC_LIST_FILE}" "${MM_SYNC_HOME_EXCLUDE_FILE}"
	exit $?
else
	# Perform full sync with partial setting
	sync_directory "${SOURCE_PATH}" "${FULL_DESTINATION}" "${SYNC_TYPE}" "${MM_SYNC_HOME_EXCLUDE_FILE}" "${MM_SYNC_PARTIAL}"
	exit $?
fi
