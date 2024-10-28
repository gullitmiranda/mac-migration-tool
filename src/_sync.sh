#!/usr/bin/env bash

# Source utility functions
source "$(dirname "$0")/_utils.sh"

# Default SSH options for rsync
get_ssh_opts() {
	echo "-o ControlMaster=auto -o ControlPath=/tmp/ssh-control-%r@%h:%p -o ControlPersist=yes"
}

# Core function to generate the list of items to be synced
generate_sync_list() {
	local source_path="$1"
	local dest_path="$2"
	local output_file="$3"
	local exclude_file="${4-}" # Optional exclude file

	local rsync_opts=(-avzn)
	# Add SSH control options
	rsync_opts+=(-e "ssh $(get_ssh_opts)")

	# Add exclude file if provided
	if [[ -n ${exclude_file} ]] && [[ -f ${exclude_file} ]]; then
		rsync_opts+=(--exclude-from="${exclude_file}")
	fi

	# Handle both files and directories
	if [[ -d ${source_path} ]]; then
		rsync "${rsync_opts[@]}" "${source_path}/" "${dest_path}/" >"${output_file}"
	else
		rsync "${rsync_opts[@]}" "${source_path}" "${dest_path}" >"${output_file}"
	fi
}

# Core function to perform the sync
perform_sync() {
	local source_path="$1"
	local dest_path="$2"
	local output_file="$3"
	local exclude_file="${4-}"
	local partial="${5:-true}"
	local sync_dir="${6-}"

	# Base rsync options with safer defaults
	local rsync_opts=(
		-avz            # archive, verbose, compress
		--progress      # show progress
		--ignore-errors # skip files with errors
	)

	# Add sync directory to exclusions if provided
	if [[ -n ${sync_dir} ]]; then
		# Get relative path by removing source_path prefix
		local rel_sync_dir
		# trunk-ignore(shellcheck/SC2001)
		rel_sync_dir=$(echo "${sync_dir}" | sed "s|^${source_path}/||")
		rsync_opts+=(--exclude="${rel_sync_dir}/") # Exclude the sync directory
	fi

	# Add SSH control options
	rsync_opts+=(-e "ssh $(get_ssh_opts)")

	# Add exclude file if provided
	if [[ -n ${exclude_file} ]] && [[ -f ${exclude_file} ]]; then
		rsync_opts+=(--exclude-from="${exclude_file}")
	fi

	# Configure partial file handling
	if [[ ${partial} == "true" ]] && [[ -n ${sync_dir} ]]; then
		local partial_dir="${sync_dir}/partial"
		mkdir -p "${partial_dir}"
		rsync_opts+=(
			--partial-dir="${partial_dir}"
			--partial
			--timeout=180 # set timeout to 3 minutes
		)
	fi

	# Handle both files and directories
	local rsync_cmd
	if [[ -d ${source_path} ]]; then
		rsync_cmd=(rsync "${rsync_opts[@]}" "${source_path}/" "${dest_path}/")
	else
		rsync_cmd=(rsync "${rsync_opts[@]}" "${source_path}" "${dest_path}")
	fi

	log_debug "Running: ${rsync_cmd[*]}"
	"${rsync_cmd[@]}" >"${output_file}" 2>&1
}

# Function to get the latest sync files for a sync type
get_latest_sync_file() {
	local sync_type="$1"
	local output_dir="$2"
	local latest_rsync

	# Ensure directory exists
	local sync_dir="${output_dir}/${sync_type}"

	# Now get the latest one
	# trunk-ignore(shellcheck/SC2312)
	if ! latest_rsync=$(find "${sync_dir}" -name "*.rsync" -type f -exec stat -f "%m %N" {} \; 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-); then
		return 1
	fi

	if [[ -n ${latest_rsync} ]]; then
		echo "${latest_rsync}"
	fi
}

gen_timestamp() {
	date +%Y%m%d_%H%M%S
}

## Sample implementation
#########################

# Interactive sync function with logging and user interaction
sync_directory() {
	local source_path="$1"
	local dest_path="$2"
	local sync_type="${3:-sync}"
	local exclude_file="${4-}"
	local partial="${5:-true}"

	# Validate inputs
	if [[ ! -e ${source_path} ]]; then
		log_error "Source path does not exist: ${source_path}"
		return 1
	fi

	# Create sync type directory if it doesn't exist
	local sync_dir="${MM_OUTPUT_DIR}/${sync_type}"
	mkdir -p "${sync_dir}"

	# Check for partial files from previous syncs
	local partial_dir="${sync_dir}/partial"
	local previous_sync_file

	# Only show partial files message if directory exists AND contains files
	# trunk-ignore(shellcheck/SC2312)
	if [[ -d ${partial_dir} ]] && [[ -n "$(ls -A "${partial_dir}" 2>/dev/null)" ]]; then
		log_warning "Found partial files from previous sync attempts"
		log_info "Partial files directory: ${partial_dir}"

		local should_resume="no"
		case "${MM_SYNC_RESUME}" in
		yes)
			should_resume="yes"
			;;
		no)
			should_resume="no"
			;;
		*)
			read -p "Do you want to resume using partial files? [y/N] " -n 1 -r
			echo
			[[ ${REPLY} =~ ^[Yy]$ ]] && should_resume="yes"
			;;
		esac

		if [[ ${should_resume} == "yes" ]]; then
			resume_sync "${source_path}" "${dest_path}" "${sync_type}" "${exclude_file}"
			return $?
		else
			log_info "Cleaning up partial files..."
			rm -rf "${partial_dir}"
			mkdir -p "${partial_dir}"
		fi
	fi

	log_debug "Getting latest sync file for ${sync_type}"
	if ! previous_sync_file=$(get_latest_sync_file "${sync_type}" "${MM_OUTPUT_DIR}"); then
		log_error "Error getting latest sync file for ${sync_type}"
		return 1
	elif [[ -n ${previous_sync_file} ]]; then
		log_info "Found previous sync attempt ${previous_sync_file}"

		local should_resume="no"
		case "${MM_SYNC_RESUME}" in
		yes)
			should_resume="yes"
			;;
		no)
			should_resume="no"
			;;
		*)
			read -p "Do you want to resume the previous sync? [y/N] " -n 1 -r
			echo
			[[ ${REPLY} =~ ^[Yy]$ ]] && should_resume="yes"
			;;
		esac

		if [[ ${should_resume} == "yes" ]]; then
			resume_sync "${source_path}" "${dest_path}" "${sync_type}" "${exclude_file}" "${previous_sync_file}"
			return $?
		fi
	fi

	# Generate new timestamp for a fresh sync
	local timestamp
	timestamp=$(gen_timestamp)
	local sync_list_file="${sync_dir}/sync_${timestamp}.rsync"
	local log_file="${sync_dir}/sync_${timestamp}.log"

	# Step 1: Generate and show sync list
	log_info "Building list of changes to be synced..."
	log_debug "List of changes to be synced: \"${sync_list_file}\""

	generate_sync_list "${source_path}" "${dest_path}" "${sync_list_file}" "${exclude_file}"

	if [[ ! -s ${sync_list_file} ]]; then
		log_info "No changes to sync"
		return 0
	fi

	log_info "Review the list of changes to be synced and make the necessary changes."
	if [[ ${MM_SYNC_NOT_EDIT} != "true" ]]; then
		read -p "Do you want to edit the sync list before proceeding? [Y/n/a] " -n 1 -r
		echo
		if [[ ${REPLY} =~ ^[Nn]$ ]]; then
			:
		elif [[ ${REPLY} =~ ^[Aa]$ ]]; then
			log_info "Sync cancelled, you can resume later"
			return 0
		else
			${EDITOR:-vi} "${sync_list_file}"
		fi
	fi

	# Step 3: Perform sync
	log_info "Starting sync..."
	log_debug "Sync log: ${log_file}"

	if perform_sync "${source_path}" "${dest_path}" "${log_file}" "${exclude_file}" "${partial}" "${sync_dir}"; then
		log_info "Sync completed successfully"
		log_info "Log file: ${log_file}"
		return 0
	else
		log_error "Sync failed - check log file: ${log_file}"
		return 1
	fi
}

# Resume an interrupted sync
resume_sync() {
	local source_path="$1"
	local dest_path="$2"
	local sync_type="$3"
	local exclude_file="$4"
	local sync_list_file="$5"

	local file_basename
	local sync_dir
	local timestamp

	sync_dir=$(dirname "${sync_list_file}")
	file_basename=$(basename "${sync_list_file}" .rsync)
	timestamp=$(gen_timestamp)

	mkdir -p "${sync_dir}"

	local log_file="${sync_dir}/${file_basename}.log"
	local resume_log="${sync_dir}/${file_basename}_resume_${timestamp}.log"

	log_info "Resuming interrupted sync..."
	if perform_sync "${source_path}" "${dest_path}" "${resume_log}" "${exclude_file}" "true" "${sync_dir}"; then
		# Clean up partial directory if sync was successful
		local partial_dir="${sync_dir}/partial"
		if [[ -d ${partial_dir} ]]; then
			rm -rf "${partial_dir}"
			mkdir -p "${partial_dir}"
		fi

		log_info "Resume completed successfully"
		log_debug "Resume log file: ${resume_log}"
		return 0
	else
		log_error "Resume failed - check log file: ${resume_log}"
		return 1
	fi
}
