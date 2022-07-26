HOME = os.getenv("HOME")

vim.g.vimwiki_list = {
  {
    path = HOME .. "/notes",
    syntax = "markdown",
    ext = ".md"
  }
}

vim.vimwiki_markdown_link_ext = true

vim.g.taskwiki_markup_syntax = "markdown"
vim.g.markdown_folding = true
