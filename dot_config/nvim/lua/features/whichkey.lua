-- Keymap hints via which-key.nvim
-- Shows a popup after a brief timeout listing available key continuations.
-- Activates when you pause mid-sequence (e.g. after <leader>, g, [, ], z).

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 500, -- ms before popup appears
    icons = { mappings = false },
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)

    -- Group labels for leader-key prefixes used across the config
    wk.add({
      { "<leader>a",  group = "AI (Claude)" },
      { "<leader>d",  group = "Diff" },
      { "<leader>f",  group = "Find (Telescope)" },
      { "<leader>g",  group = "Git" },
      { "<leader>gw", group = "Worktrees" },
      { "<leader>l",  group = "LSP / Format" },
      { "<leader>n",  group = "Notes (Obsidian)" },
      { "<leader>nR", group = "Recent notes" },
      { "<leader>t",  group = "Terminal" },
      { "<leader>z",  group = "Folds" },
    })
  end,
}
