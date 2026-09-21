return {
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
