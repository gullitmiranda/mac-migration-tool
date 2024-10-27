#!/bin/bash

# Source utility functions
source "$(dirname "$0")/_utils.sh"

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}apps-export"

# Function to display usage
usage() {
	cat <<EOF
Export list of installed apps using Homebrew.

Usage: ${CLI_NAME} apps-export [OPTIONS]

Options:
  -h, --help            Display this help message
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
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
