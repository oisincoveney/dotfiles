local function project_uses_prettier(bufnr)
  return require("conform").get_formatter_info("prettier", bufnr).cwd ~= nil
end

-- Neovim 0.12 advertises `textDocument.diagnostic` plus
-- `workspace.diagnostics.refreshSupport`, so oxlint selects DiagnosticMode::Pull and
-- re-lints on every `textDocument/diagnostic` request.  Neovim pulls on every
-- `didChange`, and oxlint honours its `run` option only in push mode, so the server
-- re-lints the whole file on each keystroke.  With `typeAware` it also spawns tsgolint
-- per run, which drives the memory and CPU blowup.  Withholding the pull-diagnostic
-- capabilities forces push mode, where `run = "onSave"` takes effect.
-- See https://github.com/oxc-project/oxc/discussions/21317
-- `vim.lsp.config` deep-merges tables, so an absent key cannot remove a default.
-- The capabilities must be stripped from the resolved `initialize` params instead.
local function force_push_diagnostics(init_params)
  if init_params.capabilities.textDocument then
    init_params.capabilities.textDocument.diagnostic = nil
  end
  if init_params.capabilities.workspace then
    init_params.capabilities.workspace.diagnostics = nil
  end
end

return {
  {
    -- vim.lsp.config() calls take precedence over lsp/*.lua files in the
    -- runtimepath, so calling it here in `init` (which runs at startup, before
    -- any events) ensures the full config is registered before vim.lsp.enable
    -- fires for this server.  This avoids the race where the FileType autocmd
    -- resolves oxlint's config using only the built-in nvim-lspconfig file
    -- (root_markers: .oxlintrc.json only), causing fe/ to be silently skipped.
    "neovim/nvim-lspconfig",
    init = function()
      vim.lsp.config("oxlint", {
        -- Prefer the project-local binary (matching the installed package
        -- version).  Falls back to PATH (e.g. Mason's oxlint).
        cmd = function(dispatchers, config)
          local local_bin = (config or {}).root_dir
            and vim.fs.joinpath(config.root_dir, "node_modules", ".bin", "oxlint")
          if local_bin and vim.fn.executable(local_bin) == 1 then
            return vim.lsp.rpc.start({ local_bin, "--lsp" }, dispatchers)
          end
          return vim.lsp.rpc.start({ "oxlint", "--lsp" }, dispatchers)
        end,
        -- client/ uses .oxlintrc.json; fe/ uses oxlint.config.ts.  Anchor on the
        -- workspace root rather than the nearest package, so a monorepo starts one
        -- server instead of one per package.  oxlint reads the nested configs itself.
        root_dir = function(bufnr, on_dir)
          local start = vim.api.nvim_buf_get_name(bufnr)
          local markers = { ".oxlintrc.json", "oxlint.config.ts" }
          local root ---@type string?
          for dir in vim.fs.parents(start) do
            for _, marker in ipairs(markers) do
              if vim.uv.fs_stat(vim.fs.joinpath(dir, marker)) then
                root = dir
                break
              end
            end
            -- Never walk past a repository boundary.
            if vim.uv.fs_stat(vim.fs.joinpath(dir, ".git")) then
              break
            end
          end
          on_dir(root)
        end,
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
        workspace_required = true,
        -- Type-aware linting spawns tsgolint per lint run and is the dominant cost
        -- in this setup.  Run it from the CLI instead.
        settings = { run = "onSave", typeAware = true },
        before_init = function(init_params, config)
          force_push_diagnostics(init_params)
          local root = config.root_dir or ""
          local settings = vim.deepcopy(config.settings or {})
          local has_json = vim.uv.fs_stat(vim.fs.joinpath(root, ".oxlintrc.json")) ~= nil
          local has_ts = vim.uv.fs_stat(vim.fs.joinpath(root, "oxlint.config.ts")) ~= nil
          if has_ts and not has_json then
            settings.configPath = "oxlint.config.ts"
          end
          local init_options = config.init_options or {}
          init_options.settings = vim.tbl_extend("force", init_options.settings or {}, settings)
          init_params.initializationOptions = init_options
        end,
      })
    end,
    opts = {
      servers = {
        oxlint = {},
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
      formatters = {
        oxfmt = {
          command = function(_, ctx)
            local local_bin = vim.fs.find("oxfmt", { upward = true, path = ctx.dirname, type = "file" })[1]
            return local_bin or "oxfmt"
          end,
          cwd = require("conform.util").root_file({
            ".oxfmtrc.json",
            ".oxfmtrc.jsonc",
            ".oxlintrc.json",
            ".oxlintrs.json",
            "oxlint.config.ts",
          }),
          require_cwd = true,
        },
      },
    },
  },
}
