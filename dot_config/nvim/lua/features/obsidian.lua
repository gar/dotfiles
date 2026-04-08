-- Obsidian-style markdown note-taking via obsidian.nvim.
-- Vault lives at ~/notes with the structure:
--   journal/daily/    YYYY-MM-DD.md
--   journal/weekly/   YYYY-WNN.md
--   journal/monthly/  YYYY-MM.md  (custom, not built-in)
--   templates/        daily.md, weekly.md, monthly.md
--   (everything else) free-form notes

local function open_monthly_note()
  local dir = vim.fn.expand("~/notes/journal/monthly/")
  vim.fn.mkdir(dir, "p")
  local path = dir .. os.date("%Y-%m") .. ".md"
  local is_new = vim.fn.filereadable(path) == 0
  vim.cmd("e " .. vim.fn.fnameescape(path))
  if is_new then
    vim.defer_fn(function()
      vim.cmd("Obsidian template monthly.md")
    end, 100)
  end
end

local function browse_journal(subfolder, title)
  require("telescope.builtin").find_files({
    prompt_title = title,
    cwd = vim.fn.expand("~/notes/journal/" .. subfolder),
    hidden = false,
  })
end

local function add_todo_to_daily()
  vim.ui.input({ prompt = "Todo: " }, function(input)
    if not input or input == "" then return end

    -- If input starts with YYYY-MM-DD, route to that date's note instead of today.
    local date_str, todo_text = input:match("^(%d%d%d%d%-%d%d%-%d%d)%s+(.+)$")

    -- daily() creates the note with template+frontmatter if it doesn't exist,
    -- or loads it if it does. It does NOT open a buffer (that's note:open(),
    -- which the :Obsidian today command calls after — we skip that here).
    local note
    if date_str then
      local y, m, d = date_str:match("(%d+)-(%d+)-(%d+)")
      local ts = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12, min = 0, sec = 0 })
      note = require("obsidian.daily").daily({ date = ts })
    else
      todo_text = input
      note = require("obsidian.daily").today()
    end
    local path = tostring(note.path)

    local todo_line = "- [ ] " .. todo_text

    -- Save the buffer first if it's open with unsaved changes, so readfile
    -- picks up the latest content and checktime doesn't prompt for a reload.
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].modified then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("write") end)
    end

    local lines = vim.fn.readfile(path)

    -- Find the first level-1 heading
    local heading_pos = nil
    for i, line in ipairs(lines) do
      if line:match("^# ") then
        heading_pos = i
        break
      end
    end

    if not heading_pos then
      table.insert(lines, todo_line)
      vim.fn.writefile(lines, path)
      return
    end

    -- Ensure a blank line immediately after the heading
    if heading_pos + 1 > #lines or lines[heading_pos + 1] ~= "" then
      table.insert(lines, heading_pos + 1, "")
    end

    -- Find the last consecutive list item starting at heading_pos + 2
    local last_todo = nil
    local pos = heading_pos + 2
    while pos <= #lines and lines[pos]:match("^[%*%-] ") do
      last_todo = pos
      pos = pos + 1
    end

    -- Append after last existing todo, or insert at heading_pos + 2 if none
    local insert_at = last_todo and (last_todo + 1) or (heading_pos + 2)
    table.insert(lines, insert_at, todo_line)

    -- Ensure a blank line after the todo block before any following content
    local after = insert_at + 1
    if after <= #lines and lines[after] ~= "" then
      table.insert(lines, after, "")
    end

    vim.fn.writefile(lines, path)

    -- Refresh the buffer if it happens to be open
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("checktime") end)
    end

    local label = date_str or "today"
    vim.notify('Todo captured to ' .. label .. ': "' .. todo_text .. '"', vim.log.levels.INFO)
  end)
end

-- Insert todos into a target daily-note file at the correct position:
-- after the last existing list item following the first # heading, or
-- right after the heading if there are none.
local function insert_todos_into_file(target_path, todo_lines)
  local lines = vim.fn.readfile(target_path)

  local heading_pos = nil
  for i, line in ipairs(lines) do
    if line:match("^# ") then
      heading_pos = i
      break
    end
  end

  if not heading_pos then
    for _, todo in ipairs(todo_lines) do
      table.insert(lines, todo)
    end
  else
    if heading_pos + 1 > #lines or lines[heading_pos + 1] ~= "" then
      table.insert(lines, heading_pos + 1, "")
    end

    local last_todo = nil
    local pos = heading_pos + 2
    while pos <= #lines and lines[pos]:match("^[%*%-] ") do
      last_todo = pos
      pos = pos + 1
    end

    local insert_at = last_todo and (last_todo + 1) or (heading_pos + 2)

    for i = #todo_lines, 1, -1 do
      table.insert(lines, insert_at, todo_lines[i])
    end

    local after = insert_at + #todo_lines
    if after <= #lines and lines[after] ~= "" then
      table.insert(lines, after, "")
    end
  end

  vim.fn.writefile(lines, target_path)
end

-- Create a daily note at `path` for `date_str` (YYYY-MM-DD) using obsidian's
-- template machinery. Falls back to a bare heading if the API isn't available.
local function create_daily_note_with_template(path, date_str)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  -- Compute integer day offset from today so we can call the right obsidian.daily fn.
  -- obsidian.daily.today/tomorrow/yesterday create the file+frontmatter from the
  -- daily template without opening a buffer (same pattern as add_todo_to_daily).
  local today_t  = os.date("*t")
  local y, m, d  = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  local target_ts = os.time({ year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=12, min=0, sec=0 })
  local today_ts  = os.time({ year=today_t.year, month=today_t.month, day=today_t.day, hour=12, min=0, sec=0 })
  local offset    = math.floor((target_ts - today_ts) / 86400 + 0.5)

  local created = false

  local daily_ok, daily = pcall(require, "obsidian.daily")
  if daily_ok then
    local fn = (offset == -1 and daily.yesterday)
            or (offset ==  0 and daily.today)
            or (offset ==  1 and daily.tomorrow)
    if fn then
      pcall(fn)
      created = vim.fn.filereadable(path) == 1
    end
  end

  -- For offsets beyond ±1, try the obsidian client's daily(offset) method
  if not created then
    local ok, client = pcall(function() return require("obsidian").get_client() end)
    if ok and client and type(client.daily) == "function" then
      pcall(function() client:daily(offset) end)
      created = vim.fn.filereadable(path) == 1
    end
  end

  -- Last resort: bare heading (no template)
  if not created then
    vim.fn.writefile({ "# " .. date_str, "" }, path)
  end
end

local function move_todos_to_date()
  local start_line = vim.fn.line("'<")
  local end_line   = vim.fn.line("'>")
  local bufnr      = vim.api.nvim_get_current_buf()

  -- Collect open todos from the selection
  local selected   = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local todo_lines = {}
  local todo_lnums = {}
  for i, line in ipairs(selected) do
    if line:match("^%s*%- %[ %] ") then
      table.insert(todo_lines, line)
      table.insert(todo_lnums, start_line + i - 1)
    end
  end

  if #todo_lines == 0 then
    vim.notify("No open todos in selection", vim.log.levels.WARN)
    return
  end

  local tomorrow_date = os.date("%Y-%m-%d", os.time() + 86400)
  local daily_dir     = vim.fn.expand("~/notes/journal/daily/")

  vim.ui.input({
    prompt  = "Move to date (YYYY-MM-DD): ",
    default = tomorrow_date,
  }, function(input)
    if not input or input == "" then return end

    local target_date = vim.trim(input)
    if not target_date:match("^%d%d%d%d%-%d%d%-%d%d$") then
      vim.notify("Invalid date — expected YYYY-MM-DD", vim.log.levels.ERROR)
      return
    end

    local target_path = daily_dir .. target_date .. ".md"

    -- Flush target buffer if it has unsaved changes
    local tbufnr = vim.fn.bufnr(target_path)
    if tbufnr ~= -1 and vim.api.nvim_buf_is_loaded(tbufnr) and vim.bo[tbufnr].modified then
      vim.api.nvim_buf_call(tbufnr, function() vim.cmd("write") end)
    end

    if vim.fn.filereadable(target_path) == 0 then
      create_daily_note_with_template(target_path, target_date)
    end

    insert_todos_into_file(target_path, todo_lines)

    -- Reload target buffer if open
    tbufnr = vim.fn.bufnr(target_path)
    if tbufnr ~= -1 and vim.api.nvim_buf_is_loaded(tbufnr) then
      vim.api.nvim_buf_call(tbufnr, function() vim.cmd("checktime") end)
    end

    -- Mark todos as moved [>] in the current buffer
    for _, lnum in ipairs(todo_lnums) do
      local line     = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
      local new_line = line:gsub("^(%s*%- )%[ %]( )", "%1[>]%2", 1)
      vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new_line })
    end

    vim.notify(#todo_lines .. " todo(s) moved to " .. target_date, vim.log.levels.INFO)
  end)
end

local function grep_todos()
  require("telescope.builtin").grep_string({
    search = "- \\[ \\]",
    use_regex = true,
    search_dirs = { vim.fn.expand("~/notes") },
    prompt_title = "Open TODOs",
  })
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  -- Load when opening any markdown file inside the vault
  event = {
    "BufReadPre " .. vim.fn.expand("~") .. "/notes/**.md",
    "BufNewFile "  .. vim.fn.expand("~") .. "/notes/**.md",
  },
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    -- Journal
    { "<leader>nd", "<cmd>Obsidian today<cr>",                                 desc = "Daily note (today)" },
    { "<leader>no", "<cmd>Obsidian tomorrow<cr>",                              desc = "Daily note (tomorrow)" },
    { "<leader>ny", "<cmd>Obsidian yesterday<cr>",                             desc = "Daily note (yesterday)" },
    { "<leader>nD", "<cmd>Obsidian dailies<cr>",                               desc = "Browse daily notes" },
    { "<leader>nw", "<cmd>Obsidian weekly<cr>",                                desc = "Weekly note" },
    { "<leader>nW", function() browse_journal("weekly",  "Weekly Notes") end,  desc = "Browse weekly notes" },
    { "<leader>nm", open_monthly_note,                                         desc = "Monthly note" },
    { "<leader>nM", function() browse_journal("monthly", "Monthly Notes") end, desc = "Browse monthly notes" },
    -- Notes
    { "<leader>nn", "<cmd>Obsidian new<cr>",          desc = "New note" },
    { "<leader>nf", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
    { "<leader>ng", "<cmd>Obsidian search<cr>",       desc = "Grep notes" },
    { "<leader>nt", "<cmd>Obsidian tags<cr>",         desc = "Find by tag" },
    -- In-note actions
    { "<leader>nb", "<cmd>Obsidian backlinks<cr>",      desc = "Backlinks" },
    { "<leader>nl", "<cmd>Obsidian links<cr>",          desc = "Links in note" },
    { "<leader>n=", "<cmd>Obsidian toc<cr>",            desc = "Table of contents" },
    { "<leader>nT", "<cmd>Obsidian template<cr>",       desc = "Insert template" },
    { "<leader>nx", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Toggle checkbox" },
    { "<leader>nr", "<cmd>Obsidian rename<cr>",         desc = "Rename note" },
    { "<leader>np", "<cmd>Obsidian paste_img<cr>",      desc = "Paste image" },
    -- Visual mode
    { "<leader>ne", "<cmd>Obsidian extract_note<cr>", mode = "v", desc = "Extract to new note" },
    { "<leader>nL", "<cmd>Obsidian link<cr>",         mode = "v", desc = "Link selection" },
    { "<leader>nK", "<cmd>Obsidian link_new<cr>",     mode = "v", desc = "Link selection to new note" },
    -- Todos
    { "<leader>ni", add_todo_to_daily,      desc = "Capture todo to daily note" },
    { "<leader>n?", grep_todos,             desc = "Open TODOs" },
    { "<leader>nO", move_todos_to_date,      mode = "v", desc = "Move todos to date…" },
  },
  opts = {
    workspaces = {
      { name = "notes", path = "~/notes" },
    },

    daily_notes = {
      folder   = "journal/daily",
      date_format = "%Y-%m-%d",
      template = "daily.md",
    },

    weekly_notes = {
      folder   = "journal/weekly",
      date_format = "%Y-W%V",
      template = "weekly.md",
    },

    templates = {
      folder      = "templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },

    legacy_commands = false,

    -- Use telescope for all pickers
    picker = { name = "telescope.nvim" },

    completion = {
      blink = true,
      min_chars = 2,
    },

    -- Note filename: slugify the title, fall back to timestamp
    note_id_func = function(title)
      if title then
        return title:lower():gsub("%s+", "-"):gsub("[^a-z0-9%-]", "")
      end
      return tostring(os.time())
    end,

    checkbox = {
      order = { " ", "x", ">", "~" },
    },

    ui = {
      enable = false, -- render-markdown.nvim handles all visual rendering
    },
  },
}
