#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions
source "${SCRIPT_DIR}/src/utils.sh"

# Default values
NEW_MAC_IP=""
USERNAME=""
SYNC_HOME=false
EXPORT_APPS=false
INSTALL_APPS=false
MIGRATE_SETTINGS=false
DRY_RUN=false
OUTPUT_DIR=""

# Function to display usage
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Migrate data and settings from one MacBook to another."
  echo
  echo "Options:"
  echo "  -i, --ip IP_ADDRESS       IP address of the new MacBook"
  echo "  -u, --username USERNAME   Username on both machines"
  echo "  -s, --sync-home           Sync home folder"
  echo "  -e, --export-apps         Export list of installed apps"
  echo "  -a, --install-apps        Install apps on the new MacBook"
  echo "  -m, --migrate-settings    Migrate settings"
  echo "  -d, --dry-run             Perform a dry run without making changes"
  echo "  -o, --output-dir DIR      Specify output directory for artifacts"
  echo "  -h, --help                Display this help message"
  exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  -i | --ip)
    NEW_MAC_IP="$2"
    shift 2
    ;;
  -u | --username)
    USERNAME="$2"
    shift 2
    ;;
  -s | --sync-home)
    SYNC_HOME=true
    shift
    ;;
  -e | --export-apps)
    EXPORT_APPS=true
    shift
    ;;
  -a | --install-apps)
    INSTALL_APPS=true
    shift
    ;;
  -m | --migrate-settings)
    MIGRATE_SETTINGS=true
    shift
    ;;
  -d | --dry-run)
    DRY_RUN=true
    shift
    ;;
  -o | --output-dir)
    OUTPUT_DIR="$2"
    shift 2
    ;;
  -h | --help) usage ;;
  *)
    echo "Unknown option: $1"
    usage
    ;;
  esac
done

# Check if required parameters are provided
if [[ -z ${NEW_MAC_IP} || -z ${USERNAME} ]]; then
  log_error "Error: IP address and username are required."
  log_info "To get the IP address, run: ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print $2}'"
  log_info "To get the username, run: whoami"
  usage
fi

# Handle output directory
if [[ -z ${OUTPUT_DIR} ]]; then
  OUTPUT_DIR=$(mktemp -d /tmp/mac-migrate.XXXXXX)
  log_info "No output directory specified. Using temporary directory: ${OUTPUT_DIR}"
elif [[ -d ${OUTPUT_DIR} ]]; then
  read -p "Output directory ${OUTPUT_DIR} already exists. Do you want to override it? (y/n) " -n 1 -r
  echo
  if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
    log_error "Aborting due to existing output directory."
    exit 1
  fi
  rm -rf "${OUTPUT_DIR}"
fi

mkdir -p "${OUTPUT_DIR}"
log_info "Using output directory: ${OUTPUT_DIR}"
export OUTPUT_DIR

# Main migration process
log_info "Starting MacBook migration..."

if [[ ${SYNC_HOME} == true ]]; then
  log_info "Syncing home folder..."
  bash "${SCRIPT_DIR}/src/sync_home.sh" "${NEW_MAC_IP}" "${USERNAME}" "${DRY_RUN}"
fi

if ${EXPORT_APPS}; then
  log_info "Exporting apps list..."
  bash "${SCRIPT_DIR}/src/export_apps.sh" "${DRY_RUN}"
fi

if ${INSTALL_APPS}; then
  log_info "Installing apps on new Mac..."
  if [[ "${DRY_RUN}" = false ]]; then
    ssh "${USERNAME}@${NEW_MAC_IP}" 'bash -s' <"${SCRIPT_DIR}/src/install_apps.sh"
  else
    log_info "[DRY RUN] Would run install_apps.sh on the new Mac"
  fi
fi

if ${MIGRATE_SETTINGS}; then
  log_info "Migrating settings..."
  bash "${SCRIPT_DIR}/src/migrate_settings.sh" "${NEW_MAC_IP}" "${USERNAME}" "${DRY_RUN}"
fi

log_info "Migration complete!"
