#!/bin/bash

source "$(dirname "$0")/utils.sh"

DRY_RUN="$1"

BREWFILE="Brewfile"

# Function to install Homebrew
install_homebrew() {
	log_info "Installing Homebrew..."
	local install_script
	install_script="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	if ! run_command /bin/bash -c "${install_script}" "${DRY_RUN}"; then
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

run_command brew bundle install --file="${BREWFILE}" "${DRY_RUN}"

log_info "Finished installing applications."
