return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>lf",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        mode = { "n", "v" },
        desc = "Format buffer / selection",
      },
    },
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
