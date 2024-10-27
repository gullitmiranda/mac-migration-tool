#!/bin/bash

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}apps-install"

BREWFILE="${DEFAULT_BREWFILE}"

# Function to display usage
usage() {
	cat <<EOF
Install applications using Homebrew and Brewfile.

Usage: ${CLI_NAME} apps-install [OPTIONS]

Options:
  -f, --file FILE    Specify Brewfile (default: ${BREWFILE})
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

# Function to install Homebrew
install_homebrew() {
	log_info "Installing Homebrew..."
	local install_script
	install_script="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if ! run_command /bin/bash -c "${install_script}"; then
		log_error "Homebrew installation failed"
		return 1
	fi
}

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
	log_warning "Homebrew is not installed. Installing now..."
	install_homebrew
else
	log_info "Homebrew is already installed."
fi

if [[ ! -f ${BREWFILE} ]]; then
	log_error "Brewfile not found: ${BREWFILE}"
	exit 1
fi

log_info "Installing applications from ${BREWFILE}..."

run_command brew bundle install --file="${BREWFILE}"

log_info "Finished installing applications."
