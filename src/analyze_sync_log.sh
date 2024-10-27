#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Append to the existing LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}analyze-sync-log"

# Default values
RSYNC_LOG="${OUTPUT_DIR}/rsync_log.txt"
ANALYSIS_LOG="${OUTPUT_DIR}/sync_analysis.log"
MAX_DEPTH=3
SHOW_ALL=false

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Analyze the rsync log to identify files and directories that were not synchronized."
  echo
  echo "Options:"
  echo "  -l, --log FILE        Specify rsync log file (default: ${RSYNC_LOG})"
  echo "  -o, --output FILE     Specify analysis output file (default: ${ANALYSIS_LOG})"
  echo "  -d, --max-depth NUM   Maximum directory depth to display (default: ${MAX_DEPTH})"
  echo "  -a, --all             Show all changes, including synced files (default: only show unsynced)"
  echo "  -h, --help            Display this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --log)
    RSYNC_LOG="$2"
    shift 2
    ;;
  -o | --output)
    ANALYSIS_LOG="$2"
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

log_info "Analyzing rsync log: ${RSYNC_LOG}"
log_info "Saving analysis to: ${ANALYSIS_LOG}"

# Function to get the depth of a file path
get_depth() {
  local path="$1"
  echo "$path" | tr -cd '/' | wc -c
}

# Function to log messages to both console and file
log_both() {
  local message="$1"
  log_info "$message"
  echo "$message" >>"$ANALYSIS_LOG"
}

# Function to analyze the rsync log
analyze_rsync_log() {
  local total_changes=0
  local total_skipped=0
  local total_unsynced=0

  # Clear the analysis log file
  >"$ANALYSIS_LOG"

  while IFS= read -r line; do
    if [[ $line =~ ^[[:alpha:]*]+ ]]; then
      local change_type="${line:0:1}"
      local file_path="${line#* }"
      local depth=$(get_depth "$file_path")

      if ((depth <= MAX_DEPTH)); then
        case $change_type in
        ">")
          if [[ $SHOW_ALL == true ]]; then
            log_both "File transferred: $file_path"
          fi
          ;;
        "c")
          if [[ $SHOW_ALL == true ]]; then
            log_both "File changed: $file_path"
          fi
          ;;
        "*")
          log_both "File deleted: $file_path"
          ((total_unsynced++))
          ;;
        ".")
          if [[ $SHOW_ALL == true ]]; then
            log_both "File attributes changed: $file_path"
          fi
          ;;
        "h")
          if [[ $SHOW_ALL == true ]]; then
            log_both "Hardlink: $file_path"
          fi
          ;;
        "?")
          log_both "Unknown change: $file_path"
          ((total_unsynced++))
          ;;
        esac
      fi

      ((total_changes++))
    elif [[ $line == *"skipping non-regular file"* ]]; then
      local item=$(echo "$line" | sed -E 's/.*skipping non-regular file "(.+)"/\1/')
      local depth=$(get_depth "$item")

      if ((depth <= MAX_DEPTH)); then
        log_both "Skipped non-regular file: $item"
      fi

      ((total_skipped++))
      ((total_unsynced++))
    elif [[ $line == *"file has vanished:"* ]]; then
      local item=$(echo "$line" | sed -E 's/.*file has vanished: "(.+)"/\1/')
      local depth=$(get_depth "$item")

      if ((depth <= MAX_DEPTH)); then
        log_both "File vanished: $item"
      fi

      ((total_unsynced++))
    elif [[ $line == *"permission denied"* ]]; then
      local item=$(echo "$line" | sed -E 's/.*permission denied (.+)/\1/')
      local depth=$(get_depth "$item")

      if ((depth <= MAX_DEPTH)); then
        log_both "Permission denied: $item"
      fi

      ((total_unsynced++))
    fi
  done <"${RSYNC_LOG}"

  log_both "Total items changed or transferred: ${total_changes}"
  log_both "Total items skipped: ${total_skipped}"
  log_both "Total items not synced: ${total_unsynced}"

  # Extract and display statistics
  local total_files=$(grep "Number of files transferred:" "${RSYNC_LOG}" | awk '{print $5}')
  local total_size=$(grep "Total transferred file size:" "${RSYNC_LOG}" | awk '{print $5, $6}')
  local total_time=$(grep "Total transferred file size:" "${RSYNC_LOG}" | awk '{print $10, $11}')

  log_both "Sync Statistics:"
  log_both "  - Total files transferred: ${total_files:-N/A}"
  log_both "  - Total data transferred: ${total_size:-N/A}"
  log_both "  - Total time: ${total_time:-N/A}"
}

# Run the analysis
analyze_rsync_log

log_both "Rsync log analysis complete. Results saved to ${ANALYSIS_LOG}"
