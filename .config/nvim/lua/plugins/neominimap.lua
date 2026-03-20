return {
  "Isrothy/neominimap.nvim",
  version = "v3.*.*",
  lazy = false,
  dependencies = { "lewis6991/gitsigns.nvim" },
  init = function()
    vim.g.neominimap = {
      auto_enable = true,
      layout = "float",
      current_line_position = "percent",
      float = {
        minimap_width = 10,
      },
    }
  end,
}
