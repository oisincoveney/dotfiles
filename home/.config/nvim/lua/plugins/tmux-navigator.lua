return {
  {
    "aserowy/tmux.nvim",
    lazy = false,
    config = function()
      require("tmux").setup({
        copy_sync = {
          enable = false, -- user already has tmux-yank/clipboard setup via oh-my-tmux
        },
        navigation = {
          cycle_navigation = true,
          enable_default_keybindings = true, -- C-h/j/k/l
          persist_zoom = false,
        },
        resize = {
          enable_default_keybindings = true, -- A-h/j/k/l
          resize_step_x = 2,
          resize_step_y = 2,
        },
      })
    end,
  },
}
