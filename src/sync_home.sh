#!/bin/bash

source "$(dirname "$0")/utils.sh"

NEW_MAC_IP="$1"
USERNAME="$2"
DRY_RUN="$3"

run_command rsync -avz --progress --exclude=".Trash" --exclude="Library/Caches" \
  ~/ "${USERNAME}@${NEW_MAC_IP}:~/" "$DRY_RUN"
