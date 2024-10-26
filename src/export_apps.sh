#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Append to the existing LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}export-apps"

# Function to export Homebrew packages and Mac App Store apps
export_brew() {
	local output_file="$1"
	log_info "Exporting Homebrew packages and Mac App Store apps, excluding VSCode extensions..."
	run_command brew bundle dump --all --describe --no-vscode --file="${output_file}" --force
}

# Check if required environment variables are set
check_required_vars "OUTPUT_DIR"

# Export Homebrew packages and Mac App Store apps
export_brew "${OUTPUT_DIR}/Brewfile"

log_info "Apps list exported to ${OUTPUT_DIR}/Brewfile"
