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
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "elixirls", "pyright", "ts_ls" },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
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

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
      })
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
      })

      -- On attach: set buffer-local keymaps and highlight references
      local on_attach = function(client, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        map("gD", vim.lsp.buf.declaration, "Go to declaration")
        map("gd", vim.lsp.buf.definition, "Go to definition")
        map("K", vim.lsp.buf.hover, "Hover documentation")
        map("gi", vim.lsp.buf.implementation, "Go to implementation")
        map("<C-k>", vim.lsp.buf.signature_help, "Signature help")
        map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map("gr", vim.lsp.buf.references, "Show references")
        map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("<leader>f", vim.diagnostic.open_float, "Open diagnostic float")
        map("[d", function() vim.diagnostic.goto_prev({ float = { border = "rounded" } }) end, "Previous diagnostic")
        map("]d", function() vim.diagnostic.goto_next({ float = { border = "rounded" } }) end, "Next diagnostic")
        map("gl", vim.diagnostic.open_float, "Line diagnostics")
        map("<leader>q", vim.diagnostic.setloclist, "Diagnostics to location list")

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

      -- Capabilities (enhanced with nvim-cmp)
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

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
        elixirls = {
          settings = {
            elixirLS = {
              dialyzerEnabled = true,
              fetchDeps = false,
            },
          },
        },
      }

      -- Set up all servers installed via mason
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          local opts = {
            on_attach = on_attach,
            capabilities = capabilities,
          }
          if server_settings[server_name] then
            opts = vim.tbl_deep_extend("force", opts, server_settings[server_name])
          end
          require("lspconfig")[server_name].setup(opts)
        end,
      })
    end,
  },
}
