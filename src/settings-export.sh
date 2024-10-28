#!/bin/bash

# Set LOG_LABEL for this script
export LOG_LABEL="${LOG_LABEL:+${LOG_LABEL}:}settings-export"

# Source utility functions and config
source "$(dirname "$0")/_utils.sh"
source "$(dirname "$0")/../config/config.sh"

# Check if required environment variables are set
check_required_vars "CLI_NAME" "MM_OUTPUT_DIR"

# Function to display usage
usage() {
	cat <<EOF
Export macOS system and user preferences using the defaults command.

Usage: ${CLI_NAME} settings-export [OPTIONS]

Options:
  -d, --domains VALUE       Specify which domains to export (user/system/all, default: all)
$(usage_global_options || true)

Environment variables:
  MM_SETTINGS_DOMAINS      Domains to export (user/system/all, default: all)
$(usage_global_env_vars || true)
EOF
}

# Environment variables that can be configured externally
: "${MM_SETTINGS_DOMAINS:=all}"

# Parse command-specific options
while [[ $# -gt 0 ]]; do
	case $1 in
	-d | --domains)
		if [[ $2 =~ ^(user|system|all)$ ]]; then
			MM_SETTINGS_DOMAINS="$2"
			shift 2
		else
			log_error "Invalid value for --domains: $2 (must be 'user', 'system', or 'all')"
			exit 1
		fi
		;;
	-h | --help)
		usage
		exit 0
		;;
	*)
		log_error "Unknown option: $1"
		usage
		exit 1
		;;
	esac
done

# Function to check and request sudo access if needed
check_sudo_access() {
	log_info "This operation requires sudo access for system preferences"
	# Request sudo credentials and keep them cached
	if ! sudo -v; then
		log_error "Failed to get sudo privileges"
		exit 1
	fi

	# Keep sudo alive in the background
	(while true; do
		sudo -n true
		sleep 60
		kill -0 "$$" || exit
	done 2>/dev/null &)
}

# Create output directory for settings with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SETTINGS_DIR="${MM_OUTPUT_DIR}/settings"
EXPORT_DIR="${SETTINGS_DIR}/${TIMESTAMP}"
mkdir -p "${EXPORT_DIR}"

# Function to export defaults for a specific domain
export_domains() {
	local context="$1" # "user" or "system"
	local context_dir="${EXPORT_DIR}/defaults_${context}"
	mkdir -p "${context_dir}"

	local domains_file="${context_dir}/domains.txt"
	local count=0

	log_info "Listing ${context} domains..."

	# Get domains based on context
	if [[ ${context} == "system" ]]; then
		# trunk-ignore(shellcheck/SC2312)
		sudo defaults domains /Library/Preferences | tr ',' '\n' | sed 's/^ *//' >"${domains_file}"
	else
		# trunk-ignore(shellcheck/SC2312)
		defaults domains | tr ',' '\n' | sed 's/^ *//' >"${domains_file}"
	fi

	while IFS= read -r domain; do
		[[ -z ${domain} ]] && continue

		log_debug "Processing ${context} domain: ${domain}"
		local output_file="${context_dir}/${domain}.plist"
		local domain_path="${domain}"

		if [[ ${context} == "system" ]]; then
			domain_path="/Library/Preferences/${domain}"
			sudo defaults export "${domain_path}" "${output_file}"
			# trunk-ignore(shellcheck/SC2312)
			sudo chown "$(id -un):$(id -gn)" "${output_file}"
		else
			defaults export "${domain_path}" "${output_file}"
		fi

		((count++))
	done <"${domains_file}"

	log_info "${context} domains export completed: ${count} domains exported"
}

# Main execution
log_info "Starting settings export..."
log_debug "Settings will be saved to: ${EXPORT_DIR}"
log_debug "Export domains: ${MM_SETTINGS_DOMAINS}"

# Check if we need sudo access (for system or all domains)
if [[ ${MM_SETTINGS_DOMAINS} == "system" ]] || [[ ${MM_SETTINGS_DOMAINS} == "all" ]]; then
	check_sudo_access
fi

case ${MM_SETTINGS_DOMAINS} in
user)
	export_domains "user"
	;;
system)
	export_domains "system"
	;;
all)
	export_domains "user"
	export_domains "system"
	;;
*)
	log_error "Invalid value for --domains: ${MM_SETTINGS_DOMAINS} (must be 'user', 'system', or 'all')"
	exit 1
	;;
esac

log_info "Settings export completed"
