#!/usr/bin/env bash

# Source utility functions
source "$(dirname "$0")/_utils.sh"

# Core function to generate the list of items to be synced
generate_sync_list() {
	local source_path="$1"
	local dest_path="$2"
	local output_file="$3"
	local exclude_file="${4-}" # Optional exclude file

	local rsync_opts=(-avzn --delete)

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

	local rsync_opts=(-avz --progress)

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
		)
	fi

	# Handle both files and directories
	if [[ -d ${source_path} ]]; then
		rsync "${rsync_opts[@]}" "${source_path}/" "${dest_path}/" >"${output_file}" 2>&1
	else
		rsync "${rsync_opts[@]}" "${source_path}" "${dest_path}" >"${output_file}" 2>&1
	fi
}

# Function to get the latest sync files for a sync type
get_latest_sync_files() {
	local sync_type="$1"
	local output_dir="$2"
	local latest_rsync
	local timestamp

	# Find the latest .rsync file in the sync type directory
	# trunk-ignore(shellcheck/SC2312)
	if ! latest_rsync=$(find "${output_dir}/${sync_type}" -name "*.rsync" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2-); then
		return 1
	fi

	if [[ -n ${latest_rsync} ]]; then
		# Extract the timestamp from the rsync file
		timestamp=$(basename "${latest_rsync}" .rsync | cut -d'_' -f2)

		# Construct the corresponding log file path
		local latest_log="${output_dir}/${sync_type}/sync_${timestamp}.log"

		echo "${latest_rsync}:${latest_log}"
	fi
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
	local latest_files
	local timestamp

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

	if ! latest_files=$(get_latest_sync_files "${sync_type}" "${MM_OUTPUT_DIR}"); then
		return 1
	elif [[ -n ${latest_files} ]]; then
		local latest_rsync="${latest_files%:*}"
		local latest_log="${latest_files#*:}"

		if [[ -f ${latest_log} ]]; then
			timestamp=$(basename "${latest_rsync}" .rsync | cut -d'_' -f2)
			log_info "Found previous sync attempt from ${timestamp}"

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
				resume_sync "${source_path}" "${dest_path}" "${sync_type}" "${exclude_file}" "${timestamp}"
				return $?
			fi
		fi
	fi

	# Generate new timestamp for a fresh sync
	timestamp=$(date +%Y%m%d_%H%M%S)
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
	local timestamp="${5:-$(date +%Y%m%d_%H%M%S)}"

	local sync_dir="${MM_OUTPUT_DIR}/${sync_type}"
	mkdir -p "${sync_dir}"

	local log_file="${sync_dir}/sync_${timestamp}.log"
	local resume_log="${sync_dir}/sync_${timestamp}_resume.log"

	log_info "Resuming interrupted sync..."
	if perform_sync "${source_path}" "${dest_path}" "${resume_log}" "${exclude_file}" "true" "${sync_dir}"; then
		# Append resume log to original log
		cat "${resume_log}" >>"${log_file}"
		rm -f "${resume_log}"

		# Clean up partial directory if sync was successful
		local partial_dir="${sync_dir}/partial"
		if [[ -d ${partial_dir} ]]; then
			rm -rf "${partial_dir}"
			mkdir -p "${partial_dir}"
		fi

		log_info "Resume completed successfully"
		log_info "Log file: ${log_file}"
		return 0
	else
		log_error "Resume failed - check log file: ${resume_log}"
		return 1
	fi
}
