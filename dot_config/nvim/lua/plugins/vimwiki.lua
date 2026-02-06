return {
  {
    "vimwiki/vimwiki",
    event = "BufReadPre *.md",
    keys = { "<leader>ww", "<leader>wt" },
    init = function()
      local home = os.getenv("HOME")
      vim.g.vimwiki_list = {
        {
          path = home .. "/notes",
          syntax = "markdown",
          ext = ".md",
        },
      }
      vim.g.vimwiki_markdown_link_ext = 1
      vim.g.markdown_folding = true
    end,
  },
  {
    "tbabej/taskwiki",
    dependencies = { "vimwiki/vimwiki" },
    init = function()
      vim.g.taskwiki_markup_syntax = "markdown"
    end,
  },
  {
    "plasticboy/vim-markdown",
    ft = "markdown",
  },
}
