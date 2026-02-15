# Dotfiles — CLAUDE.md

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports macOS, Ubuntu/Debian, and Arch/Manjaro. Secrets are stored in 1Password and injected at apply time via chezmoi templates.

## Repository Structure

```
dotfiles/
├── bin/
│   ├── executable_bootstrap.sh    # Cross-platform machine setup script
│   └── executable_test.sh         # Local test runner (mirrors CI)
├── dot_config/
│   └── nvim/                      # Neovim config (Lua, lazy.nvim)
│       ├── init.lua               # Entry point — bootstraps lazy.nvim
│       └── lua/
│           ├── editor/            # Core settings (options, keymaps, autocmds)
│           └── features/          # Plugin specs (colorscheme, completion, fuzzy_find, lsp, syntax)
├── private_dot_claude/            # Personal Claude preferences (private)
├── private_dot_ssh/               # SSH keys (populated from 1Password)
├── .github/workflows/ci.yml      # GitHub Actions CI pipeline
├── .chezmoiignore                 # OS-conditional file exclusions
├── dot_zshrc.tmpl                 # Zsh config — templated per OS
├── dot_gitconfig.tmpl             # Git config — templated
├── dot_mise.toml                  # Language runtime versions (Node, Erlang, Elixir, Python)
├── dot_macos                      # macOS system preferences (skipped on Linux)
├── Brewfile                       # Homebrew packages and casks (macOS)
└── README.md                      # User-facing setup documentation
```

## Chezmoi Conventions

- `dot_` prefix → dotfile (e.g. `dot_zshrc.tmpl` → `~/.zshrc`)
- `private_dot_` prefix → private dotfile with restricted permissions
- `.tmpl` suffix → chezmoi template with variable substitution and OS conditionals
- `executable_` prefix → file gets executable permission when applied
- `.chezmoiignore` excludes files conditionally (e.g. `.macos` excluded on non-Darwin)
- 1Password secrets are injected via `onepassword*` template functions at apply time

## Testing

Run all checks locally:

```bash
./bin/executable_test.sh
```

Run a single check:

```bash
./bin/executable_test.sh <check_name>
```

Available checks: `shellcheck`, `shell-syntax`, `lua-lint`, `nvim-startup`, `git-config`, `chezmoi-template`.

### What the tests verify

| Check | What it does |
|---|---|
| `shellcheck` | Lints shell scripts (excludes known-benign SC warnings) |
| `shell-syntax` | `bash -n` on scripts, `zsh -n` on rendered zshrc |
| `lua-lint` | `luacheck` on neovim config (globals: `vim`, no unused-args, no max-line-length) |
| `nvim-startup` | Headless neovim launch with plugin install — catches broken config |
| `git-config` | Renders and parses `dot_gitconfig.tmpl` |
| `chezmoi-template` | Renders all `.tmpl` files (1Password-dependent templates are skipped) |

### CI

GitHub Actions runs the same checks on every PR and push to `main` — five parallel jobs. See `.github/workflows/ci.yml`.

## Key Files to Know

- **`dot_zshrc.tmpl`** — Shell config. Uses chezmoi `if eq .chezmoi.os "darwin"` blocks for OS-specific plugin paths. Integrates mise, direnv, zoxide, chezmoi completions, and 1Password completions.
- **`dot_gitconfig.tmpl`** — Git config. Notable aliases: `oops` (amend), `shove` (push --force-with-lease), `l` (log oneline). Uses diff3 conflict style.
- **`dot_mise.toml`** — Pins language runtime versions. Changed here, applied via `mise install`.
- **`Brewfile`** — macOS packages. Run `brew bundle` after changes.
- **`bin/executable_bootstrap.sh`** — Full machine setup. Detects OS/distro, installs packages, applies chezmoi, installs runtimes, sets default shell.
- **`dot_config/nvim/`** — Neovim config. Each file in `lua/features/` is a lazy.nvim plugin spec. LSP servers configured: lua_ls, elixirls, pyright, ts_ls.

## Development Workflow

1. Edit files in this repo (they are chezmoi source files, not the live dotfiles)
2. Run `./bin/executable_test.sh` to validate changes
3. Commit and push — CI runs automatically
4. Apply to the local machine with `chezmoi apply` (or `chezmoi update` to pull + apply)

### When editing shell config

- `dot_zshrc.tmpl` is a chezmoi template — keep OS conditionals balanced
- Test with `./bin/executable_test.sh shell-syntax`
- Plugin source paths differ between macOS (Homebrew) and Linux distros

### When editing neovim config

- Each feature is a separate file in `dot_config/nvim/lua/features/`
- Plugin specs use lazy.nvim format (table with plugin URL, dependencies, config function)
- Test with `./bin/executable_test.sh lua-lint` and `./bin/executable_test.sh nvim-startup`
- `vim` is a recognized global in luacheck — no need to declare it

### When editing templates

- Templates using `onepassword*` functions cannot be tested without 1Password auth
- Use `chezmoi execute-template --init < file.tmpl` to test rendering locally
- Test with `./bin/executable_test.sh chezmoi-template`

## Code Style

- Shell scripts: Bash with `set -euo pipefail`. Must pass `shellcheck` and `bash -n`.
- Lua (neovim): Must pass `luacheck`. Use `vim` global freely. Follow existing lazy.nvim spec patterns.
- Templates: Use chezmoi Go template syntax with `{{- }}` for whitespace trimming.
- Match existing conventions in each file — don't impose different formatting.

## Git Conventions

- Default branch: `main`
- Commit messages: imperative mood, concise (e.g. "Add zsh plugin", "Fix nvim LSP keybind")
- Prefer small, focused commits
- Use `--force-with-lease` instead of `--force`
- Run tests before committing
