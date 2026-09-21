return {
  -- Show variable values inline while debugging
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", "nvim-treesitter/nvim-treesitter" },
    event = "VeryLazy",
    opts = {},
  },
  -- Persistent breakpoints that survive nvim restarts
  {
    "Weissle/persistent-breakpoints.nvim",
    dependencies = { "mfussenegger/nvim-dap" },
    event = "VeryLazy",
    keys = {
      { "<leader>dB", function() require("persistent-breakpoints.api").toggle_breakpoint() end, desc = "Toggle Breakpoint (persistent)" },
      { "<leader>dc", function() require("persistent-breakpoints.api").set_conditional_breakpoint() end, desc = "Conditional Breakpoint (persistent)" },
      { "<leader>dX", function() require("persistent-breakpoints.api").clear_all_breakpoints() end, desc = "Clear All Breakpoints" },
    },
    opts = {
      load_breakpoints_event = { "BufReadPost" },
    },
  },
  -- Quick language-specific log statements
  {
    "chrisgrieser/nvim-chainsaw",
    keys = {
      { "<leader>cl", function() require("chainsaw").messageLog() end, desc = "Log: message" },
      { "<leader>cv", function() require("chainsaw").variableLog() end, desc = "Log: variable" },
      { "<leader>co", function() require("chainsaw").objectLog() end, desc = "Log: object" },
      { "<leader>cL", function() require("chainsaw").removeLogs() end, desc = "Log: remove all" },
    },
    opts = {},
  },
}
