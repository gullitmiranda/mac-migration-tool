#!/bin/bash

# trunk-ignore-all(shellcheck/SC2155)
# trunk-ignore-all(shellcheck/SC2312)

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}sync-analyze-log"

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "DEFAULT_SYNC_HOME_LOG" "DEFAULT_MAX_DEPTH"

# Default values
SYNC_LOG="${SYNC_LOG:-${DEFAULT_SYNC_HOME_LOG}}"
MAX_DEPTH="${MAX_DEPTH:-${DEFAULT_MAX_DEPTH}}"
SHOW_ALL="${SHOW_ALL:-false}"

# Function to display usage
usage() {
	cat <<EOF
Analyze the sync log to identify files and directories that were not synchronized.

Usage: ${CLI_NAME} sync-analyze-log [OPTIONS]

Options:
  -i, --input FILE      Specify input sync log file (default: ${SYNC_LOG})
  -o, --output FILE     Specify analysis output file (default: <input-file>-analyzed.log)
  -d, --max-depth NUM   Maximum directory depth to display (default: ${MAX_DEPTH})
  -a, --all             Show all changes, including synced files (default: only show unsynced)
  -h, --help            Display this help message
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-i | --input)
		SYNC_LOG="$2"
		shift 2
		;;
	-o | --output)
		SYNC_ANALYZE_LOG="$2"
		shift 2
		;;
	-d | --max-depth)
		MAX_DEPTH="$2"
		shift 2
		;;
	-a | --all)
		SHOW_ALL=true
		shift
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

# Check if required options are set
if ! check_required_options "--input SYNC_LOG" "--max-depth MAX_DEPTH"; then
	usage
	exit 1
fi

# Set SYNC_ANALYZE_LOG based on SYNC_LOG if not defined
if [[ -z ${SYNC_ANALYZE_LOG} ]]; then
	SYNC_ANALYZE_LOG="${SYNC_LOG%.*}-analyzed.log"
fi

# Check if the sync log file exists
if [[ ! -f ${SYNC_LOG} ]]; then
	log_error "Sync log file not found: ${SYNC_LOG}"
	exit 1
fi

log_info "Analyzing sync log: ${SYNC_LOG}"
log_info "Saving analysis to: ${SYNC_ANALYZE_LOG}"

mkdir_parent "${SYNC_ANALYZE_LOG}"

# Function to get the depth of a file path
get_depth() {
	local path="$1"
	echo "${path}" | tr -cd '/' | wc -c
}

# Function to log messages to both console and file
log_both() {
	local message="$1"
	log_info "${message}"
	echo "${message}" >>"${SYNC_ANALYZE_LOG}"
}

# Function to analyze the rsync log
analyze_rsync_log() {
	local total_changes=0
	local total_skipped=0
	local total_unsynced=0

	# Clear the analysis log file
	echo -n "" >"${SYNC_ANALYZE_LOG}"

	while IFS= read -r line; do
		if [[ ${line} =~ ^[[:alpha:]*]+ ]]; then
			local change_type="${line:0:1}"
			local file_path="${line#* }"
			local depth=$(get_depth "${file_path}")

			if ((depth <= MAX_DEPTH)); then
				case "${change_type}" in
				">")
					if [[ ${SHOW_ALL} == true ]]; then
						log_both "File transferred: ${file_path}"
					fi
					;;
				"c")
					if [[ ${SHOW_ALL} == true ]]; then
						log_both "File changed: ${file_path}"
					fi
					;;
				"*")
					log_both "File deleted: ${file_path}"
					((total_unsynced++))
					;;
				".")
					if [[ ${SHOW_ALL} == true ]]; then
						log_both "File attributes changed: ${file_path}"
					fi
					;;
				"h")
					if [[ ${SHOW_ALL} == true ]]; then
						log_both "Hardlink: ${file_path}"
					fi
					;;
				"?")
					log_both "Unknown change: ${file_path}"
					((total_unsynced++))
					;;
				*)
					log_both "Unknown change type: ${change_type}"
					;;
				esac
			fi

			((total_changes++))
		elif [[ ${line} == *"skipping non-regular file"* ]]; then
			local item=$(echo "${line}" | sed -E 's/.*skipping non-regular file "(.+)"/\1/')
			local depth=$(get_depth "${item}")

			if ((depth <= MAX_DEPTH)); then
				log_both "Skipped non-regular file: ${item}"
			fi

			((total_skipped++))
			((total_unsynced++))
		elif [[ ${line} == *"file has vanished:"* ]]; then
			local item=$(echo "${line}" | sed -E 's/.*file has vanished: "(.+)"/\1/')
			local depth=$(get_depth "${item}")

			if ((depth <= MAX_DEPTH)); then
				log_both "File vanished: ${item}"
			fi

			((total_unsynced++))
		elif [[ ${line} == *"permission denied"* ]]; then
			local item=$(echo "${line}" | sed -E 's/.*permission denied (.+)/\1/')
			local depth=$(get_depth "${item}")

			if ((depth <= MAX_DEPTH)); then
				log_both "Permission denied: ${item}"
			fi

			((total_unsynced++))
		fi
	done <"${SYNC_LOG}"

	log_both "Total items changed or transferred: ${total_changes}"
	log_both "Total items skipped: ${total_skipped}"
	log_both "Total items not synced: ${total_unsynced}"

	# Extract and display statistics
	local total_files=$(grep "Number of files transferred:" "${SYNC_LOG}" | awk '{print $5}')
	local total_size=$(grep "Total transferred file size:" "${SYNC_LOG}" | awk '{print $5, $6}')
	local total_time=$(grep "Total transferred file size:" "${SYNC_LOG}" | awk '{print $10, $11}')

	log_both "Sync Statistics:"
	log_both "  - Total files transferred: ${total_files:-N/A}"
	log_both "  - Total data transferred: ${total_size:-N/A}"
	log_both "  - Total time: ${total_time:-N/A}"
}

# Run the analysis
analyze_rsync_log

log_both "Sync log analysis complete. Results saved to ${SYNC_ANALYZE_LOG}"
