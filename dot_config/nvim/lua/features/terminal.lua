return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>", desc = "Toggle floating terminal" },
  },
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = {
        border = "rounded",
        width = function()
          return math.floor(vim.o.columns * 0.85)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.80)
        end,
        winblend = 3,
      },
      shade_terminals = false,
      persist_mode = true,
    })

    -- Use <Esc> to exit terminal insert mode
    vim.keymap.set("t", "<Esc>", "<C-\\><C-N>", { desc = "Terminal: exit insert mode" })
  end,
}
