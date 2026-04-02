local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = "markdown",
  callback = function(ev)
    vim.opt_local.textwidth = 80
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldenable = true

    -- Focus current heading: close all folds, then reveal cursor position
    vim.keymap.set("n", "<leader>zf", "zMzv", {
      buffer = ev.buf,
      desc = "Focus current heading",
    })

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ { "<leader>zf", buffer = ev.buf, desc = "Focus current heading" } })
    end
  end,
})
