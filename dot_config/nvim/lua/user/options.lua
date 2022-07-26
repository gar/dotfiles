local opt = vim.opt

HOME = os.getenv("HOME")

-- Editor behaviour options
opt.backup = true                              -- store backups in default dir (`~/.data/nvim/backup/`)
opt.backupdir = HOME .. "/.local/share/nvim/backup//" -- store backups in XDG data dir
opt.clipboard = "unnamedplus"                  -- allows neovim to access the system clipboard
opt.undofile = true                            -- enable persistent undo

-- Appearance options
opt.cmdheight = 2                              -- more space to display messages in the command-line
opt.cursorline = true                          -- highlight the current line
opt.laststatus = 2                             -- always show a status line
opt.number = true                              -- show line numbers
opt.pumheight = 10                             -- limit completion popup menu height to 10 items
opt.ruler = true                               -- display line and column number of cursor position
opt.scrolloff = 8                              -- minimal number of lines to display above and below the cursor
opt.showtabline = 2                            -- always show buffer tab bar
opt.sidescrolloff = 8                          -- minimal number of cols to display to left and right of cursor
opt.signcolumn = "yes"                         -- always display the sign column (gutter) to prevent text shifting constantly
opt.splitbelow = true                          -- force all horizontal splits to go below current window
opt.splitright = true                          -- force all vertical splits to go to the right of current window
opt.termguicolors = true                       -- allow neovim to use colors the terminal emulator supplies
opt.wrap = false                               -- do not wrap when displaying long lines

-- Text editing options
opt.completeopt = { "menuone", "noselect" }    -- configuration for cmp completion popup window
opt.expandtab = true                           -- inserts spaces instead of tabs
opt.ignorecase = true                          -- ignore case when searching (e.g. lowercase word will find uppercase words)
opt.iskeyword:append("-")                      -- treat `-` as part of word when using cw, dw, etc.
opt.shiftwidth = 2                             -- the number of spaces for each level of indent
opt.smartcase = true                           -- if search word includes uppercase char, swithc to case sensitive search
opt.smartindent = true                         -- smart indent based on characters typed (e.g. `{`, `do`)
opt.tabstop = 2                                -- number of spaces a tab counts as

