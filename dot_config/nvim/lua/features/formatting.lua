-- TODO: There is no keymap for invoking conform.format() on demand — only the
-- BufWritePre autocmd runs the formatter. Add a `<leader>lf` (or similar under
-- the LSP group) key that calls `require("conform").format({ async = true,
-- lsp_format = "fallback" })`, and register it with which-key. Useful when the
-- user wants to format without saving, or format a visual selection.
return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = {
        elixir = { "mix" },
        heex = { "mix" },
        eelixir = { "mix" },
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
      },
      -- Format on save; timeout keeps it from hanging on slow projects
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
      },
    },
  },
}
