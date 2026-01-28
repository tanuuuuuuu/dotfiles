return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    event_handlers = {
      {
        event = "vim_buffer_enter",
        handler = function()
          -- Neo-tree のバッファでは refresh しない（再帰防止）
          if vim.bo.filetype ~= "neo-tree" then
            pcall(vim.cmd, "Neotree refresh")
          end
        end,
      },
    },
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
        never_show = {
          ".DS_Store",
        },
      },
      use_libuv_file_watcher = true,
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.cmd("Neotree focus")
      end,
    })
  end,
}
