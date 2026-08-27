local function project_uses_prettier(bufnr)
  return require("conform").get_formatter_info("prettier", bufnr).cwd ~= nil
end

return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      -- Keep the persistent LSP process syntax-only.
      -- Run type-aware checks once per save through nvim-lint.
      events = {
        "BufWritePost",
      },
      linters_by_ft = {
        javascript = { "oxlint" },
        javascriptreact = { "oxlint" },
        typescript = { "oxlint" },
        typescriptreact = { "oxlint" },
        vue = { "oxlint" },
        svelte = { "oxlint" },
        astro = { "oxlint" },
      },
      linters = {
        oxlint = {
          args = {
            "--type-aware",
            "--type-check",
            "--format",
            "github",
          },
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {
          settings = {
            typeAware = false,
          },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        javascript = { "oxfmt" },
        javascriptreact = { "oxfmt" },
        typescript = { "oxfmt" },
        typescriptreact = { "oxfmt" },
        vue = { "oxfmt" },
        svelte = function(bufnr)
          return project_uses_prettier(bufnr) and { "prettier" } or { "oxfmt" }
        end,
        astro = function(bufnr)
          return project_uses_prettier(bufnr) and { "prettier" } or {}
        end,
      },
    },
  },
}
