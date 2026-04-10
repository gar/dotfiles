# Dotfiles Tutorial

Practical walkthroughs for the tools in this config. This is not a reference — it's how to actually use things.

---

## 1. Moving Around Your System

### Jump to any directory instantly with zoxide

`zoxide` replaces `cd`. After you've visited a directory once, you can jump back with just a fragment of the name.

```bash
# First time — use the full path as normal
cd ~/projects/my-elixir-app

# Every time after that — just type a fragment
z my-elixir-app
z elixir       # works if unambiguous
z app          # picks the most frecent match
```

You still have regular `cd` when you need an exact path. Use `z` for everything you visit repeatedly.

### Find files fast in Neovim

You're in Neovim and need to open a file you don't want to type the full path for.

```
<leader>ff  — fuzzy search filenames. Start typing any part of the name.
<leader>fg  — search across all file contents (live grep).
<leader>fw  — grep for the word under the cursor. No typing needed.
<leader>fb  — switch between open buffers.
<leader>fr  — recently opened files. Great for picking up where you left off.
<leader>f.  — reopen the last picker with the same query.
```

In the picker: `<C-j>/<C-k>` to move, `<Enter>` to open, `<C-v>` to open in a vertical split, `<C-x>` for horizontal split.

### Browse code structure and problems

```
<leader>fs  — list all symbols in the current file (functions, classes, etc). Fuzzy-searchable.
<leader>fd  — all LSP diagnostics across the project in one picker.
```

### Git from inside Neovim

```
<leader>gs   — changed files with a diff preview. Good for a quick pre-commit review.
<leader>gc   — browse the full project commit history.
<leader>gbc  — browse commits that touched the current buffer only.
```

---

## 2. Daily Git Workflow

### The short form for everything

Your zsh git aliases cover the whole daily loop:

```bash
gst            # git status
ga path/file   # git add a specific file
gaa            # git add --all (stage everything)
gcm "message"  # git commit -m
gp             # git push
gl             # git pull
```

For branching:

```bash
gswc my-feature   # create and switch to a new branch
gsw main          # switch back to main
gd                # see unstaged changes
gds               # see staged changes
```

### View history

```bash
glog    # commit graph — branches and merges visualised
g l     # compact oneline log (the `l` alias in .gitconfig)
```

### Fix your last commit

Made a typo or forgot to stage a file?

```bash
ga forgotten-file.txt
g oops    # amends the last commit, keeps the message
```

### Push safely after a rebase

```bash
g shove   # --force-with-lease: safe force push, won't overwrite remote-only changes
```

### Resolve merge conflicts clearly

Git is configured with `zdiff3` conflict style, which shows the common ancestor so you can see *why* there's a conflict, not just what each side changed. Conflicts look like:

```
<<<<<<< HEAD
your change
||||||| common ancestor
original line
=======
their change
>>>>>>> branch
```

---

## 3. Editing Code with LSP

When you open a file in a supported language (Lua, Elixir, Python, TypeScript), the language server starts automatically. Here's what to use:

### Navigate code

```
gd    — go to definition. Essential. Use this constantly.
gD    — go to declaration
gi    — go to implementation
gr    — show all references to the symbol under cursor
```

`<C-o>` (standard Neovim) jumps back to where you came from after any of these.

### Understand code

```
K     — hover docs for the thing under cursor. Press again to enter the popup.
<C-k> — signature help while you're typing function arguments
```

### Fix and rename

```
<leader>rn   — rename symbol everywhere in the project
<leader>ca   — code actions (auto-fix, import, extract, etc.)
:Format      — format the current buffer via LSP
```

### Work with errors

Diagnostics (errors and warnings) appear inline. Navigate them with:

```
]d    — jump to next diagnostic
[d    — jump to previous diagnostic
<leader>f   — open the diagnostic message in a float (to read the full text)
gl    — show diagnostics for the current line
```

---

## 4. Completion

`blink.cmp` handles completion. It kicks in automatically as you type. The sources are LSP, file paths, snippets, and buffer words.

- Type to filter. Keep typing to narrow.
- `<C-n>` / `<C-p>` or arrow keys to select.
- `<Enter>` to confirm.
- `<C-e>` to dismiss.

Docs for the selected item appear automatically after a short delay in a side popup.

---

## 5. Syntax Selection with Treesitter

When you need to select a logical chunk of code (a function argument, a block, a whole function):

```
gnn   — start selection at cursor
grn   — expand outward to next syntax node
grc   — expand to the enclosing scope
grm   — shrink back inward
```

This is faster than visual mode + manual movement for selecting structured code.

---

## 6. Terminal Inside Neovim

You rarely need to leave Neovim.

```
<C-\>   — open/close a floating terminal (toggleterm)
```

The terminal floats over your editor at 85% width. It keeps state between toggles — your shell session persists.

From inside the terminal:
- `<Esc>` — go back to normal mode (so you can scroll, copy, etc.)
- `<C-\>` again — close it

You can also split navigate from terminal mode with `<C-w>h/j/k/l` to jump to other splits.

---

## 7. Working with Claude Code

### Open Claude and ask something

```
<leader>ac   — toggle the Claude panel (opens as a right-side vertical split)
<leader>af   — focus the panel if it's already open
<leader>ar   — resume your last session
```

### Add context

```
<leader>aa   — add the current file to Claude's context
```

In visual mode, select code first, then:
```
<leader>as   — send the selection to Claude
```

### Review Claude's proposed changes

When Claude proposes edits, they appear as a diff. While reviewing:

```
<leader>dy   — accept the diff
<leader>dn   — reject the diff
```

### Common workflow

1. Open a file, `<leader>aa` to add it as context
2. `<leader>ac` to open Claude, describe what you need
3. Review the diff with `<leader>dy` / `<leader>dn`
4. `<leader>ac` to close when done

---

## 8. Notes and Daily Journal

Notes live in `~/notes`. Open today's daily note with `<leader>nd` — it auto-applies the daily template if one exists at `~/notes/templates/daily.md`.

### Folding to stay focused

Daily notes often accumulate many headings throughout the day. Use folding to hide sections you're not currently working on:

```
## Support requests          ← zc to collapse this whole section
### Ask Alex about setup     ← currently working here
### Database migration        ← zc to hide this for now
## Meetings
### 1:1 with manager
```

**Focus on one heading:** Put the cursor inside the heading you're working on and press `<leader>zf`. This collapses everything else and keeps just that section visible.

**Open/close individual headings:** `zo` opens, `zc` closes. A `##` heading folds all its `###` and `####` children too — `zO` (capital O) recursively expands them all at once.

**Reset the view:** `zR` opens everything again.

### Finding things

| Keymap | Action |
|--------|--------|
| `<leader>ng` | Full-text search across all notes |
| `<leader>n?` | Find all open `- [ ]` todos vault-wide |
| `<leader>nf` | Jump to any note by name |
| `<leader>nb` | See what links to the current note |
| `<leader>nRd` | Notes changed in the last 24 hours |
| `<leader>nRw` | Notes changed in the last 7 days |
| `<leader>nRm` | Notes changed in the last 30 days |

---

## 10. Managing Language Versions with mise

`mise` manages your Node, Python, Erlang, and Elixir versions. It activates automatically per directory based on `.mise.toml` or `.tool-versions` files.

### Check what's active

```bash
mise current
```

### Install what's pinned in a project

```bash
mise install
```

### Switch versions for a project

```bash
mise use node@20    # sets node 20 for this directory (writes .mise.toml)
mise use -g node@22 # sets globally
```

### See all available versions

```bash
mise ls-remote node
```

---

## 11. Per-directory Environments with direnv

Create a `.envrc` in a project directory to automatically set environment variables when you `cd` in.

```bash
# .envrc
export DATABASE_URL=postgres://localhost/myapp_dev
export PORT=4000
```

First time (or after any change):

```bash
direnv allow
```

After that, variables are set when you enter the directory and unset when you leave. No manual `source .env` needed.

---

## 12. Managing Dotfiles with chezmoi

### Apply changes from the repo to your machine

```bash
chezmoi apply
```

### Pull the latest from git and apply

```bash
chezmoi update
```

### See what would change before applying

```bash
chezmoi diff
```

### Edit a dotfile

Edit the source file directly in this repo (e.g. `dot_zshrc.tmpl`), then apply:

```bash
chezmoi apply ~/.zshrc
```

Or edit via chezmoi's wrapper, which opens the source file and applies after you save:

```bash
chezmoi edit ~/.zshrc
```

### Test your changes

```bash
./bin/executable_test.sh             # run all checks
./bin/executable_test.sh shell-syntax   # just zsh/bash syntax
./bin/executable_test.sh lua-lint       # just neovim config
```

---

## 13. Machine-local Config

Some tools or settings belong only to a specific machine — work LSP servers, private plugins, credentials — and should not be committed to a public repo. Two places exist for this.

### Extra Neovim config

Create `~/.config/nvim/lua/local.lua`. Neovim loads it automatically at startup if it exists. chezmoi never touches this file.

```bash
# create the file (or open it in your editor)
nvim ~/.config/nvim/lua/local.lua
```

Example — registering an LSP server that's only installed on this machine:

```lua
-- ~/.config/nvim/lua/local.lua
vim.lsp.config('my-work-lsp', {
  cmd = { 'my-work-lsp', 'lsp' },
  root_markers = { '.git', 'mix.exs' },
  filetypes = { 'elixir', 'eelixir' },
})
vim.lsp.enable 'my-work-lsp'
```

This works alongside `expert` or any other LSP already configured in the dotfiles.

### Extra mise tools

`~/.mise.local.toml` sits next to `~/.mise.toml` and is never touched by chezmoi. Use it for machine-specific tools, including plugins from internal or private registries:

```bash
nvim ~/.mise.local.toml
```

```toml
# ~/.mise.local.toml  (not in git)
[plugins]
my-work-tool = "git@gitlab.com:my-org/mise-my-work-tool.git"

[tools]
my-work-tool = "latest"
```

The `[plugins]` section is how you point mise at a plugin from a custom git URL. Without it, mise looks up the plugin in the public registry only.

Then install:

```bash
mise install
```

mise merges `~/.mise.local.toml` with `~/.mise.toml` at runtime, so you never need to modify the chezmoi-managed file.

---

## 14. Useful CLI Tools

A few tools from the Brewfile worth knowing:

| Tool | What it does | Basic usage |
|------|-------------|-------------|
| `rg` | Fast grep | `rg "pattern"` or `rg "pattern" src/` |
| `fd` | Fast find | `fd filename` or `fd -e lua` (by extension) |
| `jq` | JSON processor | `cat data.json \| jq '.key'` |
| `gh` | GitHub CLI | `gh pr create`, `gh pr list`, `gh issue view 42` |
| `entr` | Re-run on file change | `fd -e ex \| entr mix test` |
| `htop` | Process viewer | `htop` |
| `tree` | Interactive directory tree (broot) | `tree src/` — fuzzy search, Alt+Enter to cd |
| `ls` | Directory listing (eza) | `ls` or `ll` for long form with git status |
| `cat` | File viewer (bat) | `cat file.ex` — syntax highlighted, with line numbers |
| `xxd` | Hex viewer (hexyl) | `xxd file` — colorized hex dump with ASCII sidebar |
| `termgraph` | Terminal bar charts | `echo "Jan,100\nFeb,120" \| termgraph` |

### eza — better ls

`ls` and `ll` are aliased to `eza`:

```bash
ls                  # icons, color-coded by type
ll                  # long form: permissions, size, modified date, git status per file
ll --sort=modified  # most recently changed files first
eza -T              # tree view (static, pipeable — use when you need output not a TUI)
```

### bat — better cat

`cat` is aliased to `bat`:

```bash
cat file.ex         # syntax highlighted with line numbers
bat -A file         # show non-printable characters (tabs, line endings)
bat --diff file     # show only changed lines (requires git)
man ls              # man pages are also rendered via bat
```

### hexyl — better xxd

`xxd` is aliased to `hexyl`:

```bash
xxd file.bin        # colorized hex dump with ASCII sidebar
xxd -n 256 file     # show first 256 bytes only
hexyl --border none file | head  # strip border for piping
```

### broot — interactive tree explorer

`tree` is aliased to `broot`:

```bash
tree                # open interactive tree for current directory
tree src/           # open at a specific path
br                  # same as tree, but cd into the selected directory on exit
```

Inside broot:
- Type to fuzzy-search files and directories
- `Alt+Enter` to `cd` into the selected directory and exit
- `?` for help

Note: `br` (cd-on-exit) requires the broot shell launcher, which bootstrap installs automatically. Plain `tree`/`broot` works without it.

### gh for pull requests

```bash
gh pr create          # interactive: title, body, base branch
gh pr list            # see open PRs
gh pr checkout 42     # check out PR #42 locally
gh pr view --web      # open current PR in browser
```
