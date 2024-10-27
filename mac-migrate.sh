#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions and config
source "${SCRIPT_DIR}/src/_utils.sh"
source "${SCRIPT_DIR}/config/config.sh"

# Set LOG_LABEL for the main script
export LOG_LABEL="mac-migrate"

# Set the CLI name to the script name as it was called
export CLI_NAME="$(basename "$0")"

# Function to display usage
usage() {
	cat <<EOF
Migrate data and settings from one MacBook to another.

Usage: ${CLI_NAME} <command> [OPTIONS]

Commands:
  sync-home           Sync home folder
  sync-analyze-log    Analyze sync log
  sync-filter-log     Filter sync log
  apps-brew-export    Export list of installed apps
  apps-brew-install   Install apps on the new MacBook

Common options:
  -o, --output-dir DIR      Specify output directory for artifacts
  -d, --dry-run             Perform a dry run without making changes
  -v, --verbose             Enable verbose output
  -h, --help                Display this help message

Use '${CLI_NAME} <command> --help' for more information about a command.
EOF
}

# Parse common options
while [[ $# -gt 0 ]]; do
	case $1 in
	-o | --output-dir)
		OUTPUT_DIR="$2"
		shift 2
		;;
	-d | --dry-run)
		DRY_RUN=true
		shift
		;;
	-v | --verbose)
		VERBOSE=true
		shift
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		break
		;;
	esac
done

# Handle output directory
if [[ -z ${OUTPUT_DIR} ]]; then
	OUTPUT_DIR=$(mktemp -d /tmp/mac-migrate.XXXXXX)
	# log_info "No output directory specified. Using temporary directory: ${OUTPUT_DIR}"
elif [[ -d ${OUTPUT_DIR} ]]; then
	read -p "Output directory \"${OUTPUT_DIR}\" already exists. Do you want to override it? (y/n) " -n 1 -r
	echo
	if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
		log_error "Aborting due to existing output directory."
		exit 1
	fi
	rm -rf "${OUTPUT_DIR}"
	mkdir -p "${OUTPUT_DIR}"
else
	mkdir -p "${OUTPUT_DIR}"
fi

# Export common variables
export DRY_RUN
export OUTPUT_DIR
export VERBOSE

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
