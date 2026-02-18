return {
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Open" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview File History" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview Branch History" },
    },
    opts = {},
  },
}
