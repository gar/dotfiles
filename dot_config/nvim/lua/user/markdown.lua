-- TODO refactor this when lua api support autocmds
vim.api.nvim_command([[
  augroup auFileTypes
  autocmd!
  autocmd FileType markdown setlocal textwidth=80
  augroup end
]])
