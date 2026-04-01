return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>",     desc = "Toggle floating terminal" },
    { "<leader>ta", desc = "Toggle agent terminal" },
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

    -- Dedicated agent terminal (terminal id=2, separate from the general <C-\> terminal)
    local Terminal = require("toggleterm.terminal").Terminal
    local agent_term = Terminal:new({
      id = 2,
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
    })
    vim.keymap.set("n", "<leader>ta", function() agent_term:toggle() end, { desc = "Toggle agent terminal" })
  end,
}
