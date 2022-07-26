#!/bin/bash
set -veuo pipefail

# Ask for the administrator password upfront
sudo -v

# Install system updates in background
sudo softwareupdate --install --all --agree-to-license --background 

# Install command line tools
which make || xcode-select --install

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install and setup 1password-cli so chezmoi can retrieve files it needs
curl -o ~/Downloads/1Password.zip https://downloads.1password.com/mac/1Password.zip
unzip ~/Downloads/1Password.zip -d ~/Downloads/
open ~/Downloads/1Password\ Installer.app
brew install --cask 1password/tap/1password-cli

read -p "Hit enter when 1Password is fully installed..."
open /Applications/1Password.app
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
