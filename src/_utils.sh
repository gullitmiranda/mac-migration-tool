#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m' # Added blue color for debug messages
NC='\033[0m'      # No Color

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC}${LOG_LABEL:+ [${LOG_LABEL}]} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC}${LOG_LABEL:+ [${LOG_LABEL}]} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC}${LOG_LABEL:+ [${LOG_LABEL}]} $1"
}

log_debug() {
	if [[ ${MM_VERBOSE} == "true" ]]; then
		echo -e "${BLUE}[DEBUG]${NC}${LOG_LABEL:+ [${LOG_LABEL}]} $1"
	fi
}

# Function to run commands with verbose support
run_command() {
	local cmd=("$@")
	log_verbose_run_command "${cmd[@]}"
	"${cmd[@]}"
}

log_verbose_run_command() {
	local cmd=("$@")

	if [[ ${MM_VERBOSE} == "true" ]]; then
		log_debug "Run: ${cmd[*]}"
	fi
}

# Make sure that the parent directory exists
mkdir_parent() {
	mkdir -p "$(dirname "$1")"
}

# Check if required environment variables are set
check_required_vars() {
	local missing_vars=()
	for var in "$@"; do
		if [[ -z ${!var} ]]; then
			missing_vars+=("${var}")
		fi
	done

	if [[ ${#missing_vars[@]} -gt 0 ]]; then
		log_error "The following required environment variables are not set: ${missing_vars[*]}"
		log_error "Please run this script through the main mac-migrate.sh script."
		exit 1
	fi
}

# Function to check if required options are set
check_required_options() {
	local missing_options=()

	for item in "$@"; do
		local option_name="${item%% *}"
		local var_name="${item#* }"

		if [[ -z ${!var_name} ]]; then
			missing_options+=("${option_name}")
		fi
	done

	if [[ ${#missing_options[@]} -gt 0 ]]; then
		log_error "The following required options are not set: ${missing_options[*]}"
		log_error "Please provide all required options."
		return 1
	fi

	return 0
}
