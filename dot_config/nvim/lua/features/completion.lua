return {
  "saghen/blink.cmp",
  event = "InsertEnter",
  version = "1.*",
  opts = {
    keymap = { preset = "default" },
    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = "mono",
    },
    sources = {
      default = function()
        local providers = { "lsp", "path", "snippets", "buffer" }
        if package.loaded["obsidian"] then
          vim.list_extend(providers, { "obsidian", "obsidian_new", "obsidian_tags" })
        end
        return providers
      end,
    },
    cmdline = {
      sources = { "buffer", "cmdline" },
    },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 500 },
    },
    fuzzy = { implementation = "prefer_rust" },
  },
}
