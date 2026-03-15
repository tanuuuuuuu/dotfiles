---@type LazySpec
return {
  "dhruvasagar/vim-table-mode",
  ft = "markdown",
  config = function()
    -- セパレータ行のダッシュをセル幅いっぱいに伸ばす
    local function fix_separator_lines(buf)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      for i, line in ipairs(lines) do
        -- セパレータ行: | と -/:/スペース のみで構成される行
        if line:match("^|[%-:%s|]+$") and line:match("%-") then
          local new_cells = {}
          for cell in line:gmatch("|([^|]+)") do
            local width = #cell
            -- セル内の : を保持しつつダッシュで埋める
            local stripped = cell:match("^%s*(.-)%s*$")
            local inner_width = width - 2 -- 前後のスペース分
            if stripped:match("^:.*:$") then
              -- :---: (中央揃え)
              table.insert(new_cells, " :" .. string.rep("-", inner_width - 2) .. ": ")
            elseif stripped:match("^:") then
              -- :--- (左揃え)
              table.insert(new_cells, " :" .. string.rep("-", inner_width - 1) .. " ")
            elseif stripped:match(":$") then
              -- ---: (右揃え)
              table.insert(new_cells, " " .. string.rep("-", inner_width - 1) .. ": ")
            else
              -- --- (デフォルト)
              table.insert(new_cells, " " .. string.rep("-", inner_width) .. " ")
            end
          end
          local new_line = "|" .. table.concat(new_cells, "|") .. "|"
          vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { new_line })
        end
      end
    end

    -- 保存時に全テーブルを整形する autocmd
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("table_mode_format_on_save", { clear = true }),
      pattern = "*.md",
      callback = function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local save_cursor = vim.api.nvim_win_get_cursor(0)

        -- Realign にはテーブルモード ON が必要
        pcall(vim.cmd, "silent TableModeEnable")

        -- テーブル行（|で始まる行）のブロックを検出し、各テーブルで Realign を実行
        local i = 1
        while i <= #lines do
          if lines[i]:match("^%s*|") then
            vim.api.nvim_win_set_cursor(0, { i, 0 })
            pcall(vim.cmd, "TableModeRealign")
            while i <= #lines and lines[i]:match("^%s*|") do
              i = i + 1
            end
          else
            i = i + 1
          end
        end

        -- セパレータ行のダッシュを修正
        fix_separator_lines(0)

        pcall(vim.cmd, "silent TableModeDisable")
        pcall(vim.api.nvim_win_set_cursor, 0, save_cursor)
      end,
    })
  end,
}
