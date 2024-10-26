#!/bin/bash

# Source utility functions
source "$(dirname "$0")/utils.sh"

# Function to export Homebrew packages and Mac App Store apps
export_brew() {
	local output_file="$1"
	log_info "Exporting Homebrew packages and Mac App Store apps, excluding VSCode extensions..."
	run_command brew bundle dump --all --describe --no-vscode --file="${output_file}" --force
}

# Check if OUTPUT_DIR is set
if [[ -z "${OUTPUT_DIR}" ]]; then
	log_error "OUTPUT_DIR is not set. Please run this script through the main mac-migrate.sh script."
	exit 1
fi

# Export Homebrew packages and Mac App Store apps
export_brew "${OUTPUT_DIR}/Brewfile"

log_info "Apps list exported to ${OUTPUT_DIR}/Brewfile"
