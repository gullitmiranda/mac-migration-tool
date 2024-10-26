#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
	echo -e "${GREEN}[INFO]${NC} $1"
}

log_warning() {
	echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run commands with verbose support
run_command() {
	local cmd=("$@")
	log_verbose_run_command "${cmd[@]}"
	"${cmd[@]}"
}

log_verbose_run_command() {
	local cmd=("$@")

	if [[ ${VERBOSE} == "true" ]]; then
		echo "Run: ${cmd[*]}"
	fi
}

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
