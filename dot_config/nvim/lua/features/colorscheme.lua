return {
  "sainnhe/gruvbox-material",
  lazy = false,
  priority = 1000,
  config = function()
    vim.g.gruvbox_material_background = "medium"
    vim.g.gruvbox_material_foreground = "material"
    vim.g.gruvbox_material_better_performance = 1
    vim.g.gruvbox_material_enable_bold = 1
    vim.g.gruvbox_material_enable_italic = 1

    local theme_file = vim.fn.expand("~/.config/theme-mode")

    local function apply_theme()
      local f = io.open(theme_file, "r")
      local mode = f and f:read("*l") or "dark"
      if f then f:close() end
      vim.o.background = (mode == "light") and "light" or "dark"
      vim.cmd.colorscheme("gruvbox-material")
    end

    apply_theme()

    -- Watch for theme-mode changes so running instances switch live.
    local uv = vim.uv or vim.loop
    local watcher = uv.new_fs_event()
    if watcher and vim.fn.filereadable(theme_file) == 1 then
      watcher:start(theme_file, {}, function(err, _filename, _events)
        if not err then
          vim.schedule(apply_theme)
        end
      end)
    end
  end,
}
