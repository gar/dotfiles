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

    -- Rename the current terminal buffer
    vim.keymap.set("n", "<leader>tr", function()
      if vim.bo.buftype ~= "terminal" then
        vim.notify("Not a terminal buffer", vim.log.levels.WARN)
        return
      end
      vim.ui.input({ prompt = "Terminal name: " }, function(name)
        if not name or name == "" then return end
        local ok, terms = pcall(require, "toggleterm.terminal")
        if ok then
          local term = terms.get(vim.b.toggle_number)
          if term then
            term.display_name = name
          end
        end
        pcall(vim.api.nvim_buf_set_name, 0, "term://" .. name)
      end)
    end, { desc = "Terminal: rename" })
  end,
}
