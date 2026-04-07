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
