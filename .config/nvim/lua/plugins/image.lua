---@type LazySpec
return {
  "3rd/image.nvim",
  event = "BufReadPre *.png,*.jpg,*.jpeg,*.gif,*.webp,*.avif,*.ico,*.bmp,*.svg",
  cmd = "ImageToggle",
  keys = {
    { "<Leader>ui", "<Cmd>ImageToggle<CR>", desc = "Toggle image preview" },
  },
  opts = {
    backend = "kitty",
    processor = "magick_rock",
    integrations = {
      markdown = { enabled = true },
    },
    max_width = 100,
    max_height = 30,
    editor_only_render_when_focused = true,
    window_overlap_clear_enabled = true,
  },
}
