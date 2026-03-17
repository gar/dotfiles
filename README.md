# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Secrets (SSH keys, config) are stored in 1Password and injected at apply time via chezmoi templates.

## Prerequisites

- macOS **or** Linux (Ubuntu/Debian, Arch/Manjaro)
- [1Password](https://1password.com/) with the `op` CLI available

**macOS additionally requires:**
- [Homebrew](https://brew.sh/) installed (the bootstrap script will install it if missing)

## New Machine Setup

Run the bootstrap script to set up everything from scratch:

```bash
bash bin/executable_bootstrap.sh
```

### What it does

1. Open 1Password for account setup, then authenticate the `op` CLI
2. Install system packages:
   - **macOS:** Homebrew packages and casks (`Brewfile`)
   - **Ubuntu/Debian:** apt packages + luacheck via luarocks
   - **Arch/Manjaro:** pacman packages (+ AUR for `zsh-you-should-use`) **plus the full Hyprland desktop stack**
3. Install chezmoi and apply dotfiles (pulling secrets from 1Password)
4. **macOS only:** Apply system preferences (`.macos`)
5. Install language runtimes via [mise](https://mise.jdx.dev/) (Node, Erlang, Elixir, Python)
6. Set zsh as the default shell (if not already)
7. **macOS only:** Restart to apply system preferences

**Arch Linux additionally installs:** Hyprland, Waybar, Ghostty, rofi-wayland, swaync, PipeWire, Bluetooth, NetworkManager, SDDM, Intel iGPU drivers, screenshot tools, and applies the Intel PSR fix. See the [Hyprland setup](#hyprland-arch-linux) section below.

## Updating Dotfiles on an Existing Machine

Pull and apply the latest changes:

```bash
chezmoi update
```

This fetches the latest from the repo and re-applies all templates (including any updated 1Password secrets).

To preview what would change before applying:

```bash
chezmoi diff
```

## Editing Dotfiles

Edit a managed file through chezmoi so changes are tracked:

```bash
chezmoi edit ~/.zshrc
```

Then apply and push:

```bash
chezmoi apply
chezmoi cd  # opens a shell in the source directory
git add -A && git commit -m "update zshrc" && git push
```

## Managing Language Runtimes

Runtimes are defined in `~/.mise.toml` (source: `dot_mise.toml`) and managed by [mise](https://mise.jdx.dev/):

```bash
# Install all defined runtimes
mise install

# Add or change a runtime version
mise use node@20
```

## Managing Packages

**macOS:** Add packages to the `Brewfile`, then:

```bash
brew bundle
```

**Ubuntu/Debian:** Packages are installed via `apt-get` in the bootstrap script. To add new packages, edit the `install_packages_debian()` function in `bin/executable_bootstrap.sh`.

**Arch:** Packages are installed via `pacman` in the bootstrap script. To add new packages, edit the `install_packages_arch()` function in `bin/executable_bootstrap.sh`.

## CLI Tools

| Tool | Purpose |
|------|---------|
| `btop` | System monitor — CPU, memory, disk, network, processes with graphs and per-core view |
| `hyperfine` | Command benchmarking with statistics (mean/stddev, warmup runs, parameter sweeps) |
| `procs` | Modern `ps` replacement — color output, keyword search, process tree view |

**Example:** Compare test suite performance with hyperfine:

```bash
hyperfine 'mix test --stale' 'mix test'
```

## Testing

A test suite validates shell scripts, neovim config, and chezmoi templates. The same checks run locally and in CI.

### Run locally

```bash
# all checks
./bin/executable_test.sh

# single check (shellcheck | shell-syntax | lua-lint | nvim-startup | git-config | chezmoi-template)
./bin/executable_test.sh lua-lint
```

**Dependencies** (install the ones you need):

```bash
# macOS
brew install shellcheck luacheck neovim chezmoi

# Ubuntu/Debian
sudo apt-get install shellcheck lua-check neovim
# chezmoi: sh -c "$(curl -fsLS get.chezmoi.io)"

# Arch
sudo pacman -S shellcheck luacheck neovim chezmoi
```

### CI

GitHub Actions runs automatically on every pull request and push to `main`. The pipeline has five parallel jobs:

| Job | What it checks |
|---|---|
| **Lint** | `shellcheck` on shell scripts, `bash -n` / `zsh -n` syntax |
| **Lua lint** | `luacheck` on all neovim Lua files |
| **Neovim startup** | Headless `nvim` launch — catches broken plugin specs, bad keymaps, etc. |
| **Git config** | Renders and parses `dot_gitconfig.tmpl` to catch malformed config |
| **Chezmoi templates** | Renders every `.tmpl` file to verify template syntax |

No manual GitHub setup is required — the workflow runs automatically once `.github/workflows/ci.yml` is pushed.

## What's Included

| File | Purpose |
|---|---|
| `dot_zshrc.tmpl` | Zsh config (aliases, plugins, tool activation) — templated per OS |
| `dot_gitconfig.tmpl` | Git config (aliases, user info) |
| `dot_mise.toml` | Language runtime versions |
| `dot_macos` | macOS system preferences (skipped on Linux via `.chezmoiignore`) |
| `dot_config/nvim/` | Neovim config (LSP, completion, fuzzy find, floating terminal, etc.) |
| `dot_config/hypr/` | Hyprland compositor config (Linux/Arch only) |
| `dot_config/waybar/` | Waybar status bar config and Gruvbox Material styles |
| `dot_config/rofi/` | Rofi-wayland launcher config and Gruvbox Material theme |
| `dot_config/swaync/` | SwayNotificationCenter config and styles |
| `dot_config/ghostty/` | Ghostty terminal config with Gruvbox Material colours |
| `private_dot_ssh/` | SSH keys and config (populated from 1Password) |
| `Brewfile` | Homebrew packages and casks (macOS only) |
| `.chezmoiignore` | OS-conditional file exclusions |
| `bin/executable_bootstrap.sh` | Cross-platform machine bootstrap script |
| `bin/executable_test.sh` | Local test runner (same checks as CI) |
| `.github/workflows/ci.yml` | GitHub Actions CI pipeline |

## Shell Aliases

### Modern CLI Replacements

These modern tools are installed and aliased over their traditional counterparts:

| Alias | Replaces | Tool |
|-------|----------|------|
| `find` | `find` | [`fd`](https://github.com/sharkdp/fd) — faster, friendlier find |
| `grep` | `grep` | [`rg`](https://github.com/BurntSushi/ripgrep) — ripgrep, faster grep |
| `sd` | `sed` | [`sd`](https://github.com/chmln/sd) — simpler stream editor (accessed as `sd`) |

> **Note:** `sd` uses a different syntax from `sed` — it does not override `sed`. Use `sd 'old' 'new' file` or pipe: `echo 'hello' | sd 'hello' 'world'`.

### Git

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `glog` | `git log --oneline --decorate --graph` |
| `gp` | `git push` |
| `grb` | `git rebase` |
| `gst` | `git status` |
| `gsw` | `git switch` |
| `gswc` | `git switch -c` |

## Neovim Keymaps

Leader key is `Space`.

### Editor

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader>e` | normal | Toggle file explorer (netrw) |
| `<A-Up>` | normal | Increase window height |
| `<A-Down>` | normal | Decrease window height |
| `<A-Left>` | normal | Increase window width |
| `<A-Right>` | normal | Decrease window width |
| `J` | visual | Move selection down |
| `K` | visual | Move selection up |
| `p` | visual | Paste without overwriting clipboard |
| `<C-\>` | normal | Toggle floating terminal |

### Fuzzy Find (Telescope)

| Keymap | Mode | Action |
|--------|------|--------|
| `<C-p>` | normal | Find files |
| `<C-t>` | normal | Live grep |

### LSP

| Keymap | Mode | Action |
|--------|------|--------|
| `gd` | normal | Go to definition |
| `gD` | normal | Go to declaration |
| `gi` | normal | Go to implementation |
| `gr` | normal | Show references |
| `K` | normal | Hover documentation |
| `<C-k>` | normal | Signature help |
| `<leader>rn` | normal | Rename symbol |
| `<leader>ca` | normal | Code action |
| `<leader>f` | normal | Open diagnostic float |
| `<leader>q` | normal | Diagnostics to location list |
| `[d` / `]d` | normal | Previous / next diagnostic |
| `gl` | normal | Line diagnostics |
| `:Format` | command | Format buffer via LSP |

### Git Worktrees

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader>gwl` | normal | List and switch between worktrees (Telescope) |
| `<leader>gwc` | normal | Create a new worktree from a branch (Telescope) |

Shell aliases:

| Alias | Command |
|-------|---------|
| `gwl` | `git worktree list` |
| `gwa` | `git worktree add <path> <branch>` |
| `gwd` | `git worktree remove <path>` |
| `gwp` | `git worktree prune` |

### Claude Code (AI)

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader>ac` | normal | Toggle Claude Code panel |
| `<leader>af` | normal | Focus Claude Code panel |
| `<leader>ar` | normal | Resume last Claude session |
| `<leader>aa` | normal | Add current file to Claude context |
| `<leader>as` | visual | Send selection to Claude |
| `<leader>dy` | normal | Accept Claude-proposed diff |
| `<leader>dn` | normal | Reject Claude-proposed diff |

**Workflow:** Select code in visual mode → `<leader>as` to send to Claude → type your instruction in the panel → accept or reject proposed changes with `<leader>dy` / `<leader>dn`.

**Worktrees + Claude Code:** Run `claude --worktree <name>` in a terminal to start an isolated Claude session on its own branch. Use `<leader>gwl` to switch between worktree directories in Neovim. Multiple worktrees let you run parallel Claude sessions without conflicts.

## Shell Aliases

### Modern CLI tools

| Alias | Replaces | Notes |
|-------|----------|-------|
| `ls` | `ls` | `eza --icons` — color-coded, Nerd Font icons |
| `ll` | `ls -la` | `eza -la --icons --git` — long list with git status per file |
| `cat` | `cat` | `bat` — syntax highlighting, line numbers, git diff markers |

`man` pages are also rendered via `bat` for syntax-highlighted output.

`broot` provides an interactive tree explorer with fuzzy search. Run `broot --install` once after install to enable the `br` shell function (`br` lets you `cd` on exit; plain `broot` does not).

### Git

| Alias | Command |
|-------|---------|
| `g` | `git` |
| `ga` | `git add` |
| `gaa` | `git add --all` |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `glog` | `git log --oneline --decorate --graph` |
| `gp` | `git push` |
| `grb` | `git rebase` |
| `gst` | `git status` |
| `gsw` | `git switch` |
| `gswc` | `git switch -c` |

## Habit Training

### Zsh — `zsh-you-should-use`

When you type a command that has a shell alias defined, you'll see a reminder after it runs:

```
Found existing alias for "git status". You should use: gst
```

This fires for all aliases in `dot_zshrc.tmpl` (git, worktree, etc.).

### Neovim — `hardtime.nvim`

When you press `h`/`j`/`k`/`l` (or the arrow keys) more than 4 times in quick succession, a hint appears suggesting a more efficient motion — a count prefix, `w`/`b`/`e`/`f`/`t`, a jump (`ctrl-d`/`ctrl-u`), or a search.

Configured in `hint` mode: the keypress still registers, you just get nudged. To switch to blocking mode (the key is swallowed until you use a better motion), set `restriction_mode = "block"` in `dot_config/nvim/lua/features/hardtime.lua`.

## Hyprland (Arch Linux)

A full keyboard-driven Wayland desktop, handcrafted — no ML4W, HyDE, or other frameworks. All colours are Gruvbox Material (medium background, material foreground), defined inline without external theme packages.

### Arch setup process

Running `bin/executable_bootstrap.sh` on Arch does the following, in order:

1. **Base packages** — installs the standard CLI tools shared with other platforms (zsh, neovim, git, ripgrep, fzf, etc.) via `pacman`
2. **AUR helper check** — uses `yay` or `paru` if available for AUR packages
3. **Hyprland stack** — installs the full desktop environment (compositor, bar, terminal, audio, network, display manager — see components below) via `pacman` and AUR
4. **Intel iGPU drivers** — installs both VA-API driver variants so the right one can be selected at runtime (see [Intel iGPU notes](#intel-igpu-notes))
5. **System services** — enables `NetworkManager`, `bluetooth`, and `sddm` via systemd; enables PipeWire user services
6. **PSR fix** — writes `options i915 enable_psr=0` to `/etc/modprobe.d/i915.conf` and rebuilds the initramfs to eliminate Intel iGPU flickering under Wayland
7. **Dotfiles** — chezmoi applies all configs including the Hyprland, Waybar, Rofi, swaync, and Ghostty configs from this repo
8. **Language runtimes** — mise installs Node, Erlang, Elixir, and Python

After bootstrap completes, reboot and select **Hyprland** at the SDDM login screen.

### Components

Every package is from the official Arch `[extra]` repo unless marked AUR.

#### Compositor layer

| Component | Package | Role |
|---|---|---|
| **Compositor** | `hyprland` | The Wayland compositor itself. Manages windows, workspaces, animations, input, and output. Replaces a traditional window manager + display server. Config lives in `~/.config/hypr/hyprland.conf`. |
| **XDG portal** | `xdg-desktop-portal-hyprland` | Implements the XDG desktop portal spec for Hyprland. Required for screen sharing, file picker dialogs, and sandboxed app permissions (Flatpak, browsers). Without this, screenshare in video calls will not work. |
| **Polkit agent** | `hyprpolkitagent` | Handles privilege escalation prompts (e.g. mounting a drive, installing a system package from a GUI). When an app needs `sudo`-level access it asks polkit, which pops a graphical password dialog via this agent. |
| **XWayland** | `xorg-xwayland` | Compatibility layer that lets X11 apps run inside the Wayland session. Most apps are native Wayland now, but some older tools (certain Electron apps, Java GUIs) still need this. |

#### Session management

| Component | Package | Role |
|---|---|---|
| **Display manager** | `sddm` | Greeter shown at boot before login. Launches the Hyprland session. Handles multi-user and session switching. |
| **Lock screen** | `hyprlock` | GPU-accelerated lock screen. Triggered by `hypridle` on timeout or manually. Shows a clock, date, and password field. Config: `~/.config/hypr/hyprlock.conf`. |
| **Idle daemon** | `hypridle` | Watches for inactivity and fires actions at configurable timeouts: dim the screen at 2.5 min, lock at 5 min, turn display off at 5.5 min, suspend at 30 min. Config: `~/.config/hypr/hypridle.conf`. |

#### UI shell

| Component | Package | Role |
|---|---|---|
| **Status bar** | `waybar` | Top bar showing workspaces, active window title, clock, battery, volume, network, and notifications. Driven by a JSON module config and a CSS stylesheet, both themed with Gruvbox Material colours. Config: `~/.config/waybar/`. |
| **App launcher** | `rofi-wayland` | Keyboard-driven launcher for apps (`Super+Space`), commands (`Super+Shift+Space`), open windows, emoji, and clipboard history. Configured and themed entirely in `~/.config/rofi/config.rasi` — no external theme files. |
| **Notifications** | `swaync` | Notification daemon and slide-out notification centre. Receives desktop notifications from apps, stacks them in a history panel (`Super+N`), and supports Do Not Disturb. Integrates with the Waybar bell icon. Config: `~/.config/swaync/`. |
| **Wallpaper** | `hyprpaper` | Lightweight wallpaper setter. Loads images into memory at startup and sets them per monitor. IPC lets you change wallpapers without restarting. Config: `~/.config/hypr/hyprpaper.conf` — add your image path there. |

#### Terminal

| Component | Package | Role |
|---|---|---|
| **Terminal** | `ghostty` | Primary terminal emulator. GPU-accelerated, GTK4-native, zero-config on Linux. Configured with JetBrains Mono Nerd Font and Gruvbox Material colours defined inline. `gtk-titlebar = false` tells it to let Hyprland draw the window border. Config: `~/.config/ghostty/config`. |
| **File manager (TUI)** | `yazi` | Keyboard-driven terminal file manager (Rust). Image previews, vim keybindings, fast directory traversal. For day-to-day file operations inside the terminal. |
| **File manager (GUI)** | `thunar` | GTK file manager for drag-and-drop, USB mount dialogs, and bulk rename. `thunar-volman` + `gvfs` handle automounting removable media. |

#### Audio

| Component | Package | Role |
|---|---|---|
| **Audio server** | `pipewire` | Modern audio/video routing layer. Replaces PulseAudio and JACK simultaneously. Handles all audio hardware access, routing between apps, and Bluetooth audio. |
| **Session manager** | `wireplumber` | Policy engine that sits on top of PipeWire. Decides which device to use, manages routing rules, and handles device hotplug. Required for PipeWire to function correctly. |
| **PulseAudio compat** | `pipewire-pulse` | Drop-in replacement for the PulseAudio socket. Lets apps that talk PulseAudio (most apps) work with PipeWire without any changes. |
| **Volume control** | `pamixer` | CLI tool for adjusting volume. Used by the Hyprland volume key bindings (`XF86AudioRaiseVolume` etc.). `pavucontrol` is also installed as a GUI mixer, available via the `Super+V` scratchpad. |

#### Input / clipboard / screenshots

| Component | Package | Role |
|---|---|---|
| **Clipboard manager** | `wl-clipboard` + `cliphist` | `wl-clipboard` provides `wl-copy`/`wl-paste` for Wayland clipboard access. `cliphist` watches the clipboard and stores every copied item persistently. Browse and paste from history with `Super+Shift+V`. |
| **Screenshot** | `grim` + `slurp` | `grim` captures Wayland output; `slurp` provides an interactive region selector. Together: `grim -g "$(slurp)"` captures a selected region. Bound to `Print`. |
| **Screenshot editor** | `swappy` | Receives the screenshot from grim and opens a lightweight annotation/crop tool before saving. |

#### Networking and hardware

| Component | Package | Role |
|---|---|---|
| **Network** | `networkmanager` + `network-manager-applet` | NetworkManager manages Wi-Fi and wired connections. The applet (`nm-applet`) provides a system tray icon and the `nm-connection-editor` GUI for managing saved networks. |
| **Bluetooth** | `bluez` + `bluez-utils` + `blueman` | `bluez` is the Linux Bluetooth stack; `bluez-utils` provides `bluetoothctl` for CLI pairing; `blueman` is the GUI manager opened from the Waybar Bluetooth icon. |
| **Backlight** | `brightnessctl` | Controls screen brightness via the kernel backlight interface. Used by `XF86MonBrightnessUp/Down` keybindings in Hyprland. |
| **Media controls** | `playerctl` | Sends play/pause/next/previous commands to any MPRIS-compatible media player (Spotify, browsers, etc.). Used by the `XF86Audio*` media key bindings. |

#### Intel iGPU drivers

| Component | Package | Role |
|---|---|---|
| **Mesa** | `mesa` | Open-source OpenGL/Vulkan implementation. For Haswell (4th gen), Mesa uses the Crocus Gallium3D driver; for Broadwell+ it uses Iris. Hyprland uses GLES2 via Mesa. |
| **VA-API (Haswell)** | `libva-intel-driver` | Hardware video decode for Haswell (4th gen, `i965` backend). Required for accelerated H.264/HEVC decode in browsers and video players on 4th-gen Intel. |
| **VA-API (Broadwell+)** | `intel-media-driver` | Hardware video decode for Broadwell and newer (`iHD` backend). Actively maintained; the correct choice for 5th-gen Core and later. |
| **Vulkan** | `vulkan-intel` | Intel Vulkan driver (HASVK). Incomplete on Haswell but not used by Hyprland — included for Vulkan-using apps. |
| **Diagnostics** | `intel-gpu-tools` + `libva-utils` | `intel_gpu_top` monitors GPU load in real time; `vainfo` lists the supported VA-API decode profiles to confirm the driver is working. |

#### Theming

| Component | Package | Role |
|---|---|---|
| **GTK theme** | `gruvbox-material-gtk-theme-git` (AUR) | Applies Gruvbox Material colours to GTK3/4 apps (file dialogs, Thunar, etc.). Set via `gsettings` on startup. |
| **Icon theme** | `papirus-icon-theme` | App icons in Rofi, Thunar, and the notification centre. |
| **GTK settings** | `nwg-look` | Wayland-compatible replacement for `lxappearance`. GUI for selecting GTK theme, icons, fonts, and cursor. |
| **Qt theming** | `qt5ct` + `qt6ct` + `kvantum` | Makes Qt apps respect the current theme. `qt5ct`/`qt6ct` set the platform theme; Kvantum applies a matching style engine. Set via `QT_QPA_PLATFORMTHEME=qt6ct`. |

### Hyprland keymaps

`$mainMod` = `Super` (Windows key).

#### Applications

| Keybind | Action |
|---|---|
| `Super + Return` | Open Ghostty terminal |
| `Super + E` | Open Thunar file manager |
| `Super + Space` | Rofi app launcher |
| `Super + Shift + Space` | Rofi run prompt |
| `Super + .` | Rofi emoji picker |
| `Super + Shift + V` | Clipboard history (cliphist → rofi) |
| `Print` | Screenshot selection → swappy |
| `Shift + Print` | Screenshot full screen → swappy |
| `Super + N` | Toggle notification centre (swaync) |

#### Window management

| Keybind | Action |
|---|---|
| `Super + Q` | Close active window |
| `Super + F` | Fullscreen |
| `Super + Shift + F` | Maximise (no gaps) |
| `Super + T` | Toggle floating |
| `Super + P` | Pseudotile |
| `Super + X` | Pin (keep on top across workspaces) |
| `Super + G` | Toggle window group (tabbed) |
| `Super + Tab` | Next window in group |
| `Super + Shift + Tab` | Previous window in group |

#### Focus and movement (vim keys)

| Keybind | Action |
|---|---|
| `Super + H/J/K/L` | Move focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move window left/down/up/right |
| `Super + R` | Enter resize submap |
| `H/J/K/L` (in resize) | Resize window |
| `Escape` / `Enter` (in resize) | Exit resize submap |

#### Workspaces

| Keybind | Action |
|---|---|
| `Super + 1–0` | Switch to workspace 1–10 |
| `Super + Shift + 1–0` | Move window to workspace 1–10 |
| `Super + mouse scroll` | Cycle workspaces |
| `Super + mouse drag` | Move window |
| `Super + right-click drag` | Resize window |

#### Scratchpads

| Keybind | Action |
|---|---|
| `Super + S` | Toggle general scratchpad (Ghostty) |
| `Super + Shift + S` | Move window to scratchpad |
| `Super + V` | Toggle volume mixer scratchpad (pavucontrol) |

#### Hardware

| Keybind | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up 5% |
| `XF86AudioLowerVolume` | Volume down 5% |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioPlay/Next/Prev` | Media controls |
| `XF86MonBrightnessUp/Down` | Backlight ±5% |

### Intel iGPU notes

The bootstrap script automatically applies the Panel Self Refresh (PSR) fix (`options i915 enable_psr=0` in `/etc/modprobe.d/i915.conf`) and rebuilds the initramfs. PSR causes flickering on nearly all Intel iGPUs under Wayland.

**VA-API driver selection** — set `LIBVA_DRIVER_NAME` in `dot_config/hypr/hyprland.conf`:
- `i965` — Haswell (4th gen, HD 4000/4600)
- `iHD` — Broadwell (5th gen, HD 5500) and newer

Run `vainfo` after first boot to confirm the driver is working.

**Blur and shadows are disabled** in the Hyprland config. On Haswell iGPUs, blur alone can drive ~25% idle GPU load; disabling it keeps the compositor near zero while keeping smooth animations. `vfr = true` ensures frames are only rendered when content changes, which is the biggest battery-life improvement.

## OS Support

| Feature | macOS | Ubuntu/Debian | Arch/Manjaro |
|---|---|---|---|
| Package installation | Homebrew | apt | pacman |
| Zsh plugins | Homebrew | apt + git clone | pacman + AUR |
| macOS preferences | Yes | Skipped | Skipped |
| Hyprland desktop | No | No | Yes |
| Neovim config | Yes | Yes | Yes |
| SSH keys (1Password) | Yes | Yes | Yes |
| Language runtimes (mise) | Yes | Yes | Yes |
