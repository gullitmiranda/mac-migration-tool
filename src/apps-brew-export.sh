#!/bin/bash

# Source utility functions
source "$(dirname "$0")/_utils.sh"

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}apps-brew-export"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "MM_OUTPUT_DIR"

DEFAULT_BREWFILE="${MM_OUTPUT_DIR}/Brewfile"

# Set default output file if not specified
: "${MM_BREWFILE:=${DEFAULT_BREWFILE}}"

# Function to display usage
usage() {
	cat <<EOF
Export list of installed apps using Homebrew.

Usage: ${CLI_NAME} apps-brew-export [OPTIONS]

Options:
  -f, --file FILE            Specify output Brewfile (default: ${DEFAULT_BREWFILE})
$(usage_global_options || true)

Environment variables:
  MM_BREWFILE        Path to output Brewfile
$(usage_global_env_vars || true)
EOF
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	-f | --file)
		MM_BREWFILE="$2"
		shift 2
		;;
	-o | --output-dir)
		MM_OUTPUT_DIR="$2"
		shift 2
		;;
	-v | --verbose)
		MM_VERBOSE=true
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
if ! check_required_options "--file MM_BREWFILE"; then
	usage
	exit 1
fi

mkdir_parent "${MM_BREWFILE}"

# Function to export Homebrew packages and Mac App Store apps
export_brew() {
	local output_file="$1"
	log_info "Exporting Homebrew packages and Mac App Store apps, excluding VSCode extensions..."
	# run_command brew bundle dump --describe --formula --cask --tap --mas --no-vscode --file="${output_file}" --force
	run_command brew bundle dump --describe --no-vscode --file="${output_file}" --force
}

# Export Homebrew packages and Mac App Store apps
if ! export_brew "${MM_BREWFILE}"; then
	log_error "Failed to export Homebrew packages"
	exit 1
fi

log_info "Apps list exported to ${MM_BREWFILE}"
