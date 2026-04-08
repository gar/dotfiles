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

    -- today() creates the note with template+frontmatter if it doesn't exist,
    -- or loads it if it does. It does NOT open a buffer (that's note:open(),
    -- which the :Obsidian today command calls after — we skip that here).
    local note = require("obsidian.daily").today()
    local path = tostring(note.path)
    local todo_line = "- [ ] " .. input

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

    vim.notify('Todo captured: "' .. input .. '"', vim.log.levels.INFO)
  end)
end

local function move_todos_to_tomorrow()
  local start_line = vim.fn.line("'<")
  local end_line   = vim.fn.line("'>")
  local bufnr      = vim.api.nvim_get_current_buf()

  -- Collect open todos from the selection
  local selected = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)
  local todo_lines   = {}
  local todo_lnums   = {}
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

  -- Tomorrow's note path
  local tomorrow_ts   = os.time() + 86400
  local tomorrow_date = os.date("%Y-%m-%d", tomorrow_ts)
  local daily_dir     = vim.fn.expand("~/notes/journal/daily/")
  local tomorrow_path = daily_dir .. tomorrow_date .. ".md"

  -- If tomorrow's buffer is open with unsaved changes, flush it first
  local tbufnr = vim.fn.bufnr(tomorrow_path)
  if tbufnr ~= -1 and vim.api.nvim_buf_is_loaded(tbufnr) and vim.bo[tbufnr].modified then
    vim.api.nvim_buf_call(tbufnr, function() vim.cmd("write") end)
  end

  -- Read or seed tomorrow's note
  local lines
  if vim.fn.filereadable(tomorrow_path) == 1 then
    lines = vim.fn.readfile(tomorrow_path)
  else
    vim.fn.mkdir(daily_dir, "p")
    lines = { "# " .. tomorrow_date, "" }
  end

  -- Find first level-1 heading
  local heading_pos = nil
  for i, line in ipairs(lines) do
    if line:match("^# ") then
      heading_pos = i
      break
    end
  end

  if not heading_pos then
    -- No heading: append at the end
    for _, todo in ipairs(todo_lines) do
      table.insert(lines, todo)
    end
  else
    -- Ensure blank line immediately after heading
    if heading_pos + 1 > #lines or lines[heading_pos + 1] ~= "" then
      table.insert(lines, heading_pos + 1, "")
    end

    -- Find last consecutive list item after the heading
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

    -- Ensure blank line after the todo block
    local after = insert_at + #todo_lines
    if after <= #lines and lines[after] ~= "" then
      table.insert(lines, after, "")
    end
  end

  vim.fn.writefile(lines, tomorrow_path)

  -- Refresh tomorrow's buffer if open
  if tbufnr ~= -1 and vim.api.nvim_buf_is_loaded(tbufnr) then
    vim.api.nvim_buf_call(tbufnr, function() vim.cmd("checktime") end)
  end

  -- Mark moved todos as [>] in the current buffer
  for _, lnum in ipairs(todo_lnums) do
    local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1]
    local new_line = line:gsub("^(%s*%- )%[ %]( )", "%1[>]%2", 1)
    vim.api.nvim_buf_set_lines(bufnr, lnum - 1, lnum, false, { new_line })
  end

  vim.notify(#todo_lines .. " todo(s) moved to " .. tomorrow_date, vim.log.levels.INFO)
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
    { "<leader>nO", move_todos_to_tomorrow, mode = "v", desc = "Move todos to tomorrow" },
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
