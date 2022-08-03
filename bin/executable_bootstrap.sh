#!/bin/bash
set -veuo pipefail

# Install all oh-my-zsh.
# Doing this early in the process so we can overwrite it with our custom zshrc, instead
# of omz overwritting mine.
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

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

# Install all languages
asdf plugin add nodejs
asdf plugin add erlang
asdf plugin add elixir
asdf plugin add golang
asdf plugin add python
asdf plugin add lua
asdf install

# restart
sudo shutdown -r now
