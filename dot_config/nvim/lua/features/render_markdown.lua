return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  ft = { "markdown" },
  opts = {
    code = {
      language_icon = false,
      highlight_language = "Comment",
    },
    heading = {
      width = "block",
      icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
    },
    checkbox = {
      unchecked = {
        icon = "○ ",
        highlight = "RenderMarkdownUnchecked",
      },
      checked = {
        icon = "✓ ",
        highlight = "RenderMarkdownChecked",
        scope_highlight = "RenderMarkdownCheckedLine",
      },
      custom = {
        forwarded = {
          raw = "[>]",
          rendered = "→ ",
          highlight = "RenderMarkdownForwarded",
          scope_highlight = "RenderMarkdownForwardedLine",
        },
        cancelled = {
          raw = "[~]",
          rendered = "⊘ ",
          highlight = "RenderMarkdownCancelled",
          scope_highlight = "RenderMarkdownCancelledLine",
        },
      },
    },
  },
  config = function(_, opts)
    -- Gruvbox-material (medium/material) palette colours
    vim.api.nvim_set_hl(0, "RenderMarkdownCheckedLine", { fg = "#928374" })      -- grey (dimmed)
    vim.api.nvim_set_hl(0, "RenderMarkdownForwarded", { fg = "#7daea3" })       -- blue
    vim.api.nvim_set_hl(0, "RenderMarkdownForwardedLine", { fg = "#928374" })   -- grey (dimmed)
    vim.api.nvim_set_hl(0, "RenderMarkdownCancelled", { fg = "#928374" })       -- grey
    vim.api.nvim_set_hl(0, "RenderMarkdownCancelledLine", { fg = "#928374", strikethrough = true })
    require("render-markdown").setup(opts)
  end,
}
