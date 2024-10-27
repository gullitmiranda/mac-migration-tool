#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Append to the existing LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}clean-sync-log"

# Default values
RSYNC_LOG="${OUTPUT_DIR}/rsync_log.txt"
CLEAN_OUTPUT="${OUTPUT_DIR}/cleaned_sync_log.txt"
CLEAN_EXCLUDE_FILE="${SCRIPT_DIR}/../config/analyze_sync.gitignore"

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Clean the rsync log file by removing entries matching patterns in the exclude file."
  echo
  echo "Options:"
  echo "  -e, --clean-exclude-file FILE   Specify clean exclude file (default: ${CLEAN_EXCLUDE_FILE})"
  echo "  -l, --log FILE                  Specify rsync log file (default: ${RSYNC_LOG})"
  echo "  -o, --output FILE               Specify output file for cleaned log (default: ${CLEAN_OUTPUT})"
  echo "  -h, --help                      Display this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --log)
    RSYNC_LOG="$2"
    shift 2
    ;;
  -e | --clean-exclude-file)
    CLEAN_EXCLUDE_FILE="$2"
    shift 2
    ;;
  -o | --output)
    CLEAN_OUTPUT="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
done

# Check if the rsync log file exists
if [[ ! -f "${RSYNC_LOG}" ]]; then
  log_error "Rsync log file not found: ${RSYNC_LOG}"
  exit 1
fi

# Check if the clean exclude file exists
if [[ ! -f "${CLEAN_EXCLUDE_FILE}" ]]; then
  log_error "Clean exclude file not found: ${CLEAN_EXCLUDE_FILE}"
  exit 1
fi

log_info "Cleaning rsync log: ${RSYNC_LOG}"
log_info "Using clean exclude file: ${CLEAN_EXCLUDE_FILE}"
log_info "Saving cleaned log to: ${CLEAN_OUTPUT}"

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

# Build grep command from clean exclude file
grep_command="grep -v"
while IFS= read -r pattern || [ -n "$pattern" ]; do
  grep_pattern=$(gitignore_to_grep "$pattern")
  if [[ -n "$grep_pattern" ]]; then
    grep_command+=" -e '${grep_pattern}'"
  fi
done <"$CLEAN_EXCLUDE_FILE"

# Execute grep command on the log file
log_info "Cleaning log file..."
if eval "${grep_command}" "$RSYNC_LOG" >"${CLEAN_OUTPUT}"; then
  log_info "Log file cleaned successfully. Cleaned log saved to: ${CLEAN_OUTPUT}"
else
  log_error "Failed to clean log file."
  exit 1
fi
