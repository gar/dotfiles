#!/bin/bash
set -veuo pipefail

OS="$(uname -s)"

# ---------------------------------------------------------------------------
# Helper: detect Linux distro family
# ---------------------------------------------------------------------------
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|pop|linuxmint) echo "debian" ;;
      arch|manjaro|endeavouros)    echo "arch" ;;
      *)                           echo "unknown" ;;
    esac
  else
    echo "unknown"
  fi
}

# ---------------------------------------------------------------------------
# 1. Install system packages
# ---------------------------------------------------------------------------
install_packages_darwin() {
  if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew bundle --file="$(cd "$(dirname "$0")/.." && pwd)/Brewfile"
}

install_packages_debian() {
  sudo apt-get update
  sudo apt-get install -y \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    autoconf build-essential \
    curl wget rsync \
    direnv \
    entr \
    fd-find \
    fzf \
    gh \
    git \
    gnupg \
    htop \
    jq \
    libpq-dev libxslt1-dev libssl-dev libreadline-dev libwxgtk3.2-dev \
    luarocks \
    neovim \
    pkg-config \
    postgresql postgresql-client \
    ripgrep \
    shellcheck \
    tree \
    zoxide

  # zsh-you-should-use is not in Ubuntu repos — install from source if missing
  if [[ ! -d /usr/share/zsh-you-should-use ]]; then
    sudo git clone https://github.com/MichaelAqwortsms/zsh-you-should-use.git /usr/share/zsh-you-should-use
  fi

  # luacheck via luarocks
  if ! command -v luacheck &>/dev/null; then
    sudo luarocks install luacheck
  fi
}

install_packages_arch() {
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm \
    zsh zsh-autosuggestions zsh-syntax-highlighting \
    autoconf base-devel \
    curl wget rsync \
    direnv \
    entr \
    fd \
    fzf \
    github-cli \
    git \
    gnupg \
    htop \
    jq \
    libxslt openssl readline wxwidgets \
    luacheck \
    neovim \
    pkgconf \
    postgresql-libs \
    ripgrep \
    shellcheck \
    tree \
    zoxide

  # zsh-you-should-use is in AUR — install if yay is available
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm zsh-you-should-use
  elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm zsh-you-should-use
  else
    echo "Note: install zsh-you-should-use from AUR manually (yay -S zsh-you-should-use)"
  fi
}

# ---------------------------------------------------------------------------
# 2. Install mise (language version manager)
# ---------------------------------------------------------------------------
install_mise() {
  if ! command -v mise &>/dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

# ---------------------------------------------------------------------------
# 3. Install chezmoi
# ---------------------------------------------------------------------------
install_chezmoi() {
  if ! command -v chezmoi &>/dev/null; then
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
      brew install chezmoi
    else
      sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/bin"
      export PATH="$HOME/bin:$PATH"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

# 1Password setup (interactive — user must set up account and enable biometrics)
if [[ "$OS" == "Darwin" ]]; then
  open /System/Volumes/Data/Applications/1Password.app
else
  # On Linux, 1Password may be installed separately; just prompt
  echo "Ensure 1Password and the op CLI are installed and configured."
fi
read -rp "Set up account in 1Password app (and enable biometrics) [enter to continue]"

eval "$(op signin --account my.1password.com)"

# Install packages
if [[ "$OS" == "Darwin" ]]; then
  install_packages_darwin
else
  DISTRO="$(detect_distro)"
  case "$DISTRO" in
    debian) install_packages_debian ;;
    arch)   install_packages_arch ;;
    *)      echo "Unsupported distro. Install packages manually, then re-run."; exit 1 ;;
  esac
fi

# Install mise and chezmoi (on macOS these come from Homebrew; on Linux install standalone)
if [[ "$OS" != "Darwin" ]]; then
  install_mise
fi
install_chezmoi

# Apply dotfiles
chezmoi init gar --apply

# macOS-specific system preferences
if [[ "$OS" == "Darwin" ]]; then
  /bin/bash .macos
fi

# Install language runtimes
mise install

# Install Claude Code (requires node from mise)
npm install -g @anthropic-ai/claude-code

# Set zsh as default shell if it isn't already
if [[ "$SHELL" != */zsh ]]; then
  ZSH_PATH="$(command -v zsh)"
  if ! grep -qxF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi
  chsh -s "$ZSH_PATH"
fi

echo "Bootstrap complete. Restart your terminal (or log out and back in) to use zsh."

# On macOS, restart to apply system preferences
if [[ "$OS" == "Darwin" ]]; then
  sudo shutdown -r now
fi
