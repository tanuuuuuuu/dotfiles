-- AstroCore provides a central place to modify mappings, vim options, autocommands, and more!
-- Configuration documentation can be found with `:h astrocore`

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        wrap = true, -- 折り返しを有効化
        linebreak = true, -- 単語の途中で折り返さない
        breakindent = true, -- 折り返し行もインデントを維持
        cursorline = true, -- カーソルラインを有効化
        swapfile = false, -- スワップファイルを無効化（Git + undofile で十分）
      },
    },
    autocmds = {
      -- 外部でファイルが変更されたら自動リロード
      auto_reload = {
        {
          event = { "FocusGained", "BufEnter", "CursorHold" },
          command = "silent! checktime",
        },
        {
          -- バッファにも変更がある場合は確認なしでリロード（外部ツール優先）
          event = "FileChangedShell",
          callback = function() vim.v.fcs_choice = "reload" end,
        },
      },
      -- アクティブウィンドウのみカーソルラインを表示
      active_window_cursorline = {
        {
          event = "VimEnter",
          callback = function()
            -- 起動時: 現在のウィンドウ以外のカーソルラインをオフ
            local current_win = vim.api.nvim_get_current_win()
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if win ~= current_win then
                vim.api.nvim_set_option_value("cursorline", false, { win = win })
              end
            end
          end,
        },
        {
          event = { "WinEnter", "BufEnter" },
          callback = function() vim.opt_local.cursorline = true end,
        },
        {
          event = { "WinLeave", "BufLeave" },
          callback = function() vim.opt_local.cursorline = false end,
        },
      },
    },
  },
}
