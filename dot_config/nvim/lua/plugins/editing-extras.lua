return {
  -- Interactively swap function arguments, list elements via treesitter
  {
    "mizlan/iswap.nvim",
    keys = {
      { "<leader>cs", "<cmd>ISwapWith<cr>", desc = "Swap argument" },
      { "<leader>cS", "<cmd>ISwapNodeWith<cr>", desc = "Swap node" },
    },
    opts = {},
  },
  -- Better replace and exchange operators
  {
    "gbprod/substitute.nvim",
    keys = {
      { "gs", function() require("substitute").operator() end, desc = "Substitute" },
      { "gss", function() require("substitute").line() end, desc = "Substitute line" },
      { "gS", function() require("substitute").eol() end, desc = "Substitute to EOL" },
      { "gs", function() require("substitute").visual() end, mode = "x", desc = "Substitute" },
      { "gsx", function() require("substitute.exchange").operator() end, desc = "Exchange" },
      { "gsxx", function() require("substitute.exchange").line() end, desc = "Exchange line" },
      { "gsx", function() require("substitute.exchange").visual() end, mode = "x", desc = "Exchange" },
    },
    opts = {},
  },
  -- LSP-aware code folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    keys = {
      { "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
      { "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
      { "zK", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
    },
    opts = {
      provider_selector = function()
        return { "lsp", "indent" }
      end,
    },
    init = function()
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
  },
  -- Smart autosave
  {
    "okuuva/auto-save.nvim",
    enabled = false,
  },
}
