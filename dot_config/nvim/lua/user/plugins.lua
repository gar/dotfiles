local fn = vim.fn
local cmd = vim.cmd

-- Automatically install packer
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer, please close and reopen neovim..."
  cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Plugins
return packer.startup(function(use)
  use "wbthomason/packer.nvim" -- Have packer manage itself

  use "sainnhe/gruvbox-material" -- Nice color scheme

  use "nvim-lua/popup.nvim" -- Popup API in Neovim

  use "nvim-lua/plenary.nvim" -- Useful lua functions used by lots of plugins

  -- Treesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate"
  }

  -- LSP
  use "neovim/nvim-lspconfig"           -- enable LSP
  use "williamboman/nvim-lsp-installer" -- nice language server installer

  -- Completion
  use "hrsh7th/nvim-cmp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"
  use "hrsh7th/cmp-cmdline"
  use "saadparwaiz1/cmp_luasnip" -- allow snippets as a completion source
  use "hrsh7th/cmp-nvim-lsp"     -- allow language servers as a source
  use "hrsh7th/cmp-nvim-lua"     -- allow completion to become neovim lua config aware

  -- Snippets
  use "L3MON4D3/LuaSnip"             -- snippet engine
  use "rafamadriz/friendly-snippets" -- collection of useful snippets for various langs

  -- Telescope
  use "nvim-telescope/telescope.nvim"
  use "p00f/nvim-ts-rainbow"

  -- Vimwiki and related plugins
  use "vimwiki/vimwiki"
  use "tbabej/taskwiki"
  use "plasticboy/vim-markdown"

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
