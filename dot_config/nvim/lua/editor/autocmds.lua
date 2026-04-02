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

    -- Focus current heading: collapse sibling/child folds, keep ancestors open
    vim.keymap.set("n", "<leader>zf", function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local level = 1
      for i = row, 1, -1 do
        local text = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        local hashes = text:match("^(#+)%s")
        if hashes then
          level = #hashes
          break
        end
      end
      vim.opt_local.foldlevel = level - 1
      vim.cmd("normal! zv")
    end, {
      buffer = ev.buf,
      desc = "Focus current heading",
    })

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ { "<leader>zf", buffer = ev.buf, desc = "Focus current heading" } })
    end
  end,
})
