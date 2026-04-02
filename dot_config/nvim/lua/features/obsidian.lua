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
      vim.cmd("ObsidianTemplate monthly.md")
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
    { "<leader>nd", "<cmd>ObsidianToday<cr>",       desc = "Daily note" },
    { "<leader>nD", "<cmd>ObsidianDailies<cr>",                               desc = "Browse daily notes" },
    { "<leader>nw", "<cmd>ObsidianWeekly<cr>",                                desc = "Weekly note" },
    { "<leader>nW", function() browse_journal("weekly",  "Weekly Notes") end,  desc = "Browse weekly notes" },
    { "<leader>nM", function() browse_journal("monthly", "Monthly Notes") end, desc = "Browse monthly notes" },
    { "<leader>nm", open_monthly_note,              desc = "Monthly note" },
    -- Notes
    { "<leader>nn", "<cmd>ObsidianNew<cr>",         desc = "New note" },
    { "<leader>nf", "<cmd>ObsidianQuickSwitch<cr>", desc = "Find note" },
    { "<leader>ng", "<cmd>ObsidianSearch<cr>",      desc = "Grep notes" },
    { "<leader>nt", "<cmd>ObsidianTags<cr>",        desc = "Find by tag" },
    -- In-note navigation
    { "<leader>nb", "<cmd>ObsidianBacklinks<cr>",   desc = "Backlinks" },
    { "<leader>nl", "<cmd>ObsidianLinks<cr>",       desc = "Links in note" },
    { "<leader>nT", "<cmd>ObsidianTemplate<cr>",    desc = "Insert template" },
    -- Todos
    { "<leader>n?", grep_todos,                     desc = "Open TODOs" },
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
