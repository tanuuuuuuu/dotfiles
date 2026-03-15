---@type LazySpec
return {
  "dhruvasagar/vim-table-mode",
  ft = "markdown",
  config = function()
    -- 保存時に全テーブルを整形する autocmd
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("table_mode_format_on_save", { clear = true }),
      pattern = "*.md",
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local save_cursor = vim.api.nvim_win_get_cursor(0)

        -- テーブル行（|で始まる行）のブロックを検出し、各テーブルで Realign を実行
        local i = 1
        while i <= #lines do
          if lines[i]:match("^%s*|") then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            pcall(vim.cmd, "TableModeRealign")
            -- テーブルの終わりまでスキップ
            while i <= #lines and lines[i]:match("^%s*|") do
              i = i + 1
            end
          else
            i = i + 1
          end
        end

        pcall(vim.api.nvim_win_set_cursor, 0, save_cursor)
      end,
    })
  end,
}
