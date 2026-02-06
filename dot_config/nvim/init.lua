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

-- Load core settings before plugins
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Load plugins (each file in lua/plugins/ is auto-loaded)
require("lazy").setup("plugins", {
  ui = { border = "rounded" },
})
