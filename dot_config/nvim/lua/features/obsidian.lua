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

    local client = require("obsidian").get_client()
    -- daily_note_path() returns an obsidian.Path object + note id
    local path = tostring(client:daily_note_path())
    local todo_line = "- [ ] " .. input

    -- Let obsidian create the note (applies template, frontmatter, etc.)
    -- client:today() writes the file to disk but does NOT open a buffer.
    if vim.fn.filereadable(path) == 0 then
      client:today()
    end

    local lines = vim.fn.readfile(path)

    -- Find insertion point: first non-blank line after the first heading.
    -- New todo becomes the first item in that section.
    local insert_pos = #lines + 1
    local found_heading = false
    for i, line in ipairs(lines) do
      if not found_heading and line:match("^#") then
        found_heading = true
      elseif found_heading and line ~= "" then
        insert_pos = i
        break
      end
    end

    table.insert(lines, insert_pos, todo_line)
    vim.fn.writefile(lines, path)

    -- Refresh the buffer if it happens to be open
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("checktime") end)
    end

    vim.notify('Todo captured: "' .. input .. '"', vim.log.levels.INFO)
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
    { "<leader>ni", add_todo_to_daily, desc = "Capture todo to daily note" },
    { "<leader>n?", grep_todos,        desc = "Open TODOs" },
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
      enable = true,
      checkboxes = {
        [" "] = { char = "○", hl_group = "ObsidianTodo" },
        ["x"] = { char = "✓", hl_group = "ObsidianDone" },
        [">"] = { char = "→", hl_group = "ObsidianRightArrow" },
        ["~"] = { char = "×", hl_group = "ObsidianTilde" },
      },
    },
  },
}
