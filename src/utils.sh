#!/bin/bash

# Logging functions
log_info() {
  echo "[INFO] $1"
}

log_error() {
  echo "[ERROR] $1" >&2
}

log_warning() {
  echo "[WARNING] $1" >&2
}

# Function to run commands with dry-run support
run_command() {
  local command="$1"
  shift
  local args=("$@")
  local dry_run="${args[-1]}"
  unset 'args[-1]'

  if [ "$dry_run" = true ]; then
    log_info "[DRY RUN] Would run: $command ${args[*]}"
  else
    $command "${args[@]}"
  fi
}
