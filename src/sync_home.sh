#!/bin/bash

source "$(dirname "$0")/utils.sh"

NEW_MAC_IP="$1"
USERNAME="$2"
DRY_RUN="$3"

# Test SSH connection
echo "Testing SSH connection to ${USERNAME}@${NEW_MAC_IP}..."
if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "${USERNAME}@${NEW_MAC_IP}" exit; then
	echo "SSH connection successful."
else
	echo "Error: Unable to establish SSH connection. Please check your network and ensure SSH is enabled on the target Mac."
	exit 1
fi

# Proceed with rsync if SSH connection is successful
echo "Starting rsync operation..."
run_command rsync -avz --progress --exclude=".Trash" --exclude="Library/Caches" \
	~/ "${USERNAME}@${NEW_MAC_IP}:~/" "${DRY_RUN}"
