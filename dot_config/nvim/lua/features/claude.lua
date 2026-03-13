-- Claude Code integration via claudecode.nvim
-- Establishes a WebSocket/MCP server that the Claude Code CLI connects to
-- automatically, giving Claude real-time awareness of open buffers,
-- selections, and diagnostics.
--
-- Keymaps (all use <leader>a for "AI"):
--   <leader>ac  — Toggle Claude Code panel (normal mode)
--   <leader>af  — Focus Claude Code panel (normal mode)
--   <leader>ar  — Resume last Claude Code session (normal mode)
--   <leader>as  — Send visual selection to Claude (visual mode)
--   <leader>aa  — Add current file to Claude context (normal mode)
--
-- Diff review (when Claude proposes changes):
--   <leader>dy  — Accept diff (ClaudeCodeDiffAccept)
--   <leader>dn  — Reject diff (ClaudeCodeDiffDeny)

return {
  "coder/claudecode.nvim",
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = {
        -- Enable only what claudecode.nvim needs; disable snacks features
        -- that would conflict with the existing Neovim setup.
        terminal = { enabled = true },
        -- Explicitly disable snacks features that overlap with existing plugins
        -- (telescope for fuzzy find, toggleterm for ad-hoc terminals, etc.)
        picker = { enabled = false },
        dashboard = { enabled = false },
        notifier = { enabled = false },
        statuscolumn = { enabled = false },
      },
    },
  },
  opts = {
    -- Auto-start the WebSocket server on Neovim startup so the Claude CLI
    -- can connect without any manual step.
    auto_start = true,

    -- Track the current visual selection and send it to Claude as context.
    track_selection = true,

    -- Don't steal focus back to the editor after sending a selection —
    -- keep Claude focused so you can immediately type a follow-up prompt.
    focus_after_send = true,

    terminal = {
      -- Open Claude in a right-side vertical split (keeps code visible).
      split_side = "right",
      -- ~38% of the total width is enough for Claude's responses while
      -- leaving the majority of the screen for code.
      split_width_percentage = 0.38,
      -- Prefer snacks terminal for consistent rendering.
      provider = "snacks",
      -- Close the terminal automatically when Claude exits.
      auto_close = true,
    },

    diff_opts = {
      -- Vertical split for diffs keeps the original and proposed change
      -- side-by-side, consistent with the rest of the layout.
      layout = "vertical",
      open_in_new_tab = false,
      -- Stay in the Claude panel while reviewing — navigate to the diff
      -- explicitly with <leader>dy / <leader>dn.
      keep_terminal_focus = true,
    },
  },
  keys = {
    -- Normal-mode toggles
    { "<leader>ac", "<cmd>ClaudeCode<cr>",        desc = "Toggle Claude Code" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",   desc = "Focus Claude Code" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude session" },
    -- Add the current file to Claude's context (@-mention)
    {
      "<leader>aa",
      function()
        vim.cmd("ClaudeCodeAdd " .. vim.fn.expand("%:p"))
      end,
      desc = "Add file to Claude context",
    },
    -- Visual-mode: send the selected lines to Claude
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    -- Diff accept / deny
    { "<leader>dy", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept Claude diff" },
    { "<leader>dn", "<cmd>ClaudeCodeDiffDeny<cr>",   desc = "Reject Claude diff" },
  },
}
