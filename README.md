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
   - **Arch/Manjaro:** pacman packages (+ AUR for `zsh-you-should-use`)
3. Install chezmoi and apply dotfiles (pulling secrets from 1Password)
4. **macOS only:** Apply system preferences (`.macos`)
5. Install language runtimes via [mise](https://mise.jdx.dev/) (Node, Erlang, Elixir, Python)
6. Set zsh as the default shell (if not already)
7. **macOS only:** Restart to apply system preferences

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
| `dot_config/nvim/` | Neovim config (LSP, completion, fuzzy find, etc.) |
| `private_dot_ssh/` | SSH keys and config (populated from 1Password) |
| `Brewfile` | Homebrew packages and casks (macOS only) |
| `.chezmoiignore` | OS-conditional file exclusions |
| `bin/executable_bootstrap.sh` | Cross-platform machine bootstrap script |
| `bin/executable_test.sh` | Local test runner (same checks as CI) |
| `.github/workflows/ci.yml` | GitHub Actions CI pipeline |

## OS Support

| Feature | macOS | Ubuntu/Debian | Arch/Manjaro |
|---|---|---|---|
| Package installation | Homebrew | apt | pacman |
| Zsh plugins | Homebrew | apt + git clone | pacman + AUR |
| macOS preferences | Yes | Skipped | Skipped |
| Neovim config | Yes | Yes | Yes |
| SSH keys (1Password) | Yes | Yes | Yes |
| Language runtimes (mise) | Yes | Yes | Yes |
