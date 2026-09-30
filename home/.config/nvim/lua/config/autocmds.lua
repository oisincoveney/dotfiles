-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Library source vendored with `git subtree` under `<git root>/repos/` is
-- reference material. Reading it should not show lint diagnostics from its
-- own tooling, and saving it should not reformat it with this project's
-- formatter.
local function is_vendored(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local root = path ~= "" and vim.fs.root(buf, ".git")
  return root and vim.startswith(path, root .. "/repos/") or false
end

local function quiet_vendored(buf)
  if not is_vendored(buf) then
    return
  end
  vim.diagnostic.enable(false, { bufnr = buf })
  vim.b[buf].autoformat = false
end

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("vendored_repos", { clear = true }),
  callback = function(event)
    quiet_vendored(event.buf)
  end,
})

-- This file loads on VeryLazy, after the buffers from the command line.
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) then
    quiet_vendored(buf)
  end
end
