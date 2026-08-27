local function project_uses_prettier(bufnr)
  return require("conform").get_formatter_info("prettier", bufnr).cwd ~= nil
end

local function oxlint_before_init(init_params, config)
  local init_options = config.init_options or {}
  init_options.settings = vim.tbl_extend("force", init_options.settings or {}, config.settings or {})
  init_params.initializationOptions = init_options
  if init_params.capabilities.textDocument then
    init_params.capabilities.textDocument.diagnostic = nil
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {
          settings = {
            run = "onSave",
            typeAware = true,
          },
          before_init = oxlint_before_init,
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
