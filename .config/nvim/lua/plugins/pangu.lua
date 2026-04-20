-- CJK文字と英数字の間に半角スペースを自動挿入（保存時）
-- 例: "Google Mapは便利です" → "Google Map は便利です"

---@type LazySpec
return {
  "AstroNvim/astrocore",
  opts = {
    autocmds = {
      pangu_spacing = {
        {
          event = "BufWritePre",
          pattern = "*.md",
          desc = "CJK文字と英数字の間に半角スペースを自動挿入",
          callback = function()
            local save_cursor = vim.api.nvim_win_get_cursor(0)
            local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
            local in_code_block = false

            for i, line in ipairs(lines) do
              if line:match("^```") then
                in_code_block = not in_code_block
              elseif not in_code_block and not line:match("^# ") then
                -- [[...]] を一時プレースホルダに退避（Obsidian 内部リンクはそのまま残す）
                local links = {}
                local new_line = line:gsub("%[%[(.-)%]%]", function(content)
                  table.insert(links, "[[" .. content .. "]]")
                  return "\001LINK" .. #links .. "\001"
                end)
                -- CJK の直後に英数字 → 間にスペース挿入
                new_line = vim.fn.substitute(new_line,
                  [[\([一-龥ぁ-んァ-ヶー々〇]\)\([a-zA-Z0-9]\)]],
                  [[\1 \2]], "g")
                -- 英数字の直後に CJK → 間にスペース挿入
                new_line = vim.fn.substitute(new_line,
                  [[\([a-zA-Z0-9]\)\([一-龥ぁ-んァ-ヶー々〇]\)]],
                  [[\1 \2]], "g")
                -- CJK の直後にインラインコード → 間にスペース挿入
                new_line = vim.fn.substitute(new_line,
                  [[\([一-龥ぁ-んァ-ヶー々〇]\)\(`\)]],
                  [[\1 \2]], "g")
                -- インラインコードの直後に CJK → 間にスペース挿入
                new_line = vim.fn.substitute(new_line,
                  [[\(`\)\([一-龥ぁ-んァ-ヶー々〇]\)]],
                  [[\1 \2]], "g")
                -- プレースホルダを元の [[...]] に復元
                new_line = new_line:gsub("\001LINK(%d+)\001", function(idx)
                  return links[tonumber(idx)]
                end)
                if new_line ~= line then
                  vim.api.nvim_buf_set_lines(0, i - 1, i, false, { new_line })
                end
              end
            end

            pcall(vim.api.nvim_win_set_cursor, 0, save_cursor)
          end,
        },
      },
    },
  },
}
