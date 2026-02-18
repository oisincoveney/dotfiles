return {
  -- Project-wide TypeScript type-checking via tsc
  {
    "dmmulroy/tsc.nvim",
    cmd = "TSC",
    keys = {
      { "<leader>ct", "<cmd>TSC<cr>", desc = "TypeScript Check (project)" },
    },
    opts = {
      auto_open_qflist = true,
      auto_focus_qflist = true,
    },
  },
  -- Translate cryptic TS errors to plain English
  {
    "dmmulroy/ts-error-translator.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {},
  },
}
