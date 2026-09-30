-- Generated repomix snapshots duplicate the whole repository, so every
-- search would match them. Exclude them from all fzf-lua pickers.
local repomix_glob = "repomix-output.*"

return {
  {
    "ibhagwan/fzf-lua",
    opts = function(_, opts)
      local defaults = require("fzf-lua.defaults").defaults
      local rg_exclude = "--glob='!" .. repomix_glob .. "' "
      local fd_exclude = "--exclude='" .. repomix_glob .. "' "

      -- Filter at the source so rg and fd never read the snapshot.
      opts.files = opts.files or {}
      opts.files.rg_opts = rg_exclude .. (opts.files.rg_opts or defaults.files.rg_opts)
      opts.files.fd_opts = fd_exclude .. (opts.files.fd_opts or defaults.files.fd_opts)
      opts.grep = opts.grep or {}
      opts.grep.rg_opts = rg_exclude .. (opts.grep.rg_opts or defaults.grep.rg_opts)

      -- Catch the pickers that do not use rg or fd (git_files, oldfiles, ...).
      opts.file_ignore_patterns = opts.file_ignore_patterns or {}
      table.insert(opts.file_ignore_patterns, "repomix%-output%.[^/]*$")
    end,
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
