local function project_uses_prettier(bufnr)
  return require("conform").get_formatter_info("prettier", bufnr).cwd ~= nil
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        oxlint = {
          settings = {
            -- In push mode, this defers linting until save.
            run = "onSave",
            typeAware = true,
          },
          before_init = function(init_params, config)
            -- Workaround: hide pull-diagnostic support so the server uses
            -- push mode, where `run = "onSave"` is honored. Without this,
            -- Neovim pulls diagnostics on every change and type-aware
            -- analysis runs on each keystroke.
            -- See https://github.com/oxc-project/oxc/discussions/21317
            if init_params.capabilities.textDocument then
              init_params.capabilities.textDocument.diagnostic = nil
            end
            if init_params.capabilities.workspace then
              init_params.capabilities.workspace.diagnostics = nil
            end

            -- Replicate upstream's initializationOptions plumbing, since
            -- providing before_init replaces the upstream function.
            local init_options = config.init_options or {}
            init_options.settings = vim.tbl_extend("force", init_options.settings or {}, config.settings or {})
            init_params.initializationOptions = init_options
          end,
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
