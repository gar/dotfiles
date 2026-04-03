local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local M = {}

-- Custom formatexpr for markdown: treats markdown link URLs as zero-width when
-- computing whether a line needs wrapping.  [visible text](url) counts only
-- "visible text" toward the textwidth limit, matching what obsidian.nvim
-- displays (URLs are concealed when the cursor is not on that line).
--
-- Called by `gq` (v:char == "").  Auto-wrap during insert (v:char != "") falls
-- back to Vim's default, but we remove 't' from formatoptions so that path is
-- never taken.
function M.markdown_formatexpr()
  if vim.v.char ~= "" then return 1 end  -- not a gq call; use default

  local tw = vim.bo.textwidth
  if tw == 0 then tw = 80 end

  local s = vim.v.lnum
  local n = vim.v.count
  if n == 0 then return 1 end

  local lines = vim.api.nvim_buf_get_lines(0, s - 1, s - 1 + n, false)

  -- Visual length: [label](url) counts only the label
  local function vlen(str)
    return #(str:gsub("%[([^%]]*)%]%([^%)]*%)", "%1"))
  end

  -- Detect list prefix on the first line (task "- [ ] ", bullet "- ", numbered "1. ")
  local first = lines[1] or ""
  local prefix = first:match("^%s*[%*%-] %[[^%]]*%] ")
               or first:match("^%s*[%*%-] ")
               or first:match("^%s*%d+%. ")
               or ""
  local cont = string.rep(" ", #prefix)

  -- Collect words, stripping the list prefix / continuation indent
  local words = {}
  for i, line in ipairs(lines) do
    local text
    if i == 1 then
      text = line:sub(#prefix + 1)
    elseif #cont > 0 and line:sub(1, #cont) == cont then
      text = line:sub(#cont + 1)
    else
      text = line
    end
    for w in text:gmatch("%S+") do
      words[#words + 1] = w
    end
  end

  if #words == 0 then return 1 end

  -- Reflow: build output lines using visual width for break decisions
  local out = {}
  local cur = prefix
  local cur_vl = vlen(prefix)

  for _, w in ipairs(words) do
    local wv = vlen(w)
    if cur == prefix or cur == cont then
      cur = cur .. w
      cur_vl = cur_vl + wv
    elseif cur_vl + 1 + wv <= tw then
      cur = cur .. " " .. w
      cur_vl = cur_vl + 1 + wv
    else
      out[#out + 1] = cur
      cur = cont .. w
      cur_vl = #cont + wv
    end
  end
  if #cur > 0 and cur ~= prefix and cur ~= cont then
    out[#out + 1] = cur
  end

  if #out == 0 then return 1 end
  vim.api.nvim_buf_set_lines(0, s - 1, s - 1 + n, false, out)
  return 0
end

augroup("FileTypeSettings", { clear = true })
autocmd("FileType", {
  group = "FileTypeSettings",
  pattern = "markdown",
  callback = function(ev)
    vim.opt_local.textwidth = 80
    -- Use URL-aware formatter for gq; disable auto-wrap-on-type ('t') so that
    -- typing past textwidth never inserts a newline mid-link.
    vim.opt_local.formatexpr = "v:lua.require('editor.autocmds').markdown_formatexpr()"
    vim.opt_local.formatoptions:remove("t")
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldenable = true

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

return M
