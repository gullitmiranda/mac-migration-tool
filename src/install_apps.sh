#!/bin/bash

source "$(dirname "$0")/utils.sh"

# Install Homebrew if not already installed
if ! command -v brew &>/dev/null; then
  log_info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Homebrew packages
log_info "Installing Homebrew packages..."
brew bundle --file=~/Brewfile

# Install Mac App Store apps
log_info "Installing Mac App Store apps..."
while read app; do
  mas install $(echo $app | cut -d' ' -f1)
done <~/mas_apps.txt
