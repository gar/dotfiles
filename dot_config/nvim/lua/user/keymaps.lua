local keymap = vim.api.nvim_set_keymap
local g = vim.g

local opts = { noremap = true, silent = true }
local term_opts = { silent = true }

-- Remap leader key to space
keymap("", "<Space>", "<Nop>", opts)
g.mapleader = " "
g.maplocalleader = " "

-- Open file explorer
keymap("n", "<Leader>e", ":Lexplore 15<CR>", opts)

-- Resize with arrow keys
keymap("n", "<A-Up>", ":resize +2<CR>", opts)
keymap("n", "<A-Down>", ":resize -2<CR>", opts)
keymap("n", "<A-Left>", ":vertical resize +2<CR>", opts)
keymap("n", "<A-Right>", ":vertical resize -2<CR>", opts)

-- Move lines up and down
keymap("x", "J", ":move '>+1<CR>gv-gv", opts)
keymap("x", "K", ":move '<-2<CR>gv-gv", opts)

-- When pasting over a word, don't replace clipboard with that word
keymap("v", "p", '"_dP', opts)

-- Better terminal navigation
keymap("t", "<C-w>h", "<C-\\><C-N><C-w>h", term_opts)
keymap("t", "<C-w>j", "<C-\\><C-N><C-w>j", term_opts)
keymap("t", "<C-w>k", "<C-\\><C-N><C-w>k", term_opts)
keymap("t", "<C-w>l", "<C-\\><C-N><C-w>l", term_opts)

-- Telescope
keymap("n", "<C-p>", "<cmd>lua require'telescope.builtin'.find_files(require('telescope.themes').get_dropdown({ previewer = false }))<cr>", opts)
keymap("n", "<C-t>", "<cmd>Telescope live_grep<cr>", opts)
