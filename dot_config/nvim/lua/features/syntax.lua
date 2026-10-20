return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = function()
    if not vim.env.CI then
      require("nvim-treesitter").install({ "all" }):wait(300000)
    end
  end,
  config = function()
    -- Neovim 0.12 parses in 3ms async slices and leaves the C parser halted
    -- between them. A sync parse from another plugin (render-markdown) can
    -- resume that halted parse and get a tree that doesn't match the buffer,
    -- which surfaces as "Index out of bounds" in get_node_text.
    vim.g._ts_force_sync_parsing = true

    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- Enable treesitter highlighting for all filetypes that have a parser
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Enable treesitter-based indentation
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
