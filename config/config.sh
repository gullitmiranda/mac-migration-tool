#!/bin/bash
# trunk-ignore-all(shellcheck/SC2034)

# Handle output directory
MM_DEFAULT_OUTPUT_DIR=~/mac-migrate

# Global options
MM_VERBOSE=${MM_VERBOSE:-false}

check_required_vars "SCRIPT_DIR"

# Default exclude file path for sync-home
DEFAULT_SYNC_HOME_EXCLUDE_FILE="${SCRIPT_DIR}/config/sync-home.gitignore"

# Default values for sync-home.sh
DEFAULT_SYNC_HOME_LOG="${MM_OUTPUT_DIR}/sync-home.log"

# Default sync options
MM_DEFAULT_SYNC_PARTIAL=true

# Default values for sync-analyze-log.sh
DEFAULT_MAX_DEPTH=3

# Default values for sync-filter-log.sh
DEFAULT_SYNC_FILTER_EXCLUDE_FILE="${SCRIPT_DIR}/config/sync-filter.gitignore"

# Default value for apps-install.sh
DEFAULT_BREWFILE="${MM_OUTPUT_DIR}/Brewfile"

# List of settings files to migrate for settings-migrate.sh
SETTINGS_FILES=(
	".zshrc"
	".vimrc"
	".gitconfig"
	".ssh/config"
)

# Other default values can be added here as needed
