#!/bin/bash

# Source utility functions
source "$(dirname "$0")/_utils.sh"

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}apps-brew-export"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "DEFAULT_BREWFILE"

# Set default output file if not specified
BREWFILE="${BREWFILE:-${DEFAULT_BREWFILE}}"

# Function to display usage
usage() {
	cat <<EOF
Export list of installed apps using Homebrew.

Usage: ${CLI_NAME} apps-brew-export [OPTIONS]

Options:
  -f, --file FILE    Specify output Brewfile (default: ${BREWFILE})
  -h, --help         Display this help message
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-f | --file)
		BREWFILE="$2"
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
if ! check_required_options "--file BREWFILE"; then
	usage
	exit 1
fi

mkdir_parent "${BREWFILE}"

# Function to export Homebrew packages and Mac App Store apps
export_brew() {
	local output_file="$1"
	log_info "Exporting Homebrew packages and Mac App Store apps, excluding VSCode extensions..."
	run_command brew bundle dump --all --describe --no-vscode --file="${output_file}" --force
}

# Export Homebrew packages and Mac App Store apps
export_brew "${BREWFILE}"

log_info "Apps list exported to ${BREWFILE}"
