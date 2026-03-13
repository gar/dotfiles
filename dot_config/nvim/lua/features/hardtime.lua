-- Habit training: warns when you repeat inefficient motions instead of using
-- a better Vim idiom. For example, pressing j/k more than a few times in a
-- row triggers a hint suggesting a count, search, or jump instead.
--
-- hardtime.nvim detects repeated use of h/j/k/l and arrow keys and nudges
-- you toward counts, motions (w/e/b/f/t/{/}), and jumps (gg/G/ctrl-d/u).

return {
  "m4xshen/hardtime.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  opts = {
    -- Show a hint notification rather than blocking the keypress.
    -- Set to true to also prevent the repeated key from registering.
    restriction_mode = "hint",

    -- Number of times a key can be pressed before a hint fires.
    max_time = 1000,
    max_count = 4,

    -- Disable inside these filetypes (navigating these with hjkl is fine).
    disabled_filetypes = { "qf", "netrw", "NvimTree", "lazy", "mason", "oil" },
  },
}
