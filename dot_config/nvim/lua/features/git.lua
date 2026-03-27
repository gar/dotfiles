-- Git integration via gitsigns.nvim
-- Shows signs in the gutter for added/changed/removed lines and inline
-- virtual-text git blame on the current line (dimmed, via Comment highlight).
--
-- Keymaps:
--   <leader>gb  — Toggle current-line blame visibility

return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
  config = function()
    require("gitsigns").setup({
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 300,
      },
      current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> · <summary>",
    })

    vim.keymap.set("n", "<leader>gb", function()
      require("gitsigns").toggle_current_line_blame()
    end, { desc = "Toggle git blame" })
  end,
}
