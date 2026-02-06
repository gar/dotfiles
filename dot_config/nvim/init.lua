-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load editor settings before features
require("editor.options")
require("editor.keymaps")
require("editor.autocmds")

-- Load features (each file in lua/features/ is auto-loaded by lazy.nvim)
require("lazy").setup("features", {
  ui = { border = "rounded" },
})
