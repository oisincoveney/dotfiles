return {
  -- Inline color previews (hex, rgb, hsl, tailwind)
  {
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = {
      user_default_options = {
        tailwind = true,
        css = true,
        mode = "virtualtext",
      },
    },
  },
  -- Dim inactive code for focus
  {
    "folke/twilight.nvim",
    cmd = { "Twilight", "TwilightEnable", "TwilightDisable" },
    keys = {
      { "<leader>ut", "<cmd>Twilight<cr>", desc = "Toggle Twilight" },
    },
    opts = {},
  },
}
