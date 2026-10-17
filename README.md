# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). No secrets are committed — machine-specific secrets go in an unmanaged `~/.env.local` (see [Machine-local Config](#machine-local-config)).

## Prerequisites

- macOS **or** Linux (Ubuntu/Debian, Arch/Manjaro)

**macOS additionally requires:**
- [Homebrew](https://brew.sh/) installed (the bootstrap script will install it if missing)

## New Machine Setup

Run the bootstrap script to set up everything from scratch:

```bash
bash bin/executable_bootstrap.sh
```

**Fresh Ubuntu desktop (first boot):** a stock Ubuntu install has neither `git` nor `curl`, so install those first, then clone and bootstrap:

```bash
sudo apt update && sudo apt install -y git curl
git clone https://github.com/gar/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash bin/executable_bootstrap.sh
```

Bootstrap asks for your `sudo` password (apt) and your login password (`chsh` to zsh). Expect `mise install` to take a while on Ubuntu: Erlang, Ruby and Postgres compile from source.

**Non-interactive runs:** set `HOMEBREW_DOTFILES_WORK=0|1` to answer the work-machine prompt and `DOTFILES_EMAIL=you@example.com` to answer the git email prompt. `DOTFILES_REPO` (default `gar`) changes the repo `chezmoi init` applies, e.g. `file:///path/to/checkout`.

### What it does

1. Ask whether this is a work machine (see [Work Machines](#work-machines))
2. Install system packages:
   - **macOS:** Homebrew packages and casks (`Brewfile`)
   - **Ubuntu/Debian:** apt packages (including Ghostty, build deps for the runtimes mise compiles from source) + luacheck via luarocks
   - **Arch/Manjaro:** pacman packages (including Ghostty, + AUR for `zsh-you-should-use`)
3. Install chezmoi and apply dotfiles (prompts for your git email — see [chezmoi init prompts](#chezmoi-init-prompts))
4. **macOS only, personal machines only:** Apply system preferences (`.macos`)
5. Install language runtimes and tools via [mise](https://mise.jdx.dev/) (Node, Erlang, Elixir, Python, [dexter](https://github.com/remoteoss/dexter))
6. Set zsh as the default shell (if not already)
7. **macOS only, personal machines only:** Restart to apply system preferences

### chezmoi init prompts

`chezmoi init` (run by bootstrap, or by hand) asks two questions once and caches the answers in `~/.config/chezmoi/chezmoi.toml`:

| Prompt | Data key | Used for |
|---|---|---|
| Is this a work machine (MDM-managed)? | `isWork` (default `false`) | Skipping MDM-unsafe setup — see [Work Machines](#work-machines) |
| Git email address | `email` (default `garmorley@gmail.com`) | `user.email` in `~/.gitconfig` |

Only the personal default is in the repo — a work email is entered at init time and only exists in the local chezmoi config. To change an answer later, edit `~/.config/chezmoi/chezmoi.toml` or re-run `chezmoi init --prompt`.

> **Existing machines:** after pulling this change, run `chezmoi init` once to answer the new prompts — `chezmoi apply` fails on the missing `email`/`isWork` data until you do.

### Work Machines

On a company-managed Mac (MDM, endpoint security), answer **yes** to the work-machine prompt. With `isWork = true`:

- `~/.macos` is not installed (excluded in `.chezmoiignore`) and bootstrap never runs it — MDM owns system settings
- bootstrap does **not** finish with `sudo shutdown -r now`
- `brew bundle` skips the personal-only `firefox` cask (the Brewfile checks `HOMEBREW_DOTFILES_WORK=1`, which bootstrap sets from `isWork`)
- bootstrap doesn't require 1Password or the `op` CLI (no machine does any more)

Everything else — shell, git, Neovim, mise, CLI tools — is applied as normal.

Setting up a work Mac by hand, without bootstrap:

```bash
brew install chezmoi
chezmoi init gar            # answer: work machine = yes, email = your work email
chezmoi diff                # review before touching anything
chezmoi apply
HOMEBREW_DOTFILES_WORK=1 brew bundle --file="$(chezmoi source-path)/Brewfile"
```

When running `brew bundle` by hand on a work machine, **always** set `HOMEBREW_DOTFILES_WORK=1` — without it the Brewfile installs the personal casks too.

## Updating Dotfiles on an Existing Machine

Pull and apply the latest changes:

```bash
chezmoi update
```

This fetches the latest from the repo and re-applies all templates.

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

Personal default runtime versions live in mise's global config, `~/.config/mise/config.toml` (source: `dot_config/mise/config.toml`), managed by [mise](https://mise.jdx.dev/). It has the lowest priority, so anything more specific wins:

| Priority | File | Managed by |
|---|---|---|
| Highest | `mise.toml` / `.mise.toml` in a project (and its parents) | the project |
| | `~/.mise.toml` (or `~/.mise.local.toml`) | you, per machine — never touched by chezmoi |
| Lowest | `~/.config/mise/config.toml` | chezmoi (this repo) |

```bash
# Install all defined runtimes
mise install

# Change a personal default (all machines) — edit the chezmoi source, not the live file
chezmoi edit ~/.config/mise/config.toml

# Override a version on this machine only
mise use --path ~/.mise.toml python@3.12

# Pin a version for one project
mise use node@20
```

Avoid `mise use -g` — it writes to the chezmoi-managed global config, and the next `chezmoi apply` will want to revert it.

`~/.mise.toml` only applies inside `$HOME` (mise looks for it as a parent directory of the cwd); outside `$HOME` the global defaults apply.

> **Upgrading an existing machine:** older versions of these dotfiles managed `~/.mise.toml` directly. chezmoi leaves that file in place, and since it outranks the global config it would hide future version changes. After `chezmoi apply`, delete `~/.mise.toml` (or trim it down to genuine per-machine overrides).

## Machine-local Config

Some settings belong to a specific machine (work tools, private plugins, local LSP servers) and should not be committed to a public repo. Three escape hatches are provided for this:

### Environment variables / secrets

Create `~/.env.local`. `~/.zshenv` sources it on every zsh invocation with `allexport` enabled, so plain `KEY=value` lines become exported env vars for shells, scripts, and Raycast script commands (whose shebang is zsh so they source zshenv too).

```sh
# ~/.env.local  (not in git)
HUE_BRIDGE_IP=192.168.1.2
HUE_USERNAME=abc123...
OPENAI_API_KEY=sk-...
```

Template: `cp ~/.env.local.example ~/.env.local && $EDITOR ~/.env.local`.

This is a single shared bucket — any consumer (Raycast, shell aliases, Neovim subprocesses) sees every var. Prefer 1Password + `op run` for higher-sensitivity secrets.

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

`~/.mise.toml` (or `~/.mise.local.toml`) is never touched by chezmoi and outranks the chezmoi-managed `~/.config/mise/config.toml`. Use it to override personal default versions on this machine, and for machine-specific tools and plugins from internal or private registries:

```toml
# ~/.mise.toml  (not in git)
[tools]
python = "3.12.15"          # overrides the personal default
my-private-tool = "latest"

[plugins]
my-private-tool = "git@github.com:my-org/mise-my-private-tool.git"
```
The `[plugins]` section registers a plugin from a custom git URL — equivalent to `mise plugin add <name> <url>`. mise merges this file with the global config at runtime; per-project `mise.toml` files still win over both.

## Managing Packages

**macOS:** Add packages to the `Brewfile`, then:

```bash
brew bundle                  # personal machine
HOMEBREW_DOTFILES_WORK=1 brew bundle  # work machine — skips firefox
```

Personal-only casks go inside the `unless ENV["HOMEBREW_DOTFILES_WORK"] == "1"` block at the bottom of the `Brewfile`.

**Ubuntu/Debian:** Packages are installed via `apt-get` in the bootstrap script. To add new packages, edit the `install_packages_debian()` function in `bin/executable_bootstrap.sh`.

**Arch:** Packages are installed via `pacman` in the bootstrap script. To add new packages, edit the `install_packages_arch()` function in `bin/executable_bootstrap.sh`.

## CLI Tools

| Tool | Purpose |
|------|---------|
| `btop` | System monitor — CPU, memory, disk, network, processes with graphs and per-core view |
| `termgraph` | Draw bar charts and sparklines from piped data — `value,label` CSV format |
| `hexyl` | Hex viewer — colorized, human-readable alternative to `xxd` (run as `hexyl`; `xxd` is untouched) |
| `broot` | Interactive tree explorer with fuzzy search (run as `broot`/`br`; `tree` is untouched) |
| `hyperfine` | Command benchmarking with statistics (mean/stddev, warmup runs, parameter sweeps) |
| `procs` | Modern `ps` replacement — color output, keyword search, process tree view |
| `watson` | Time tracker — `watson start <project> +tag`, `watson stop`, `watson report`. Active task is shown centred in the Neovim statusline. |

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

Each check hard-fails if its tool is missing (e.g. running `secret-scan` without `gitleaks` installed is a failure, not a skip). If you haven't installed every dependency, run the specific checks you care about instead of the full suite.

### End-to-end Ubuntu bootstrap

Runs the whole bootstrap non-interactively in a fresh `ubuntu:26.04` container (needs Docker), applying this checkout's committed `HEAD`:

```bash
./bin/executable_test_bootstrap_ubuntu.sh            # or pass another image, e.g. ubuntu:24.04
```

Not part of CI: `mise install` compiles Erlang, Ruby and Postgres from source, which takes too long for a per-PR job. Run it before merging changes to the Ubuntu path of bootstrap.

### CI

GitHub Actions runs automatically on every pull request and push to `main`. The pipeline has seven parallel jobs:

| Job | What it checks |
|---|---|
| **Lint** | `shellcheck` on shell scripts, `bash -n` / `zsh -n` syntax |
| **Lua lint** | `luacheck` on all neovim Lua files |
| **Neovim startup** | Headless `nvim` launch — catches broken plugin specs, bad keymaps, etc. |
| **Git config** | Renders and parses `dot_gitconfig.tmpl` to catch malformed config |
| **Chezmoi templates** | Renders every `.tmpl` file to verify template syntax |
| **Ubuntu bootstrap deps** | In an `ubuntu:26.04` container: `apt-get install --dry-run` on every package in `install_packages_debian()` (fails on a name that doesn't exist), and `git ls-remote` on every GitHub repo bootstrap clones |
| **Secret scan** | `gitleaks` over the full git history — fails the build if an API key, token, password, or similar secret is detected. Output is `--redact`ed so secrets never appear in logs. |

No manual GitHub setup is required — the workflow runs automatically once `.github/workflows/ci.yml` is pushed.

## What's Included

| File | Purpose |
|---|---|
| `dot_zshrc.tmpl` | Zsh config (aliases, plugins, tool activation) — templated per OS |
| `dot_gitconfig.tmpl` | Git config (aliases, user info) |
| `.chezmoi.toml.tmpl` | `chezmoi init` prompts — `isWork` and git `email` |
| `dot_config/mise/config.toml` | Personal default language runtime versions (mise global config) |
| `dot_macos` | macOS system preferences (skipped on Linux and on work machines via `.chezmoiignore`) |
| `dot_config/ghostty/config.tmpl` | Ghostty terminal config (font size 16 on macOS, 12 on Linux) |
| `dot_config/xdg-terminals.list` | Makes Ghostty the default terminal on Linux (GNOME `Ctrl+Alt+T`, via `xdg-terminal-exec`) |
| `dot_config/nvim/` | Neovim config (LSP, completion, fuzzy find, floating terminal, etc.) |
| `Brewfile` | Homebrew packages and casks (macOS only) |
| `.chezmoiignore` | OS- and `isWork`-conditional file exclusions |
| `bin/executable_bootstrap.sh` | Cross-platform machine bootstrap script |
| `bin/executable_test.sh` | Local test runner (same checks as CI) |
| `bin/executable_test_bootstrap_ubuntu.sh` | End-to-end bootstrap test in an Ubuntu container (Docker) |
| `.github/workflows/ci.yml` | GitHub Actions CI pipeline |

## Shell Aliases

### Modern CLI Replacements

These modern tools are installed alongside their traditional counterparts and run under their own names — `find`, `grep`, `sed`, `tree` and `xxd` are never aliased, so scripts and muscle memory that expect the standard tools keep working:

| Command | Alternative to | Tool |
|-------|----------|------|
| `fd` | `find` | [`fd`](https://github.com/sharkdp/fd) — faster, friendlier find (aliased from `fdfind` on Debian/Ubuntu) |
| `rg` | `grep` | [`rg`](https://github.com/BurntSushi/ripgrep) — ripgrep, faster grep |
| `sd` | `sed` | [`sd`](https://github.com/chmln/sd) — simpler stream editor |
| `broot` | `tree` | [`broot`](https://github.com/Canop/broot) — interactive tree explorer |
| `hexyl` | `xxd` | [`hexyl`](https://github.com/sharkdp/hexyl) — colorized hex viewer |

> **Note:** `sd` uses a different syntax from `sed`. Use `sd 'old' 'new' file` or pipe: `echo 'hello' | sd 'hello' 'world'`.

### Watson

| Alias | Command |
|-------|---------|
| `we` | Fuzzy-pick a `watson log` entry with `fzf` and open `watson edit` on it. Defaults to `--day`; pass any `watson log` flag to override (e.g. `we --week`, `we --all -p dotfiles`). |

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
| `<leader>L` | normal | Toggle office lights (Philips Hue) |

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
| `<leader>aS` | normal | Sharpen the saw — file a dotfiles task for cloud Claude |
| `<leader>dy` | normal | Accept Claude-proposed diff |
| `<leader>dn` | normal | Reject Claude-proposed diff |

Shell alias: `cl` → `claude` (defined when the `claude` CLI is on `PATH`).

Shell command: `sharpen "<prompt>"` files a GitHub issue against `gar/dotfiles` mentioning `@claude`. The Claude Code GitHub app picks it up, works in a sandbox, opens a PR, and (per instructions in the issue body) enables squash auto-merge so the fix lands by itself once CI passes — useful when you hit friction in your own setup and want it fixed without dropping what you're doing. `<leader>aS` in Neovim wraps the same script behind `vim.ui.input`. Override the target repo with `SHARPEN_REPO=owner/name`.

**Workflow:** Select code in visual mode → `<leader>as` to send to Claude → type your instruction in the panel → accept or reject proposed changes with `<leader>dy` / `<leader>dn`.

**Worktrees + Claude Code:** Run `claude --worktree <name>` in a terminal to start an isolated Claude session on its own branch. Use `<leader>gwl` to switch between worktree directories in Neovim. Multiple worktrees let you run parallel Claude sessions without conflicts.

### Claude Code status line

`bin/executable_claude_statusline.sh` (lands at `~/bin/claude_statusline.sh`) renders a one-line Claude Code status bar: model tag, context-usage bar, cumulative tokens, cost, elapsed time, cwd, and git branch. It expects Claude Code's status-line JSON on stdin, so it isn't useful as a generic shell prompt.

`~/.claude/settings.json` is intentionally **not** managed by chezmoi — it holds per-machine state (permissions, MCP servers, hooks). To enable the status line on a given machine, add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/bin/claude_statusline.sh"
  }
}
```

### Claude Code Skills

Claude Code auto-discovers skills from `~/.claude/skills/<name>/SKILL.md`. The dotfiles ship a curated starter set; ask Claude in plain language ("grill me on this plan", "let's TDD this", "extract a glossary") and it picks the matching skill.

| Skill | What it does |
|---|---|
| `grill-me` | Relentlessly interviews you about a plan or design until every branch of the decision tree is resolved |
| `grill-with-docs` | Stress-tests a plan against the codebase's domain models and updates `CONTEXT.md` / ADRs as decisions land |
| `tdd` | Test-driven red-green-refactor loop with bundled guidance on mocking, refactoring, and module depth |
| `improve-codebase-architecture` | Identifies architectural friction and proposes deepening opportunities (covers module depth, interface design, design vocabulary) |
| `ubiquitous-language` | Extracts a DDD-style glossary from the conversation, flags ambiguous terms, and proposes canonical names |
| `notes` | Searches, creates, and links markdown notes in `~/notes` using wikilinks and index notes |

Most skills are vendored from [`mattpocock/skills`](https://github.com/mattpocock/skills); `notes` is locally adapted. Provenance and re-sync instructions: `~/.claude/skills/README.md`.

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
| `<leader>nh` | Promote the current todo into a `###` heading at the end of the `## Notes` section |
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

These are the only aliases that shadow a standard command. `fd`, `broot` and `hexyl` are installed too but are run by their own names (see [Modern CLI Replacements](#modern-cli-replacements)).

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

## Philips Hue — Toggle Office Lights

The generic script `~/bin/toggle_office_lights` (chezmoi source: `bin/executable_toggle_office_lights`) toggles the office light group on/off. When turning on, it activates the `Read` scene between 08:00 and 18:00, and the `Rest` scene outside those hours.

It's reachable from three places, each a thin entry into the same script:

| Surface | How |
|---|---|
| Shell | `toggle_office_lights` |
| Neovim | `<leader>L` (status appears via `vim.notify`) |
| Raycast (macOS) | Script command in `~/.config/raycast-scripts/` |

Credentials come from `~/.env.local` (see [Machine-local Config → Environment variables](#environment-variables--secrets)). Required variables:

| Variable | How to find it |
|---|---|
| `HUE_BRIDGE_IP` | Local IP of your Hue bridge (e.g. 192.168.1.2). See https://developers.meethue.com/develop/get-started-2/ |
| `HUE_USERNAME` | Authorised username issued by the bridge (same guide) |
| `HUE_OFFICE_GROUP_ID` | List groups: `curl http://$HUE_BRIDGE_IP/api/$HUE_USERNAME/groups \| jq 'to_entries[] \| {id: .key, name: .value.name}'` |

The script only uses `curl` and `jq` (both installed by the bootstrap) — no Node/`zx` required.

### Raycast setup (macOS)

Raycast script commands live in `~/.config/raycast-scripts/` (excluded on Linux via `.chezmoiignore`). Point Raycast at that folder once: **Raycast → Extensions → Script Commands → Add More Directories → `~/.config/raycast-scripts`**. The "Toggle Office Lights" command will appear in Raycast immediately.

## OS Support

| Feature | macOS | Ubuntu/Debian | Arch/Manjaro |
|---|---|---|---|
| Package installation | Homebrew | apt | pacman |
| Zsh plugins | Homebrew | apt + git clone | pacman + AUR |
| macOS preferences | Yes (skipped on work machines) | Skipped | Skipped |
| Neovim config | Yes | Yes | Yes |
| Language runtimes (mise) | Yes | Yes | Yes |
