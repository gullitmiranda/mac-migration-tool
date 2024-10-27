#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions and config
source "${SCRIPT_DIR}/src/_utils.sh"
source "${SCRIPT_DIR}/config/config.sh"

# Set LOG_LABEL for the main script
export LOG_LABEL="mac-migrate"

# Set the CLI name to the script name as it was called
CLI_NAME="$(basename "$0")"

check_required_vars "MM_DEFAULT_OUTPUT_DIR"

# Function to display global options in usage messages
usage_global_options() {
	cat <<EOF
  -o, --output-dir    	     Specify output directory (default: "${MM_DEFAULT_OUTPUT_DIR}")
  -v, --verbose       	     Enable verbose output
  -h, --help          	     Display this help message
EOF
}

# Function to display global environment variables in usage messages
usage_global_env_vars() {
	cat <<EOF
  MM_OUTPUT_DIR              Directory for output files (default: "${MM_DEFAULT_OUTPUT_DIR}")
  MM_VERBOSE                 Set to "true" to enable verbose output
EOF
}

# Export the functions so subcommands can use them
export -f usage_global_options
export -f usage_global_env_vars

# Function to display usage
usage() {
	cat <<EOF
Migrate data and settings from one MacBook to another.

Usage: ${CLI_NAME} [OPTIONS] <command>

Commands:
  sync-home                  Sync home folder
  sync-analyze-log           Analyze sync log
  sync-filter-log            Filter sync log
  apps-brew-export           Export list of installed apps
  apps-brew-install          Install apps on the new MacBook

Global options:
$(usage_global_options || true)

Global environment variables:
$(usage_global_env_vars || true)

Use '${CLI_NAME} <command> --help' for more information about a command.
EOF
}

# Environment variables that can be configured externally
: "${MM_OUTPUT_DIR:=${MM_DEFAULT_OUTPUT_DIR}}"

# Parse global options
while [[ $# -gt 0 ]]; do
	case $1 in
	-v | --verbose)
		export MM_VERBOSE=true
		shift
		;;
	-o | --output-dir)
		export MM_OUTPUT_DIR="$2"
		shift 2
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		# If it's not a global option, it should be a command
		break
		;;
	esac
done

check_required_vars "MM_OUTPUT_DIR"

# Export common variables
export SCRIPT_DIR
export CLI_NAME
export MM_OUTPUT_DIR

# Check for subcommand
if [[ $# -eq 0 ]]; then
	usage
	exit 1
fi

SUBCOMMAND=$1
shift

case ${SUBCOMMAND} in
sync-home)
	bash "${SCRIPT_DIR}/src/sync-home.sh" "$@"
	;;
sync-analyze-log)
	bash "${SCRIPT_DIR}/src/sync-analyze-log.sh" "$@"
	;;
sync-filter-log)
	bash "${SCRIPT_DIR}/src/sync-filter-log.sh" "$@"
	;;
apps-brew-export)
	source "${SCRIPT_DIR}/src/apps-brew-export.sh"
	;;
apps-brew-install)
	source "${SCRIPT_DIR}/src/apps-brew-install.sh"
	;;
# For now this is a hidden command
settings-migrate)
	bash "${SCRIPT_DIR}/src/settings-migrate.sh" "$@"
	;;
*)
	echo "Unknown command: ${SUBCOMMAND}"
	usage
	exit 1
	;;
esac
