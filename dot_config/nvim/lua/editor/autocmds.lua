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

-- ---------------------------------------------------------------------------
-- Markdown gq: reflow prose at textwidth, treating [[wikilinks]],
-- ![[embeds]], and [text](url) links as atomic tokens never split across lines.
-- Falls back to Neovim default for headings, list items, fences, and tables.
-- ---------------------------------------------------------------------------
local function md_reflow(lines, tw)
  local first = lines[1] or ""
  if first:match("^%s*[#>]") or first:match("^%s*[-*+] ")
    or first:match("^%s*%d+%. ") or first:match("^%s*```")
    or first:match("^%s*|") then
    return nil -- let Neovim handle it
  end
  -- Reference link definitions ([label]: url "title") — preserve verbatim
  if first:match("^%s*%[.-%]:%s") then return lines end

  local para = table.concat(lines, " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
  if para == "" then return { "" } end

  local tokens, i = {}, 1
  while i <= #para do
    while i <= #para and para:sub(i, i) == " " do i = i + 1 end
    if i > #para then break end

    local token, ni

    -- ![[obsidian embed]]
    if para:sub(i, i + 2) == "![[" then
      local j = para:find("%]%]", i + 3)
      if j then token, ni = para:sub(i, j + 1), j + 2 end
    end

    -- [[wikilink]] or [[wikilink|alias with spaces]]
    if not token and para:sub(i, i + 1) == "[[" then
      local j = para:find("%]%]", i + 2)
      if j then token, ni = para:sub(i, j + 1), j + 2 end
    end

    -- ![alt](url) or [text](url) — walk brackets to handle nesting
    if not token and (para:sub(i, i + 1) == "![" or para:sub(i, i) == "[") then
      local start = para:sub(i, i) == "!" and i + 1 or i
      local depth, j = 1, start + 1
      while j <= #para and depth > 0 do
        local c = para:sub(j, j)
        if c == "[" then depth = depth + 1
        elseif c == "]" then depth = depth - 1 end
        j = j + 1
      end
      if depth == 0 and para:sub(j, j) == "(" then
        local k = para:find("%)", j + 1)
        if k then token, ni = para:sub(i, k), k + 1 end
      end
    end

    -- plain word
    if not token then
      local j = para:find(" ", i)
      if j then token, ni = para:sub(i, j - 1), j + 1
      else token, ni = para:sub(i), #para + 1 end
    end

    if token ~= "" then table.insert(tokens, token) end
    i = ni
  end

  local result, cur = {}, ""
  for _, tok in ipairs(tokens) do
    if cur == "" then cur = tok
    elseif #cur + 1 + #tok <= tw then cur = cur .. " " .. tok
    else table.insert(result, cur); cur = tok end
  end
  if cur ~= "" then table.insert(result, cur) end
  return #result > 0 and result or { "" }
end

-- Exposed via _G so formatexpr can reference it with v:lua
_G._md_formatexpr = function()
  local tw = vim.bo.textwidth
  if tw <= 0 then return 1 end
  local s = vim.v.lnum - 1
  local n = vim.v.count
  local lines = vim.api.nvim_buf_get_lines(0, s, s + n, false)
  local result = md_reflow(lines, tw)
  if not result then return 1 end
  vim.api.nvim_buf_set_lines(0, s, s + n, false, result)
  return 0
end

-- Reflow every prose paragraph in a buffer, preserving structural blocks.
local function md_format_buffer(bufnr)
  local tw = vim.bo[bufnr].textwidth
  if tw <= 0 then tw = 80 end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local out, block = {}, {}
  local function flush()
    if #block > 0 then
      local r = md_reflow(block, tw) or block
      for _, l in ipairs(r) do out[#out + 1] = l end
      block = {}
    end
  end
  for _, line in ipairs(lines) do
    if line:match("^%s*$") then flush(); out[#out + 1] = line
    else block[#block + 1] = line end
  end
  flush()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
end

augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = "markdown",
  callback = function(ev)
    vim.opt_local.textwidth = 80
    vim.opt_local.formatoptions:remove({ "t", "c" })
    vim.opt_local.formatexpr = "v:lua._md_formatexpr()"

    autocmd("BufWritePre", {
      group = "FileTypeSettings",
      buffer = ev.buf,
      callback = function(e)
        local view = vim.fn.winsaveview()
        md_format_buffer(e.buf)
        vim.fn.winrestview(view)
      end,
    })

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
