return {
  {
    "karshPrime/tmux-compile.nvim",
    cmd = "TMUXcompile",
    keys = {
      { "<leader>cr", "<cmd>TMUXcompile Run<cr>", desc = "Run (overlay)" },
      { "<leader>cR", "<cmd>TMUXcompile RunH<cr>", desc = "Run (horizontal)" },
      { "<leader>cb", "<cmd>TMUXcompile Make<cr>", desc = "Make (overlay)" },
      { "<leader>cB", "<cmd>TMUXcompile MakeH<cr>", desc = "Make (horizontal)" },
      { "<leader>gg", "<cmd>TMUXcompile lazygit<cr>", desc = "Lazygit (overlay)" },
    },
    opts = {
      overlay_width_percent = 80,
      overlay_height_percent = 80,
      overlay_sleep = -1,
      build_run_config = {
        { extension = { "ts", "js" }, run = "npm run dev", build = "npm run build" },
        { extension = { "rs" }, run = "cargo run", build = "cargo build" },
      },
    },
  },
}
