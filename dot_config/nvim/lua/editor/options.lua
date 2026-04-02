local opt = vim.opt

local home = os.getenv("HOME")

-- Ensure mise shims are in PATH so Mason can find npm, node, etc.
-- Neovim launched outside a shell (GUI, launchd) doesn't inherit mise's PATH.
local mise_shims = home .. "/.local/share/mise/shims"
if vim.fn.isdirectory(mise_shims) == 1 then
  vim.env.PATH = mise_shims .. ":" .. vim.env.PATH
end

-- Leader key (must be set before lazy.nvim loads plugins)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Backups and undo
opt.backup = true
opt.backupdir = home .. "/.local/share/nvim/backup//"
opt.undofile = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Font (GUI clients: Neovide, etc.)
opt.guifont = "JetBrainsMono Nerd Font:h13"

-- Appearance
opt.cmdheight = 2
opt.cursorline = true
opt.laststatus = 2
opt.number = true
opt.pumheight = 10
opt.ruler = true
opt.scrolloff = 8
opt.showtabline = 2
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.splitbelow = true
opt.splitright = true
opt.termguicolors = true
opt.conceallevel = 1
opt.wrap = false

-- Text editing
opt.completeopt = { "menuone", "noselect" }
opt.expandtab = true
opt.ignorecase = true
opt.iskeyword:append("-")
opt.shiftwidth = 2
opt.smartcase = true
opt.smartindent = true
opt.tabstop = 2
