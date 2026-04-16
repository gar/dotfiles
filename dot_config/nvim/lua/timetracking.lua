-- Watson-based time tracking for todos in the Obsidian vault.
-- Keymaps (<leader>nc*) are buffer-local, active only in ~/notes/**/*.md.
--
-- Workflow:
--   <leader>ncs  toggle timer: start on current todo, or stop + complete it
--   <leader>ncS  stop timer only (no checkbox change)
--   <leader>ncr  show this week's Watson report in a floating window
--
-- Watson project is derived from context:
--   - Nearest markdown heading above cursor  (any level)
--   - Filename stem if in a journal note and no heading found
--   - First H1 heading (or filename stem) for all other notes

-- ---------------------------------------------------------------------------
-- Markdown stripping
-- ---------------------------------------------------------------------------

-- Remove common markdown formatting from a string so it is suitable as a
-- Watson project name or tag.  Order matters: handle multi-char delimiters
-- before their single-char subsets.
local function strip_markdown(text)
  -- [[wikilinks]] → inner text
  text = text:gsub("%[%[(.-)%]%]", "%1")
  -- [display](url) → display text
  text = text:gsub("%[(.-)%]%((.-)%)", "%1")
  -- ~~strikethrough~~
  text = text:gsub("~~(.-)~~", "%1")
  -- **bold** and __bold__
  text = text:gsub("%*%*(.-)%*%*", "%1")
  text = text:gsub("__(.-)__", "%1")
  -- *italic* and _italic_
  text = text:gsub("%*(.-)%*", "%1")
  text = text:gsub("_(.-)_", "%1")
  -- `inline code`
  text = text:gsub("`(.-)`", "%1")
  -- leading heading markers (e.g. "## Section")
  text = text:gsub("^#+%s*", "")
  return vim.trim(text)
end

-- ---------------------------------------------------------------------------
-- Context helpers
-- ---------------------------------------------------------------------------

-- Extract the task description from the current line, stripping the checkbox
-- prefix (e.g. "- [ ] ", "  * [x] ") and any residual markdown.
local function get_todo_text()
  local line = vim.api.nvim_get_current_line()
  -- Capture everything after the checkbox marker
  local text = line:match("^%s*[%-%*]%s*%[.%]%s*(.+)$")
  -- Fall back to text after a bare list marker
  if not text then
    text = line:match("^%s*[%-%*]%s*(.+)$") or vim.trim(line)
  end
  return strip_markdown(vim.trim(text))
end

-- Walk backwards from the cursor line and return the first markdown heading
-- found (any level), with formatting stripped.  Returns nil if none found.
local function get_nearest_heading()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  for i = cursor_line, 1, -1 do
    local heading = lines[i]:match("^#+%s+(.+)$")
    if heading then
      return strip_markdown(heading)
    end
  end
  return nil
end

-- Derive a Watson project string from the current buffer and cursor position:
--   1. Nearest heading above cursor (any level)
--   2. Filename stem for journal notes (daily / weekly / monthly)
--   3. First H1 heading in the file, or the filename stem
local function get_project()
  local bufname = vim.api.nvim_buf_get_name(0)

  local heading = get_nearest_heading()
  if heading and heading ~= "" then return heading end

  local is_journal = bufname:match("/journal/daily/")
    or bufname:match("/journal/weekly/")
    or bufname:match("/journal/monthly/")

  if is_journal then
    -- Stem is already a date/period string: 2026-04-16, 2026-W16, 2026-04
    return vim.fn.fnamemodify(bufname, ":t:r")
  end

  -- Non-journal: use the first H1 heading or the filename stem
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local h1 = line:match("^#%s+(.+)$")
    if h1 then return strip_markdown(h1) end
  end
  return vim.fn.fnamemodify(bufname, ":t:r")
end

-- ---------------------------------------------------------------------------
-- Watson wrappers
-- ---------------------------------------------------------------------------

local function watson_available()
  return vim.fn.executable("watson") == 1
end

-- Returns true when Watson has a running frame.
-- "No project started." is Watson's idle message.
local function watson_is_running()
  local out = vim.fn.trim(vim.fn.system({ "watson", "status" }))
  return not out:match("^No project started")
end

-- ---------------------------------------------------------------------------
-- Extmark state
-- ---------------------------------------------------------------------------

local ns = vim.api.nvim_create_namespace("timetracking")

-- Tracks the single active timer's location so the gutter icon can be
-- cleared or re-applied across buffer reloads.
-- Shape: { bufnr, line (0-indexed), extmark_id }  or  nil
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

-- ---------------------------------------------------------------------------
-- Timer actions
-- ---------------------------------------------------------------------------

local function start_timer()
  if not watson_available() then
    vim.notify("watson not found — install it first", vim.log.levels.ERROR)
    return
  end

  local project = get_project()
  local todo    = get_todo_text()

  if todo == "" then
    vim.notify("No todo text on current line", vim.log.levels.WARN)
    return
  end

  -- Watson errors if you start while a frame is open; stop silently first.
  if watson_is_running() then
    vim.fn.system({ "watson", "stop" })
    clear_extmark()
  end

  -- Pass the tag as a single arg prefixed with "+".  Because we use a table
  -- (no shell), special characters in `todo` (including "+") need no escaping
  -- — they are passed verbatim to Watson as one argument.
  vim.fn.system({ "watson", "start", project, "+" .. todo })

  if vim.v.shell_error ~= 0 then
    vim.notify("watson start failed", vim.log.levels.ERROR)
    return
  end

  local bufnr  = vim.api.nvim_get_current_buf()
  local line_0 = vim.api.nvim_win_get_cursor(0)[1] - 1
  local eid    = set_extmark(bufnr, line_0)
  active = { bufnr = bufnr, line = line_0, extmark_id = eid }

  vim.notify(("⏱ [%s] %s"):format(project, todo), vim.log.levels.INFO)
end

-- Stop the running timer.  When `complete` is true, also toggle the checkbox
-- on the current line from [ ] to [x].
local function stop_timer(complete)
  if not watson_available() then
    vim.notify("watson not found — install it first", vim.log.levels.ERROR)
    return
  end

  if not watson_is_running() then
    vim.notify("No timer running", vim.log.levels.WARN)
    return
  end

  vim.fn.system({ "watson", "stop" })
  clear_extmark()

  if complete then
    local line     = vim.api.nvim_get_current_line()
    local new_line = line:gsub("^(%s*[%-%*]%s*)%[ %]", "%1[x]", 1)
    if new_line ~= line then
      vim.api.nvim_set_current_line(new_line)
    end
    vim.notify("⏹ Done", vim.log.levels.INFO)
  else
    vim.notify("⏹ Stopped", vim.log.levels.INFO)
  end
end

-- Single keymap: start if idle, stop+complete if running.
local function toggle_timer()
  if watson_is_running() then
    stop_timer(true)
  else
    start_timer()
  end
end

-- ---------------------------------------------------------------------------
-- Report floating window
-- ---------------------------------------------------------------------------

local function show_report()
  if not watson_available() then
    vim.notify("watson not found — install it first", vim.log.levels.ERROR)
    return
  end

  local lines = vim.fn.systemlist({ "watson", "report", "--week" })
  if #lines == 0 then
    lines = { "No time entries this week." }
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local width  = math.min(80, vim.o.columns - 4)
  local height = math.min(math.max(#lines, 3), vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative   = "editor",
    width      = width,
    height     = height,
    row        = math.floor((vim.o.lines - height) / 2),
    col        = math.floor((vim.o.columns - width) / 2),
    style      = "minimal",
    border     = "rounded",
    title      = " Watson: this week ",
    title_pos  = "center",
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

-- When re-entering the buffer that holds the active timer, re-apply the gutter
-- icon in case the buffer was reloaded (which destroys extmarks).
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("timetracking_extmark", { clear = true }),
  callback = function()
    if not active then return end
    if not watson_is_running() then
      active = nil
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    if bufnr ~= active.bufnr then return end
    -- Delete stale extmark (no-op if already gone), then re-apply.
    pcall(vim.api.nvim_buf_del_extmark, bufnr, ns, active.extmark_id)
    active.extmark_id = set_extmark(bufnr, active.line)
  end,
})

-- ---------------------------------------------------------------------------
-- Buffer-local keymaps (vault files only)
-- ---------------------------------------------------------------------------

local vault_pattern = vim.fn.expand("~/notes/") .. "**/*.md"

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group   = vim.api.nvim_create_augroup("timetracking_keys", { clear = true }),
  pattern = vault_pattern,
  callback = function(ev)
    local buf  = ev.buf
    local bopts = { buffer = buf }

    vim.keymap.set("n", "<leader>ncs", toggle_timer,
      vim.tbl_extend("force", bopts, { desc = "Timer: start / stop+complete" }))
    vim.keymap.set("n", "<leader>ncS", function() stop_timer(false) end,
      vim.tbl_extend("force", bopts, { desc = "Timer: stop only" }))
    vim.keymap.set("n", "<leader>ncr", show_report,
      vim.tbl_extend("force", bopts, { desc = "Timer: weekly report" }))

    -- which-key: buffer-local keymaps are not auto-discovered, register explicitly
    local ok, wk = pcall(require, "which-key")
    if not ok then return end
    wk.add({
      { "<leader>ncs", buffer = buf, desc = "Timer: start / stop+complete" },
      { "<leader>ncS", buffer = buf, desc = "Timer: stop only" },
      { "<leader>ncr", buffer = buf, desc = "Timer: weekly report" },
    })
  end,
})
