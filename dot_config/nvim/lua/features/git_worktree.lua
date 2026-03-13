-- Git worktree management via ThePrimeagen/git-worktree.nvim
-- Integrates with Telescope for interactive worktree switching and creation.
--
-- Keymaps (all use <leader>gw for "git worktree"):
--   <leader>gwl  — List and switch between existing worktrees (Telescope picker)
--   <leader>gwc  — Create a new worktree from a branch (Telescope picker)

return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>gwl", desc = "List/switch worktrees" },
    { "<leader>gwc", desc = "Create worktree" },
  },
  config = function()
    require("git-worktree").setup()
    require("telescope").load_extension("git_worktree")

    vim.keymap.set("n", "<leader>gwl", function()
      require("telescope").extensions.git_worktree.git_worktrees()
    end, { desc = "List/switch worktrees" })

    vim.keymap.set("n", "<leader>gwc", function()
      require("telescope").extensions.git_worktree.create_git_worktree()
    end, { desc = "Create worktree" })
  end,
}
