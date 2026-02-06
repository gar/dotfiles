# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Secrets (SSH keys, config) are stored in 1Password and injected at apply time via chezmoi templates.

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/) installed
- [1Password](https://1password.com/) with the `op` CLI available

## New Machine Setup

Run the bootstrap script to set up everything from scratch:

```bash
bash bin/executable_bootstrap.sh
```

This will, in order:

1. Install Oh-My-Zsh
2. Open 1Password for account setup, then authenticate the `op` CLI
3. Install chezmoi and apply dotfiles (pulling secrets from 1Password)
4. Apply macOS system preferences (`.macos`)
5. Install all Homebrew packages and casks (`Brewfile`)
6. Install language runtimes via [mise](https://mise.jdx.dev/) (Node, Erlang, Elixir, Go, Python, Lua)
7. Restart

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

## Managing Brew Packages

Add packages to the `Brewfile`, then:

```bash
brew bundle
```

## What's Included

| File | Purpose |
|---|---|
| `dot_zshrc` | Zsh config (oh-my-zsh, aliases, tool activation) |
| `dot_gitconfig.tmpl` | Git config (delta, aliases, user info) |
| `dot_mise.toml` | Language runtime versions |
| `dot_macos` | macOS system preferences |
| `dot_config/nvim/` | Neovim config (LSP, completion, fuzzy find, etc.) |
| `private_dot_ssh/` | SSH keys and config (populated from 1Password) |
| `Brewfile` | Homebrew packages, casks, and Mac App Store apps |
| `bin/executable_bootstrap.sh` | Full machine bootstrap script |
