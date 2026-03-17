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
    zsh zsh-autosuggestions \
    autoconf build-essential \
    curl wget rsync \
    direnv \
    unzip \
    bat \
    broot \
    entr \
    fd-find \
    fzf \
    gh \
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
    fzf \
    github-cli \
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
# Arch: Hyprland desktop environment (Wayland, Dell laptop)
# ---------------------------------------------------------------------------
install_hyprland_arch() {
  # Core Hyprland compositor + first-party ecosystem (all in [extra])
  sudo pacman -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    hyprpolkitagent \
    hyprpaper \
    hyprlock \
    hypridle \
    hyprpicker \
    hyprsunset \
    hyprcursor

  # Status bar, launcher, notifications
  sudo pacman -S --needed --noconfirm \
    waybar \
    rofi-wayland \
    swaync

  # Terminal + file managers
  sudo pacman -S --needed --noconfirm \
    ghostty \
    yazi \
    thunar thunar-volman gvfs tumbler

  # Audio (PipeWire stack)
  sudo pacman -S --needed --noconfirm \
    pipewire wireplumber pipewire-audio pipewire-pulse \
    pamixer

  # Bluetooth
  sudo pacman -S --needed --noconfirm \
    bluez bluez-utils blueman

  # Network
  sudo pacman -S --needed --noconfirm \
    networkmanager network-manager-applet

  # Clipboard + screenshots
  sudo pacman -S --needed --noconfirm \
    wl-clipboard cliphist \
    grim slurp swappy \
    libnotify

  # Display manager + Qt Wayland + XWayland compatibility
  sudo pacman -S --needed --noconfirm \
    sddm \
    qt5-wayland qt6-wayland \
    xorg-xwayland

  # Fonts (JetBrains Mono Nerd is installed separately on Linux; add extras here)
  sudo pacman -S --needed --noconfirm \
    inter-font \
    noto-fonts noto-fonts-emoji \
    ttf-jetbrains-mono-nerd

  # Theming tools + icons + hardware control
  sudo pacman -S --needed --noconfirm \
    nwg-look \
    qt5ct qt6ct kvantum \
    papirus-icon-theme \
    brightnessctl playerctl

  # Intel iGPU — installs both VA-API drivers; LIBVA_DRIVER_NAME in hyprland.conf
  # picks the right one at runtime (i965 for Haswell, iHD for Broadwell+).
  sudo pacman -S --needed --noconfirm \
    mesa \
    libva-intel-driver \
    intel-media-driver \
    vulkan-intel \
    intel-gpu-tools \
    libva-utils \
    libvdpau-va-gl

  # AUR: Gruvbox Material GTK theme + grimblast screenshot helper
  local aur_helper=""
  if command -v yay &>/dev/null; then
    aur_helper="yay"
  elif command -v paru &>/dev/null; then
    aur_helper="paru"
  fi

  if [[ -n "$aur_helper" ]]; then
    "$aur_helper" -S --needed --noconfirm \
      gruvbox-material-gtk-theme-git \
      grimblast-git \
      flavours
  else
    echo "Note: install AUR packages manually:"
    echo "  yay -S gruvbox-material-gtk-theme-git grimblast-git flavours"
  fi

  # Enable system services
  sudo systemctl enable --now NetworkManager
  sudo systemctl enable --now bluetooth
  sudo systemctl enable sddm

  # Enable user services (PipeWire starts via socket activation automatically)
  systemctl --user enable --now pipewire pipewire-pulse wireplumber

  # Apply i915 PSR fix — Panel Self Refresh causes flickering on Intel iGPUs
  if [[ ! -f /etc/modprobe.d/i915.conf ]]; then
    echo "options i915 enable_psr=0" | sudo tee /etc/modprobe.d/i915.conf
    sudo mkinitcpio -P
    echo "PSR fix applied — reboot required."
  fi

  echo "Hyprland stack installed. Reboot and select Hyprland at the SDDM login screen."
}

# ---------------------------------------------------------------------------
# 2. Apply colour scheme via flavours (Arch/Hyprland only)
# ---------------------------------------------------------------------------
apply_flavours_theme() {
  if ! command -v flavours &>/dev/null; then
    echo "Note: flavours not installed — skipping colour scheme application"
    return
  fi

  local flavours_data="$HOME/.local/share/flavours/base16"
  local flavours_cfg="$HOME/.config/flavours"

  # Link the bundled scheme into flavours's data directory
  mkdir -p "$flavours_data/schemes/gruvbox-material"
  if [[ ! -L "$flavours_data/schemes/gruvbox-material/gruvbox-material.yaml" ]]; then
    ln -sf "$flavours_cfg/schemes/gruvbox-material/gruvbox-material.yaml" \
           "$flavours_data/schemes/gruvbox-material/gruvbox-material.yaml"
  fi

  # Link each bundled template into flavours's data directory
  for tpl in waybar rofi swaync hyprland; do
    mkdir -p "$flavours_data/templates/$tpl/templates"
    if [[ ! -L "$flavours_data/templates/$tpl/templates/colors.mustache" ]]; then
      ln -sf "$flavours_cfg/templates/$tpl/templates/colors.mustache" \
             "$flavours_data/templates/$tpl/templates/colors.mustache"
    fi
  done

  flavours apply gruvbox-material
}

# ---------------------------------------------------------------------------
# 4. Install JetBrains Mono Nerd Font (Linux only — macOS uses Homebrew cask)
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
# 5. Install broot shell launcher
# ---------------------------------------------------------------------------
install_broot_launcher() {
  if command -v broot &>/dev/null && [[ ! -f "$HOME/.config/broot/launcher/bash/1" ]]; then
    printf 'y\n' | broot --install
  fi
}

# ---------------------------------------------------------------------------
# 6. Install mise (language version manager)
# ---------------------------------------------------------------------------
install_mise() {
  if ! command -v mise &>/dev/null; then
    curl https://mise.jdx.dev/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi
}

# ---------------------------------------------------------------------------
# 7. Install chezmoi
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
    arch)
      install_packages_arch
      install_hyprland_arch
      ;;
    *) echo "Unsupported distro. Install packages manually, then re-run."; exit 1 ;;
  esac
fi

# Install JetBrains Mono Nerd Font (Linux only; macOS gets it via Brewfile cask)
if [[ "$OS" != "Darwin" ]]; then
  install_jetbrains_mono_nerd_font
fi

# Install broot shell launcher (enables the 'br' cd-on-exit function)
install_broot_launcher

# Install mise and chezmoi (on macOS these come from Homebrew; on Linux install standalone)
if [[ "$OS" != "Darwin" ]]; then
  install_mise
fi
install_chezmoi

# Apply dotfiles
chezmoi init gar --apply

# Apply colour scheme (Arch/Hyprland only — flavours installed above)
if [[ "$(detect_distro)" == "arch" ]]; then
  apply_flavours_theme
fi

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
