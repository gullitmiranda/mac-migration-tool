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
export_domain_defaults() {
	local domain="$1"
	local output_file="$2"
	local failed_file="${EXPORT_DIR}/failed_exports.txt"

	log_info "Exporting defaults for domain: ${domain}"

	if ! defaults export "${domain}" "${output_file}" 2>/dev/null; then
		log_debug "Failed to export defaults for domain: ${domain}"
		echo "${domain}" >>"${failed_file}"
		return 0 # Continue with other domains
	fi

	return 0
}

# Function to export all user domains
export_user_domains() {
	local user_dir="${EXPORT_DIR}/defaults_user"
	mkdir -p "${user_dir}"

	local domains_file="${user_dir}/domains.txt"
	local failed_file="${user_dir}/failed_exports.txt"
	local success_count=0
	local failed_count=0

	log_info "Listing user domains..."
	# The domains command outputs a single line with space-separated domains
	# trunk-ignore(shellcheck/SC2312)
	defaults domains | tr ',' '\n' | sed 's/^ *//' >"${domains_file}"

	# Create or clear the failed exports file
	: >"${failed_file}"

	while IFS= read -r domain; do
		# Skip empty lines and trim whitespace
		[[ -z ${domain} ]] && continue

		log_debug "Processing domain: ${domain}"
		local output_file="${user_dir}/${domain}.plist"

		if export_domain_defaults "${domain}" "${output_file}"; then
			if [[ -f ${output_file} ]]; then
				((success_count++))
			else
				((failed_count++))
			fi
		fi
	done <"${domains_file}"

	log_info "User domains export completed:"
	log_info "  Successfully exported: ${success_count}"
	log_info "  Failed to export: ${failed_count}"

	if [[ -s ${failed_file} ]]; then
		log_info "Failed domains are listed in: ${failed_file}"
	fi
}

# Function to export system domains
export_system_domains() {
	local system_dir="${EXPORT_DIR}/defaults_system"
	mkdir -p "${system_dir}"

	local domains_file="${system_dir}/domains.txt"
	local failed_file="${system_dir}/failed_exports.txt"
	local success_count=0
	local failed_count=0

	log_info "Listing system domains..."
	# Create or clear the failed exports file
	: >"${failed_file}"

	# Get system domains
	# trunk-ignore(shellcheck/SC2312)
	sudo defaults domains /Library/Preferences | tr ',' '\n' | sed 's/^ *//' >"${domains_file}"

	while IFS= read -r domain; do
		# Skip empty lines and trim whitespace
		[[ -z ${domain} ]] && continue

		log_debug "Processing system domain: ${domain}"
		local output_file="${system_dir}/${domain}.plist"

		if ! sudo defaults export "/Library/Preferences/${domain}" "${output_file}" 2>/dev/null; then
			log_debug "Failed to export system domain: ${domain}"
			echo "${domain}" >>"${failed_file}"
			continue
		fi

		# Fix permissions on the output file since it was created with sudo
		# trunk-ignore(shellcheck/SC2312)
		sudo chown "$(id -un):$(id -gn)" "${output_file}"

		if [[ -f ${output_file} ]]; then
			((success_count++))
		else
			((failed_count++))
		fi
	done <"${domains_file}"

	log_info "System domains export completed:"
	log_info "  Successfully exported: ${success_count}"
	log_info "  Failed to export: ${failed_count}"

	if [[ -s ${failed_file} ]]; then
		log_info "Failed domains are listed in: ${failed_file}"
	fi
}

# Main execution
log_info "Starting settings export..."
log_debug "Settings will be saved to: ${EXPORT_DIR}"
log_debug "Export domains: ${MM_SETTINGS_DOMAINS}"
log_debug "Output format: ${MM_SETTINGS_FORMAT}"

# Check if we need sudo access (for system or all domains)
if [[ ${MM_SETTINGS_DOMAINS} == "system" ]] || [[ ${MM_SETTINGS_DOMAINS} == "all" ]]; then
	check_sudo_access
fi

case ${MM_SETTINGS_DOMAINS} in
user)
	export_user_domains
	;;
system)
	export_system_domains
	;;
all)
	export_user_domains
	export_system_domains
	;;
*)
	log_error "Invalid value for --domains: ${MM_SETTINGS_DOMAINS} (must be 'user', 'system', or 'all')"
	exit 1
	;;
esac

log_info "Settings export completed"
