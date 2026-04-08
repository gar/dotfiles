return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  ft = { "markdown" },
  opts = {
    sign = {
      enabled = false,
    },
    code = {
      language_name = false,
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
      },
      custom = {
        forwarded = {
          raw = "[>]",
          rendered = "→ ",
          highlight = "RenderMarkdownForwarded",
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
    vim.api.nvim_set_hl(0, "RenderMarkdownForwarded", { fg = "#7daea3" })       -- blue
    vim.api.nvim_set_hl(0, "RenderMarkdownCancelled", { fg = "#928374" })       -- grey
    vim.api.nvim_set_hl(0, "RenderMarkdownCancelledLine", { fg = "#928374", strikethrough = true })
    require("render-markdown").setup(opts)
  end,
}
