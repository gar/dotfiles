local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Conceal long URLs in markdown reference link definitions.
-- When the cursor is off the line, shows the link title if present,
-- otherwise truncates to domain/… (e.g. notion.so/…).
-- Title syntax is standard CommonMark: [0]: https://... "My Title"
local md_url_ns = vim.api.nvim_create_namespace("md_url_truncate")

local function md_shorten_url(url)
  local domain = url:match("https?://([^/]+)")
  if not domain then return url end
  return domain:gsub("^www%.", "") .. "/…"
end

local function md_parse_ref_link(line)
  -- Capture 1-indexed position of URL start after [label]: whitespace
  local url_col = line:match("^%s*%[.-%]:%s+()")
  if not url_col then return nil end
  url_col = url_col - 1 -- convert to 0-indexed

  local rest = line:sub(url_col + 1)
  local url, after_url

  -- Angle-bracket URL form: <https://...>
  url, after_url = rest:match("^<(.-)>%s*(.*)")
  if not url then
    -- Plain URL form
    url, after_url = rest:match("^(%S+)%s*(.*)")
    after_url = after_url or ""
  end

  if not url or not url:match("^https?://") then return nil end

  local title = after_url:match('^"(.-)"')
    or after_url:match("^'(.-)'")
    or after_url:match("^%((.-)%)")

  return url_col, url, title
end

local function update_md_url_conceals(bufnr, cursor_row)
  vim.api.nvim_buf_clear_namespace(bufnr, md_url_ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local row = i - 1
    if row ~= cursor_row then
      local url_col, url, title = md_parse_ref_link(line)
      if url_col then
        local display = (title and title ~= "") and title or md_shorten_url(url)
        vim.api.nvim_buf_set_extmark(bufnr, md_url_ns, row, url_col, {
          end_col = #line,
          conceal = "",
        })
        vim.api.nvim_buf_set_extmark(bufnr, md_url_ns, row, url_col, {
          virt_text = { { display, "RenderMarkdownLink" } },
          virt_text_pos = "inline",
        })
      end
    end
  end
end

augroup("MdUrlConceal", { clear = true })
autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" }, {
  group = "MdUrlConceal",
  pattern = "*.md",
  callback = function(ev)
    local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
    update_md_url_conceals(ev.buf, cursor_row)
  end,
})

augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = "markdown",
  callback = function(ev)
    vim.opt_local.textwidth = 80
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldenable = true
    vim.opt_local.spell = true
    vim.opt_local.spelllang = "en_gb"

    -- Focus current heading: collapse sibling/child folds, keep ancestors open
    vim.keymap.set("n", "<leader>zf", function()
      local row = vim.api.nvim_win_get_cursor(0)[1]
      local level = 1
      for i = row, 1, -1 do
        local text = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
        local hashes = text:match("^(#+)%s")
        if hashes then
          level = #hashes
          break
        end
      end
      vim.opt_local.foldlevel = level - 1
      vim.schedule(function()
        vim.cmd("normal! zv")
      end)
    end, {
      buffer = ev.buf,
      desc = "Focus current heading",
    })

    local ok, wk = pcall(require, "which-key")
    if ok then
      wk.add({ { "<leader>zf", buffer = ev.buf, desc = "Focus current heading" } })
    end
  end,
})
