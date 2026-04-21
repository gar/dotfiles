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
6. Fetch the latest [Expert Elixir LSP](https://github.com/elixir-lang/expert) release into `~/bin/expert`
7. Set zsh as the default shell (if not already)
8. **macOS only:** Restart to apply system preferences

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

## Machine-local Config

Some settings belong to a specific machine (work tools, private plugins, local LSP servers) and should not be committed to a public repo. Two escape hatches are provided for this:

### Neovim

Create `~/.config/nvim/lua/local.lua`. This file is loaded automatically at startup if it exists. It is never created or overwritten by chezmoi.

Use it to register extra LSP servers, override settings, or load private plugins:

```lua
-- ~/.config/nvim/lua/local.lua  (not in git)
vim.lsp.config('my-private-lsp', {
  cmd = { 'my-lsp', 'lsp' },
  root_markers = { '.git', 'mix.exs' },
  filetypes = { 'elixir', 'eelixir' },
})
vim.lsp.enable 'my-private-lsp'
```

Any valid Neovim Lua is fine here — the file runs after all plugins are loaded.

### mise

`~/.mise.local.toml` sits next to the chezmoi-managed `~/.mise.toml` and is never touched by chezmoi. Use it for machine-specific tools and plugins from internal or private registries:

```toml
# ~/.mise.local.toml  (not in git)
[plugins]
my-private-tool = "git@github.com:my-org/mise-my-private-tool.git"

[tools]
my-private-tool = "latest"
```

The `[plugins]` section registers a plugin from a custom git URL — equivalent to `mise plugin add <name> <url>`. mise merges this file with `~/.mise.toml` at runtime.

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
| `termgraph` | Draw bar charts and sparklines from piped data — `value,label` CSV format |
| `hexyl` | Hex viewer — colorized, human-readable `xxd` replacement (`xxd` is aliased to `hexyl`) |
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

# single check (shellcheck | shell-syntax | lua-lint | nvim-startup | git-config | chezmoi-template | secret-scan)
./bin/executable_test.sh lua-lint
```

**Dependencies** (install the ones you need):

```bash
# macOS
brew install shellcheck luacheck neovim chezmoi gitleaks

# Ubuntu/Debian
sudo apt-get install shellcheck lua-check neovim
# chezmoi:  sh -c "$(curl -fsLS get.chezmoi.io)"
# gitleaks: download from https://github.com/gitleaks/gitleaks/releases

# Arch
sudo pacman -S shellcheck luacheck neovim chezmoi gitleaks
```

The `secret-scan` check is skipped locally if `gitleaks` isn't installed, so it's safe to run the full suite without it — CI will still enforce the scan on every PR.

### CI

GitHub Actions runs automatically on every pull request and push to `main`. The pipeline has six parallel jobs:

| Job | What it checks |
|---|---|
| **Lint** | `shellcheck` on shell scripts, `bash -n` / `zsh -n` syntax |
| **Lua lint** | `luacheck` on all neovim Lua files |
| **Neovim startup** | Headless `nvim` launch — catches broken plugin specs, bad keymaps, etc. |
| **Git config** | Renders and parses `dot_gitconfig.tmpl` to catch malformed config |
| **Chezmoi templates** | Renders every `.tmpl` file to verify template syntax |
| **Secret scan** | `gitleaks` over the full git history — fails the build if an API key, token, password, or similar secret is detected. Output is `--redact`ed so secrets never appear in logs. |

No manual GitHub setup is required — the workflow runs automatically once `.github/workflows/ci.yml` is pushed.

## What's Included

| File | Purpose |
|---|---|
| `dot_zshrc.tmpl` | Zsh config (aliases, plugins, tool activation) — templated per OS |
| `dot_gitconfig.tmpl` | Git config (aliases, user info) |
| `dot_mise.toml` | Language runtime versions |
| `dot_macos` | macOS system preferences (skipped on Linux via `.chezmoiignore`) |
| `dot_config/nvim/` | Neovim config (LSP, completion, fuzzy find, floating terminal, etc.) |
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
| `gap` | `git add -p` (interactive patch) |
| `gbr` | `git branch` (formatted with date + author) |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `glog` | `git log --oneline --decorate --graph` |
| `gp` | `git push` |
| `gpu` | `git push -u` (push and set upstream) |
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
| `p` | visual | Paste without overwriting clipboard |
| `<C-\>` | normal | Toggle floating terminal |

### Fuzzy Find (Telescope)

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader><space>` | normal | Find files (alternative) |
| `<leader>ff` | normal | Find files |
| `<leader>fg` | normal | Live grep |
| `<leader>fw` | normal | Grep word under cursor |
| `<leader>fb` | normal | Find open buffers |
| `<leader>fr` | normal | Recent files |
| `<leader>fs` | normal | Document symbols (LSP) |
| `<leader>fd` | normal | Diagnostics |
| `<leader>gc` | normal | Git commits |
| `<leader>gbc` | normal | Git commits for current buffer |
| `<leader>gs` | normal | Git status |
| `<leader>f.` | normal | Resume last picker |

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
| `<leader>lf` | normal, visual | Format buffer / selection via conform.nvim |
| `:Format` | command | Format buffer via LSP |

### Git

| Keymap | Mode | Action |
|--------|------|--------|
| `<leader>gb` | normal | Toggle inline git blame on current line |

Inline blame appears as dimmed virtual text at the end of the current line (format: `author, date · commit summary`). It is enabled by default with a 300 ms delay.

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

### Notes (Obsidian)

Vault lives at `~/notes`. Create the directory before first use. obsidian.nvim works alongside the Obsidian app — point the app at the same folder for mobile sync.

| Keymap | Action |
|--------|--------|
| `<leader>nd` | Open today's daily note |
| `<leader>no` | Open tomorrow's daily note |
| `<leader>ny` | Open yesterday's daily note |
| `<leader>nD` | Browse daily notes (±7 days from today; missing dates are creatable) |
| `<leader>nw` | Open this week's note |
| `<leader>nW` | Browse all weekly notes |
| `<leader>nm` | Open this month's note |
| `<leader>nM` | Browse all monthly notes |
| `<leader>nn` | New note (prompts for title) |
| `<leader>nf` | Find note (Telescope) |
| `<leader>ng` | Full-text search across vault |
| `<leader>nt` | Browse notes by tag |
| `<leader>nb` | Backlinks to current note |
| `<leader>nl` | Links in current note |
| `<leader>n=` | Table of contents |
| `<leader>nT` | Insert template into current buffer |
| `<leader>nx` | Toggle checkbox |
| `<leader>nr` | Rename note |
| `<leader>np` | Paste image |
| `<leader>ni` | Capture todo to today's daily note |
| `<leader>n?` | Find all open todos across vault |
| `<leader>ne` | Extract selection to new note (visual) |
| `<leader>nL` | Link selection (visual) |
| `<leader>nK` | Link selection to new note (visual) |
| `<leader>nRd` | Recent notes changed in the last 24 hours |
| `<leader>nRw` | Recent notes changed in the last 7 days |
| `<leader>nRm` | Recent notes changed in the last 30 days |

**New note from template:** `<leader>nn` to create and open → `<leader>nT` to insert a template.

**Checkboxes:** `- [ ]` renders as `○`, `- [x]` as `✓`. Use `<leader>n?` to grep open todos vault-wide.

**Templates:** Put markdown files in `~/notes/templates/`. Reference them by filename with `<leader>nT`. Daily/weekly notes auto-apply `templates/daily.md` / `templates/weekly.md` if those files exist.

### Markdown Folding

Headings at all levels fold their content. Folds start open — use these to collapse sections you're not focused on:

| Keymap | Action |
|--------|--------|
| `zc` | Close fold under cursor |
| `zo` | Open fold under cursor |
| `za` | Toggle fold under cursor |
| `zO` | Recursively open all folds under cursor |
| `zM` | Close all folds |
| `zR` | Open all folds |
| `<leader>zf` | Focus: close everything, reveal only current heading |

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
| `gap` | `git add -p` (interactive patch) |
| `gbr` | `git branch` (formatted with date + author) |
| `gc` | `git commit` |
| `gcm` | `git commit -m` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git pull` |
| `glog` | `git log --oneline --decorate --graph` |
| `gp` | `git push` |
| `gpu` | `git push -u` (push and set upstream) |
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

## OS Support

| Feature | macOS | Ubuntu/Debian | Arch/Manjaro |
|---|---|---|---|
| Package installation | Homebrew | apt | pacman |
| Zsh plugins | Homebrew | apt + git clone | pacman + AUR |
| macOS preferences | Yes | Skipped | Skipped |
| Neovim config | Yes | Yes | Yes |
| SSH keys (1Password) | Yes | Yes | Yes |
| Language runtimes (mise) | Yes | Yes | Yes |
