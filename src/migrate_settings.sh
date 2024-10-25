#!/bin/bash

source "$(dirname "$0")/utils.sh"

NEW_MAC_IP="$1"
USERNAME="$2"
DRY_RUN="$3"

# Sync SSH keys
run_command rsync -avz ~/.ssh/ "${USERNAME}@${NEW_MAC_IP}:~/.ssh/" "$DRY_RUN"

# Sync Git configuration
run_command rsync -avz ~/.gitconfig "${USERNAME}@${NEW_MAC_IP}:~/.gitconfig" "$DRY_RUN"

# Sync Bash/Zsh history and configuration
run_command rsync -avz ~/.bash_history "${USERNAME}@${NEW_MAC_IP}:~/.bash_history" "$DRY_RUN"
run_command rsync -avz ~/.zsh_history "${USERNAME}@${NEW_MAC_IP}:~/.zsh_history" "$DRY_RUN"
run_command rsync -avz ~/.bashrc "${USERNAME}@${NEW_MAC_IP}:~/.bashrc" "$DRY_RUN"
run_command rsync -avz ~/.zshrc "${USERNAME}@${NEW_MAC_IP}:~/.zshrc" "$DRY_RUN"
