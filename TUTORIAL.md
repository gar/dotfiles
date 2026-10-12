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

Lua, Python, and TypeScript servers are installed via Mason the first time you open a matching file. The Elixir server is configured separately:

- **[dexter](https://github.com/remoteoss/dexter)** is installed via mise (`dot_mise.toml` registers the plugin and pins `dexter = "latest"`). Run `mise install` to (re)install. Format-on-save is enabled for dexter buffers — saving an Elixir file runs `dexter`'s formatter via `BufWritePre`. The autocmd is scoped to dexter so other LSPs that also advertise formatting won't fight over the buffer.

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
<leader>lf   — format the buffer (or visual selection) via conform.nvim
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

### Launch from the shell

```
cl           — alias for `claude` (start Claude Code in the current terminal)
```

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

### Sharpen the saw — fire a task at cloud Claude

When you hit friction in your own setup ("ugh, the todo tool sorts case-sensitively"), you usually don't want to break flow and fix it yourself. `sharpen` files the task at cloud Claude instead, so the fix lands as a PR while you keep working.

From the shell:

```
sharpen "fix the todo tool to ignore case when sorting"
sharpen                              # interactive prompt
echo "tighten the zsh prompt" | sharpen
SHARPEN_REPO=me/other-repo sharpen "..."   # send it elsewhere
```

From inside Neovim, `<leader>aS` opens an input prompt and dispatches the same command. The issue URL is printed (and opened in a browser if a graphical opener is available); you'll get a PR once Claude is done.

Under the hood it's just `gh issue create -R gar/dotfiles -t "sharpen: <prompt>" -b "@claude\n\n<prompt>"`. The Claude Code GitHub app responds to the mention. The body also asks Claude to put `Closes #<n>` in the PR (so the issue closes on merge) and enable squash auto-merge, so the fix lands and tidies up by itself once CI passes; if CI fails, auto-merge stays off and you handle it manually.

### Skills — making Claude do the right thing automatically

Skills live in `~/.claude/skills/` and Claude picks them up by description. You don't invoke them by name; you describe what you want and Claude reaches for the matching skill.

| Try saying… | Skill it triggers | What you get |
|---|---|---|
| "Grill me on this plan" / "interview me" | `grill-me` | One sharp question at a time until every decision branch is closed off |
| "Pressure-test this against `CONTEXT.md`" / "what would the docs say?" | `grill-with-docs` | Plan checked against domain docs and ADRs; doc updates proposed |
| "Let's TDD this" / "red-green-refactor" | `tdd` | Failing test first, minimum implementation, then refactor — with mocking/refactoring sub-guides |
| "What architectural improvements does this codebase have?" | `improve-codebase-architecture` | Shallow modules flagged, deepening opportunities proposed |
| "Extract a glossary" / "build the ubiquitous language" | `ubiquitous-language` | DDD-style glossary in markdown with synonyms flagged |
| "Find my notes about X" / "make a new note titled Y" | `notes` | Search/create in `~/notes` with wikilinks |

To see what's installed: `ls ~/.claude/skills/`. To add a skill, drop a directory containing a `SKILL.md` (with `name` and `description` frontmatter) into `private_dot_claude/skills/` in the dotfiles repo and run `chezmoi apply`.

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

### Working a todo into a notes section

Daily notes often start with a checklist of larger tasks at the top, and a `## Notes` section below for the running commentary:

```
# 2026-04-22 Wednesday

* [ ] Reply on Slack to Foo
* [ ] Implement new readiness API
* [ ] Send email

## Notes

### Some earlier note
…
```

When you sit down to work on one of those todos, put the cursor on its line and press `<leader>nh`. It copies the todo text into a new `###` heading appended to the end of `## Notes`, then drops the cursor there so you can start jotting sub-todos or decisions:

```
## Notes

### Some earlier note
…

### Implement new readiness API   ← cursor lands here
```

The original checkbox stays untouched — tick it off later with `<leader>nx` when the task is done.

### Finding things

| Keymap | Action |
|--------|--------|
| `<leader>ng` | Full-text search across all notes |
| `<leader>n?` | Find all open `- [ ]` todos vault-wide |
| `<leader>nf` | Jump to any note by name |
| `<leader>nb` | See what links to the current note |
| `<leader>nh` | Promote the current todo into a `###` heading in the `## Notes` section |
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
mise use node@20    # sets node 20 for this directory (writes mise.toml)
```

### Where versions come from

mise layers config files; the most specific one wins:

1. `mise.toml` in the project (or a parent directory) — per-repo pins
2. `~/.mise.toml` — this machine's overrides, never touched by chezmoi
3. `~/.config/mise/config.toml` — your personal defaults, managed by chezmoi

Run `mise ls --current` to see each active version and which file it came from.

### Override a version on one machine

Say a work laptop needs Python 3.12 while your defaults say 3.14:

```bash
mise use --path ~/.mise.toml python@3.12.15
mise install
```

This writes `~/.mise.toml`, which beats the personal default everywhere under `$HOME`. Project `mise.toml` files still win over it.

### Change your personal defaults

These live in the dotfiles repo, so edit them through chezmoi so every machine picks them up:

```bash
chezmoi edit ~/.config/mise/config.toml
mise install
```

Avoid `mise use -g` — it edits the chezmoi-managed file directly, and `chezmoi diff` will flag the change.

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

### Answer the init prompts

The first `chezmoi init` asks two questions and remembers the answers in `~/.config/chezmoi/chezmoi.toml`:

- **Is this a work machine (MDM-managed)?** — answer yes on a company-managed Mac. chezmoi then skips `~/.macos`, and bootstrap skips the final reboot.
- **Git email address** — becomes `user.email` in `~/.gitconfig`. Press enter for the default (`garmorley@gmail.com`); type your work email on a work machine — it never goes into the repo.

To change an answer, re-run `chezmoi init --prompt`, then `chezmoi diff` and `chezmoi apply`.

### Set up a work Mac

Skip bootstrap and go step by step, so you can see each change before it happens:

```bash
brew install chezmoi
chezmoi init gar        # work machine: yes; email: your work email
chezmoi diff            # no ~/.macos in the list
chezmoi apply
DOTFILES_WORK=1 brew bundle --file="$(chezmoi source-path)/Brewfile"   # skips Firefox
```

Need different runtime versions from your personal defaults? Create `~/.mise.toml` first (see [Override a version on one machine](#override-a-version-on-one-machine)).

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

This works alongside `dexter` or any other LSP already configured in the dotfiles.

### Extra mise tools

`~/.mise.toml` (or `~/.mise.local.toml`) is never touched by chezmoi and outranks your chezmoi-managed defaults in `~/.config/mise/config.toml`. Use it for machine-specific versions and tools, including plugins from internal or private registries:

```bash
nvim ~/.mise.toml
```

```toml
# ~/.mise.toml  (not in git)
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

mise merges `~/.mise.toml` with the global `~/.config/mise/config.toml` at runtime, so you never need to modify the chezmoi-managed file.

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
| `broot` | Interactive directory tree | `broot src/` — fuzzy search, Alt+Enter to cd |
| `ls` | Directory listing (eza) | `ls` or `ll` for long form with git status |
| `cat` | File viewer (bat) | `cat file.ex` — syntax highlighted, with line numbers |
| `hexyl` | Hex viewer | `hexyl file` — colorized hex dump with ASCII sidebar |
| `termgraph` | Terminal bar charts | `echo "Jan,100\nFeb,120" \| termgraph` |
| `watson` | Time tracker | `watson start project +tag`, `watson stop`, `watson report` |

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

Run it as `hexyl` — plain `xxd` is left alone, so scripts that rely on its output format still work:

```bash
hexyl file.bin      # colorized hex dump with ASCII sidebar
hexyl -n 256 file   # show first 256 bytes only
hexyl --border none file | head  # strip border for piping
```

### broot — interactive tree explorer

Run it as `broot` (or `br`) — plain `tree` is left alone for static, pipeable output:

```bash
broot               # open interactive tree for current directory
broot src/          # open at a specific path
br                  # same as broot, but cd into the selected directory on exit
```

Inside broot:
- Type to fuzzy-search files and directories
- `Alt+Enter` to `cd` into the selected directory and exit
- `?` for help

Note: `br` (cd-on-exit) requires the broot shell launcher, which bootstrap installs automatically. Plain `broot` works without it.

### fd — better find

Run it as `fd` — `find` is not aliased, so scripts and commands that expect POSIX `find` flags keep working. (On Debian/Ubuntu the binary is `fdfind`; the zshrc aliases `fd` to it.)

```bash
fd config           # files/dirs whose name contains "config"
fd -e lua           # all .lua files
fd -H .env          # include hidden files
```

### gh for pull requests

```bash
gh pr create          # interactive: title, body, base branch
gh pr list            # see open PRs
gh pr checkout 42     # check out PR #42 locally
gh pr view --web      # open current PR in browser
```

### watson — time tracking

Basic usage:

```bash
watson start dotfiles +config       # start a task (tags prefixed with +)
watson status                       # what am I tracking?
watson stop                         # stop the current frame
watson report --day                 # today's breakdown by project
watson log -f                       # full log, most recent first
```

Editing a frame is easier with the `we` shell function — it pipes `watson log` through `fzf` and opens `watson edit` on the chosen frame. Defaults to today (`--day`); pass any other `watson log` flag to widen the picker:

```bash
we                                  # pick from today's frames
we --week                           # pick from this week
we --all -p dotfiles                # all-time, filtered to one project
```

Neovim shows the active task (`⏱ project [tags]`) in the centre of the statusline while watson is running. It refreshes immediately on start/stop and polls every 5 s to pick up changes made in another terminal, and truncates to fit narrow windows.
