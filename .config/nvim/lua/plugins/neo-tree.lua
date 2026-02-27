return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    commands = {
      reveal_in_finder = function(state)
        local node = state.tree:get_node()
        local path = node:get_id()
        vim.fn.jobstart({ "open", "-R", path }, { detach = true })
      end,
    },
    window = {
      width = 45,
      mappings = {
        ["F"] = "reveal_in_finder",
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
    -- Neovim にフォーカスが戻った時に Neo-tree をリフレッシュ
    vim.api.nvim_create_autocmd("FocusGained", {
      callback = function()
        pcall(vim.cmd, "Neotree refresh")
      end,
    })
  end,
}
