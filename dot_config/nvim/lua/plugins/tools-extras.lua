return {
  -- HTTP client (like Postman in nvim)
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    keys = {
      { "<leader>rr", function() require("kulala").run() end, desc = "Run HTTP request", ft = "http" },
      { "<leader>ra", function() require("kulala").run_all() end, desc = "Run all HTTP requests", ft = "http" },
      { "<leader>re", function() require("kulala").set_selected_env() end, desc = "Set HTTP env", ft = "http" },
    },
    opts = {},
  },
  -- Workspace/project switching
  {
    "natecraddock/workspaces.nvim",
    cmd = { "WorkspacesAdd", "WorkspacesRemove", "WorkspacesOpen", "WorkspacesList" },
    keys = {
      { "<leader>fw", "<cmd>WorkspacesOpen<cr>", desc = "Open workspace" },
    },
    opts = {
      hooks = {
        open = { "Telescope find_files" },
      },
    },
  },
  -- YAML schema auto-detection (Docker Compose, K8s, GitHub Actions, etc.)
  {
    "mosheavni/yaml-companion.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
    },
    ft = { "yaml", "yml" },
    keys = {
      { "<leader>cy", "<cmd>lua require('yaml-companion').open_ui_select()<cr>", desc = "YAML schema picker", ft = { "yaml", "yml" } },
    },
    config = function()
      local cfg = require("yaml-companion").setup({
        builtin_matchers = {
          kubernetes = { enabled = true },
        },
        lspconfig = {
          settings = {
            yaml = {
              validate = true,
              schemaStore = { enable = false, url = "" },
            },
          },
        },
      })
      require("lspconfig")["yamlls"].setup(cfg)
    end,
  },
}
