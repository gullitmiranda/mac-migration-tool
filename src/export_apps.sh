#!/bin/bash

source "$(dirname "$0")/utils.sh"

DRY_RUN="$1"

BREWFILE="Brewfile"

log_info "Exporting list of installed applications to Brewfile..."

if [[ ${DRY_RUN} == "--dry-run" ]]; then
	log_info "[DRY RUN] Would create Brewfile with installed applications"
else
	# Export Homebrew bundle (includes brew, cask, and mas entries)
	run_command brew bundle dump --force --file="${BREWFILE}"
fi

log_info "Exported app list to ${BREWFILE}"
