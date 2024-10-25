#!/bin/bash

source "$(dirname "$0")/utils.sh"

DRY_RUN="$1"

# Export Homebrew packages
run_command brew bundle dump --file=~/Brewfile "$DRY_RUN"

# Export Mac App Store apps
run_command mas list ">" ~/mas_apps.txt "$DRY_RUN"
