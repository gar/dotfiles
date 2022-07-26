#!/bin/bash
set -veuo pipefail

# Ask for the administrator password upfront
sudo -v

# Install system updates in background
sudo softwareupdate --install --all --agree-to-license --background 

# Install command line tools
xcode-select --install

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install and setup 1password-cli so chezmoi can retrieve files it needs
brew install --cask 1password
brew install --cask 1password/tap/1password-cli
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

open /System/Volumes/Data/Applications/1Password.app
read -p "Set up account in 1Password app (and enable biometrics) [enter to continue]"

eval $(op signin --account my.1password.com)

# Install and run chezmoi to pull in config and scripts
brew install chezmoi
chezmoi init gar --apply

# Configure macOS
/bin/bash .macos

# Install all applications
brew bundle
asdf install

# restart
sudo shutdown -r now
