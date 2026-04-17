-- Watson-based time tracking for todos in the Obsidian vault.
-- Keymaps are buffer-local, active only in ~/notes/**/*.md.
--
-- <leader>ns  smart timer toggle:
--               not running + on open todo      → start
--               running + on active todo line   → stop
--               running + on different todo     → stop + start new
--               running + not on a todo         → stop only
-- <leader>nS  weekly summary in a floating window
--
-- Watson project is derived from context:
--   - Nearest markdown heading above cursor (any level)
--   - Filename stem for journal notes (YYYY-MM-DD / YYYY-Wnn / YYYY-MM)
--   - First H1 heading or filename stem for all other notes

-- ---------------------------------------------------------------------------
-- Markdown stripping
-- ---------------------------------------------------------------------------

-- Remove common markdown formatting so text is suitable as a Watson project
-- name or tag.  Order matters: handle multi-char delimiters before subsets.
local function strip_markdown(text)
  text = text:gsub("%[%[(.-)%]%]", "%1")        -- [[wikilinks]]
  text = text:gsub("%[(.-)%]%((.-)%)", "%1")    -- [display](url)
  text = text:gsub("~~(.-)~~", "%1")            -- ~~strikethrough~~
  text = text:gsub("%*%*(.-)%*%*", "%1")        -- **bold**
  text = text:gsub("__(.-)__", "%1")            -- __bold__
  text = text:gsub("%*(.-)%*", "%1")            -- *italic*
  text = text:gsub("_(.-)_", "%1")              -- _italic_
  text = text:gsub("`(.-)`", "%1")              -- `code`
  text = text:gsub("^#+%s*", "")                -- ## heading prefix
  return vim.trim(text)
end

-- ---------------------------------------------------------------------------
-- Context helpers
-- ---------------------------------------------------------------------------

-- True if the current line is an open todo (checkbox state " ").
local function is_open_todo()
  return vim.api.nvim_get_current_line():match("^%s*[%-%*]%s*%[ %]%s*(.+)$") ~= nil
end

-- Extract the task description from the current line, stripping the checkbox
-- prefix and any residual markdown.
local function get_todo_text()
  local line = vim.api.nvim_get_current_line()
  local text = line:match("^%s*[%-%*]%s*%[.%]%s*(.+)$")
    or line:match("^%s*[%-%*]%s*(.+)$")
    or vim.trim(line)
  return strip_markdown(vim.trim(text))
end

-- Walk backwards from the cursor and return the nearest heading (any level),
-- markdown-stripped.  Returns nil if none found.
local function get_nearest_heading()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  for i = cursor_line, 1, -1 do
    local h = lines[i]:match("^#+%s+(.+)$")
    if h then return strip_markdown(h) end
  end
  return nil
end

-- Derive a Watson project string from the current buffer + cursor position.
local function get_project()
  local bufname = vim.api.nvim_buf_get_name(0)

  local heading = get_nearest_heading()
  if heading and heading ~= "" then return heading end

  local is_journal = bufname:match("/journal/daily/")
    or bufname:match("/journal/weekly/")
    or bufname:match("/journal/monthly/")

  if is_journal then
    return vim.fn.fnamemodify(bufname, ":t:r")
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local h1 = line:match("^#%s+(.+)$")
    if h1 then return strip_markdown(h1) end
  end
  return vim.fn.fnamemodify(bufname, ":t:r")
end

-- Extract #hashtags from text, returning (cleaned_text, tags_list).
-- Consecutive spaces left behind are collapsed; result is trimmed.
local function extract_markdown_tags(text)
  local tags = {}
  local cleaned = text:gsub("#([%w_%-]+)", function(tag)
    table.insert(tags, tag)
    return ""
  end)
  return vim.trim(cleaned:gsub("%s+", " ")), tags
end

-- ---------------------------------------------------------------------------
-- Watson wrappers
-- ---------------------------------------------------------------------------

local function watson_is_running()
  local out = vim.fn.trim(vim.fn.system({ "watson", "status" }))
  return not out:match("^No project started")
end

local function ensure_watson()
  if vim.fn.executable("watson") == 1 then return true end
  vim.notify("watson not found — install it first", vim.log.levels.ERROR)
  return false
end

-- ---------------------------------------------------------------------------
-- Extmark state
-- ---------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace("timetracking")

-- { bufnr, line (0-indexed), extmark_id }  or  nil
local active = nil

local function clear_extmark()
  if active then
    pcall(vim.api.nvim_buf_del_extmark, active.bufnr, ns, active.extmark_id)
    active = nil
  end
end

local function set_extmark(bufnr, line_0)
  return vim.api.nvim_buf_set_extmark(bufnr, ns, line_0, 0, {
    virt_text     = { { "⏱", "DiagnosticWarn" } },
    virt_text_pos = "eol",
  })
end

-- Re-create the active extmark in place. Needed after :e reloads the buffer,
-- which drops all extmarks.
local function refresh_extmark()
  pcall(vim.api.nvim_buf_del_extmark, active.bufnr, ns, active.extmark_id)
  active.extmark_id = set_extmark(active.bufnr, active.line)
end

local function start_on_current_line()
  -- Drop any stale extmark before creating a new one. Without this, if
  -- `active` got out of sync (e.g. watson stopped externally in a terminal
  -- without nvim noticing via BufEnter), the previous stopwatch icon would
  -- be orphaned when we overwrite `active` below.
  clear_extmark()

  local project    = get_project()
  local todo       = get_todo_text()
  local text, tags = extract_markdown_tags(todo)
  -- No shell is involved so special characters need no escaping.
  local cmd = { "watson", "start", project, "+" .. text }
  for _, tag in ipairs(tags) do
    table.insert(cmd, "+" .. tag)
  end
  vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("watson start failed", vim.log.levels.ERROR)
    return false
  end
  local bufnr  = vim.api.nvim_get_current_buf()
  local line_0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  active = { bufnr = bufnr, line = line_0, extmark_id = set_extmark(bufnr, line_0) }
  vim.notify(("⏱ [%s] %s"):format(project, text), vim.log.levels.INFO)
  return true
end

-- ---------------------------------------------------------------------------
-- Smart toggle  (<leader>ns)
-- ---------------------------------------------------------------------------

local function handle_ns()
  if not ensure_watson() then return end

  local on_todo = is_open_todo()

  if not watson_is_running() then
    if not on_todo then
      vim.notify("No open todo on current line", vim.log.levels.WARN)
      return
    end
    start_on_current_line()
    return
  end

  local bufnr  = vim.api.nvim_get_current_buf()
  local line_0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local on_active_line = active
    and active.bufnr == bufnr
    and active.line == line_0

  vim.fn.system({ "watson", "stop" })
  clear_extmark()

  if on_todo and not on_active_line then
    start_on_current_line()
  else
    vim.notify("⏹ Stopped", vim.log.levels.INFO)
  end
end

-- ---------------------------------------------------------------------------
-- Weekly summary  (<leader>nS)
-- ---------------------------------------------------------------------------

local function show_summary()
  if not ensure_watson() then return end

  local lines = vim.fn.systemlist({ "watson", "report", "--week" })
  if #lines == 0 then lines = { "No time entries this week." } end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width  = math.min(80, vim.o.columns - 4)
  local height = math.min(math.max(#lines, 3), vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = math.floor((vim.o.lines - height) / 2),
    col       = math.floor((vim.o.columns - width) / 2),
    style     = "minimal",
    border    = "rounded",
    title     = " Watson: this week ",
    title_pos = "center",
  })

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      vim.api.nvim_win_close(win, true)
    end, { buffer = buf, nowait = true })
  end
end

-- ---------------------------------------------------------------------------
-- Extmark persistence across buffer reloads
-- ---------------------------------------------------------------------------

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("timetracking_extmark", { clear = true }),
  callback = function()
    if not active then return end
    if vim.api.nvim_get_current_buf() ~= active.bufnr then return end
    if not watson_is_running() then clear_extmark(); return end
    refresh_extmark()
  end,
})

-- ---------------------------------------------------------------------------
-- Buffer-local keymaps (vault files only)
-- ---------------------------------------------------------------------------

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group   = vim.api.nvim_create_augroup("timetracking_keys", { clear = true }),
  pattern = vim.fn.expand("~/notes/") .. "**/*.md",
  callback = function(ev)
    local buf = ev.buf
    vim.keymap.set("n", "<leader>ns", handle_ns,
      { buffer = buf, desc = "Timer: start / stop / transition" })
    vim.keymap.set("n", "<leader>nS", show_summary,
      { buffer = buf, desc = "Timer: weekly summary" })

    -- which-key: buffer-local keymaps must be registered explicitly
    local ok, wk = pcall(require, "which-key")
    if not ok then return end
    wk.add({
      { "<leader>ns", buffer = buf, desc = "Timer: start / stop / transition" },
      { "<leader>nS", buffer = buf, desc = "Timer: weekly summary" },
    })
  end,
})
