-- Paths that project-wide search skips (fzf-lua, grug-far, todo-comments).
-- * repomix-output.*: generated snapshots duplicate the whole repository.
-- * /repos/: library source vendored with `git subtree` as reference
--   material for coding agents. The leading slash anchors the glob to the
--   search root: a nested `repos` directory still matches, and a search
--   started inside `repos/<library>` still finds that library's files.
-- The globs use gitignore syntax, which rg `--glob` and fd `--exclude` share.
local excluded_globs = { "repomix-output.*", "/repos/" }

-- rg arguments as a list, for tools that call rg without a shell.
local rg_exclude_args = vim.tbl_map(function(glob)
  return "--glob=!" .. glob
end, excluded_globs)

-- Shell-quoted prefix for fzf-lua, which runs rg and fd through a shell.
local function shell_prefix(format)
  local parts = vim.tbl_map(function(glob)
    return string.format(format, glob)
  end, excluded_globs)
  return table.concat(parts, " ") .. " "
end

return {
  {
    "ibhagwan/fzf-lua",
    opts = function(_, opts)
      local defaults = require("fzf-lua.defaults").defaults
      local rg_exclude = shell_prefix("--glob='!%s'")
      local fd_exclude = shell_prefix("--exclude='%s'")

      -- Filter at the source so rg and fd never read the excluded paths.
      opts.files = opts.files or {}
      opts.files.rg_opts = rg_exclude .. (opts.files.rg_opts or defaults.files.rg_opts)
      opts.files.fd_opts = fd_exclude .. (opts.files.fd_opts or defaults.files.fd_opts)
      opts.grep = opts.grep or {}
      opts.grep.rg_opts = rg_exclude .. (opts.grep.rg_opts or defaults.grep.rg_opts)

      -- Catch the pickers that do not use rg or fd (git_files, oldfiles, ...).
      opts.file_ignore_patterns = opts.file_ignore_patterns or {}
      table.insert(opts.file_ignore_patterns, "repomix%-output%.[^/]*$")

      -- `git ls-files` lists the vendored subtree because it is tracked.
      -- Paths are relative to the picker cwd, so this hides `repos/` only
      -- from a search at the project root. Recent files and buffers still
      -- show vendored files that you opened on purpose.
      opts.git = opts.git or {}
      opts.git.files = opts.git.files or {}
      opts.git.files.file_ignore_patterns = { "^repos/" }
    end,
  },
  -- Project search and replace must not match, or rewrite, excluded paths.
  {
    "MagicDuck/grug-far.nvim",
    optional = true,
    opts = {
      engines = {
        ripgrep = { extraArgs = table.concat(rg_exclude_args, " ") },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    optional = true,
    opts = {
      search = {
        -- The todo-comments default arguments, then the exclusions. The
        -- plugin does not export its defaults, so the list repeats them.
        args = vim.list_extend({
          "--color=never",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
        }, vim.deepcopy(rg_exclude_args)),
      },
    },
  },
  -- Treesitter structural search and replace
  {
    "cshuaimin/ssr.nvim",
    keys = {
      { "<leader>sr", function() require("ssr").open() end, mode = { "n", "x" }, desc = "Structural Replace (SSR)" },
    },
    opts = {},
  },
  -- Visual undo tree with Telescope
  {
    "debugloop/telescope-undo.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    keys = {
      { "<leader>su", "<cmd>Telescope undo<cr>", desc = "Undo tree" },
    },
    config = function()
      require("telescope").load_extension("undo")
    end,
  },
  -- Single-buffer search/replace with live preview
  {
    "chrisgrieser/nvim-rip-substitute",
    keys = {
      { "<leader>sR", function() require("rip-substitute").sub() end, mode = { "n", "x" }, desc = "Rip Substitute" },
    },
    opts = {},
  },
  -- Search git history by commit content/message/author
  {
    "aaronhallaert/advanced-git-search.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "sindrets/diffview.nvim",
    },
    cmd = "AdvancedGitSearch",
    keys = {
      { "<leader>gS", "<cmd>AdvancedGitSearch<cr>", desc = "Git Search (advanced)" },
    },
    config = function()
      require("telescope").load_extension("advanced_git_search")
    end,
  },
}
