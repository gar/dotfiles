#!/bin/bash
# TODO: `-v` echoes every command to stderr, producing noisy output for a user-facing
# setup script. Drop `-v` (keep `-euo pipefail`) unless verbose tracing is intentional;
# if it is, switch to `-x` behind a DEBUG env var.
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
    zsh zsh-autosuggestions \
    autoconf build-essential \
    curl wget rsync \
    direnv \
    unzip \
    bat \
    pipx \
    broot \
    entr \
    fd-find \
    hexyl \
    fzf \
    gh \
    pipx \
    git \
    gnupg \
    btop \
    hyperfine \
    procs \
    jq \
    libpq-dev libxslt1-dev libssl-dev libreadline-dev libwxgtk3.2-dev \
    luarocks \
    neovim \
    pkg-config \
    postgresql postgresql-client \
    ripgrep \
    sd \
    shellcheck \
    tree \
    tree-sitter \
    zoxide

  # eza is available in Ubuntu 24.04+ — skip silently on older releases
  if apt-cache show eza &>/dev/null 2>&1; then
    sudo apt-get install -y eza
  else
    echo "Note: eza not available via apt. Install manually: https://github.com/eza-community/eza/releases"
  fi

  # zsh-you-should-use is not in Ubuntu repos — install from source if missing
  if [[ ! -d /usr/share/zsh-you-should-use ]]; then
    sudo git clone https://github.com/MichaelAqwortsms/zsh-you-should-use.git /usr/share/zsh-you-should-use
  fi

  # fast-syntax-highlighting is not in Ubuntu repos — install from source if missing
  if [[ ! -d /usr/share/zsh/plugins/fast-syntax-highlighting ]]; then
    sudo git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git /usr/share/zsh/plugins/fast-syntax-highlighting
  fi

  # luacheck via luarocks
  if ! command -v luacheck &>/dev/null; then
    sudo luarocks install luacheck
  fi
}

install_packages_arch() {
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm \
    zsh zsh-autosuggestions \
    autoconf base-devel \
    curl wget rsync \
    direnv \
    unzip \
    bat \
    broot \
    entr \
    eza \
    fd \
    hexyl \
    fzf \
    github-cli \
    python-pipx \
    git \
    gnupg \
    btop \
    hyperfine \
    procs \
    jq \
    libxslt openssl readline wxwidgets \
    luacheck \
    neovim \
    pkgconf \
    postgresql-libs \
    ripgrep \
    sd \
    shellcheck \
    tree \
    tree-sitter \
    zoxide

  # AUR packages (zsh-you-should-use, zsh-fast-syntax-highlighting)
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm zsh-you-should-use zsh-fast-syntax-highlighting
  elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm zsh-you-should-use zsh-fast-syntax-highlighting
  else
    echo "Note: install from AUR manually (yay -S zsh-you-should-use zsh-fast-syntax-highlighting)"
  fi
}

# ---------------------------------------------------------------------------
# 2. Install Python CLI tools via pipx
# ---------------------------------------------------------------------------
install_python_tools() {
  if command -v pipx &>/dev/null; then
    # TODO: `2>/dev/null || true` silently swallows all failures — including real
    # errors like pipx misconfig or a broken Python install. Distinguish "already
    # installed" (ok) from other failures: check `pipx list` first, or grep stderr
    # for the already-installed message and only then suppress.
    pipx install termgraph 2>/dev/null || true
    pipx install td-watson 2>/dev/null || true
  else
    echo "Note: pipx not found — install manually: pipx install termgraph td-watson"
  fi
}

# ---------------------------------------------------------------------------
# 3. Install JetBrains Mono Nerd Font (Linux only — macOS uses Homebrew cask)
# ---------------------------------------------------------------------------
install_jetbrains_mono_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  if [[ ! -d "$font_dir" ]]; then
    local version="3.2.1"
    local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/JetBrainsMono.zip"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    curl -fsSL "$url" -o "$tmp_dir/JetBrainsMono.zip"
    mkdir -p "$font_dir"
    unzip -q "$tmp_dir/JetBrainsMono.zip" -d "$font_dir"
    rm -rf "$tmp_dir"
    fc-cache -fv "$font_dir"
  fi
}

# ---------------------------------------------------------------------------
# 3. Install broot shell launcher
# ---------------------------------------------------------------------------
install_broot_launcher() {
  if command -v broot &>/dev/null && [[ ! -f "$HOME/.config/broot/launcher/bash/1" ]]; then
    printf 'y\n' | broot --install
  fi
}

# ---------------------------------------------------------------------------
# 4. Install mise (language version manager)
# ---------------------------------------------------------------------------
install_mise() {
  if ! command -v mise &>/dev/null; then
    # TODO: `curl | sh` silently swallows network/HTTP failures. Use `curl -fsSL`
    # so HTTP errors exit non-zero, and verify `$HOME/.local/bin/mise` exists after
    # the install before proceeding. Currently a failed install falls through to
    # `mise install` at the bottom of the script with a confusing error.
    curl https://mise.jdx.dev/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

# ---------------------------------------------------------------------------
# 6. Install chezmoi
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

# TODO: `op` may not be installed at this point on Linux (it's documented as a
# prerequisite but not enforced). Gate this behind `command -v op &>/dev/null` and
# emit a clear error telling the user to install the 1Password CLI before re-running,
# rather than failing with a raw shell error.
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

# Install JetBrains Mono Nerd Font (Linux only; macOS gets it via Brewfile cask)
if [[ "$OS" != "Darwin" ]]; then
  install_jetbrains_mono_nerd_font
fi

# Install Python CLI tools via pipx (all platforms)
install_python_tools

# Install broot shell launcher (enables the 'br' cd-on-exit function)
install_broot_launcher

# Install mise and chezmoi (on macOS these come from Homebrew; on Linux install standalone)
if [[ "$OS" != "Darwin" ]]; then
  install_mise
fi
install_chezmoi

# Apply dotfiles
chezmoi init gar --apply

# macOS-specific system preferences
if [[ "$OS" == "Darwin" ]]; then
  # TODO: `.macos` is a relative path — this fails when the script is invoked from
  # any directory other than the repo root. Use the absolute-path pattern already
  # used at line 30 for the Brewfile:
  #   /bin/bash "$(cd "$(dirname "$0")/.." && pwd)/.macos"
  /bin/bash .macos
fi

# Install language runtimes
mise install

# TODO: `mise install` only downloads runtimes into mise's data dir — it does NOT
# activate them in this shell, so `npm` is not on PATH here and the next line fails
# on a truly fresh machine. Either prepend `mise exec --` (`mise exec -- npm install
# -g @anthropic-ai/claude-code`) or source `eval "$(mise activate bash)"` before
# running npm.
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
