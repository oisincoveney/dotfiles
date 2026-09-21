-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local function prepend_path(dir)
  if vim.fn.isdirectory(dir) == 1 and not vim.env.PATH:find(vim.pesc(dir), 1, false) then
    vim.env.PATH = dir .. ":" .. vim.env.PATH
  end
end

prepend_path("/opt/homebrew/bin")
prepend_path("/usr/local/bin")
