#!/bin/bash

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}sync-filter-log"

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "DEFAULT_SYNC_HOME_LOG" "DEFAULT_SYNC_FILTER_EXCLUDE_FILE"

# Default values
SYNC_LOG="${SYNC_LOG:-${DEFAULT_SYNC_HOME_LOG}}"
EXCLUDE_FILE="${EXCLUDE_FILE:-${DEFAULT_SYNC_FILTER_EXCLUDE_FILE}}"

# Function to display usage
usage() {
  cat <<EOF
Clean the sync log file by removing entries matching patterns in the exclude file.

Usage: ${CLI_NAME} sync-filter-log [OPTIONS]

Options:
  -i, --input FILE      Specify input sync log file (default: ${SYNC_LOG})
  -o, --output FILE     Specify output file for cleaned log (default: <input-file>-filtered.log)
  -e, --exclude FILE    Specify exclude file for filtering (default: ${EXCLUDE_FILE})
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
  -e | --exclude)
    EXCLUDE_FILE="$2"
    shift 2
    ;;
  -o | --output)
    SYNC_FILTER_LOG="$2"
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

# Check if required options are set
if ! check_required_options "--input SYNC_LOG" "--exclude EXCLUDE_FILE"; then
  usage
  exit 1
fi

# Set SYNC_FILTER_LOG based on SYNC_LOG if not defined
if [[ -z "${SYNC_FILTER_LOG}" ]]; then
  SYNC_FILTER_LOG="${SYNC_LOG%.*}-filtered.log"
fi

# Check if the sync log file exists
if [[ ! -f "${SYNC_LOG}" ]]; then
  log_error "Sync log file not found: ${SYNC_LOG}"
  exit 1
fi

# Check if the exclude file exists
if [[ ! -f "${EXCLUDE_FILE}" ]]; then
  log_error "Exclude file not found: ${EXCLUDE_FILE}"
  exit 1
fi

log_info "Cleaning sync log: ${SYNC_LOG}"
log_info "Using exclude file: ${EXCLUDE_FILE}"
log_info "Saving cleaned log to: ${SYNC_FILTER_LOG}"

# Function to convert gitignore pattern to grep pattern
gitignore_to_grep() {
  local pattern="$1"
  # Remove leading and trailing whitespace
  pattern=$(echo "$pattern" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  # Ignore empty lines and comments
  if [[ -z "$pattern" || "$pattern" == \#* ]]; then
    return
  fi
  # Escape special characters for grep
  pattern=$(echo "$pattern" | sed 's/[[\.*^$/]/\\&/g')
  # Convert gitignore wildcards to grep wildcards
  pattern=$(echo "$pattern" | sed 's/\?/./g; s/\*/.*/g')
  # Add start and end anchors
  echo "^[+.] .*${pattern}.*$"
}

# Build grep command from exclude file
grep_command="grep -v"
while IFS= read -r pattern || [ -n "$pattern" ]; do
  grep_pattern=$(gitignore_to_grep "$pattern")
  if [[ -n "$grep_pattern" ]]; then
    grep_command+=" -e '${grep_pattern}'"
  fi
done <"$EXCLUDE_FILE"

# Execute grep command on the log file
log_info "Cleaning log file..."
if eval "${grep_command}" "$SYNC_LOG" >"${SYNC_FILTER_LOG}"; then
  log_info "Log file cleaned successfully. Cleaned log saved to: ${SYNC_FILTER_LOG}"
else
  log_error "Failed to clean log file."
  exit 1
fi
