local map = vim.keymap.set

-- Open file explorer
map("n", "<Leader>e", ":Lexplore 15<CR>", { desc = "Toggle file explorer" })

-- Resize splits with arrow keys
map("n", "<A-Up>", ":resize +2<CR>", { desc = "Increase window height" })
map("n", "<A-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
map("n", "<A-Left>", ":vertical resize +2<CR>", { desc = "Increase window width" })
map("n", "<A-Right>", ":vertical resize -2<CR>", { desc = "Decrease window width" })

-- Move lines up and down in visual mode
map("x", "J", ":move '>+1<CR>gv-gv", { desc = "Move selection down" })
map("x", "K", ":move '<-2<CR>gv-gv", { desc = "Move selection up" })

-- Paste without replacing clipboard
map("v", "p", '"_dP', { desc = "Paste without yanking replaced text" })

-- Terminal navigation
map("t", "<C-w>h", "<C-\\><C-N><C-w>h", { desc = "Terminal: move to left split" })
map("t", "<C-w>j", "<C-\\><C-N><C-w>j", { desc = "Terminal: move to below split" })
map("t", "<C-w>k", "<C-\\><C-N><C-w>k", { desc = "Terminal: move to above split" })
map("t", "<C-w>l", "<C-\\><C-N><C-w>l", { desc = "Terminal: move to right split" })
