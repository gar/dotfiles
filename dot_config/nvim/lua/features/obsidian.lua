-- Obsidian-style markdown note-taking via obsidian.nvim.
-- Vault lives at ~/notes with the structure:
--   journal/daily/    YYYY-MM-DD.md
--   journal/weekly/   YYYY-WNN.md
--   journal/monthly/  YYYY-MM.md  (custom, not built-in)
--   templates/        daily.md, weekly.md, monthly.md
--   (everything else) free-form notes

local function open_weekly_note()
  local dir = vim.fn.expand("~/notes/journal/weekly/")
  vim.fn.mkdir(dir, "p")
  local path = dir .. os.date("%Y-W%V") .. ".md"
  local is_new = vim.fn.filereadable(path) == 0
  vim.cmd("e " .. vim.fn.fnameescape(path))
  if is_new then
    vim.defer_fn(function()
      vim.cmd("Obsidian template weekly.md")
    end, 100)
  end
end

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

-- Insert new_lines into lines immediately after the last todo item under the first
-- # heading. Ensures blank lines before the block starts and after it ends.
local function insert_after_todo_block(lines, new_lines)
  local heading_pos = nil
  for i, line in ipairs(lines) do
    if line:match("^# ") then
      heading_pos = i
      break
    end
  end

  if not heading_pos then
    for _, l in ipairs(new_lines) do
      table.insert(lines, l)
    end
    return lines
  end

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
  for i = #new_lines, 1, -1 do
    table.insert(lines, insert_at, new_lines[i])
  end

  local after = insert_at + #new_lines
  if after <= #lines and lines[after] ~= "" then
    table.insert(lines, after, "")
  end

  return lines
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
    lines = insert_after_todo_block(lines, { todo_line })
    vim.fn.writefile(lines, path)

    -- Refresh the buffer if it happens to be open
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("checktime") end)
    end

    local label = date_str or "today"
    vim.notify('Todo captured to ' .. label .. ': "' .. todo_text .. '"', vim.log.levels.INFO)
  end)
end

local function insert_todos_into_file(target_path, todo_lines)
  local lines = vim.fn.readfile(target_path)
  lines = insert_after_todo_block(lines, todo_lines)
  vim.fn.writefile(lines, target_path)
end

-- Create a daily note at `path` for `date_str` (YYYY-MM-DD) using obsidian's
-- template machinery. Falls back to a bare heading if the API isn't available.
local function create_daily_note_with_template(path, date_str)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")

  local y, m, d   = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)")
  local target_ts  = os.time({ year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=12, min=0, sec=0 })

  -- daily.daily({ date = ts }) creates the note for any target date and passes
  -- that date to template substitution — same call used in add_todo_to_daily.
  local created = false
  local daily_ok, daily = pcall(require, "obsidian.daily")
  if daily_ok and type(daily.daily) == "function" then
    pcall(function() daily.daily({ date = target_ts }) end)
    created = vim.fn.filereadable(path) == 1
  end

  -- Last resort: bare heading (no template)
  if not created then
    vim.fn.writefile({ "# " .. date_str, "" }, path)
  end
end

-- Shared logic: move `todo_lines` (at buffer line numbers `todo_lnums`) in
-- `bufnr` to `target_path`, creating the target note if needed.
local function do_move_todos(bufnr, todo_lines, todo_lnums, target_path, target_date)
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
end

-- Parse a date string that may be natural language (e.g. "tomorrow", "next tuesday",
-- "april 14", "3 weeks"). Returns a YYYY-MM-DD string on success, or nil on failure.
-- Uses GNU date -d (Linux) with a gdate fallback (macOS via coreutils in Brewfile).
local function parse_natural_date(input)
  input = vim.trim(input)
  if input:match("^%d%d%d%d%-%d%d%-%d%d$") then
    return input
  end
  for _, cmd in ipairs({ "date", "gdate" }) do
    local result = vim.fn.trim(vim.fn.system({ cmd, "-d", input, "+%Y-%m-%d" }))
    if vim.v.shell_error == 0 and result:match("^%d%d%d%d%-%d%d%-%d%d$") then
      return result
    end
  end
  return nil
end

-- Prompt for a target date then move todo_lines/todo_lnums to it.
-- Shared by both the visual-selection and heading-group move commands.
local function prompt_and_move_todos(bufnr, todo_lines, todo_lnums, empty_msg)
  if #todo_lines == 0 then
    vim.notify(empty_msg or "No open todos in selection", vim.log.levels.WARN)
    return
  end

  local daily_dir = vim.fn.expand("~/notes/journal/daily/")

  vim.ui.input({
    prompt  = "Move to date: ",
    default = "tomorrow",
  }, function(input)
    if not input or input == "" then return end

    local target_date = parse_natural_date(input)
    if not target_date then
      local hint = vim.uv.os_uname().sysname == "Darwin"
        and " (macOS: install coreutils via `brew install coreutils`)"
        or ""
      vim.notify("Could not parse date: " .. input .. hint, vim.log.levels.ERROR)
      return
    end

    do_move_todos(bufnr, todo_lines, todo_lnums, daily_dir .. target_date .. ".md", target_date)
  end)
end

-- Called via the MoveOpenTodosToDate user command (range = true), so start_line
-- and end_line are the visual selection boundaries evaluated by vim at `:` time —
-- more reliable than reading '< / '> marks inside Lua after lazy plugin loading.
local function move_todos_to_date(start_line, end_line)
  local bufnr    = vim.api.nvim_get_current_buf()
  local selected = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  local todo_lines = {}
  local todo_lnums = {}
  for i, line in ipairs(selected) do
    if line:match("^%s*%- %[ %] ") then
      table.insert(todo_lines, line)
      table.insert(todo_lnums, start_line + i - 1)
    end
  end

  prompt_and_move_todos(bufnr, todo_lines, todo_lnums, "No open todos in selection")
end

-- Normal-mode companion to the visual <leader>nO: auto-collects all open todos
-- in the group under the first # heading (blank line after heading, consecutive
-- list items) then prompts for a target date — same prompt as visual mode.
local function move_open_todos_from_heading()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines  = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the first # heading
  local heading_pos = nil
  for i, line in ipairs(lines) do
    if line:match("^# ") then
      heading_pos = i
      break
    end
  end

  if not heading_pos then
    vim.notify("No heading found in current buffer", vim.log.levels.WARN)
    return
  end

  -- Skip the blank line after the heading, then walk the consecutive list block
  local pos = heading_pos + 1
  if pos <= #lines and lines[pos] == "" then
    pos = pos + 1
  end

  local todo_lines = {}
  local todo_lnums = {}
  while pos <= #lines and lines[pos]:match("^[%*%-] ") do
    if lines[pos]:match("^%s*%- %[ %] ") then
      table.insert(todo_lines, lines[pos])
      table.insert(todo_lnums, pos)
    end
    pos = pos + 1
  end

  prompt_and_move_todos(bufnr, todo_lines, todo_lnums, "No open todos found in heading group")
end

-- Promote the todo on the current line into a third-level heading inside the
-- `## Notes` section, then drop into insert mode at the end of that H3 section
-- so the user can start writing. Reuses an existing matching heading if one
-- already exists. Leaves the source todo in place.
local function promote_todo_to_notes_heading()
  local bufnr    = vim.api.nvim_get_current_buf()
  local cur_lnum = vim.api.nvim_win_get_cursor(0)[1]
  local cur_line = vim.api.nvim_buf_get_lines(bufnr, cur_lnum - 1, cur_lnum, false)[1] or ""

  local todo_text = cur_line:match("^%s*[%*%-]%s+%[.%]%s+(.+)$")
  if not todo_text then
    vim.notify("Current line is not a todo item", vim.log.levels.WARN)
    return
  end

  -- (Re)compute the bounds of the `## Notes` section. `##%s` matches H2 only;
  -- `### ` won't match because `%s` needs whitespace, not another `#`.
  local function notes_bounds()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local notes_pos
    for i, line in ipairs(lines) do
      if line:match("^##%s+Notes%s*$") then
        notes_pos = i
        break
      end
    end
    if not notes_pos then return lines, nil, nil end
    local notes_end = #lines + 1
    for i = notes_pos + 1, #lines do
      if lines[i]:match("^##%s") then
        notes_end = i
        break
      end
    end
    return lines, notes_pos, notes_end
  end

  local lines, notes_pos, notes_end = notes_bounds()
  if not notes_pos then
    vim.notify("No `## Notes` heading found", vim.log.levels.WARN)
    return
  end

  local heading_pat = "^###%s+" .. vim.pesc(todo_text) .. "%s*$"
  local heading_pos
  for i = notes_pos + 1, notes_end - 1 do
    if lines[i]:match(heading_pat) then
      heading_pos = i
      break
    end
  end

  local created = false
  if not heading_pos then
    local new_lines = { "### " .. todo_text, "" }
    if notes_end > 1 and lines[notes_end - 1] ~= "" then
      table.insert(new_lines, 1, "")
    end
    vim.api.nvim_buf_set_lines(bufnr, notes_end - 1, notes_end - 1, false, new_lines)
    lines, notes_pos, notes_end = notes_bounds()
    for i = notes_pos + 1, notes_end - 1 do
      if lines[i]:match(heading_pat) then
        heading_pos = i
        break
      end
    end
    created = true
  end

  -- End of this H3 section: next H3/H2 inside Notes, or end of Notes.
  local section_end = notes_end
  for i = heading_pos + 1, notes_end - 1 do
    if lines[i]:match("^###?%s") then
      section_end = i
      break
    end
  end

  -- Land on the trailing blank of the section. If the section has no trailing
  -- blank (or no body at all), insert one so we don't disturb existing content.
  local target = section_end - 1
  if target <= heading_pos or lines[target] ~= "" then
    vim.api.nvim_buf_set_lines(bufnr, section_end - 1, section_end - 1, false, { "" })
    target = section_end
  end

  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd("startinsert")

  if created then
    vim.notify('Added heading: "' .. todo_text .. '"', vim.log.levels.INFO)
  end
end

local function grep_todos()
  require("telescope.builtin").grep_string({
    search = "- \\[ \\]",
    use_regex = true,
    search_dirs = { vim.fn.expand("~/notes") },
    prompt_title = "Open TODOs",
  })
end

local function browse_recent_notes(fd_duration, label)
  local notes_dir = vim.fn.expand("~/notes")
  local results = vim.fn.systemlist({
    "fd", "--extension", "md",
    "--changed-within", fd_duration,
    "--absolute-path",
    "--exclude", "templates",
    notes_dir,
  })
  if #results == 0 then
    vim.notify("No notes changed in the last " .. label, vim.log.levels.INFO)
    return
  end
  table.sort(results, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  require("telescope.pickers").new({}, {
    prompt_title = "Recent Notes: " .. label,
    finder = require("telescope.finders").new_table({
      results = results,
      entry_maker = require("telescope.make_entry").gen_from_file({ cwd = notes_dir }),
    }),
    sorter = require("telescope.config").values.file_sorter({}),
    previewer = require("telescope.config").values.file_previewer({}),
  }):find()
end

-- User command with range so vim evaluates '< / '> at the point ':' is pressed
-- in visual mode, before Lua ever runs. This avoids stale-mark issues caused by
-- lazy plugin loading happening between keypress and function execution.
vim.api.nvim_create_user_command("MoveOpenTodosToDate", function(opts)
  move_todos_to_date(opts.line1, opts.line2)
end, { range = true })

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
    { "<leader>nD", "<cmd>Obsidian dailies -7 7<cr>",                          desc = "Browse daily notes" },
    { "<leader>nw", open_weekly_note,                                          desc = "Weekly note" },
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
    -- Recent notes
    { "<leader>nRd", function() browse_recent_notes("1day",  "24 hours") end, desc = "Recent notes (24h)" },
    { "<leader>nRw", function() browse_recent_notes("7days", "7 days")   end, desc = "Recent notes (7d)"  },
    { "<leader>nRm", function() browse_recent_notes("30days","30 days")  end, desc = "Recent notes (30d)" },
    -- Todos
    { "<leader>ni", add_todo_to_daily,                                         desc = "Capture todo to daily note" },
    { "<leader>nh", promote_todo_to_notes_heading,                             desc = "Todo → heading in Notes" },
    { "<leader>n?", grep_todos,                                                desc = "Open TODOs" },
    { "<leader>nO", ":MoveOpenTodosToDate<CR>",        mode = "v",             desc = "Move todos to date…" },
    { "<leader>nO", move_open_todos_from_heading,       mode = "n",             desc = "Move open todos to date…" },
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
      substitutions = {
        -- {{date}} and {{day}} → date / weekday of the note's target date.
        -- obsidian.nvim's built-ins call os.time() unconditionally, so daily
        -- notes for non-today dates render today's values. The target date
        -- is plumbed through only as ctx.partial_note.id (set from the
        -- target datetime via daily_notes.date_format = "%Y-%m-%d").
        date = function(ctx, suffix)
          local id = ctx and ctx.partial_note and ctx.partial_note.id or ""
          local y, m, d = tostring(id):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
          local ts = y and os.time({ year = y, month = m, day = d, hour = 12 }) or os.time()
          return os.date(suffix and suffix ~= "" and suffix or "%Y-%m-%d", ts)
        end,
        day = function(ctx)
          local id = ctx and ctx.partial_note and ctx.partial_note.id or ""
          local y, m, d = tostring(id):match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
          if y then
            return os.date("%A", os.time({ year = y, month = m, day = d, hour = 12 }))
          end
          return os.date("%A")
        end,
      },
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
