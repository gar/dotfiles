return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    -- config is deferred to nvim-lspconfig block so capabilities/on_attach are available
  },
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Diagnostic signs
      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "" },
        { name = "DiagnosticSignInfo", text = "" },
      }
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end

      vim.diagnostic.config({
        virtual_text = false,
        signs = { active = signs },
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- On attach: set buffer-local keymaps and highlight references
      local on_attach = function(client, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover documentation")
        map("gi", vim.lsp.buf.implementation, "Go to implementation")
        map("<C-k>", function() vim.lsp.buf.signature_help({ border = "rounded" }) end, "Signature help")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("gr", vim.lsp.buf.references, "Show references")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>f", vim.diagnostic.open_float, "Open diagnostic float")
        map("[d", function() vim.diagnostic.goto_prev({ float = { border = "rounded" } }) end, "Previous diagnostic")
        map("]d", function() vim.diagnostic.goto_next({ float = { border = "rounded" } }) end, "Next diagnostic")
        map("gl", vim.diagnostic.open_float, "Line diagnostics")
        map("<leader>q", vim.diagnostic.setloclist, "Diagnostics to location list")

        -- Register LSP keymaps with which-key so they appear in the popup.
        -- Buffer-local keymaps set via vim.keymap.set inside on_attach are not
        -- auto-discovered by which-key, so they must be registered explicitly.
        local ok, wk = pcall(require, "which-key")
        if ok then
          wk.add({
            { "g",           buffer = bufnr, group = "Go to" },
            { "gd",          buffer = bufnr, desc = "Go to definition" },
            { "gD",          buffer = bufnr, desc = "Go to declaration" },
            { "gi",          buffer = bufnr, desc = "Go to implementation" },
            { "gr",          buffer = bufnr, desc = "Show references" },
            { "K",           buffer = bufnr, desc = "Hover documentation" },
            { "gl",          buffer = bufnr, desc = "Line diagnostics" },
            { "[d",          buffer = bufnr, desc = "Previous diagnostic" },
            { "]d",          buffer = bufnr, desc = "Next diagnostic" },
            { "<leader>rn",  buffer = bufnr, desc = "Rename symbol" },
            { "<leader>ca",  buffer = bufnr, desc = "Code action" },
            { "<leader>q",   buffer = bufnr, desc = "Diagnostics to location list" },
          })
        end

        vim.api.nvim_buf_create_user_command(bufnr, "Format", function()
          vim.lsp.buf.format({ async = true })
        end, { desc = "Format buffer with LSP" })

        -- Disable formatting for tsserver (use dedicated formatters instead)
        if client.name == "ts_ls" then
          client.server_capabilities.documentFormattingProvider = false
        end

        -- Highlight references on cursor hold
        if client.server_capabilities.documentHighlightProvider then
          local highlight_group = vim.api.nvim_create_augroup("LspDocumentHighlight", { clear = false })
          vim.api.nvim_clear_autocmds({ buffer = bufnr, group = highlight_group })
          vim.api.nvim_create_autocmd("CursorHold", {
            group = highlight_group,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd("CursorMoved", {
            group = highlight_group,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end

      -- Capabilities (enhanced with blink.cmp)
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Register custom servers not in lspconfig's built-in registry.
      -- Call vim.lsp.config first (Neovim 0.11+ requirement) then register with lspconfig.
      vim.lsp.config("expert", {
        cmd = { vim.fn.expand("~/bin/expert"), "--stdio" },
        filetypes = { "elixir", "eelixir", "heex" },
        root_markers = { "mix.exs", ".git" },
      })
      local lspconfig_configs = require("lspconfig.configs")
      if not lspconfig_configs.expert then
        lspconfig_configs.expert = {
          default_config = {
            cmd = { vim.fn.expand("~/bin/expert"), "--stdio" },
            filetypes = { "elixir", "eelixir", "heex" },
            root_dir = function(fname)
              return require("lspconfig").util.root_pattern("mix.exs", ".git")(fname) or vim.loop.cwd()
            end,
          },
        }
      end

      -- Server-specific settings
      local server_settings = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = {
                  [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                  [vim.fn.stdpath("config") .. "/lua"] = true,
                },
              },
            },
          },
        },
        -- Override default filetypes to remove compound types (javascript.jsx,
        -- typescript.tsx) that Neovim doesn't recognise as standard filetypes.
        ts_ls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
          },
        },
      }

      -- Mason-managed servers (custom servers like "expert" are excluded)
      local mason_servers = { "lua_ls", "pyright", "ts_ls" }
      require("mason-lspconfig").setup({
        ensure_installed = mason_servers,
        -- Exclude formatters/linters that mason installs but are not LSP servers;
        -- automatic_enable would otherwise try to enable them and warn.
        automatic_enable = {
          exclude = { "stylua" },
        },
      })

      -- All servers to configure (includes custom servers not managed by mason)
      local servers = { "lua_ls", "pyright", "ts_ls", "expert" }
      for _, server_name in ipairs(servers) do
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }
        if server_settings[server_name] then
          opts = vim.tbl_deep_extend("force", opts, server_settings[server_name])
        end
        require("lspconfig")[server_name].setup(opts)
      end
    end,
  },
}
